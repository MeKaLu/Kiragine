const std = @import("std");

const utils = @import("kira").utils;
const glfw = @import("kira").glfw;
const gl = @import("kira").gl;
const renderer = @import("kira").renderer;
const window = @import("kira").window;
const input = @import("kira").input;

const math = @import("kira").math;

const Mat4x4f = math.mat4x4.Generic(f32);
const Vec2f = math.vec2.Generic(f32);
const Vertex = comptime renderer.VertexGeneric(false, Vec2f);
const Batch = renderer.BatchGeneric(1024, 6, 4, Vertex);
const Colour = renderer.ColourGeneric(f32);

const Ship = struct {
    firerate: f32 = 0.5,
    firetimer: f32 = 0,
    firecount: u32 = 0,
    position: Vec2f = Vec2f{},
    speed: Vec2f = Vec2f{},
    size: Vec2f = Vec2f{},
    colour: Colour = Colour.rgba(255, 255, 255, 255),

    pub fn draw(self: Ship, batch: *Batch) anyerror!void {
        try batch.submitDrawable([Batch.max_vertex_count]Vertex{
            .{ .position = self.position, .colour = self.colour },
            .{ .position = .{ .x = self.position.x + self.size.x, .y = self.position.y }, .colour = self.colour },
            .{ .position = .{ .x = self.position.x + self.size.x, .y = self.position.y + self.size.y }, .colour = self.colour },
            .{ .position = .{ .x = self.position.x, .y = self.position.y + self.size.y }, .colour = self.colour },
        });
    }
};

const Bullet = struct {
    position: Vec2f = Vec2f{},
    velocity: Vec2f = Vec2f{},
    size: Vec2f = Vec2f{},
    colour: Colour = Colour.rgba(255, 255, 255, 255),
    alive: bool = false,

    pub fn draw(self: Bullet, batch: *Batch) anyerror!void {
        try batch.submitDrawable([Batch.max_vertex_count]Vertex{
            .{ .position = self.position, .colour = self.colour },
            .{ .position = .{ .x = self.position.x + self.size.x, .y = self.position.y }, .colour = self.colour },
            .{ .position = .{ .x = self.position.x + self.size.x, .y = self.position.y + self.size.y }, .colour = self.colour },
            .{ .position = .{ .x = self.position.x, .y = self.position.y + self.size.y }, .colour = self.colour },
        });
    }
};

const BulletFactory = struct {
    pub const maxcount: u32 = 500;
    list: [maxcount]Bullet = undefined,

    pub fn clear(self: *BulletFactory) void {
        var i: u32 = 0;
        while (i < maxcount) : (i += 1) {
            self.list[i].alive = false;
        }
    }

    pub fn draw(self: BulletFactory, batch: *Batch) anyerror!void {
        var i: u32 = 0;
        while (i < maxcount) : (i += 1) {
            if (self.list[i].alive) {
                try self.list[i].draw(batch);
            }
        }
    }

    pub fn update(self: *BulletFactory) void {
        var i: u32 = 0;
        while (i < maxcount) : (i += 1) {
            if (self.list[i].alive) {
                self.list[i].position = self.list[i].position.addValues(self.list[i].velocity.x * @floatCast(f32, targetfps), self.list[i].velocity.y * @floatCast(f32, targetfps));
                if (self.list[i].velocity.y > 0.1 and self.list[i].position.y > 1000 or self.list[i].velocity.y < -0.1 and self.list[i].position.y < -100) {
                    self.list[i].alive = false;
                }
            }
        }
    }

    pub fn add(self: *BulletFactory, bullet: Bullet) anyerror!void {
        var i: u32 = 0;
        while (i < maxcount) : (i += 1) {
            if (!self.list[i].alive) {
                self.list[i] = bullet;
                self.list[i].alive = true;
                return;
            }
        }
        try utils.check(true, "Unable to add bullet(filled list)!", .{});
    }
};

var win_running = false;
var targetfps: f64 = 1.0 / 60.0;
var inp = input.Info{};

var player = Ship{
    .firerate = 0.1,
    .firetimer = 0.0,
    .firecount = 100,
    .position = Vec2f{ .x = 1024 / 2 - 15, .y = 768 - 30 * 2 },
    .speed = Vec2f{ .x = 0, .y = 0 },
    .size = Vec2f{ .x = 30, .y = 30 },
    .colour = Colour.rgba(30, 70, 230, 255),
};

const vertex_shader =
    \\#version 330 core
    \\layout (location = 0) in vec3 aPos;
    \\layout (location = 1) in vec4 aColor;
    \\out vec4 ourColor;
    \\uniform mat4 MVP;
    \\void main() {
    \\  gl_Position = MVP * vec4(aPos, 1.0);
    \\  ourColor = aColor;
    \\}
;

const fragment_shader =
    \\#version 330 core
    \\out vec4 final;
    \\in vec4 ourColor;
    \\void main() {
    \\  final = ourColor;
    \\}
;

fn closeCallback(handle: ?*c_void) void {
    win_running = false;
}

fn resizeCallback(handle: ?*c_void, w: i32, h: i32) void {
    gl.viewport(0, 0, w, h);
}

fn keyboardCallback(handle: ?*c_void, key: i32, sc: i32, ac: i32, mods: i32) void {
    inp.handleKeyboard(key, ac) catch unreachable;
}

fn shaderAttribs() void {
    const stride = @sizeOf(Vertex);
    gl.shaderProgramSetVertexAttribArray(0, true);
    gl.shaderProgramSetVertexAttribArray(1, true);

    gl.shaderProgramSetVertexAttribPointer(0, 3, f32, false, stride, @intToPtr(?*const c_void, @byteOffsetOf(Vertex, "position")));
    gl.shaderProgramSetVertexAttribPointer(1, 4, f32, false, stride, @intToPtr(?*const c_void, @byteOffsetOf(Vertex, "colour")));
}

