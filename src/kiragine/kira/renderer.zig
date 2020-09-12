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

const std = @import("std");

const utils = @import("utils.zig");
const gl = @import("gl.zig");
const vec2 = @import("math/vec2.zig");
const vec3 = @import("math/vec3.zig");

const Vec2f = vec2.Generic(f32);
const Vec3f = vec3.Generic(f32);

/// Error set
pub const Error = error{ FailedToGenerateBuffers, ObjectOverflow, VertexOverflow, IndexOverflow, UnknownSubmitFn };

/// Colour generic struct
pub fn ColourGeneric(comptime typ: type) type {
    switch (typ) {
        f16, f32, f64, f128 => {
            return struct {
                r: typ = 0,
                g: typ = 0,
                b: typ = 0,
                a: typ = 0,

                pub fn rgba(r: u32, g: u32, b: u32, a: u32) @This() {
                    return .{
                        .r = @intToFloat(typ, r) / 255.0,
                        .g = @intToFloat(typ, g) / 255.0,
                        .b = @intToFloat(typ, b) / 255.0,
                        .a = @intToFloat(typ, a) / 255.0,
                    };
                }
            };
        },
        u8, u16, u32, u64, u128 => {
            return struct {
                r: typ = 0,
                g: typ = 0,
                b: typ = 0,
                a: typ = 0,

                pub fn rgba(r: u32, g: u32, b: u32, a: u32) @This() {
                    return .{
                        .r = @intCast(typ, r),
                        .g = @intCast(typ, g),
                        .b = @intCast(typ, b),
                        .a = @intCast(typ, a),
                    };
                }
            };
        },
        else => @compileError("Non-implemented type"),
    }
}

const Colour = ColourGeneric(f32);

/// Vertex generic struct
pub fn VertexGeneric(istextcoord: bool, comptime positiontype: type) type {
    if (positiontype == Vec2f or positiontype == Vec3f) {
        if (!istextcoord) {
            return struct {
                const Self = @This();
                position: positiontype = positiontype{},
                colour: Colour = comptime Colour.rgba(255, 255, 255, 255)
            };
        }
        return struct {
            const Self = @This();
            position: positiontype = positiontype{},
            texcoord: Vec2f = Vec2f{},
            colour: Colour = comptime Colour.rgba(255, 255, 255, 255)
        };
    }
    @compileError("Unknown position type");
}

/// Batch generic structure
pub fn BatchGeneric(max_object: u32, max_index: u32, max_vertex: u32, comptime vertex_type: type) type {
    return struct {
        const Self = @This();
        pub const max_object_count: u32 = max_object;
        pub const max_index_count: u32 = max_index;
        pub const max_vertex_count: u32 = max_vertex;
        pub const Vertex: type = vertex_type;

        vertex_array: u32 = 0,
        buffers: [2]u32 = [2]u32{ 0, 0 },

        vertex_list: [max_object_count][max_vertex_count]vertex_type = undefined,
        index_list: [max_object_count][max_index_count]u32 = undefined,

        submitfn: ?fn (self: *Self, vertex: [Self.max_vertex_count]vertex_type) Error!void = null,
        submission_counter: u32 = 0,

        /// Creates the batch
        pub fn create(self: *Self, shaderprogram: u32, shadersetattribs: fn () void) Error!void {
            self.submission_counter = 0;
            gl.vertexArraysGen(1, @ptrCast([*]u32, &self.vertex_array));
            gl.buffersGen(2, &self.buffers);

            if (self.vertex_array == 0 or self.buffers[0] == 0 or self.buffers[1] == 0) {
                gl.vertexArraysDelete(1, @ptrCast([*]const u32, &self.vertex_array));
                gl.buffersDelete(2, @ptrCast([*]const u32, &self.buffers));
                return Error.FailedToGenerateBuffers;
            }

            gl.vertexArrayBind(self.vertex_array);
            defer gl.vertexArrayBind(0);

            gl.bufferBind(gl.BufferType.array, self.buffers[0]);
            gl.bufferBind(gl.BufferType.elementarray, self.buffers[1]);

            defer gl.bufferBind(gl.BufferType.array, 0);
            defer gl.bufferBind(gl.BufferType.elementarray, 0);

            gl.bufferData(gl.BufferType.array, @sizeOf(vertex_type) * max_vertex_count * max_object_count, @ptrCast(?*const c_void, &self.vertex_list), gl.DrawType.dynamic);
            gl.bufferData(gl.BufferType.elementarray, @sizeOf(u32) * max_index_count * max_object_count, @ptrCast(?*const c_void, &self.index_list), gl.DrawType.dynamic);

            gl.shaderProgramUse(shaderprogram);
            defer gl.shaderProgramUse(0);
            shadersetattribs();
        }

        /// Destroys the batch
        pub fn destroy(self: Self) void {
            gl.vertexArraysDelete(1, @ptrCast([*]const u32, &self.vertex_array));
            gl.buffersDelete(2, @ptrCast([*]const u32, &self.buffers));
        }

        /// Set the vertex data from set and given position
        pub fn submitVertex(self: *Self, firstposition: u32, lastposition: u32, data: Vertex) Error!void {
            if (firstposition >= Self.max_object_count) {
                return Error.ObjectOverflow;
            } else if (lastposition >= Self.max_vertex_count) {
                return Error.VertexOverflow;
            }
            self.vertex_list[firstposition][lastposition] = data;
        }

        /// Set the index data from set and given position
        pub fn submitIndex(self: *Self, firstposition: u32, lastposition: u32, data: u32) Error!void {
            if (firstposition >= Self.max_object_count) {
                return Error.ObjectOverflow;
            } else if (lastposition >= Self.max_index_count) {
                return Error.IndexOverflow;
            }
            self.index_list[firstposition][lastposition] = data;
        }

        /// Submit a drawable object
        pub fn submitDrawable(self: *Self, obj: [Self.max_vertex_count]vertex_type) Error!void {
            if (self.submission_counter >= Self.max_object_count) {
                return Error.ObjectOverflow;
            } else if (self.submitfn) |fun| {
                try fun(self, obj);
                return;
            }
            return Error.UnknownSubmitFn;
        }

        /// Draw the submitted objects
        pub fn draw(self: Self, drawmode: gl.DrawMode) Error!void {
            if (self.submission_counter > Self.max_object_count) return Error.ObjectOverflow;
            gl.vertexArrayBind(self.vertex_array);
            defer gl.vertexArrayBind(0);

            gl.bufferBind(gl.BufferType.array, self.buffers[0]);
            gl.bufferBind(gl.BufferType.elementarray, self.buffers[1]);

            defer gl.bufferBind(gl.BufferType.array, 0);
            defer gl.bufferBind(gl.BufferType.elementarray, 0);

            gl.bufferSubData(gl.BufferType.array, 0, @sizeOf(Vertex) * max_vertex_count * max_object_count, @ptrCast(?*const c_void, &self.vertex_list));
            gl.bufferSubData(gl.BufferType.elementarray, 0, @sizeOf(u32) * max_index_count * max_object_count, @ptrCast(?*const c_void, &self.index_list));

            gl.drawElements(drawmode, @intCast(i32, Self.max_object_count * Self.max_index_count), u32, null);
        }
    };
}
