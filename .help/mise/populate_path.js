import { spawnSync } from "node:child_process";
import { accessSync, constants, existsSync, lstatSync, readdirSync, readlinkSync, statSync, symlinkSync, unlinkSync } from "node:fs";
import { homedir } from "node:os";
import { basename, join } from "node:path";

populate()

function populate() {
    const miseBinDir = join(homedir(), ".local", "share", "mise")
    const result = spawnSync("mise", ["doctor", "-J"], { encoding: "utf-8" });
    const paths = JSON.parse(result.stdout).paths.filter(p => p.startsWith(miseBinDir));
    const binDir = join(homedir(), ".local", "bin");
    for (const file of readdirSync(binDir)) {
        const absFile = join(binDir, file);
        try {
            let path = readlinkSync(absFile, { encoding: "utf-8" });
            if (path.startsWith(miseBinDir)) {
                unlinkSync(absFile);
            }
        } catch (error) {
        }
    }
    for (const path of paths) {
        for (const file of readdirSync(path)) {
            const absFile = join(path, file);
            const stats = statSync(absFile);
            try {
                accessSync(absFile, constants.X_OK);
            } catch (error) {
                continue;
            }
            if (!stats.isFile() && !stats.isSymbolicLink()) {
                continue;
            }
            const newPath = join(binDir, basename(absFile));
            if (!existsSync(newPath)) {
                symlinkSync(absFile, newPath);
            }
        }
    }
}
