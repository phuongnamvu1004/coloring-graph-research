const std = @import("std");

const Graph = @import("graph.zig");
const zlm = @import("zlm").as(f64);

const Eigen = @import("eigen.zig");

const GraphGen = @import("graph-generator.zig");

pub fn main() !void {
    var allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer allocator.deinit();

    const gpa = allocator.allocator();

    var graph = try GraphGen.connected_graph(10, gpa);

    var laplacian = try graph.laplacian_matrix(gpa);

    var compressed = try laplacian.compressed_matrix(2, gpa);

    compressed.debug_print();

    try graph.print_as_graphml("original.graphml", 1);
}

// As k increases, coloring graph of graph on n vertices "approaches" H(n, k)? a.k.a. take complete graph on k vertices and "expand" it into n dimensions
// for example, H(3, 2) is a cube, and is the coloring graph of 3 disconnected vertices for k=2
// try compressing the laplacian according to the first group of eigenvalues

// compression for 4-path graph on k=3 works great until compression by >15, then the original graph is still there but the edge probabilities are very close to -0.5
// compression by <=15 has very consistent values by permutation classes, by >15 they begin to vary but still follow the patterns

// edge compression matches very well with the degree of each vertex, which also appears to match up well with permutation class.

// number is the last for which the original graph remains
// 3-path graph for k=4 breaks at keeping 12 eigenvalues out of 36
// 3-path graph for k=3 breaks at keeping 3 eigenvalues out of 12
