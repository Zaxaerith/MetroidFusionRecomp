"""Small input-only TCP driver. MF state fields come from the pinned decomp."""
import json, os, socket, struct, subprocess, sys, time, zlib, wave, math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PORT = 17654

def png(path, w, h, data):
    def chunk(kind, payload):
        return struct.pack('>I', len(payload)) + kind + payload + struct.pack('>I', zlib.crc32(kind + payload))
    rows = b''.join(b'\0' + data[y*w*3:(y+1)*w*3] for y in range(h))
    path.write_bytes(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>2I5B', w,h,8,2,0,0,0)) + chunk(b'IDAT',zlib.compress(rows)) + chunk(b'IEND',b''))

env = dict(os.environ, GBARECOMP_SELFHEAL_RECOMPILE='0')
env.pop('GBARECOMP_INPUT_REPLAY', None)
(ROOT/'logs').mkdir(exist_ok=True)
log = open(ROOT/'logs/play-run.log', 'w')
args = [str(ROOT/'build/host/MetroidFusionRecomp.exe'), '--rom', str(ROOT/'Metroid Fusion (USA).gba'), '--bios', str(ROOT.parent/'gbarecomp-cli-windows-x86_64/gbabios/gba_bios.bin'), str(ROOT/'game.toml'), '--no-window', '--tcp', str(PORT)]
process = subprocess.Popen(args, cwd=ROOT, env=env, stdout=log, stderr=log)
sock = None
try:
    deadline = time.monotonic() + 20
    while sock is None:
        if process.poll() is not None: raise RuntimeError('host exited')
        try: sock = socket.create_connection(('127.0.0.1',PORT),1)
        except OSError:
            if time.monotonic() > deadline: raise
            time.sleep(.1)
    sock.settimeout(60)
    stream = sock.makefile('rb')
    def call(cmd, **fields):
        sock.sendall(json.dumps(dict(cmd=cmd,**fields)).encode()+b'\n')
        result = json.loads(stream.readline())
        if not result.get('ok'): raise RuntimeError(result)
        return result
    def state():
        data = bytes.fromhex(call('read_iwram',addr=0x03000000,len=0x1340)['data'])
        u16 = lambda off: struct.unpack_from('<H',data,off)[0]
        bullets=[dict(slot=i,status=data[0x960+i*32],x=u16(0x96a+i*32),y=u16(0x968+i*32)) for i in range(16) if data[0x960+i*32]]
        return dict(frame=call('frame')['frame'], mode=u16(0xbde), sub1=u16(0xbe0),sub2=data[0xbe2],event=data[0xb87],area=data[0x2c],room=data[0x2d],pose=data[0x1245],x=u16(0x125a),y=u16(0x125c),vx=struct.unpack_from('<h',data,0x125e)[0],vy=struct.unpack_from('<h',data,0x1260)[0],energy=u16(0x1310),bullets=bullets)
    if len(sys.argv) > 1:
        call('savestate_load',path=str(ROOT/sys.argv[1]))
    print(json.dumps(dict(ready=True,**state())),flush=True)
    for line in sys.stdin:
        req = json.loads(line)
        action = req.pop('action')
        if action == 'boot':
            events = [tuple((int(a),int(b,16))) for a,b in (line.split(',') for line in (ROOT/'tests/new-game-input.csv').read_text().splitlines())]
            for idx,(frame,key) in enumerate(events):
                end = events[idx+1][0] if idx+1 < len(events) else 19000
                if end > frame: call('run_frames',n=end-frame,keyinput=key)
            result = state()
        elif action == 'input':
            call('run_frames',n=req['frames'],keyinput=0x3ff ^ req.get('buttons',0))
            result = state()
        elif action == 'press':
            for _ in range(req.get('count',1)):
                call('run_frames',n=req.get('held',2),keyinput=0x3ff ^ req.get('buttons',1))
                call('run_frames',n=req.get('released',58),keyinput=0x3ff)
            result = state()
        elif action == 'audio':
            cap=call('audio_cap',count=65536)
            pcm=bytes.fromhex(cap['mixed'])
            path=ROOT/'logs'/req.get('name','game-audio.wav')
            with wave.open(str(path),'wb') as wav:
                wav.setnchannels(1);wav.setsampwidth(2);wav.setframerate(cap['rate']);wav.writeframes(pcm)
            samples=struct.unpack('<'+'h'*(len(pcm)//2),pcm)
            result=dict(path=str(path),rate=cap['rate'],count=len(samples),peak=max(abs(v) for v in samples),rms=math.sqrt(sum(v*v for v in samples)/len(samples)))
        elif action == 'snapshot':
            shot = call('screenshot')
            path = ROOT/'logs'/req.get('name','play.png')
            png(path,shot['w'],shot['h'],bytes.fromhex(shot['data']))
            result = dict(path=str(path),**state())
        elif action == 'save': result = call('savestate_save',path=str(ROOT/'logs'/req['name']))
        elif action == 'state': result = state()
        elif action == 'sprites':
            data=bytes.fromhex(call('read_iwram',addr=0x03000140,len=56*24)['data'])
            result=[dict(slot=i,status=struct.unpack_from('<H',data,i*56)[0],id=data[i*56+29],pose=data[i*56+36],health=struct.unpack_from('<H',data,i*56+20)[0],x=struct.unpack_from('<H',data,i*56+4)[0],y=struct.unpack_from('<H',data,i*56+2)[0]) for i in range(24) if struct.unpack_from('<H',data,i*56)[0]]
        elif action == 'quit':
            result = call('quit')
            print(json.dumps(result),flush=True)
            break
        else: result = call(action,**req)
        print(json.dumps(result),flush=True)
finally:
    if sock: sock.close()
    if process.poll() is None:
        try: process.wait(timeout=5)
        except subprocess.TimeoutExpired: process.terminate(); process.wait(timeout=5)
    log.close()
