# API documentation
## Errors might occur(Error)
* Engine is not initialized, initialize it before using the engine

--> `EngineIsNotInitialized`

* Engine is initialized, cannot initialize it again

--> `EngineIsInitialized`

* Current batch cannot able to do thing you are just about to do

--> `InvalidBatch`

* Failes to load texture

--> `FailedToLoadTexture`

* Current batch has filled, cannot able to draw anymore

--> `FailedToDraw`

* Texture is not available or corrupted

--> `InvalidTexture`
    
* Custom batch already enabled

--> `UnableToEnableCustomBatch`
  
* Binding is not available

--> `InvalidBinding`

* Binding list has filled, cannot able to bind anymore

--> `NoEmptyBinding`

* Check has failed(expression was true)

--> `CheckFailed`

* GLFW failed to initialize, check logs!

--> `GLFWFailedToInitialize`

* OpenGL failes to generate vbo, vao, ebo

--> `FailedToGenerateBuffers`

* Object list has been reached it's limits and you are trying to write into it

--> `ObjectOverflow`

* Vertex list has been reached it's limits and you are trying to write into it

--> `VertexOverflow`

* Index list has been reached it's limits and you are trying to write into it

--> `IndexOverflow`

* Submit fn is not initialized and you are trying to execute it

--> `UnknownSubmitFn`

* 'thing' already exists in the other 'thing', cannot add one more time

--> Duplicate,

* Unknown 'thing', corrupted or invalid

--> `Unknown`

* Failed to add 'thing'

--> `FailedToAdd`
---
### Model matrix, helper type
```zig
pub const ModelMatrix = struct {
    model: Mat4x4f = Mat4x4f.identity(), // model matrix
    trans: Mat4x4f = Mat4x4f.identity(), // translation matrix
    rot: Mat4x4f = Mat4x4f.identity(), // rotation matrix 
    sc: Mat4x4f = Mat4x4f.identity(), // scale matrix
	// functions ..
};
```
* Apply the changes were made
```zig
pub fn update(self: *ModelMatrix) void 
```
* Translate the matrix 
```zig
pub fn translate(self: *ModelMatrix, x: f32, y: f32, z: f32) void 
```
* Rotate the matrix 
```zig
pub fn rotate(self: *ModelMatrix, x: f32, y: f32, z: f32, angle: f32) void
```
* Scale the matrix 
```zig
pub fn scale(self: *ModelMatrix, x: f32, y: f32, z: f32) void
```
---
##### Rectangle type 
```zig
pub const Rectangle = struct {
    x: f32 = 0,
    y: f32 = 0,
    width: f32 = 0,
    height: f32 = 0,

    // functions...
};
```
* Get the originated position of the rectangle
```zig
pub fn getOriginated(self: Rectangle) Vec2f 
```
* Get origin of the rectangle
```zig
pub fn getOrigin(self: Rectangle) Vec2f 
```
---
### Texture loading/generating
*  Texture type
```zig
pub const Texture = struct {
    id: u32 = 0,
	width: i32 = 0,
	height: i32 = 0
	// functions ..
};
```
* Creates a texture from png file
```zig
pub fn createFromPNG(path: []const  u8) Error!Texture
```
* Creates a texture from png memory
```zig
pub fn createFromPNGMemory(mem: []const  u8) Error!Texture
```
* Creates a texture from given colour
```zig
pub fn createFromColour(colour: [*]UColour, w: i32, h: i32) Texture
```
* Destroys the texture
```zig
pub fn destroy(self: *Texture) void
```
---
* TODO: FlipBook
---
## Core API
* Callbacks struct
```zig
pub const Callbacks = struct {
    update: ?fn (deltatime: f32) anyerror!void = null,
    fixed: ?fn (fixedtime: f32) anyerror!void = null,
    draw: ?fn () anyerror!void = null,
    resize: ?fn (w: i32, h: i32) void = null,
    close: ?fn () void = null,
};
```
* Initializes the engine
```zig
pub fn init(callbacks: Callbacks, width: i32, height: i32, title: []const  u8, fpslimit: u32, alloc: *std.mem.Allocator) !void
```
* Deinitializes the engine
```zig
pub fn deinit() Error!void
```
* Opens the window
```zig 
pub fn open() Error!void
 ```
 * Closes the window
```zig 
pub fn close() Error!void
 ```
 * Updates the engine
 ```zig 
pub fn update() !void
 ```
* Returns the fps
 ```zig 
pub fn getFps() u32 
```
* Returns the window
 ```zig 
pub fn getWindow() *Window
```
* Returns the input
 ```zig 
pub fn getInput() *Input
```
* Returns the mouse pos x
 ```zig 
pub fn getMouseX() f32
```
* Returns the mouse pos y
 ```zig
pub fn getMouseY() f32
```
* Sets the callbacks
```zig
pub fn setCallbacks(calls: Callbacks) void
``` 
---

## Renderer API
##### 2D Renderer batch tags(Renderer2DBatchTag enum)
* **Only** pixel draw calls can be used in this batch 

--> `pixels`

* Line & circle line draw can olsa be used in non-textured line batch

--> `lines`

* Triangle & rectangle & circles draw can also be used in non-textured triangle batch

--> `triangles`

* Triangle & rectangle & circles draw can also be used in non-textured quad batch

--> `quads`

