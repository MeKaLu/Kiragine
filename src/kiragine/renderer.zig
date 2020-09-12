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

// TODO: 3D camera 
// TODO: Text rendering
// TODO: Some kind of ecs
// TODO: Simple layering system

const std = @import("std");

const renderer = @import("kira/renderer.zig");
const gl = @import("kira/gl.zig");
const utils = @import("kira/utils.zig");
const c = @import("kira/c.zig");
const m = @import("kira/math/common.zig");
usingnamespace @import("sharedtypes.zig");

pub const Vertex2DNoTexture = comptime renderer.VertexGeneric(false, Vec2f);
pub const Vertex2DTexture = comptime renderer.VertexGeneric(true, Vec2f);
// Maybe create a white texture and remove this?
// With that you'll be able to use textured batchs with shape draw calls
pub const Batch2DQuadNoTexture = comptime renderer.BatchGeneric(1024 * 8, 6, 4, Vertex2DNoTexture);
pub const Batch2DQuadTexture = comptime renderer.BatchGeneric(1024 * 8, 6, 4, Vertex2DTexture);

/// Helper type
const Renderer2D = struct {
    tag: Renderer2DBatchTag = Renderer2DBatchTag.quads,
    cam: Camera2D = Camera2D{},
    
    quadbatch_notexture: Batch2DQuadNoTexture = Batch2DQuadNoTexture{},
    quadbatch_texture: Batch2DQuadTexture = Batch2DQuadTexture{},
    current_texture: Texture = Texture{},

    current_quadbatch_notexture: *Batch2DQuadNoTexture = undefined,
    current_quadbatch_texture: *Batch2DQuadTexture = undefined,
    current_quadbatch_shader: u32 = undefined,
    custombatch: bool = false,

    autoflush: bool = true,

    notextureshader: u32 = 0,
    textureshader: u32 = 0,
    textured: bool = false,
};

pub const Renderer2DBatchTag = enum {
    pixels,
    /// Line & circle line draw can olsa be used in non-textured line batch
    lines,
    /// Triangle & rectangle & circles draw can also be used in non-textured triangle batch
    triangles,
    /// Triangle & rectangle & circles draw can also be used in non-textured quad batch
    quads,
};

pub const Rectangle = struct {
    x: f32 = 0,
    y: f32 = 0,
    width: f32 = 0,
    height: f32 = 0,
};

/// Particle type
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

/// Particle system generic function
pub fn ParticleSystemGeneric(maxparticle_count: u32) type {
    return struct {
        const Self = @This();

        /// Maximum particle count
        pub const maxparticle = maxparticle_count;

        /// Particle list
        list: [maxparticle]Particle = undefined,

        /// Draw function for drawing particle
        drawfn: ?fn (self: Particle) Error!void = null,

        /// Clear the all particles
        pub fn clearAll(self: *Self) void {
            // This is going to set every particle to default values
            self.list = undefined;
        }

        /// Draw the particles
        pub fn draw(self: Self) Error!void {
            if (self.drawfn) |fun| {
                var i: u32 = 0;
                while (i < Self.maxparticle) : (i += 1) {
                    if (self.list[i].is_alive) {
                        try fun(self.list[i]);
                    }
                }
            } else {
                try utils.printEndl(utils.LogLevel.warn, "kiragine -> particle system draw fallbacks to drawing as rectangles", .{});
                try self.drawAsRectangle();
            }
        }

        /// Draws the particles as rectangles
        pub fn drawAsRectangles(self: Self) Error!void {
            var i: u32 = 0;
            while (i < Self.maxparticle) : (i += 1) {
                if (self.list[i].is_alive) {
                    const rect = Rectangle{
                        .x = self.list[i].position.x,
                        .y = self.list[i].position.y,
                        .width = self.list[i].size.x,
                        .height = self.list[i].size.y,
                    };
                    try drawRectangle(rect, self.list[i].colour);
                }
            }
        }
        
        /// Draws the particles as triangles
        pub fn drawAsTriangles(self: Self) Error!void {
            var i: u32 = 0;
            while (i < Self.maxparticle) : (i += 1) {
                if (self.list[i].is_alive) {
                    const triangle = [3]Vec2f{
                        .{ .x = self.list[i].position.x, .y = self.list[i].position.y },
                        .{ .x = self.list[i].position.x + (self.list[i].size.x / 2), .y = self.list[i].position.y - self.list[i].size.y },
                        .{ .x = self.list[i].position.x + self.list[i].size.x, .y = self.list[i].position.y },
                    };
                    try drawTriangle(triangle[0], triangle[1], triangle[2], self.list[i].colour);
                }
            }
        }
        
        /// Draws the particles as circles
        pub fn drawAsCircles(self: Self) Error!void {
            var i: u32 = 0;
            while (i < Self.maxparticle) : (i += 1) {
                if (self.list[i].is_alive) {
                    const rad: f32 = (self.list[i].size.x / self.list[i].size.y) * 10;
                    try drawCircle(self.list[i].position, rad, self.list[i].colour);
                }
            }
        }
        
        /// Draws the particles as textures
        /// Don't forget the enable texture batch!
        pub fn drawAsTextures(self: Self) Error!void {
            var i: u32 = 0;
            while (i < Self.maxparticle) : (i += 1) {
                if (self.list[i].is_alive) {
                    const t = try getTextureBatch2D();
                    const rect = Rectangle{
                        .x = self.list[i].position.x,
                        .y = self.list[i].position.y,
                        .width = self.list[i].size.x,
                        .height = self.list[i].size.y,
                    };
                    const srcrect = Rectangle{
                        .x = 0, 
                        .y = 0, 
                        .width = t.width, 
                        .height = t.height, 
                    };
                    try drawTexture(rect, srcrect, self.list[i].colour);
                }
            }
        }

        /// Update the particles
        pub fn update(self: *Self, fixedtime: f32) void {
            var i: u32 = 0;
            while (i < Self.maxparticle) : (i += 1) {
                if (self.list[i].is_alive) {
                    const vel = Vec2f{
                        .x = self.list[i].velocity.x * fixedtime,
                        .y = self.list[i].velocity.y * fixedtime,
                    };
                    self.list[i].position = Vec2f.add(self.list[i].position, vel);
                    if (self.list[i].lifetime > 0) {
                        self.list[i].lifetime -= 1 * fixedtime;
                        var alpha: f32 = self.list[i].colour.a;
                        var r: f32 = self.list[i].colour.r;
                        var g: f32 = self.list[i].colour.g;
                        var b: f32 = self.list[i].colour.b;

                        if (r < self.list[i].fade_colour.r) {
                            r = self.list[i].fade_colour.r;
                        } else r = ((r * 255.0) - (self.list[i].fade * fixedtime)) / 255.0;
                        
                        if (g < self.list[i].fade_colour.g) {
                            g = self.list[i].fade_colour.g;
                        } else g = ((g * 255.0) - (self.list[i].fade * fixedtime)) / 255.0;
                        
                        if (b < self.list[i].fade_colour.b) {
                            b = self.list[i].fade_colour.b;
                        } else b = ((b * 255.0) - (self.list[i].fade * fixedtime)) / 255.0;
                        
                        if (alpha < self.list[i].fade_colour.a) {
                            alpha = self.list[i].fade_colour.a;
                        } else alpha = ((alpha * 255.0) - (self.list[i].fade * fixedtime)) / 255.0;

                        self.list[i].colour.a = alpha;
                        self.list[i].colour.r = r;
                        self.list[i].colour.g = g;
                        self.list[i].colour.b = b; 
                    } else self.list[i].is_alive = false;
                }
            }
        }

        /// Add particle
        /// Will return false if failes to add a particle
        /// Which means the list has been filled
        pub fn add(self: *Self, particle: Particle) bool {
            var i: u32 = 0;
            while (i < Self.maxparticle) : (i += 1) {
                if (!self.list[i].is_alive) {
                    self.list[i] = particle;
                    self.list[i].is_alive = true;
                    return true;
                }
            }
            return false;
        }
    };
}

