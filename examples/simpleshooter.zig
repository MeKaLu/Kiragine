const std = @import("std");
const engine = @import("kiragine");

const Ship = struct {
    firerate: f32 = 0.5,
    firetimer: f32 = 0,
    firecount: u32 = 0,
    position: engine.Vec2f = engine.Vec2f{},
    speed: engine.Vec2f = engine.Vec2f{},
    size: engine.Vec2f = engine.Vec2f{},
    colour: engine.Colour = engine.Colour.rgba(255, 255, 255, 255),

    pub fn draw(self: Ship) anyerror!void {
        const triangle = [3]engine.Vec2f{
            .{ .x = self.position.x, .y = self.position.y },
            .{ .x = self.position.x + (self.size.x / 2), .y = self.position.y - self.size.y },
            .{ .x = self.position.x + self.size.x, .y = self.position.y },
        };
        try engine.drawTriangle(triangle[0], triangle[1], triangle[2], self.colour);
    }
};

const Bullet = struct {
    position: engine.Vec2f = engine.Vec2f{},
    velocity: engine.Vec2f = engine.Vec2f{},
    size: engine.Vec2f = engine.Vec2f{},
    colour: engine.Colour = engine.Colour.rgba(255, 255, 255, 255),
    alive: bool = false,

    pub fn draw(self: Bullet) anyerror!void {
        try engine.drawRectangle(.{ .x = self.position.x, .y = self.position.y, .width = self.size.x, .height = self.size.y }, self.colour);
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

    pub fn draw(self: BulletFactory) anyerror!void {
        var i: u32 = 0;
        while (i < maxcount) : (i += 1) {
            if (self.list[i].alive) {
                try self.list[i].draw();
            }
        }
    }

    pub fn update(self: *BulletFactory, fixedtime: f32) void {
        var i: u32 = 0;
        while (i < maxcount) : (i += 1) {
            if (self.list[i].alive) {
                self.list[i].position = self.list[i].position.addValues(self.list[i].velocity.x * fixedtime, self.list[i].velocity.y * fixedtime);
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
        try engine.check(true, "Unable to add bullet(filled list)!", .{});
    }
};

const windowWidth = 1024;
const windowHeight = 768;

var input: *engine.Input = undefined;

var player = Ship{
    .firerate = 0.1,
    .firetimer = 0.0,
    .firecount = 100,
    .position = .{ .x = 1024 / 2 - 15, .y = 768 - 30 * 2 },
    .speed = .{ .x = 0, .y = 0 },
    .size = .{ .x = 30, .y = 30 },
    .colour = engine.Colour.rgba(30, 70, 230, 255),
};
var playerbulletfactory = BulletFactory{};

fn update(deltatime: f32) anyerror!void {
    {
        const keyF = input.keyState('F');
        const bullet = Bullet{
            .size = .{ .x = 10, .y = 10 },
            .position = .{ .x = player.position.x + player.size.x / 2 - 5, .y = player.position.y - player.size.y },
            .velocity = .{ .x = 0, .y = -200 },
            .colour = engine.Colour.rgba(200, 150, 50, 255),
        };

        if (player.firetimer < player.firerate) {
            player.firetimer += 1 * deltatime;
        } else if (player.firecount > 0) {
            if (keyF == engine.Input.State.down) {
                player.firetimer = 0.0;
                player.firecount -= 1;
                try engine.printEndl(engine.LogLevel.trace, "player: fire({})", .{player.firecount});

                playerbulletfactory.add(bullet) catch |err| {
                    if (err == engine.LogError.KiraCheck) {
                        player.firecount += 1;
                    }
                };
            }
        }
    }
}

fn fixedUpdate(fixedtime: f32) anyerror!void {
    {
        const keyA = input.keyState('A');
        const keyD = input.keyState('D');

        const acc = 50.0;
        const maxspd = 300.0;
        const friction = 10.0;

        if (keyD == engine.Input.State.down and player.speed.x <= maxspd) {
            player.speed.x += acc;
        }
        if (keyA == engine.Input.State.down and player.speed.x >= -maxspd) {
            player.speed.x -= acc;
        }

        if (player.speed.x > 0.1) {
            player.speed.x -= friction;
        } else if (player.speed.x < -0.1) {
            player.speed.x += friction;
        }

        if (player.position.x > @intToFloat(f32, windowWidth) - player.size.x or player.position.x <= 0) player.speed.x = -player.speed.x;
        player.position.x += player.speed.x * fixedtime;
    }

    playerbulletfactory.update(fixedtime);
}

fn draw() anyerror!void {
    engine.clearScreen(0.1, 0.1, 0.1, 1.0);

    try engine.pushBatch2D(engine.Renderer2DBatchTag.triangles);

    try playerbulletfactory.draw();
    try player.draw();

    try engine.popBatch2D();
}

pub fn main() anyerror!void {
    try engine.init(update, fixedUpdate, draw, windowWidth, windowHeight, "simple shooter", 75);

    input = engine.getInput();
    try input.bindKey('D');
    try input.bindKey('A');
    try input.bindKey('F');

    try engine.open();
    try engine.update();

    try engine.deinit();
}