---
##### Particle type 
```zig
pub const Particle = struct {
    /// Particle position 
    position: Vec2f = Vec2f{},
    /// Particle size 
    size: Vec2f = Vec2f{},

    /// Particle velocity 
    velocity: Vec2f = Vec2f{},
    /// Colour modifier(particle colour)
    colour: Colour = Colour{},

    /// Lifetime modifier,
    /// Particle gonna die after this hits 0 
    lifetime: f32 = 0,

    /// Fade modifier,
    /// Particle gonna fade over lifetime decreases
    /// With this modifier as a decrease value
    fade: f32 = 100,

    /// Fade colour modifier
    /// Particles colour is gonna change over fade modifer,
    /// until hits this modifier value
    fade_colour: Colour = colour, 

    /// Is particle alive?
    is_alive: bool = false,
};
```

---
##### Particle system generic type 
```zig
pub fn ParticleSystemGeneric(maxparticle_count: u32) type {
    return struct {
        const Self = @This();

        /// Maximum particle count
        pub const maxparticle = maxparticle_count;

        /// Particle list
        list: [maxparticle]Particle = undefined,

        /// Draw function for drawing particle
        drawfn: ?fn (self: Particle) Error!void = null
		
		// functions ..
	};
}
```
* Clears the all particles
```zig
pub fn clearAll(self: *Self) void 
```
* Draws the particles

--> Fallbacks to drawing as rectangles

--> if `drawfn` not provided
```zig
pub fn draw(self: *Self) !void 
```
* Draws the particles as rectangles
```zig
pub fn drawAsRectangles(self: Self) Error!void 
```
* Draws the particles as triangles
```zig
pub fn drawAsTriangles(self: Self) Error!void 
```
* Draws the particles as circles
```zig
pub fn drawAsCircles(self: Self) Error!void 
```
* Draws the particles as textures
```zig
pub fn drawAsTextures(self: Self) Error!void 
```
* Updates the particles 
```zig
pub fn update(self: Self, fixedtime: f32) void 
```
* Add particle

--> Will return false if failes to add a particle

--> Which means the list has been filled
```zig
pub fn add(self: *Self, particle: Particle) bool
```
---

* Initializes the renderer

--> Do **not** call this if you already called the `init` function
```zig
pub fn initRenderer(alloc: *std.mem.Allocator, pwin: *const Window) !void 
```

* Deinitializes the renderer

--> Do **not** call this if you already called the `deinit` function
```zig
pub fn deinitRenderer() void 
```
* Clears the screen with given colour
```zig
pub fn clearScreen(r: f32, g: f32, b: f32, a: f32) void 
```
* Returns the 2D camera
```zig
pub fn getCamera2D() *Camera2D 
```
* Enables the autoflush
```zig
pub fn enableAutoFlushBatch2D() void 
```
* Disables the autoflush
```zig
pub fn disableAutoFlushBatch2D() void 
```
* Enables the texture
```zig
pub fn enableTextureBatch2D(t: Texture) void 
```
* Disables the texture
```zig
pub fn disableTextureBatch2D() void 
```
* Returns the enabled texture
```zig
pub fn getTextureBatch2D() Error!Texture
```
* Enables the custom batch
```zig
pub fn enableCustomBatch2D(comptime batchtype: type, batch: *batchtype, shader: u32) Error!void 
```
* Disables the custom batch
```zig
pub fn disableCustomBatch2D(comptime batchtype: type) void 
```
* Returns the current batch
```zig
pub fn getCustomBatch2D(comptime batchtype: type) Error!*batchtype 
```
* Pushes the batch
```zig
pub fn pushBatch2D(tag: Renderer2DBatchTag) Error!void 
```
* Pops the batch
```zig
pub fn popBatch2D() Error!void 
```
* Flushes the batch
```zig
pub fn flushBatch2D() Error!void 
```
* Draws a pixel
```zig
pub fn drawPixel(pixel: Vec2f, colour: Colour) Error!void 
```

* Draws a line
```zig
pub fn drawLine(line0: Vec2f, line1: Vec2f, colour: Colour) Error!void 
```

* Draws a triangle
```zig
pub fn drawTriangle(left: Vec2f, top: Vec2f, right: Vec2f, colour: Colour) Error!void 
```

* Draws a circle

--> The segments are lowered for sake of making it smaller on the batch

```zig
pub fn drawCircle(position: Vec2f, radius: f32, colour: Colour) Error!void 
```

* Draws a circle
```zig
pub fn drawCircleAdvanced(center: Vec2f, radius: f32, startangle: i32, endangle: i32, segments: i32, colour: Colour) Error!void 
```
* Draws a circle line

--> The segments are lowered for sake of making it smaller on the batch

```zig
pub fn drawCircleLines(position: Vec2f, radius: f32, colour: Colour) Error!void 
```

* Draws a circle lines
```zig
pub fn drawCircleLinesAdvanced(center: Vec2f, radius: f32, startangle: i32, endangle: i32, segments: i32, colour: Colour) Error!void 
```

* Draws a rectangle
```zig
pub fn drawRectangle(rect: Rectangle, colour: Colour) Error!void 
```

* Draws a rectangle lines
```zig
pub fn drawRectangleLines(rect: Rectangle, colour: Colour) Error!void 
```

* Draws a rectangle rotated(rotation should be provided in radians)
```zig
pub fn drawRectangleRotated(rect: Rectangle, origin: Vec2f, rotation: f32, colour: Colour) Error!void 
```

* Draws a texture
```zig
pub fn drawTexture(rect: Rectangle, srcrect: Rectangle, colour: Colour) Error!void 
```

* Draws a texture(rotation should be provided in radians)
```zig
pub fn drawTextureRotated(rect: Rectangle, srcrect: Rectangle, origin: Vec2f, rotation: f32, colour: Colour) Error!void 
```