const pnotexture_vertex_shader =
    \\#version 330 core
    \\layout (location = 0) in vec2 aPos;
    \\layout (location = 1) in vec4 aColour;
    \\
    \\out vec4 ourColour;
    \\uniform mat4 MVP;
    \\
    \\void main() {
    \\  gl_Position = MVP * vec4(aPos.xy, 0.0, 1.0);
    \\  ourColour = aColour;
    \\}
;

const pnotexture_fragment_shader =
    \\#version 330 core
    \\
    \\out vec4 final;
    \\in vec4 ourColour;
    \\
    \\void main() {
    \\  final = ourColour;
    \\}
;

const ptexture_vertex_shader =
    \\#version 330 core
    \\layout (location = 0) in vec2 aPos;
    \\layout (location = 1) in vec2 aTexCoord;
    \\layout (location = 2) in vec4 aColour;
    \\
    \\out vec2 ourTexCoord;
    \\out vec4 ourColour;
    \\uniform mat4 MVP;
    \\
    \\void main() {
    \\  gl_Position = MVP * vec4(aPos.xy, 0.0, 1.0);
    \\  ourTexCoord = aTexCoord;
    \\  ourColour = aColour;
    \\}
;

const ptexture_fragment_shader =
    \\#version 330 core
    \\
    \\out vec4 final;
    \\in vec2 ourTexCoord;
    \\in vec4 ourColour;
    \\uniform sampler2D uTexture;
    \\
    \\void main() {
    \\  vec4 texelColour = texture(uTexture, ourTexCoord);
    \\  final = ourColour * texelColour;
    \\}
;

var prenderer2D: *Renderer2D = undefined;
var allocator: *std.mem.Allocator = undefined;

/// Initializes the renderer
/// WARN: Do NOT call this if you already called the init function
pub fn initRenderer(alloc: *std.mem.Allocator, pwin: *const Window) !void {
    allocator = alloc;
    prenderer2D = try allocator.create(Renderer2D);
    
    prenderer2D.* = Renderer2D{};
    prenderer2D.cam.ortho = Mat4x4f.ortho(0, @intToFloat(f32, pwin.size.width), @intToFloat(f32, pwin.size.height), 0, -1, 1);

    prenderer2D.notextureshader = try gl.shaderProgramCreate(allocator, pnotexture_vertex_shader, pnotexture_fragment_shader);
    prenderer2D.textureshader = try gl.shaderProgramCreate(allocator, ptexture_vertex_shader, ptexture_fragment_shader);

    try prenderer2D.quadbatch_notexture.create(prenderer2D.notextureshader, pnoTextureShaderAttribs);
    try prenderer2D.quadbatch_texture.create(prenderer2D.textureshader, pTextureShaderAttribs);

    prenderer2D.current_quadbatch_notexture = &prenderer2D.quadbatch_notexture;
    prenderer2D.current_quadbatch_texture = &prenderer2D.quadbatch_texture;
}

