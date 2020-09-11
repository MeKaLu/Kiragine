# API documentation
### Errors might occur
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
### Texture loading/generating
*  Texture type
```zig
pub const Texture = struct {
    id: u32 = 0,
	width: i32 = 0,
	height: i32 = 0
	// functions ..
}
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
### Core API
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

### Renderer API
TODO:
