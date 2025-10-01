const std = @import("std");

const Self = @This();

const num_runs = 100;

size: usize,
values: []f32,

pub fn init(size: usize, gpa: std.mem.Allocator) !Self {
    return .{
        .size = size,
        .values = try gpa.alloc(f32, size * size),
    };
}

pub fn deinit(self: Self, gpa: std.mem.Allocator) void {
    gpa.free(self.values);
}

pub fn zero(self: *Self) void {
    for (self.values) |*v| {
        v.* = 0;
    }
}

pub fn set(self: *Self, values: []const f32) void {
    @memcpy(self.values, values);
}

pub fn get(self: *Self, x: usize, y: usize) *f32 {
    return &self.values[y * self.size + x];
}

pub fn debug_print(self: *Self) void {
    for (0..self.size) |y| {
        for (0..self.size) |x| {
            std.debug.print("{d} ", .{self.get(x, y).*});
        }
        std.debug.print("\n", .{});
    }
}

pub fn compute_eigenvalues(self: *Self, gpa: std.mem.Allocator) !Self { // translated from https://www.cs.nthu.edu.tw/~cchen/ISA5305/Prog/eigen.c which is perhaps the ugliest code I've seen in my entire life
    var ret = try Self.init(self.size, gpa);
    ret.set(self.values);
    const epsilon = 1e-22;

    var p: usize = 0;
    var q: usize = 0;

    var alpha: f32 = 0;
    var t: f32 = 0;
    var c: f32 = 0;
    var s: f32 = 0;
    var tau: f32 = 0;

    for (0..num_runs) |_| { // number of iterations
        var tmax: f32 = -1;
        var sum: f32 = 0;

        for (0..ret.size) |i| {
            for (i + 1..ret.size) |j| {
                t = @abs(ret.get(i, j).*);
                sum += t * t;
                if (t > tmax) {
                    tmax = t;
                    p = i;
                    q = j;
                }
            }
        }

        sum = @sqrt(2 * sum);
        if (sum < epsilon)
            return ret;

        alpha = (ret.get(q, q).* - ret.get(p, p).*) / 2 / ret.get(p, q).*;
        if (alpha > epsilon) {
            t = 1 / (alpha + @sqrt(1 + alpha * alpha));
        } else if (alpha < epsilon) {
            t = 1 / (alpha - @sqrt(1 + alpha * alpha)); // unsure about this but trust the awful c code
        } else {
            t = 1;
        }

        c = 1 / @sqrt(1.0 + t * t);
        s = c * t;
        tau = s / c;

        for (0..p) |r|
            ret.get(p, r).* = c * ret.get(r, p).* - s * ret.get(r, q).*;
        for (p + 1..ret.size) |r| {
            if (r != q)
                ret.get(r, p).* = c * ret.get(p, r).* - s * ret.get(q, r).*;
        }

        for (0..p) |r|
            ret.get(q, r).* = s * ret.get(r, p).* + c * ret.get(r, q).*;
        for (p + 1..q) |r|
            ret.get(q, r).* = s * ret.get(p, r).* + c * ret.get(r, q).*;
        for (q + 1..ret.size) |r|
            ret.get(r, q).* = s * ret.get(p, r).* + c * ret.get(q, r).*;

        ret.get(p, p).* = ret.get(p, p).* - t * ret.get(p, q).*;
        ret.get(q, q).* = ret.get(q, q).* + t * ret.get(p, q).*;
        ret.get(q, p).* = 0;

        for (0..ret.size) |i| {
            for (i + 1..ret.size) |j| {
                ret.get(i, j).* = ret.get(j, i).*;
            }
        }
    }
    return ret;
}
