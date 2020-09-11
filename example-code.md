<h1 id="examples">Examples</h1>
<p>More on <a href="https://github.com/Kiakra/Kiragine/tree/master/examples">examples</a></p>
<h2 id="how-to-compile">How to compile?</h2>
<p>Download this github repo and copy the “libbuild.zig” file to your project for zig’s build system</p>
<p>After that all you need to do put this code in <code>build.zig</code> file:</p>
<pre class=" language-zig"><code class="prism  language-zig">const Builder = @import("std").build.Builder;
usingnamespace @import("libbuild.zig");

pub fn build(b: *Builder) void {
	const target = b.standardTargetOptions(.{});
	const mode = b.standardReleaseOptions();

	const lib = buildEngine(b, target, mode, enginepath);
	const exe = buildExe(b, target, mode, path, exename, lib, enginepath);
}
</code></pre>
<p><code>zig build</code> and done!</p>
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

