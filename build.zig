// -----------------------------------------
// |           Kiragine 1.1.1              |
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
    const tests = b.option(bool, "tests", "Compile tests?") orelse false;
    strip = b.option(bool, "strip", "Strip the exe?") orelse false;

    var exe: *Build.LibExeObjStep = undefined;
    var run_cmd: *Build.RunStep = undefined;
    var run_step: *Build.Step = undefined;

    const lib = buildEngine(b, target, mode, "./");

    if (tests) {
        exe = buildExe(b, target, mode, "src/tests/atlaspacker.zig", "test-atlaspacker", lib, "./");
        exe = buildExe(b, target, mode, "src/tests/list.zig", "test-list", lib, "./");
        exe = buildExe(b, target, mode, "src/tests/font.zig", "test-font", lib, "./");
    }

    if (examples) {
        exe = buildExe(b, target, mode, "examples/ecs.zig", "ecs", lib, "./");
        exe = buildExe(b, target, mode, "examples/pong.zig", "pong", lib, "./");
        exe = buildExe(b, target, mode, "examples/packer.zig", "packer", lib, "./");
        exe = buildExe(b, target, mode, "examples/collision.zig", "collision", lib, "./");
        exe = buildExe(b, target, mode, "examples/simpleshooter.zig", "simpleshooter", lib, "./");
        exe = buildExe(b, target, mode, "examples/shapedraw.zig", "shapedraw", lib, "./");
        exe = buildExe(b, target, mode, "examples/textures.zig", "textures", lib, "./");
        exe = buildExe(b, target, mode, "examples/flipbook.zig", "flipbook", lib, "./");
        exe = buildExe(b, target, mode, "examples/particlesystem.zig", "particlesystem", lib, "./");
        exe = buildExe(b, target, mode, "examples/custombatch.zig", "custombatch", lib, "./");
        exe = buildExe(b, target, mode, "examples/logging.zig", "logging", lib, "./");

        exe = buildExePrimitive(b, target, mode, "examples/primitive-simpleshooter.zig", "primitive-simpleshooter", lib, "./");
        exe = buildExePrimitive(b, target, mode, "examples/primitive-window.zig", "primitive-window", lib, "./");
        exe = buildExePrimitive(b, target, mode, "examples/primitive-renderer.zig", "primitive-renderer", lib, "./");
        exe = buildExePrimitive(b, target, mode, "examples/primitive-triangle.zig", "primitive-triangle", lib, "./");
    }
}
