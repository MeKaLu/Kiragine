const c = @import("c.zig");
const utils = @import("utils.zig");
const std = @import("std");
usingnamespace @import("log.zig");

// zig fmt: off
pub const Load = struct {
    pub const default = 0x0;
    pub const no_scale = 1 << 0;
    pub const no_hinting = 1 << 1;
    pub const render = 1 << 2;
    pub const no_bitmap = 1 << 3;
    // .. https://www.freetype.org/freetype2/docs/reference/ft2-base_interface.html#ft_load_xxx
};
// zig fmt: on

pub const Library = struct {
    base: c.FT_Library = undefined,

    pub fn init(ft: *Library) utils.Error!void {
        try utils.check(c.FT_Init_FreeType(@ptrCast(?*c.FT_Library, &ft.base)) != 0, "kira/ft2 -> could not initialize freetype2!", .{});
    }

    pub fn deinit(ft: Library) utils.Error!void {
        try utils.check(c.FT_Done_FreeType(ft.base) != 0, "kira/ft2 -> failed to deinitialize freetype2!", .{});
    }
};

pub const Face = struct {
    base: c.FT_Face = undefined,

    pub fn new(lib: Library, path: []const u8, face_index: i32) utils.Error!Face {
        var result = Face{};
        try utils.check(c.FT_New_Face(lib.base, @ptrCast([*c]const u8, path), face_index, @ptrCast(?*c.FT_Face, &result.base)) != 0, "kira/ft2 -> failed to load ft2 face from path!", .{});
        return result;
    }

    pub fn newMemory(lib: Library, mem: []const u8, face_index: i32) utils.Error!Face {
        var result = Face{};
        try utils.check(c.FT_New_Memory_Face(lib.base, @ptrCast([*c]const u8, mem), mem.len, face_index, @ptrCast(?*c.FT_Face, &result.base)) != 0, "kira/ft2 -> failed to load ft2 face from memory!", .{});
        return result;
    }

    pub fn destroy(self: Face) utils.Error!void {
        try utils.check(c.FT_Done_Face(self.base) != 0, "kira/ft2 -> failed to destroy face!", .{});
    }

    pub fn setPixelSizes(self: Face, width: u32, height: u32) utils.Error!void {
        try utils.check(c.FT_Set_Pixel_Sizes(self.base, width, height) != 0, "kira/ft -> failed to set pixel sizes!", .{});
    }

    pub fn loadChar(self: Face, char_code: u64, load_flags: i32) utils.Error!void {
        try utils.check(c.FT_Load_Char(self.base, char_code, load_flags) == 1, "kira/ft -> failed to load char information from face!", .{});
    }
};
