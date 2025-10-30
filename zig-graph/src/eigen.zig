const std = @import("std");
const zla = @import("zla");

const Self = @This();

const num_runs = 10000;

num_rows: usize,
num_cols: usize,
values: []f64,

pub fn init(num_rows: usize, num_cols: usize, gpa: std.mem.Allocator) !Self {
    return .{
        .num_rows = num_rows,
        .num_cols = num_cols,
        .values = try gpa.alloc(f64, num_rows * num_cols),
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

pub fn set(self: *Self, values: []const f64) void {
    @memcpy(self.values, values);
}

pub fn get(self: *Self, x: usize, y: usize) *f64 {
    return &self.values[y * self.num_cols + x];
}

pub fn get_val(self: Self, x: usize, y: usize) f64 {
    return self.values[y * self.num_cols + x];
}

pub fn debug_print(self: *Self) void {
    for (0..self.num_cols) |y| {
        for (0..self.num_rows) |x| {
            std.debug.print("{d} ", .{self.get(x, y).*});
        }
        std.debug.print("\n", .{});
    }
}

pub fn compute_eigenvalues(self: Self, eigenvals: *Self, eigenvecs: *Self) void { // translated from https://www.cs.nthu.edu.tw/~cchen/ISA5305/Prog/eigen.c which is perhaps the ugliest code I've seen in my entire life
    eigenvals.set(self.values);
    eigenvecs.set(self.values);
    const epsilon = 1e-10;

    var p: usize = 0;
    var q: usize = 0;

    var alpha: f64 = 0;
    var t: f64 = 0;
    var c: f64 = 0;
    var s: f64 = 0;
    var tau: f64 = 0;

    for (0..self.num_rows) |i| {
        for (0..self.num_cols) |j| {
            if (i == j) {
                eigenvecs.get(i, j).* = 1;
            } else {
                eigenvecs.get(i, j).* = 0;
            }
        }
    }

    for (0..num_runs) |_| { // number of iterations
        var tmax: f64 = -1;
        var sum: f64 = 0;

        for (0..eigenvals.num_rows) |i| {
            for (i + 1..eigenvals.num_cols) |j| {
                t = @abs(eigenvals.get(i, j).*);
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
            return;

        alpha = (eigenvals.get(q, q).* - eigenvals.get(p, p).*) / 2 / eigenvals.get(p, q).*;
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
            eigenvals.get(p, r).* = c * eigenvals.get(r, p).* - s * eigenvals.get(r, q).*;
        for (p + 1..eigenvals.num_rows) |r| {
            if (r != q)
                eigenvals.get(r, p).* = c * eigenvals.get(p, r).* - s * eigenvals.get(q, r).*;
        }

        for (0..p) |r|
            eigenvals.get(q, r).* = s * eigenvals.get(r, p).* + c * eigenvals.get(r, q).*;
        for (p + 1..q) |r|
            eigenvals.get(q, r).* = s * eigenvals.get(p, r).* + c * eigenvals.get(r, q).*;
        for (q + 1..eigenvals.num_rows) |r|
            eigenvals.get(r, q).* = s * eigenvals.get(p, r).* + c * eigenvals.get(q, r).*;

        eigenvals.get(p, p).* = eigenvals.get(p, p).* - t * eigenvals.get(p, q).*;
        eigenvals.get(q, q).* = eigenvals.get(q, q).* + t * eigenvals.get(p, q).*;
        eigenvals.get(q, p).* = 0;

        for (0..eigenvals.num_rows) |i| {
            for (i + 1..eigenvals.num_rows) |j| {
                eigenvals.get(i, j).* = eigenvals.get(j, i).*;
            }
        }

        for (0..eigenvals.num_rows) |i| {
            const xp = eigenvecs.get_val(i, p);
            const xq = eigenvecs.get_val(i, q);
            eigenvecs.get(i, p).* = c * xp - s * xq;
            eigenvecs.get(i, q).* = s * xp + c * xq;
        }
    }
}

pub fn mul(self: Self, other: Self, gpa: std.mem.Allocator) !Self {
    const self_num_rows = self.num_rows;

    const other_num_cols = other.num_cols;

    var ret = try Self.init(self_num_rows, other_num_cols, gpa);

    for (0..self_num_rows) |i| {
        for (0..other_num_cols) |j| {
            var dot_prod: f64 = 0;
            for (0..self.num_cols) |col| {
                dot_prod += self.get_val(i, col) * other.get_val(col, j);
            }

            ret.get(i, j).* = dot_prod;
        }
    }

    return ret;
}

pub fn transpose(self: Self, gpa: std.mem.Allocator) !Self {
    var ret = try Self.init(self.num_cols, self.num_rows, gpa);

    for (0..self.num_rows) |i| {
        for (0..self.num_cols) |j| {
            ret.get(j, i).* = self.get_val(i, j);
        }
    }

    return ret;
} 

pub fn original_from_eigens(eigenvals: Self, eigenvecs: Self, gpa: std.mem.Allocator) !Self {
    // var fancy_eigenvals = zla.Mat(f64, 5, 5).zero;
    // for (0..eigenvals.num_rows) |i| {
    //     for (0..eigenvals.num_cols) |j| {
    //         fancy_eigenvals.items[j][i] = eigenvals.get_val(i, j);
    //     }
    // }

    // var fancy_eigenvecs = zla.Mat(f64, 5, 5).zero;
    // for (0..eigenvecs.size) |i| {
    //     for (0..eigenvecs.size) |j| {
    //         fancy_eigenvecs.items[j][i] = eigenvecs.get_val(i, j);
    //     }
    // }

    // const fancy_ret = fancy_eigenvecs.mul(fancy_eigenvals).mul(fancy_eigenvecs.transpose());

    const transposed = try eigenvecs.transpose(gpa);

    defer transposed.deinit(gpa);

    const ret1 = try eigenvecs.mul(eigenvals, gpa);

    defer ret1.deinit(gpa);

    const ret2 = try ret1.mul(transposed, gpa);

    

    // for (0..eigenvals.size) |i| {
    //     for (0..eigenvecs.size) |j| {
    //         ret.get(i, j).* = fancy_ret.items[j][i];
    //     }
    // }
    return ret2;
}
