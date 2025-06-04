const assert = @import("std").debug.assert;
const math = @import("std").math;

fn radians(deg: f32) f32 {
    return deg * (math.pi / 180.0);
}

pub const Vec2 = extern struct {
    x: f32,
    y: f32,

    const Self = @This();
    pub fn zero() Vec2 {
        return Vec2{ .x = 0.0, .y = 0.0 };
    }

    pub fn normalize(self: Self) Self {
        const len = math.sqrt(self.x * self.x + self.y * self.y);
        if (len == 0.0) return zero();
        return Self{
            .x = self.x / len,
            .y = self.y / len,
        };
    }

    pub fn magnitue(self: Self) f32 {
        return @abs(self.x) + @abs(self.y);
    }

    pub fn add(self: Self, other: Self) Self {
        return .{ .x = self.x + other.x, .y = self.y + other.y };
    }

    pub fn sub(self: Self, other: Self) Self {
        return .{ .x = self.x - other.x, .y = self.y - other.y };
    }

    pub fn mul(self: Self, other: Self) Self {
        return .{ .x = self.x * other.x, .y = self.y * other.y };
    }

    pub fn div(self: Self, other: Self) Self {
        return .{ .x = self.x / other.x, .y = self.y / other.y };
    }

    pub fn scale(self: Self, factor: f32) Self {
        return .{ .x = self.x * factor, .y = self.y * factor };
    }

    pub fn init(x: f32, y: f32) Self {
        return .{ .x = x, .y = y };
    }
};

pub const Vec4 = extern struct {
    r: f32,
    g: f32,
    b: f32,
    a: f32,

    const Self = @This();
    pub fn zero() Self {
        return Self{ .r = 0.0, .g = 0.0, .b = 0.0, .a = 0.0 };
    }

    pub fn init(r: f32, g: f32, b: f32, a: f32) Self {
        return Self{ .r = r, .b = b, .g = g, .a = a };
    }
};
pub const Vec3 = extern struct {
    x: f32,
    y: f32,
    z: f32,

    const Self = @This();
    pub const up = init(0, 1, 0);

    pub fn zero() Self {
        return Self{ .x = 0.0, .y = 0.0, .z = 0.0 };
    }

    pub fn init(x: f32, y: f32, z: f32) Self {
        return Self{ .x = x, .y = y, .z = z };
    }

    pub fn len(v: Self) f32 {
        return math.sqrt(Self.dot(v, v));
    }

    pub fn add(left: Self, right: Self) Self {
        return Self{ .x = left.x + right.x, .y = left.y + right.y, .z = left.z + right.z };
    }

    pub fn sub(left: Self, right: Self) Self {
        return Self{ .x = left.x - right.x, .y = left.y - right.y, .z = left.z - right.z };
    }

    pub fn mul(v: Self, s: f32) Self {
        return Self{ .x = v.x * s, .y = v.y * s, .z = v.z * s };
    }

    pub fn norm(v: Self) Self {
        const l = Self.len(v);
        if (l != 0.0) {
            return Self{ .x = v.x / l, .y = v.y / l, .z = v.z / l };
        } else {
            return Self.zero();
        }
    }

    pub fn cross(v0: Self, v1: Self) Self {
        return Self{ .x = (v0.y * v1.z) - (v0.z * v1.y), .y = (v0.z * v1.x) - (v0.x * v1.z), .z = (v0.x * v1.y) - (v0.y * v1.x) };
    }

    pub fn dot(v0: Self, v1: Self) f32 {
        return v0.x * v1.x + v0.y * v1.y + v0.z * v1.z;
    }
};

