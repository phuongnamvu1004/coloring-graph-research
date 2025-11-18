const std = @import("std");

const Graph = @import("graph.zig");
const zlm = @import("zlm").as(f64);

const Eigen = @import("eigen.zig");

const GraphGen = @import("graph-generator.zig");

pub fn main() !void {
    var allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer allocator.deinit();

    var prng = std.Random.DefaultPrng.init(@intCast(std.time.timestamp()));
    const rng = prng.random();

    const gpa = allocator.allocator();

    _ = rng;

    // var graph = try GraphGen.random_graph(12, 15, rng, gpa);

    var graph = try Graph.init(gpa);

    const v1 = try graph.add_vertex(0);
    const v2 = try graph.add_vertex(0);
    const v3 = try graph.add_vertex(0);

    try graph.add_edge(v1, v2);
    try graph.add_edge(v2, v3);

    const k = 3;

    var coloring = try graph.get_coloring_graph(k, gpa);

    var laplacian = try coloring.laplacian_matrix(gpa);

    laplacian.debug_print();

    var compressed = try laplacian.compressed_matrix(3, gpa);

    var compressed_graph = try Graph.propable_graph_from_laplacian(compressed, gpa);

    try compressed_graph.print_as_graphml("compressed.graphml", k);

    compressed.debug_print();

    std.debug.print("{}\n", .{laplacian.equals_compressed(compressed)});
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
