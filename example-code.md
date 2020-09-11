<h1 id="examples">Examples</h1>
<p>More on <a href="https://github.com/Kiakra/Kiragine/tree/master/examples">examples</a></p>
<h2 id="basic-engine-initialization">Basic engine initialization</h2>
<pre class=" language-zig"><code class="prism  language-zig">const std = @import("std");
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
</code></pre>
<hr>
<h2 id="basic-engine-initialization-with-game-loops">Basic engine initialization with game loops</h2>
<pre class=" language-zig"><code class="prism  language-zig">const std = @import("std");
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
</code></pre>