/// Deinitializes the renderer
/// WARN: Do NOT call this if you already called the deinit function
pub fn deinitRenderer() void {
    prenderer2D.quadbatch_notexture.destroy();
    prenderer2D.quadbatch_texture.destroy();

    gl.shaderProgramDelete(prenderer2D.notextureshader);
    gl.shaderProgramDelete(prenderer2D.textureshader);
    
    allocator.destroy(prenderer2D);
}

/// Clears the screen with given colour
pub fn clearScreen(r: f32, g: f32, b: f32, a: f32) void {
    gl.clearColour(r, g, b, a);
    gl.clearBuffers(gl.BufferBit.colour);
}

/// Returns the 2D camera
pub fn getCamera2D() *Camera2D {
    return &prenderer2D.cam;
}

/// Enables the autoflush
pub fn enableAutoFlushBatch2D() void {
    prenderer2D.autoflush = true;
}

/// Disables the autoflush
pub fn disableAutoFlushBatch2D() void {
    prenderer2D.autoflush = true;
}

/// Enables the texture
pub fn enableTextureBatch2D(t: Texture) void {
    prenderer2D.current_texture = t;
    prenderer2D.textured = true;
}

/// Disables the texture
pub fn disableTextureBatch2D() void {
    prenderer2D.current_texture.id = 0;
    prenderer2D.textured = false;
}

/// Returns the enabled texture
pub fn getTextureBatch2D() Error!Texture {
    if (prenderer2D.textured) {
        return prenderer2D.current_texture;
    }
    return Error.InvalidTexture;
}

/// Enables the custom batch
pub fn enableCustomBatch2D(comptime batchtype: type, batch: *batchtype, shader: u32) Error!void {
    if (batchtype == Batch2DQuadNoTexture) {
        if (prenderer2D.custombatch) {
            return Error.UnableToEnableCustomBatch; 
        }
        prenderer2D.custombatch = true;
        prenderer2D.current_quadbatch_notexture = batch;
        prenderer2D.current_quadbatch_shader = shader;
        return;
    } else if (batchtype == Batch2DQuadTexture) {
        if (prenderer2D.custombatch) {
            return Error.UnableToEnableCustomBatch; 
        }
        prenderer2D.custombatch = true;
        prenderer2D.current_quadbatch_texture = batch;
        prenderer2D.current_quadbatch_shader = shader;
        return;
    }

    @compileError("Unknown batch type!");
}

/// Disables the custom batch
pub fn disableCustomBatch2D(comptime batchtype: type) void {
    if (batchtype == Batch2DQuadNoTexture) {
        prenderer2D.custombatch = false;
        prenderer2D.current_quadbatch_notexture = undefined;
        prenderer2D.current_quadbatch_shader = 0;
        return;
    } else if (batchtype == Batch2DQuadTexture) {
        prenderer2D.custombatch = false;
        prenderer2D.current_quadbatch_texture = undefined;
        prenderer2D.current_quadbatch_shader = 0;
        return;
    }

    @compileError("Unknown batch type!");
}

/// Returns the current batch 
pub fn getCustomBatch2D(comptime batchtype: type) Error!*batchtype {
    if (batchtype == Batch2DQuadNoTexture) {
        return &current_quadbatch_notexture;
    } else if (batchtype == Batch2DQuadTexture) {
        return &current_quadbatch_texture;
    }

    @compileError("Unknown batch type!");
}

/// Pushes the batch
pub fn pushBatch2D(tag: Renderer2DBatchTag) Error!void {
    prenderer2D.tag = tag;

    switch (prenderer2D.tag) {
        Renderer2DBatchTag.pixels => {
            if (prenderer2D.textured) return Error.InvalidBatch; // No textured lines
            prenderer2D.current_quadbatch_notexture.submitfn = pnoTextureSubmitQuadfn;
        },
        Renderer2DBatchTag.lines => {
            if (prenderer2D.textured) return Error.InvalidBatch; // No textured lines
            prenderer2D.current_quadbatch_notexture.submitfn = pnoTextureSubmitQuadfn;
        },
        Renderer2DBatchTag.triangles => {
            if (prenderer2D.textured) return Error.InvalidBatch; // No textured triangle
            prenderer2D.current_quadbatch_notexture.submitfn = pnoTextureSubmitQuadfn;
        },
        Renderer2DBatchTag.quads => {
            prenderer2D.current_quadbatch_texture.submitfn = pTextureSubmitQuadfn;
            prenderer2D.current_quadbatch_notexture.submitfn = pnoTextureSubmitQuadfn;
        },
    }

    var shader: u32 = 0;
    var mvploc: i32 = -1;
    if (!prenderer2D.textured) {
        if (prenderer2D.custombatch) {
            shader = prenderer2D.current_quadbatch_shader;
        } else {
            shader = prenderer2D.notextureshader;
        }
        try utils.check(shader == 0, "kiragine -> unable to use non-textured shader!", .{});

        mvploc = gl.shaderProgramGetUniformLocation(shader, "MVP");
        try utils.check(mvploc == -1, "kiragine -> unable to use uniforms from non-textured shader!", .{});
    } else {
        if (prenderer2D.custombatch) {
            shader = prenderer2D.current_quadbatch_shader;
        } else {
            shader = prenderer2D.textureshader;
        }
        try utils.check(shader == 0, "kiragine -> unable to use textured shader!", .{});

        mvploc = gl.shaderProgramGetUniformLocation(shader, "MVP");
        try utils.check(mvploc == -1, "kiragine -> unable to use uniforms from textured shader!", .{});
    }

    gl.shaderProgramUse(shader);

    prenderer2D.cam.attach();
    gl.shaderProgramSetMat4x4f(mvploc, @ptrCast([*]const f32, &prenderer2D.cam.view.toArray()));
}

