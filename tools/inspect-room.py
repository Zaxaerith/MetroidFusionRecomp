"""Read original MF room collision data; never write guest or ROM memory.

RLE decoding follows pinned mf src/room.c::RoomRleDecompress, MIT,
Copyright 2025 YohannDR; full license: docs/MF_DECOMP_LICENSE.txt.
"""
import hashlib, json, sys
from pathlib import Path
root = Path(__file__).resolve().parents[1]
rom = (root/'Metroid Fusion (USA).gba').read_bytes()
assert hashlib.sha1(rom).hexdigest() == 'ca33f4348c2c05dd330d37b97e2c5a69531dfe87'
room = int(sys.argv[1])
db = json.loads((root/'third_party/mf/database.json').read_text())
entry = next(e for e in db if e['path'] == f'rooms/main_deck/main_deck_{room}_clipdata.rle')
p = int(entry['addr']['us'],16)
w,h = rom[p-2:p]
passes=[]
for _ in range(2):
    wide=rom[p]!=1;p+=1;out=[]
    while True:
        n=rom[p];p+=1
        if wide:n=n*256+rom[p];p+=1
        if not n:break
        bit=32768 if wide else 128
        if n&bit:out += [rom[p]]*(n&~bit);p+=1
        else:out += rom[p:p+n];p+=n
    passes.append(out)
tiles=[a|b*256 for a,b in zip(*passes)]
assert len(tiles)==w*h
print(f'room={room} width={w} height={h}')
start=int(sys.argv[2]) if len(sys.argv)>2 else 0
end=int(sys.argv[3]) if len(sys.argv)>3 else h
for y in range(start,min(end,h)):
    print(f'{y:02}:',' '.join(f'{v:02x}' for v in tiles[y*w:(y+1)*w]))
