# Examples
More on [examples](https://github.com/Kiakra/Kiragine/tree/master/examples)

## Basic engine initialization
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
-------------------------
## Basic engine initialization with game loops
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