/// Pops the batch
pub fn popBatch2D() Error!void {
    defer {
        prenderer2D.cam.detach();
        if (prenderer2D.textured) {
            prenderer2D.current_quadbatch_texture.submission_counter = 0;
            prenderer2D.current_quadbatch_texture.vertex_list = undefined;
            prenderer2D.current_quadbatch_texture.index_list = undefined;
        } else {
            prenderer2D.current_quadbatch_notexture.submission_counter = 0;
            prenderer2D.current_quadbatch_notexture.vertex_list = undefined;
            prenderer2D.current_quadbatch_notexture.index_list = undefined;
        }
    }

    switch (prenderer2D.tag) {
        Renderer2DBatchTag.pixels => {
            if (prenderer2D.textured) {
                return Error.InvalidBatch;
            } else {
                try prenderer2D.current_quadbatch_notexture.draw(gl.DrawMode.points);
            }
        },
        Renderer2DBatchTag.lines => {
            if (prenderer2D.textured) {
                return Error.InvalidBatch;
            } else {
                try prenderer2D.current_quadbatch_notexture.draw(gl.DrawMode.lines);
            }
        },
        Renderer2DBatchTag.triangles => {
            if (prenderer2D.textured) {
                return Error.InvalidBatch;
            } else {
                try prenderer2D.current_quadbatch_notexture.draw(gl.DrawMode.triangles);
            }
        },
        Renderer2DBatchTag.quads => {
            if (prenderer2D.textured) {
                gl.textureBind(gl.TextureType.t2D, prenderer2D.current_texture.id);
                try prenderer2D.current_quadbatch_texture.draw(gl.DrawMode.triangles);
                gl.textureBind(gl.TextureType.t2D, 0);
            } else {
                try prenderer2D.current_quadbatch_notexture.draw(gl.DrawMode.triangles);
            }
        },
    }
}

/// Flushes the batch
pub fn flushBatch2D() Error!void {
    const tag = prenderer2D.tag;
    try popBatch2D();
    try pushBatch2D(tag);
}

/// Draws a pixel
pub fn drawPixel(pixel: Vec2f, colour: Colour) Error!void {
    if (prenderer2D.textured) return Error.InvalidBatch;
    switch (prenderer2D.tag) {
        Renderer2DBatchTag.quads, Renderer2DBatchTag.triangles, Renderer2DBatchTag.lines => {
            return Error.InvalidBatch;
        },
        else => {},
    }
    prenderer2D.current_quadbatch_notexture.submitDrawable([Batch2DQuadNoTexture.max_vertex_count]Vertex2DNoTexture{
        .{ .position = pixel, .colour = colour },
        .{ .position = pixel, .colour = colour },
        .{ .position = pixel, .colour = colour },
        .{ .position = pixel, .colour = colour },
    }) catch |err| {
        if (err == renderer.Error.ObjectOverflow) {
            if (prenderer2D.autoflush) {
                try flushBatch2D();
                try prenderer2D.current_quadbatch_notexture.submitDrawable([Batch2DQuadNoTexture.max_vertex_count]Vertex2DNoTexture{
                    .{ .position = pixel, .colour = colour },
                    .{ .position = pixel, .colour = colour },
                    .{ .position = pixel, .colour = colour },
                    .{ .position = pixel, .colour = colour }
                });
            } else {
                return Error.FailedToDraw;
            }
        } else return err;
    };
}

/// Draws a line
pub fn drawLine(line0: Vec2f, line1: Vec2f, colour: Colour) Error!void {
    if (prenderer2D.textured) return Error.InvalidBatch;
    switch (prenderer2D.tag) {
        Renderer2DBatchTag.quads, Renderer2DBatchTag.triangles => {
            return Error.InvalidBatch;
        },
        else => {},
    }
    prenderer2D.current_quadbatch_notexture.submitDrawable([Batch2DQuadNoTexture.max_vertex_count]Vertex2DNoTexture{
        .{ .position = line0, .colour = colour },
        .{ .position = line1, .colour = colour },
        .{ .position = line1, .colour = colour },
        .{ .position = line1, .colour = colour },
    }) catch |err| {
        if (err == renderer.Error.ObjectOverflow) {
            if (prenderer2D.autoflush) {
                try flushBatch2D();
                try prenderer2D.current_quadbatch_notexture.submitDrawable([Batch2DQuadNoTexture.max_vertex_count]Vertex2DNoTexture{
                    .{ .position = line0, .colour = colour },
                    .{ .position = line1, .colour = colour },
                    .{ .position = line1, .colour = colour },
                    .{ .position = line1, .colour = colour },
                });
            } else {
                return Error.FailedToDraw;
            }
        } else return err;
    };
}

