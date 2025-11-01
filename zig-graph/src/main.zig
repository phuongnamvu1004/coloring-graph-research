const std = @import("std");

const Graph = @import("graph.zig");
const zlm = @import("zlm").as(f64);

const Eigen = @import("eigen.zig");

const GraphGen = @import("graph-generator.zig");

pub fn main() !void {
    var allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer allocator.deinit();

    const gpa = allocator.allocator();

    var test_matrix = try Eigen.init(5, 5, gpa);
    defer test_matrix.deinit(gpa);

    test_matrix.set(&.{
        1,      0.5,   0.25, 0.125, 0.0625,
        0.5,    1,     0.5,  0.25,  0.125,
        0.25,   0.5,   1,    0.5,   0.25,
        0.125,  0.25,  0.5,  1,     0.5,
        0.0625, 0.125, 0.25, 0.5,   1,
    });

    var vals = try Eigen.init(5, 5, gpa);
    defer vals.deinit(gpa);

    var vecs = try Eigen.init(5, 5, gpa);
    defer vecs.deinit(gpa);

    test_matrix.compute_eigenvalues(&vals, &vecs);

    const original = try Eigen.original_from_eigens(vals, vecs, gpa);
    defer original.deinit(gpa);
    original.debug_print();

    var compressed = try test_matrix.compressed_matrix(1, gpa);
    compressed.debug_print();
}

// As k increases, coloring graph of graph on n vertices "approaches" H(n, k)? a.k.a. take complete graph on k vertices and "expand" it into n dimensions
// for example, H(3, 2) is a cube, and is the coloring graph of 3 disconnected vertices for k=2
// try compressing the laplacian according to the first group of eigenvalues
