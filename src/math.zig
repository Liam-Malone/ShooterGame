const std = @import("std");

pub const Vec2 = struct {
    x: f32,
    y: f32,
    mag: f32,

    pub fn mag(x: f32, y: f32) f32 {
        return std.math.sqrt(x * x + y * y);
    }

    fn normalize(self: *Vec2) void {
        self.x /= self.mag;
        self.y /= self.mag;
    }

    pub fn adjust(self: *Vec2, speed: f32) void {
        if (self.mag != speed and self.mag != (speed * -1)) {
            self.normalize();
            self.scale(speed);
        }
    }

    pub fn scale(self: *Vec2, scalar: f32) void {
        self.x *= scalar;
        self.y *= scalar;
        self.mag = mag(self.x, self.y);
    }
};

// not needed !! use builtin @fabs()
pub fn abs(num: i32) i32 {
    switch (num > 0) {
        true => return num,
        false => return (num * -1),
    }
}
pub fn rand(min: f32, max: f32) f32 {
    var prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.os.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    return prng.random().intRangeAtMost(i32, min, max);
}