/// Draws a triangle
pub fn drawTriangle(left: Vec2f, top: Vec2f, right: Vec2f, colour: Colour) Error!void {
    if (prenderer2D.textured) return Error.InvalidBatch;
    switch (prenderer2D.tag) {
        Renderer2DBatchTag.lines => {
            return Error.InvalidBatch;
        },
        else => {},
    }
    prenderer2D.current_quadbatch_notexture.submitDrawable([Batch2DQuadNoTexture.max_vertex_count]Vertex2DNoTexture{
        .{ .position = left, .colour = colour },
        .{ .position = top, .colour = colour },
        .{ .position = right, .colour = colour },
        .{ .position = right, .colour = colour },
    }) catch |err| {
        if (err == renderer.Error.ObjectOverflow) {
            if (prenderer2D.autoflush) {
                try flushBatch2D();
                try prenderer2D.current_quadbatch_notexture.submitDrawable([Batch2DQuadNoTexture.max_vertex_count]Vertex2DNoTexture{
                    .{ .position = left, .colour = colour },
                    .{ .position = top, .colour = colour },
                    .{ .position = right, .colour = colour },
                    .{ .position = right, .colour = colour },
                });
            } else {
                return Error.FailedToDraw;
            }
        } else return err;
    };
}

/// Draws a circle
/// The segments are lowered for sake of 
/// making it smaller on the batch
pub fn drawCircle(position: Vec2f, radius: f32, colour: Colour) Error!void {
    try drawCircleAdvanced(position, radius, 0, 360, 16, colour);
}

// Source: https://github.com/raysan5/raylib/blob/f1ed8be5d7e2d966d577a3fd28e53447a398b3b6/src/shapes.c#L209
/// Draws a circle
pub fn drawCircleAdvanced(center: Vec2f, radius: f32, startangle: i32, endangle: i32, segments: i32, colour: Colour) Error!void {
    const SMOOTH_CIRCLE_ERROR_RATE = comptime 0.5;
    
    var iradius = radius;
    var istartangle = startangle;
    var iendangle = endangle;
    var isegments = segments;

    if (iradius <= 0.0) iradius = 0.1;  // Avoid div by zero
    // Function expects (endangle > startangle)
    if (iendangle < istartangle) {
        // Swap values
        const tmp = istartangle;
        istartangle = iendangle;
        iendangle = tmp;
    }
    
    if (isegments < 4) {
        // Calculate the maximum angle between segments based on the error rate (usually 0.5f)
        const th: f32 = std.math.acos(2 * std.math.pow(f32, 1 - SMOOTH_CIRCLE_ERROR_RATE / iradius, 2) - 1);
        isegments = @floatToInt(i32, (@intToFloat(f32, (iendangle - istartangle)) * std.math.ceil(2 * m.PI / th) / 360));

        if (isegments <= 0) isegments = 4;
    }
    const steplen: f32 = @intToFloat(f32, iendangle - istartangle) / @intToFloat(f32, isegments);
    var angle: f32 = @intToFloat(f32, istartangle);

    // NOTE: Every QUAD actually represents two segments
    var i: i32 = 0;
    while (i < @divTrunc(isegments, 2)) : (i += 1) {
        const pos0 = Vec2f{ .x = center.x, .y = center.y };
        const pos1 = Vec2f{ 
            .x = center.x + std.math.sin(m.deg2radf(angle)) * iradius, 
            .y = center.y + std.math.cos(m.deg2radf(angle)) * iradius
        };
        const pos2 = Vec2f{ 
            .x = center.x + std.math.sin(m.deg2radf(angle + steplen)) * iradius, 
            .y = center.y + std.math.cos(m.deg2radf(angle + steplen)) * iradius
        };
        const pos3 = Vec2f{ 
            .x = center.x + std.math.sin(m.deg2radf(angle + steplen * 2)) * iradius, 
            .y = center.y + std.math.cos(m.deg2radf(angle + steplen * 2)) * iradius
        };

        angle += steplen * 2;
        pdrawRectangle(pos0, pos1, pos2, pos3, colour) catch |err| {
            if (err == renderer.Error.ObjectOverflow) {
                if (prenderer2D.autoflush) {
                    try flushBatch2D();
                    try pdrawRectangle(pos0, pos1, pos2, pos3, colour);
                } else {
                    return Error.FailedToDraw;
                }
            } else return err;
        };
    }
    // NOTE: In case number of segments is odd, we add one last piece to the cake
    if (@mod(isegments, 2) != 0) {
        const pos0 = Vec2f{ .x = center.x, .y = center.y };
        const pos1 = Vec2f{ 
            .x = center.x + std.math.sin(m.deg2radf(angle)) * iradius, 
            .y = center.y + std.math.cos(m.deg2radf(angle)) * iradius
        };
        const pos2 = Vec2f{ 
            .x = center.x + std.math.sin(m.deg2radf(angle + steplen)) * iradius, 
            .y = center.y + std.math.cos(m.deg2radf(angle + steplen)) * iradius
        };
        const pos3 = Vec2f{ .x = center.x, .y = center.y };
        
        pdrawRectangle(pos0, pos1, pos2, pos3, colour) catch |err| {
            if (err == renderer.Error.ObjectOverflow) {
                if (prenderer2D.autoflush) {
                    try flushBatch2D();
                    try pdrawRectangle(pos0, pos1, pos2, pos3, colour);
                } else {
                    return Error.FailedToDraw;
                }
            } else return err;
        };
    }
}

