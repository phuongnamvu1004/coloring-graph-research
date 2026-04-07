const std = @import("std");

const Graph = @import("graph.zig");
const Lazy = @import("lazy-coloring-graph.zig");
const zlm = @import("zlm").as(f64);

const Eigen = @import("eigen.zig");

const GraphGen = @import("graph-generator.zig");

pub fn main() !void {
    var allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer allocator.deinit();

    const gpa = allocator.allocator();

    // var graph = try Graph.init(gpa);
    // defer graph.deinit();

    // const v1 = try graph.add_vertex(0);
    // const v2 = try graph.add_vertex(0);
    // const v3 = try graph.add_vertex(0);
    // const v4 = try graph.add_vertex(0);
    // const v5 = try graph.add_vertex(0);
    // const v6 = try graph.add_vertex(0);
    // const v7 = try graph.add_vertex(0);
    //
    // _ = try graph.add_edge(v1, v2);
    // _ = try graph.add_edge(v2, v3);
    // _ = try graph.add_edge(v1, v3);
    //
    // _ = try graph.add_edge(v1, v4);
    // _ = try graph.add_edge(v4, v5);
    // _ = try graph.add_edge(v2, v6);
    // _ = try graph.add_edge(v5, v7);
    // _ = try graph.add_edge(v6, v7);

    // const v1 = try graph.add_vertex(0);
    // const v2 = try graph.add_vertex(0);
    // const v3 = try graph.add_vertex(0);
    //
    // _ = try graph.add_edge(v1, v2);
    // _ = try graph.add_edge(v2, v3);

    var prng = std.Random.DefaultPrng.init(@intCast(std.time.timestamp()));
    const rng = prng.random();
    var graph = try GraphGen.random_connected_graph(50, 100, rng, gpa);

    const k = try graph.get_minimum_k() + 2; // surplus color

    try graph.print_as_graphml("original.graphml", k);

    var lazy_coloring = try Lazy.init(graph, k, gpa);

    const v = try lazy_coloring.get_special_vertex();
    defer lazy_coloring.deinit_vertex(v);

    var reconstruction = try lazy_coloring.reconstruct(v, gpa);
    try reconstruction.print_as_graphml("lazy_reconstruction.graphml", k);
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
