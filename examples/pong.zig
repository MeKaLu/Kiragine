const std = @import("std");
usingnamespace @import("kiragine").kira.log;
const engine = @import("kiragine");

const windowWidth = 1024;
const windowHeight = 768;
const title = "Pong";
const targetfps = 60;

const aabb = engine.kira.math.aabb;

var input: *engine.Input = undefined;

var ballpos = engine.Vec2f{
    .x = 1024 / 2 - 50,
    .y = 768 / 2,
};
var ballmotion = engine.Vec2f{
    .y = 1,
    .x = 0,
};
const ballspeed: f32 = 400;
const ballsize = 10;
const ballcolour = engine.Colour.rgba(240, 240, 240, 255);

var paddle = engine.Rectangle{
    .x = 1024 / 2 - 100,
    .y = 700,
    .width = 100,
    .height = 20,
};
var paddlemotion: f32 = 0;
const paddlespeed: f32 = 300;
const paddlecolour = engine.Colour.rgba(30, 70, 200, 255);

fn update(dt: f32) !void {
    const keyA: engine.Input.State = try input.keyState('A');
    const keyD: engine.Input.State = try input.keyState('D');

    if (keyA == .down) {
        paddlemotion = -paddlespeed;
    } else if (keyD == .down) {
        paddlemotion = paddlespeed;
    } else paddlemotion = 0;
    if (paddle.x > 1024 - paddle.width) {
        paddlemotion = -paddlespeed;
    } else if (paddle.x <= 0) {
        paddlemotion = paddlespeed;
    }

    if (ballpos.x > 1024 - 20) {
        ballmotion.x = -ballspeed;
    } else if (ballpos.x < 100) {
        ballmotion.x = ballspeed;
    }

    if (aabb(paddle.x, paddle.y, paddle.width, paddle.height, ballpos.x, ballpos.y, ballsize, ballsize)) {
        ballmotion.y = -ballspeed;

        if (ballmotion.x == 0) {
            ballmotion.x = 1 * ballspeed;
        }
        ballmotion.x *= -1;
    }

    if (ballpos.y <= 20) {
        ballmotion.y = ballspeed;
    } else if (ballpos.y > 800) {
        ballpos.y = 20;
    }
}

fn fixedupdate(fixedtime: f32) !void {
    paddle.x += paddlemotion * fixedtime;
    ballpos.x += ballmotion.x * fixedtime;
    ballpos.y += ballmotion.y * fixedtime;
}

fn draw() !void {
    engine.clearScreen(0.1, 0.1, 0.1, 1.0);

    // Push the triangle batch, it can be mixed with quad batch
    try engine.pushBatch2D(engine.Renderer2DBatchTag.triangles);
    // or
    // try engine.pushBatch2D(engine.Renderer2DBatchTag.quads);

    try engine.drawRectangle(paddle, paddlecolour);

    try engine.drawCircle(ballpos, ballsize, ballcolour);

    // Pops the current batch
    try engine.popBatch2D();
}

pub fn main() !void {
    const callbacks = engine.Callbacks{
        .draw = draw,
        .fixed = fixedupdate,
        .update = update,
    };
    try engine.init(callbacks, windowWidth, windowHeight, title, targetfps, std.heap.page_allocator);

    input = engine.getInput();
    try input.bindKey('A');
    try input.bindKey('D');

    ballmotion.y = ballspeed;

    try engine.open();
    try engine.update();

    try engine.deinit();
}