/// Draws a circle lines
/// The segments are lowered for sake of 
/// making it smaller on the batch
pub fn drawCircleLines(position: Vec2f, radius: f32, colour: Colour) Error!void {
    try drawCircleLinesAdvanced(position, radius, 0, 360, 16, colour);
}

// Source: https://github.com/raysan5/raylib/blob/f1ed8be5d7e2d966d577a3fd28e53447a398b3b6/src/shapes.c#L298 
/// Draws a circle lines
pub fn drawCircleLinesAdvanced(center: Vec2f, radius: f32, startangle: i32, endangle: i32, segments: i32, colour: Colour) Error!void {
    const SMOOTH_CIRCLE_ERROR_RATE = comptime 0.5;
    
    var iradius = radius;
    var istartangle = startangle;
    var iendangle = endangle;
    var isegments = segments;

    if (iradius <= 0.0) iradius = 0.1;  // Avoid div by zero
    // Function expects (endangle > startangle)
    if (iendangle < istartangle) {
        // Swap values
        const tmp = istartangle;
        istartangle = iendangle;
        iendangle = tmp;
    }
    
    if (isegments < 4) {
        // Calculate the maximum angle between segments based on the error rate (usually 0.5f)
        const th: f32 = std.math.acos(2 * std.math.pow(f32, 1 - SMOOTH_CIRCLE_ERROR_RATE / iradius, 2) - 1);
        isegments = @floatToInt(i32, (@intToFloat(f32, (iendangle - istartangle)) * std.math.ceil(2 * m.PI / th) / 360));

        if (isegments <= 0) isegments = 4;
    }
    const steplen: f32 = @intToFloat(f32, iendangle - istartangle) / @intToFloat(f32, isegments);
    var angle: f32 = @intToFloat(f32, istartangle);

    // Hide the cap lines when the circle is full
    var showcaplines: bool = true;
    var limit: i32 = 2 * (isegments + 2);

    if (@mod(iendangle - istartangle, 350) == 0) {
        limit = 2 * isegments;
        showcaplines = false;
    }
    
    if (showcaplines) {
        const pos0 = Vec2f{ .x = center.x, .y = center.y };
        const pos1 = Vec2f{ 
            .x = center.x + std.math.sin(m.deg2radf(angle)) * iradius, 
            .y = center.y + std.math.cos(m.deg2radf(angle)) * iradius
        };

        try drawLine(pos0, pos1, colour); 
    }

    var i: i32 = 0;
    while (i < isegments) : (i += 1) {
        const pos1 = Vec2f{ 
            .x = center.x + std.math.sin(m.deg2radf(angle)) * iradius, 
            .y = center.y + std.math.cos(m.deg2radf(angle)) * iradius
        };
        const pos2 = Vec2f{ 
            .x = center.x + std.math.sin(m.deg2radf(angle + steplen)) * iradius, 
            .y = center.y + std.math.cos(m.deg2radf(angle + steplen)) * iradius
        };
        
        try drawLine(pos1, pos2, colour); 
        angle += steplen;
    }
    
    if (showcaplines) {
        const pos0 = Vec2f{ .x = center.x, .y = center.y };
        const pos1 = Vec2f{ 
            .x = center.x + std.math.sin(m.deg2radf(angle)) * iradius, 
            .y = center.y + std.math.cos(m.deg2radf(angle)) * iradius
        };
        
        try drawLine(pos0, pos1, colour); 
    }
}

/// Draws a rectangle
pub fn drawRectangle(rect: Rectangle, colour: Colour) Error!void {
    const pos0 = Vec2f{ .x = rect.x, .y = rect.y };
    const pos1 = Vec2f{ .x = rect.x + rect.width, .y = rect.y };
    const pos2 = Vec2f{ .x = rect.x + rect.width, .y = rect.y + rect.height };
    const pos3 = Vec2f{ .x = rect.x, .y = rect.y + rect.height };

    pdrawRectangle(pos0, pos1, pos2, pos3, colour) catch |err| {
        if (err == renderer.Error.ObjectOverflow) {
            if (prenderer2D.autoflush) {
                try flushBatch2D();
                try pdrawRectangle(pos0, pos1, pos2, pos3, colour);
            } else {
                return Error.FailedToDraw;
            }
        } else return err;
    };
}

/// Draws a rectangle lines
pub fn drawRectangleLines(rect: Rectangle, colour: Colour) Error!void {
    try drawRectangle(.{ .x = rect.x, .y = rect.y, .width = rect.width, .height = 1 }, colour);
    try drawRectangle(.{ .x = rect.x + rect.width - 1, .y = rect.y + 1, .width = 1, .height = rect.height - 2 }, colour);
    try drawRectangle(.{ .x = rect.x, .y = rect.y + rect.height - 1, .width = rect.width, .height = 1 }, colour);
    try drawRectangle(.{ .x = rect.x, .y = rect.y + 1, .width = 1, .height = rect.height - 2 }, colour);
}

