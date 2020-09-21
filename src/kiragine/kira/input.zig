// -----------------------------------------
// |           Kiragine 1.1.1              |
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

const c = @import("c.zig");
const utils = @import("utils.zig");

/// Error set
pub const Error = error{ InvalidBinding, NoEmptyBinding };

/// Input info
pub const Info = struct {
    /// States
    pub const State = enum {
        none = 0, pressed, down, released
    };

    /// For managing key / button states
    /// I prefer call them as bindings
    pub const BindingManager = struct {
        status: State = State.none,
        key: i16 = empty_binding,
    };

    /// Maximum key count
    pub const max_key_count: u8 = 50;
    /// Maximum mouse button count
    pub const max_mbutton_count: u8 = 5;
    /// Empty binding
    pub const empty_binding: i16 = -1;

    /// Binded key list
    key_list: [max_key_count]BindingManager = undefined,
    /// Binded mouse button list
    mbutton_list: [max_mbutton_count]BindingManager = undefined,

    /// Clears the key bindings
    pub fn clearKeyBindings(self: *Info) void {
        var i: u8 = 0;
        var l = &self.key_list;
        while (i < max_key_count) : (i += 1) {
            l[i] = BindingManager{};
        }
    }

    /// Clears the mouse button bindings
    pub fn clearMButtonBindings(self: *Info) void {
        var i: u8 = 0;
        var l = &self.mbutton_list;
        while (i < max_mbutton_count) : (i += 1) {
            l[i] = BindingManager{};
        }
    }

    /// Clears all the bindings
    pub fn clearAllBindings(self: *Info) void {
        self.clearKeyBindings();
        self.clearMButtonBindings();
    }

    /// Binds a key
    pub fn bindKey(self: *Info, key: i16) Error!void {
        var i: u8 = 0;
        var l = &self.key_list;
        while (i < max_key_count) : (i += 1) {
            if (i == empty_binding) {
                continue;
            } else if (l[i].key == empty_binding) {
                l[i].key = key;
                l[i].status = State.none;
                return;
            }
        }
        return Error.NoEmptyBinding;
    }

    /// Unbinds a key
    pub fn unbindKey(self: *Info, key: i16) Error!void {
        var i: u8 = 0;
        var l = &self.key_list;
        while (i < max_key_count) : (i += 1) {
            if (l[i].key == key) {
                l[i] = BindingManager{};
                return;
            }
        }
        return Error.InvalidBinding;
    }

    /// Binds a mouse button
    pub fn bindMButton(self: *Info, key: i16) Error!void {
        var i: u8 = 0;
        var l = &self.mbutton_list;
        while (i < max_mbutton_count) : (i += 1) {
            if (i == empty_binding) {
                continue;
            } else if (l[i].key == empty_binding) {
                l[i].key = key;
                l[i].status = State.none;
                return;
            }
        }
        return Error.NoEmptyBinding;
    }

    /// Unbinds a mouse button
    pub fn unbindMButton(self: *Info, key: i16) Error!void {
        var i: u8 = 0;
        var l = &self.mbutton_list;
        while (i < max_mbutton_count) : (i += 1) {
            if (l[i].key == key) {
                l[i] = BindingManager{};
                return;
            }
        }
        return Error.InvalidBinding;
    }

    /// Returns a binded key state
    pub fn keyState(self: *Info, key: i16) Error!State {
        var i: u8 = 0;
        var l = &self.key_list;
        while (i < max_key_count) : (i += 1) {
            if (l[i].key == key) {
                return l[i].status;
            }
        }
        return Error.InvalidBinding;
    }

    /// Returns a const reference to a binded key state
    pub fn keyStatePtr(self: *Info, key: i16) Error!*const State {
        var i: u8 = 0;
        var l = &self.key_list;
        while (i < max_key_count) : (i += 1) {
            if (l[i].key == key) {
                return &l[i].status;
            }
        }
        return Error.InvalidBinding;
    }

    /// Returns a binded key state
    pub fn mbuttonState(self: *Info, key: i16) Error!State {
        var i: u8 = 0;
        var l = &self.mbutton_list;
        while (i < max_mbutton_count) : (i += 1) {
            if (l[i].key == key) {
                return l[i].status;
            }
        }
        return Error.InvalidBinding;
    }

    /// Returns a const reference to a binded key state
    pub fn mbuttonStatePtr(self: *Info, key: i16) Error!*const State {
        var i: u8 = 0;
        var l = &self.mbutton_list;
        while (i < max_mbutton_count) : (i += 1) {
            if (l[i].key == key) {
                return &l[i].status;
            }
        }
        return Error.InvalidBinding;
    }

    /// Handles the inputs
    /// Warning: Call just before polling/processing the events
    /// Keep in mind binding states will be useless after polling events
    pub fn handle(self: *Info) void {
        var i: u8 = 0;
        while (i < max_key_count) : (i += 1) {
            if (i < max_mbutton_count) {
                var l = &self.mbutton_list[i];
                if (l.key == empty_binding) {} else if (l.status == State.released) {
                    l.status = State.none;
                } else if (l.status == State.pressed) {
                    l.status = State.down;
                }
            }
            var l = &self.key_list[i];
            if (l.key == empty_binding) {
                continue;
            } else if (l.status == State.released) {
                l.status = State.none;
            } else if (l.status == State.pressed) {
                l.status = State.down;
            }
        }
    }
    /// Handles the keyboard inputs
    pub fn handleKeyboard(input: *Info, key: i32, ac: i32) !void {
        var l = &input.key_list;
        var i: u8 = 0;
        while (i < Info.max_key_count) : (i += 1) {
            if (l[i].key != key) {
                continue;
            }
            switch (ac) {
                0 => {
                    if (l[i].status == Info.State.released) {
                        l[i].status = Info.State.none;
                    } else if (l[i].status == Info.State.down) {
                        l[i].status = Info.State.released;
                    }
                },
                1, 2 => {
                    if (l[i].status != Info.State.down) l[i].status = Info.State.pressed;
                },
                else => {
                    try utils.check(true, "kira/input -> unknown action!", .{});
                },
            }
        }
    }
    /// Handles the mouse button inputs
    pub fn handleMButton(input: *Info, key: i32, ac: i32) !void {
        var l = &input.mbutton_list;
        var i: u8 = 0;
        while (i < Info.max_mbutton_count) : (i += 1) {
            if (l[i].key != key) {
                continue;
            }
            switch (ac) {
                0 => {
                    if (l[i].status == Info.State.released) {
                        l[i].status = Info.State.none;
                    } else if (l[i].status == Info.State.down) {
                        l[i].status = Info.State.released;
                    }
                },
                1, 2 => {
                    if (l[i].status != Info.State.down) l[i].status = Info.State.pressed;
                },
                else => {
                    try utils.check(true, "kira/input -> unknown action!", .{});
                },
            }
        }
    }
};
