const std = @import("std");
const zla = @import("zla");

const Self = @This();

const Error = error{InvalidMatrixMultiply};

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

pub fn debug_print(self: Self) void {
    std.debug.print("------------\n", .{});
    for (0..self.num_rows) |y| {
        for (0..self.num_cols) |x| {
            std.debug.print("{d: >7.4} ", .{self.get_val(x, y)});
        }
        std.debug.print("\n", .{});
    }
    std.debug.print("------------\n", .{});
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

pub fn mul(self: Self, other: Self, gpa: std.mem.Allocator) !Self { // definitely correct
    if (self.num_cols != other.num_rows)
        return Error.InvalidMatrixMultiply;
    var ret = try Self.init(self.num_rows, other.num_cols, gpa);

    for (0..self.num_rows) |i| {
        for (0..other.num_cols) |j| {
            var dot_prod: f64 = 0;
            for (0..self.num_cols) |col| {
                dot_prod += self.get_val(col, i) * other.get_val(j, col);
            }

            ret.get(j, i).* = dot_prod;
        }
    }

    return ret;
}

pub fn transpose(self: Self, gpa: std.mem.Allocator) !Self {
    var ret = try Self.init(self.num_cols, self.num_rows, gpa);

    for (0..self.num_rows) |i| {
        for (0..self.num_cols) |j| {
            ret.get(i, j).* = self.get_val(j, i);
        }
    }

    return ret;
}

pub fn original_from_eigens(eigenvals: Self, eigenvecs: Self, gpa: std.mem.Allocator) !Self {
    const transposed = try eigenvecs.transpose(gpa);
    defer transposed.deinit(gpa);

    const step1 = try transposed.mul(eigenvals, gpa);
    defer step1.deinit(gpa);

    const result = try step1.mul(eigenvecs, gpa);
    return result;
}

pub fn compressed_matrix(self: Self, m: usize, gpa: std.mem.Allocator) !Self {
    var eigenvalues_matrix = try Self.init(self.num_rows, self.num_rows, gpa); // self assumed to be square
    defer eigenvalues_matrix.deinit(gpa);

    var eigenvectors_matrix = try Self.init(self.num_rows, self.num_rows, gpa); // self assumed to be square
    defer eigenvectors_matrix.deinit(gpa);

    self.compute_eigenvalues(&eigenvalues_matrix, &eigenvectors_matrix);

    for (0..m) |_| { // remove m smallest eigenvalues
        var min = std.math.inf(f64);
        var min_index: usize = 0;

        for (0..eigenvalues_matrix.num_rows) |i| {
            const eigenval = eigenvalues_matrix.get_val(i, i);
            if (!std.math.isNan(eigenval) and eigenval < min) { // nan to mark as removed
                min = eigenval;
                min_index = i;
            }
        }

        eigenvalues_matrix.get(min_index, min_index).* = std.math.nan(f64);
    }

    var new_eigenvalues_matrix = try Self.init(eigenvalues_matrix.num_rows - m, eigenvalues_matrix.num_cols - m, gpa);
    new_eigenvalues_matrix.zero();
    defer new_eigenvalues_matrix.deinit(gpa);

    var new_eigenvectors_matrix = try Self.init(eigenvectors_matrix.num_rows - m, eigenvectors_matrix.num_cols, gpa);
    new_eigenvectors_matrix.zero();
    defer new_eigenvectors_matrix.deinit(gpa);

    var new_index: usize = 0;
    for (0..eigenvalues_matrix.num_rows) |i| {
        const eigenval = eigenvalues_matrix.get_val(i, i);
        if (!std.math.isNan(eigenval)) {
            new_eigenvalues_matrix.get(new_index, new_index).* = eigenval;

            for (0..new_eigenvectors_matrix.num_cols) |x| {
                new_eigenvectors_matrix.get(x, new_index).* = eigenvectors_matrix.get_val(x, i);
            }

            new_index += 1;
        }
    }

    const ret = try original_from_eigens(new_eigenvalues_matrix, new_eigenvectors_matrix, gpa);
    return ret;
}