/// Draws a rectangle rotated(rotation should be provided in radians)
pub fn drawRectangleRotated(rect: Rectangle, origin: Vec2f, rotation: f32, colour: Colour) Error!void {
    var matrix = ModelMatrix{};
    matrix.translate(rect.x, rect.y, 0);
    matrix.translate(origin.x, origin.y, 0);
    matrix.rotate(0, 0, 1, rotation);
    matrix.translate(-origin.x, -origin.y, 0);
    const mvp = matrix.model;

    const r0 = Vec3f.transform(.{ .x = 0, .y = 0 }, mvp);
    const r1 = Vec3f.transform(.{ .x = rect.width, .y = 0 }, mvp);
    const r2 = Vec3f.transform(.{ .x = rect.width, .y = rect.height }, mvp);
    const r3 = Vec3f.transform(.{ .x = 0, .y = rect.height }, mvp);

    const pos0 = Vec2f{ .x = rect.x + r0.x, .y = rect.y + r0.y };
    const pos1 = Vec2f{ .x = rect.x + r1.x, .y = rect.y + r1.y };
    const pos2 = Vec2f{ .x = rect.x + r2.x, .y = rect.y + r2.y };
    const pos3 = Vec2f{ .x = rect.x + r3.x, .y = rect.y + r3.y };

    pdrawRectangle(pos0, pos1, pos2, pos3, colour) catch |err| {
        if (err == renderer.Error.ObjectOverflow) {
            if (prenderer2D.autoflush) {
                try flushBatch2D();
                try pdrawRectangle(pos0, pos1, pos2, pos3, colour);
            } else {
                return Error.FailedToDraw;
            }
        } else return err;
    };
}

/// Draws a texture
pub fn drawTexture(rect: Rectangle, srcrect: Rectangle, colour: Colour) Error!void {
    const pos0 = Vec2f{ .x = rect.x, .y = rect.y };
    const pos1 = Vec2f{ .x = rect.x + rect.width, .y = rect.y };
    const pos2 = Vec2f{ .x = rect.x + rect.width, .y = rect.y + rect.height };
    const pos3 = Vec2f{ .x = rect.x, .y = rect.y + rect.height };

    pdrawTexture(pos0, pos1, pos2, pos3, srcrect, colour) catch |err| {
        if (err == renderer.Error.ObjectOverflow) {
            if (prenderer2D.autoflush) {
                try flushBatch2D();
                try pdrawTexture(pos0, pos1, pos2, pos3, srcrect, colour);
            } else {
                return Error.FailedToDraw;
            }
        } else return err;
    };
}

/// Draws a texture(rotation should be provided in radians)
pub fn drawTextureRotated(rect: Rectangle, srcrect: Rectangle, origin: Vec2f, rotation: f32, colour: Colour) Error!void {
    var matrix = ModelMatrix{};
    matrix.translate(rect.x, rect.y, 0);
    matrix.translate(origin.x, origin.y, 0);
    matrix.rotate(0, 0, 1, rotation);
    matrix.translate(-origin.x, -origin.y, 0);
    const mvp = matrix.model;

    const r0 = Vec3f.transform(.{ .x = 0, .y = 0 }, mvp);
    const r1 = Vec3f.transform(.{ .x = rect.width, .y = 0 }, mvp);
    const r2 = Vec3f.transform(.{ .x = rect.width, .y = rect.height }, mvp);
    const r3 = Vec3f.transform(.{ .x = 0, .y = rect.height }, mvp);

    const pos0 = Vec2f{ .x = rect.x + r0.x, .y = rect.y + r0.y };
    const pos1 = Vec2f{ .x = rect.x + r1.x, .y = rect.y + r1.y };
    const pos2 = Vec2f{ .x = rect.x + r2.x, .y = rect.y + r2.y };
    const pos3 = Vec2f{ .x = rect.x + r3.x, .y = rect.y + r3.y };

    pdrawTexture(pos0, pos1, pos2, pos3, srcrect, colour) catch |err| {
        if (err == renderer.Error.ObjectOverflow) {
            if (prenderer2D.autoflush) {
                try flushBatch2D();
                try pdrawTexture(pos0, pos1, pos2, pos3, srcrect, colour);
            } else {
                return Error.FailedToDraw;
            }
        } else return err;
    };
}

// PRIVATE FUNCTIONS

fn pnoTextureShaderAttribs() void {
    const stride = @sizeOf(Vertex2DNoTexture);
    gl.shaderProgramSetVertexAttribArray(0, true);
    gl.shaderProgramSetVertexAttribArray(1, true);

    gl.shaderProgramSetVertexAttribPointer(0, 2, f32, false, stride, @intToPtr(?*const c_void, @byteOffsetOf(Vertex2DNoTexture, "position")));
    gl.shaderProgramSetVertexAttribPointer(1, 4, f32, false, stride, @intToPtr(?*const c_void, @byteOffsetOf(Vertex2DNoTexture, "colour")));
}

fn pTextureShaderAttribs() void {
    const stride = @sizeOf(Vertex2DTexture);
    gl.shaderProgramSetVertexAttribArray(0, true);
    gl.shaderProgramSetVertexAttribArray(1, true);
    gl.shaderProgramSetVertexAttribArray(2, true);

    gl.shaderProgramSetVertexAttribPointer(0, 2, f32, false, stride, @intToPtr(?*const c_void, @byteOffsetOf(Vertex2DTexture, "position")));
    gl.shaderProgramSetVertexAttribPointer(1, 2, f32, false, stride, @intToPtr(?*const c_void, @byteOffsetOf(Vertex2DTexture, "texcoord")));
    gl.shaderProgramSetVertexAttribPointer(2, 4, f32, false, stride, @intToPtr(?*const c_void, @byteOffsetOf(Vertex2DTexture, "colour")));
}