pub const Mat4 = extern struct {
    m: [4][4]f32,

    const Self = @This();
    pub fn identity() Self {
        return Self{
            .m = [_][4]f32{ .{ 1.0, 0.0, 0.0, 0.0 }, .{ 0.0, 1.0, 0.0, 0.0 }, .{ 0.0, 0.0, 1.0, 0.0 }, .{ 0.0, 0.0, 0.0, 1.0 } },
        };
    }

    pub fn zero() Self {
        return Self{
            .m = [_][4]f32{ .{ 0.0, 0.0, 0.0, 0.0 }, .{ 0.0, 0.0, 0.0, 0.0 }, .{ 0.0, 0.0, 0.0, 0.0 }, .{ 0.0, 0.0, 0.0, 0.0 } },
        };
    }

    pub fn mul(left: Self, right: Mat4) Mat4 {
        var res = Self.zero();
        for (0..4) |col| {
            for (0..4) |row| {
                res.m[col][row] = left.m[0][row] * right.m[col][0] +
                    left.m[1][row] * right.m[col][1] +
                    left.m[2][row] * right.m[col][2] +
                    left.m[3][row] * right.m[col][3];
            }
        }
        return res;
    }

    pub fn persp(fov: f32, aspect: f32, near: f32, far: f32) Self {
        var res = Self.identity();
        const t = math.tan(fov * (math.pi / 360.0));
        res.m[0][0] = 1.0 / t;
        res.m[1][1] = aspect / t;
        res.m[2][3] = -1.0;
        res.m[2][2] = (near + far) / (near - far);
        res.m[3][2] = (2.0 * near * far) / (near - far);
        res.m[3][3] = 0.0;
        return res;
    }

    pub fn lookat(eye: Vec3, center: Vec3, up: Vec3) Self {
        var res = Self.zero();

        const f = Vec3.norm(Vec3.sub(center, eye));
        const s = Vec3.norm(Vec3.cross(f, up));
        const u = Vec3.cross(s, f);

        res.m[0][0] = s.x;
        res.m[0][1] = u.x;
        res.m[0][2] = -f.x;

        res.m[1][0] = s.y;
        res.m[1][1] = u.y;
        res.m[1][2] = -f.y;

        res.m[2][0] = s.z;
        res.m[2][1] = u.z;
        res.m[2][2] = -f.z;

        res.m[3][0] = -Vec3.dot(s, eye);
        res.m[3][1] = -Vec3.dot(u, eye);
        res.m[3][2] = Vec3.dot(f, eye);
        res.m[3][3] = 1.0;

        return res;
    }

    pub fn rotate(angle: f32, axis_unorm: Vec3) Self {
        var res = Self.identity();

        const axis = Vec3.norm(axis_unorm);
        const sin_theta = math.sin(radians(angle));
        const cos_theta = math.cos(radians(angle));
        const cos_value = 1.0 - cos_theta;

        res.m[0][0] = (axis.x * axis.x * cos_value) + cos_theta;
        res.m[0][1] = (axis.x * axis.y * cos_value) + (axis.z * sin_theta);
        res.m[0][2] = (axis.x * axis.z * cos_value) - (axis.y * sin_theta);
        res.m[1][0] = (axis.y * axis.x * cos_value) - (axis.z * sin_theta);
        res.m[1][1] = (axis.y * axis.y * cos_value) + cos_theta;
        res.m[1][2] = (axis.y * axis.z * cos_value) + (axis.x * sin_theta);
        res.m[2][0] = (axis.z * axis.x * cos_value) + (axis.y * sin_theta);
        res.m[2][1] = (axis.z * axis.y * cos_value) - (axis.x * sin_theta);
        res.m[2][2] = (axis.z * axis.z * cos_value) + cos_theta;

        return res;
    }

    pub fn translate(translation: Vec3) Self {
        var res = Self.identity();
        res.m[3][0] = translation.x;
        res.m[3][1] = translation.y;
        res.m[3][2] = translation.z;
        return res;
    }
};

test "Vec3.zero" {
    const v = Vec3.zero();
    assert(v.x == 0.0 and v.y == 0.0 and v.z == 0.0);
}

