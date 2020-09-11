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
## Core API
* Initializes the engine. Respectively:

--> Update/FixedUpdate/Draw function,

-->  Window width/height and title,

--> Target(Maximum) fps if sets the 0 vsync will be enabled otherwise it's disabled,

--> Allocator for allocating memories.

```zig
pub fn init(updatefn: ?fn (deltatime: f32) anyerror!void, fixedupdatefn: ?fn (fixedtime: f32) anyerror!void, draw2dfn: ?fn () anyerror!void, width: i32, height: i32, title: []const  u8, fpslimit: u32, alloc: *std.mem.Allocator) !void
````

* Deinitializes the engine
```zig
pub fn deinit() !void
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
---

## Renderer API
##### 2D Renderer batch tags(Renderer2DBatchTag enum)
* **Only** pixel draw calls can be used in this batch 

--> `pixels`

* **Only** line draw calls can be used in this batch 

--> `lines`

* Triangle & rectangle & circles draw can also be used in non-textured triangle batch

--> `triangles`

* Triangle & rectangle & circles draw can also be used in non-textured quad batch

--> `quads`

---
##### Rectangle type 
```zig
pub const Rectangle = struct {
    x: f32 = 0,
    y: f32 = 0,
    width: f32 = 0,
    height: f32 = 0
};
```

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