fn pnoTextureSubmitQuadfn(self: *Batch2DQuadNoTexture, vertex: [Batch2DQuadNoTexture.max_vertex_count]Vertex2DNoTexture) renderer.Error!void {
    try psubmitVerticesQuad(Batch2DQuadNoTexture, self, vertex);
    try psubmitIndiciesQuad(Batch2DQuadNoTexture, self);

    self.submission_counter += 1;
}

fn pTextureSubmitQuadfn(self: *Batch2DQuadTexture, vertex: [Batch2DQuadTexture.max_vertex_count]Vertex2DTexture) renderer.Error!void {
    try psubmitVerticesQuad(Batch2DQuadTexture, self, vertex);
    try psubmitIndiciesQuad(Batch2DQuadTexture, self);

    self.submission_counter += 1;
}

fn psubmitVerticesQuad(comptime typ: type, self: *typ, vertex: [typ.max_vertex_count]typ.Vertex) renderer.Error!void {
    try self.submitVertex(self.submission_counter, 0, vertex[0]);
    try self.submitVertex(self.submission_counter, 1, vertex[1]);
    try self.submitVertex(self.submission_counter, 2, vertex[2]);
    try self.submitVertex(self.submission_counter, 3, vertex[3]);
}

fn psubmitIndiciesQuad(comptime typ: type, self: *typ) renderer.Error!void {
    if (self.submission_counter == 0) {
        try self.submitIndex(self.submission_counter, 0, 0);
        try self.submitIndex(self.submission_counter, 1, 1);
        try self.submitIndex(self.submission_counter, 2, 2);
        try self.submitIndex(self.submission_counter, 3, 2);
        try self.submitIndex(self.submission_counter, 4, 3);
        try self.submitIndex(self.submission_counter, 5, 0);
    } else {
        const back = self.index_list[self.submission_counter - 1];
        var i: u8 = 0;
        while (i < typ.max_index_count) : (i += 1) {
            try self.submitIndex(self.submission_counter, i, back[i] + 4);
            try self.submitIndex(self.submission_counter, i, back[i] + 4);
            try self.submitIndex(self.submission_counter, i, back[i] + 4);
            try self.submitIndex(self.submission_counter, i, back[i] + 4);
            try self.submitIndex(self.submission_counter, i, back[i] + 4);
            try self.submitIndex(self.submission_counter, i, back[i] + 4);
        }
    }
}

fn pdrawRectangle(pos0: Vec2f, pos1: Vec2f, pos2: Vec2f, pos3: Vec2f, colour: Colour) Error!void {
    if (prenderer2D.textured) return Error.InvalidBatch;
    switch (prenderer2D.tag) {
        Renderer2DBatchTag.lines => {
            return Error.InvalidBatch;
        },
        else => {},
    }
    try prenderer2D.current_quadbatch_notexture.submitDrawable([Batch2DQuadNoTexture.max_vertex_count]Vertex2DNoTexture{
        .{ .position = pos0, .colour = colour },
        .{ .position = pos1, .colour = colour },
        .{ .position = pos2, .colour = colour },
        .{ .position = pos3, .colour = colour },
    });
}

fn pdrawTexture(pos0: Vec2f, pos1: Vec2f, pos2: Vec2f, pos3: Vec2f, srcrect: Rectangle, colour: Colour) Error!void {
    if (!prenderer2D.textured) return Error.InvalidBatch;
    switch (prenderer2D.tag) {
        Renderer2DBatchTag.triangles, Renderer2DBatchTag.lines => {
            return Error.InvalidBatch;
        },
        else => {},
    }
    const width: f32 = @intToFloat(f32, prenderer2D.current_texture.width);
    const height: f32 = @intToFloat(f32, prenderer2D.current_texture.height);

    var src = srcrect;
    var flipX: bool = true;
    if (srcrect.width > 0) {
        flipX = false;
        src.width *= -1;
    }

    if (srcrect.height < 0) {
        src.y -= src.height;
    }

    const t0 = Vec2f{
        .x = if (flipX) src.x / width else (src.x + src.width) / width,
        .y = src.y / height,
    };

    const t1 = Vec2f{
        .x = if (flipX) (src.x + src.width) / width else src.x / width,
        .y = src.y / height,
    };

    const t2 = Vec2f{
        .x = if (flipX) (src.x + src.width) / width else src.x / width,
        .y = (src.y + src.height) / height,
    };

    const t3 = Vec2f{
        .x = if (flipX) src.x / width else (src.x + src.width) / width,
        .y = (src.y + src.height) / height,
    };

    try prenderer2D.current_quadbatch_texture.submitDrawable([Batch2DQuadTexture.max_vertex_count]Vertex2DTexture{
        .{ .position = pos0, .texcoord = t0, .colour = colour },
        .{ .position = pos1, .texcoord = t1, .colour = colour },
        .{ .position = pos2, .texcoord = t2, .colour = colour },
        .{ .position = pos3, .texcoord = t3, .colour = colour },
    });
}