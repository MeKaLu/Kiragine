# Kiragine
Game engine written in zig(compatible with master branch)

No external dependencies required

## How to compile?
Download this github repo and copy the "libbuild.zig" file to your project for zig's build system

After that all you need to do put this code in `build.zig` file:
```zig
const Builder = @import("std").build.Builder;

usingnamespace @import("libbuild.zig");

pub fn build(b: *Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    const lib = buildEngine(b, target, mode, enginepath);
     
    const exe = buildExe(b, target, mode, path, exename, lib, enginepath);
}

```
`zig build` and done!

## Examples (more on examples directory)

#### Basic engine initialization
```zig
const std = @import("std");
const engine = @import("kiragine");

const windowWidth = 1024;
const windowHeight = 768;
const targetfps = 60;

var allocator = std.heap.page_allocator;

pub fn main() anyerror!void {
  try engine.init(null, null, null, windowWidth, windowHeight, "title", targetfps, allocator);

  try engine.open();
  try engine.update();

  try engine.deinit();
}

```

#### Basic engine initialization with game loops
```zig
const std = @import("std");
const engine = @import("kiragine");

const windowWidth = 1024;
const windowHeight = 768;
const targetfps = 60;

fn update(deltatime: f32) anyerror!void {
  // Game logic
}

fn fixedUpdate(fixedtime: f32) anyerror!void {
  // Game logic
}

fn draw() anyerror!void {
  engine.clearScreen(0.1, 0.1, 0.1, 1.0);
  // Draw calls 
}

var allocator = std.heap.page_allocator;

pub fn main() anyerror!void {
  try engine.init(update, fixedUpdate, draw, windowWidth, windowHeight, "title", targetfps, allocator);

  try engine.open();
  try engine.update();

  try engine.deinit();
}

```

#### About release cycle
* Versioning: major.minor.patch
* Every x.x.3 creates a new minor, which becomes x.(x + 1).0 
* Again every x.3.x creates a new major, which becomes (x + 1).0.x
* When a minor gets created, there will be a new release 