fn submitFn(self: *Batch, vertex: [Batch.max_vertex_count]Vertex) renderer.Error!void {
    try self.submitVertex(self.submission_counter, 0, vertex[0]);
    try self.submitVertex(self.submission_counter, 1, vertex[1]);
    try self.submitVertex(self.submission_counter, 2, vertex[2]);
    try self.submitVertex(self.submission_counter, 3, vertex[3]);

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
        while (i < Batch.max_index_count) : (i += 1) {
            try self.submitIndex(self.submission_counter, i, back[i] + 4);
            try self.submitIndex(self.submission_counter, i, back[i] + 4);
            try self.submitIndex(self.submission_counter, i, back[i] + 4);
            try self.submitIndex(self.submission_counter, i, back[i] + 4);
            try self.submitIndex(self.submission_counter, i, back[i] + 4);
            try self.submitIndex(self.submission_counter, i, back[i] + 4);
        }
    }

    self.submission_counter += 1;
}

pub fn main() anyerror!void {
    try utils.initTimer();
    defer utils.deinitTimer();

    try glfw.init();
    defer glfw.deinit();
    glfw.resizable(false);
    glfw.initGLProfile();

    var win = window.Info{};
    var frametime = window.FrameTime{};
    win.title = "Simple shooter";
    win.callbacks.close = closeCallback;
    win.callbacks.resize = resizeCallback;
    win.callbacks.keyinp = keyboardCallback;
    const sw = glfw.getScreenWidth();
    const sh = glfw.getScreenHeight();

    win.position.x = @divTrunc((sw - win.size.width), 2);
    win.position.y = @divTrunc((sh - win.size.height), 2);

    try win.create(false);
    defer win.destroy() catch unreachable;

    inp.bindKey('A') catch |err| {
        if (err == input.Error.NoEmptyBinding) {
            inp.clearAllBindings();
            try inp.bindKey('A');
        } else return err;
    };

    try inp.bindKey('D');
    try inp.bindKey('F');

    glfw.makeContext(win.handle);
    glfw.vsync(true);

    gl.init();
    defer gl.deinit();

    var shaderprogram = try gl.shaderProgramCreate(std.heap.page_allocator, vertex_shader, fragment_shader);
    defer gl.shaderProgramDelete(shaderprogram);

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = &arena.allocator;

    var batch = try alloc.create(Batch);
    try batch.create(shaderprogram, shaderAttribs);
    defer batch.destroy();

    batch.submitfn = submitFn;

    var cam = try alloc.create(math.Camera2D);
    cam.ortho = Mat4x4f.ortho(0, @intToFloat(f32, win.size.width), @intToFloat(f32, win.size.height), 0, -1, 1);
    cam.view = Mat4x4f.identity();
    cam.zoom = .{ .x = 1, .y = 1 };

    var playerbulletfactory = try alloc.create(BulletFactory);
    playerbulletfactory.clear();

    win_running = true;
    while (win_running) {
        frametime.start();
        {
            const keyA = inp.keyState('A');
            const keyD = inp.keyState('D');
            const keyF = inp.keyState('F');

            const acc = 50.0;
            const maxspd = 300.0;
            const friction = 10.0;
            const bullet = Bullet{
                .size = .{ .x = 10, .y = 10 },
                .position = .{ .x = player.position.x + player.size.x / 2 - 5, .y = player.position.y },
                .velocity = .{ .x = 0, .y = -200 },
                .colour = Colour.rgba(200, 150, 50, 255),
            };

            if (keyD == input.Info.State.down and player.speed.x <= maxspd) {
                player.speed.x += acc;
            }
            if (keyA == input.Info.State.down and player.speed.x >= -maxspd) {
                player.speed.x -= acc;
            }

            if (player.speed.x > 0.1) {
                player.speed.x -= friction;
            } else if (player.speed.x < -0.1) {
                player.speed.x += friction;
            }

            if (player.firetimer < player.firerate) {
                player.firetimer += 1 * @floatCast(f32, frametime.delta);
            } else if (player.firecount > 0) {
                if (keyF == input.Info.State.down) {
                    player.firetimer = 0.0;
                    player.firecount -= 1;
                    try utils.printEndl(utils.LogLevel.trace, "player: fire({})", .{player.firecount});
                    playerbulletfactory.add(bullet) catch |err| {
                        if (err == utils.Error.KiraCheck) {
                            player.firecount += 1;
                        }
                    };
                }
            }

            if (player.position.x > @intToFloat(f32, win.size.width) - player.size.x or player.position.x <= 0) player.speed.x = -player.speed.x;
            player.position.x += player.speed.x * @floatCast(f32, targetfps);
        }

        playerbulletfactory.update();

        inp.handle();

        gl.clearColour(0.1, 0.1, 0.1, 1.0);
        gl.clearBuffers(gl.BufferBit.colour);

        gl.shaderProgramUse(shaderprogram);

        cam.attach();
        defer cam.detach();
        gl.shaderProgramSetMat4x4f(gl.shaderProgramGetUniformLocation(shaderprogram, "MVP"), @ptrCast([*]const f32, &cam.view.toArray()));

        try player.draw(batch);
        try playerbulletfactory.draw(batch);

        try batch.draw(gl.DrawMode.triangles);
        defer batch.vertex_list = undefined;
        defer batch.index_list = undefined;
        defer batch.submission_counter = 0;

        glfw.sync(win.handle);
        glfw.processEvents();

        frametime.stop();
        frametime.sleep(targetfps);
    }
}
