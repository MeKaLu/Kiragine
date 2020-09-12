// -----------------------------------------
// |           Kiragine 1.0.2              |
// -----------------------------------------
// Copyright © 2020-2020 Mehmet Kaan Uluç <kaanuluc@protonmail.com>
// This software is provided 'as-is', without any express or implied
// warranty. In no event will the authors be held liable for any damages
// arising from the use of this software.
//
// Permission is granted to anyone to use this software for any purpose,
// including commercial applications, and to alter it and redistribute it
// freely, subject to the following restrictions:
//
// 1. The origin of this software must not be misrepresented; you must not
//    claim that you wrote the original software. If you use this software
//    in a product, an acknowledgment in the product documentation would
//    be appreciated but is not required.
//
// 2. Altered source versions must be plainly marked as such, and must not
//    be misrepresented as being the original software.
//
// 3. This notice may not be removed or altered from any source
//    distribution.

const Builder = @import("std").build.Builder;
const Build = @import("std").build;
const Builtin = @import("std").builtin;
const Zig = @import("std").zig;

usingnamespace @import("libbuild.zig");

pub fn build(b: *Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    const examples = b.option(bool, "examples", "Compile examples?") orelse false;

    var exe: *Build.LibExeObjStep = undefined;
    var run_cmd: *Build.RunStep = undefined;
    var run_step: *Build.Step = undefined;

    const lib = buildEngine(b, target, mode, "./");

    if (examples) {
        exe = buildExe(b, target, mode, "examples/simpleshooter.zig", "simpleshooter", lib, "./");
        exe = buildExe(b, target, mode, "examples/shapedraw.zig", "shapedraw", lib, "./");
        exe = buildExe(b, target, mode, "examples/textures.zig", "textures", lib, "./");
        exe = buildExe(b, target, mode, "examples/particlesystem.zig", "particlesystem", lib, "./");
        exe = buildExe(b, target, mode, "examples/custombatch.zig", "custombatch", lib, "./");

        exe = buildExePrimitive(b, target, mode, "examples/simpleshooteradvanced.zig", "simpleshooter-advanced", lib, "./");
        exe = buildExePrimitive(b, target, mode, "examples/primitive-window.zig", "primitive-window", lib, "./");
        exe = buildExePrimitive(b, target, mode, "examples/primitive-renderer.zig", "primitive-renderer", lib, "./");
        exe = buildExePrimitive(b, target, mode, "examples/primitive-triangle.zig", "primitive-triangle", lib, "./");
    }
}
