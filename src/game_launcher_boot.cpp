#include "launcher_seam.h"

int game_launcher_preboot(std::vector<std::string>& args,
                         const gbarecomp::RunOptions& options) {
    return gbarecomp_launcher_preboot(args, options);
}