test "Vec3.init" {
    const v = Vec3.init(1.0, 2.0, 3.0);
    assert(v.x == 1.0 and v.y == 2.0 and v.z == 3.0);
}

test "Mat4.ident" {
    const m = Mat4.identity();
    for (m.m, 0..) |row, y| {
        for (row, 0..) |val, x| {
            if (x == y) {
                assert(val == 1.0);
            } else {
                assert(val == 0.0);
            }
        }
    }
}

test "Mat4.mul" {
    const l = Mat4.identity();
    const r = Mat4.identity();
    const m = Mat4.mul(l, r);
    for (m.m, 0..) |row, y| {
        for (row, 0..) |val, x| {
            if (x == y) {
                assert(val == 1.0);
            } else {
                assert(val == 0.0);
            }
        }
    }
}

fn eq(val: f32, cmp: f32) bool {
    const delta: f32 = 0.00001;
    return (val > (cmp - delta)) and (val < (cmp + delta));
}

test "Mat4.persp" {
    const m = Mat4.persp(60.0, 1.33333337, 0.01, 10.0);

    assert(eq(m.m[0][0], 1.73205));
    assert(eq(m.m[0][1], 0.0));
    assert(eq(m.m[0][2], 0.0));
    assert(eq(m.m[0][3], 0.0));

    assert(eq(m.m[1][0], 0.0));
    assert(eq(m.m[1][1], 2.30940));
    assert(eq(m.m[1][2], 0.0));
    assert(eq(m.m[1][3], 0.0));

    assert(eq(m.m[2][0], 0.0));
    assert(eq(m.m[2][1], 0.0));
    assert(eq(m.m[2][2], -1.00200));
    assert(eq(m.m[2][3], -1.0));

    assert(eq(m.m[3][0], 0.0));
    assert(eq(m.m[3][1], 0.0));
    assert(eq(m.m[3][2], -0.02002));
    assert(eq(m.m[3][3], 0.0));
}

test "Mat4.lookat" {
    const m = Mat4.lookat(.{ .x = 0.0, .y = 1.5, .z = 6.0 }, Vec3.zero(), Vec3.up);

    assert(eq(m.m[0][0], 1.0));
    assert(eq(m.m[0][1], 0.0));
    assert(eq(m.m[0][2], 0.0));
    assert(eq(m.m[0][3], 0.0));

    assert(eq(m.m[1][0], 0.0));
    assert(eq(m.m[1][1], 0.97014));
    assert(eq(m.m[1][2], 0.24253));
    assert(eq(m.m[1][3], 0.0));

    assert(eq(m.m[2][0], 0.0));
    assert(eq(m.m[2][1], -0.24253));
    assert(eq(m.m[2][2], 0.97014));
    assert(eq(m.m[2][3], 0.0));

    assert(eq(m.m[3][0], 0.0));
    assert(eq(m.m[3][1], 0.0));
    assert(eq(m.m[3][2], -6.18465));
    assert(eq(m.m[3][3], 1.0));
}

test "Mat4.rotate" {
    const m = Mat4.rotate(2.0, .{ .x = 0.0, .y = 1.0, .z = 0.0 });

    assert(eq(m.m[0][0], 0.99939));
    assert(eq(m.m[0][1], 0.0));
    assert(eq(m.m[0][2], -0.03489));
    assert(eq(m.m[0][3], 0.0));

    assert(eq(m.m[1][0], 0.0));
    assert(eq(m.m[1][1], 1.0));
    assert(eq(m.m[1][2], 0.0));
    assert(eq(m.m[1][3], 0.0));

    assert(eq(m.m[2][0], 0.03489));
    assert(eq(m.m[2][1], 0.0));
    assert(eq(m.m[2][2], 0.99939));
    assert(eq(m.m[2][3], 0.0));

    assert(eq(m.m[3][0], 0.0));
    assert(eq(m.m[3][1], 0.0));
    assert(eq(m.m[3][2], 0.0));
    assert(eq(m.m[3][3], 1.0));
}
