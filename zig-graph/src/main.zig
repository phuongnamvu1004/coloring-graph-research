const std = @import("std");

const Graph = @import("graph.zig");
const zlm = @import("zlm").as(f64);

const Eigen = @import("eigen.zig");

const GraphGen = @import("graph-generator.zig");

pub fn main() !void {
    var allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer allocator.deinit();

    // var prng = std.Random.DefaultPrng.init(@intCast(std.time.timestamp()));
    // const rng = prng.random();

    const gpa = allocator.allocator();

    var graph = try Graph.init(gpa);
    defer graph.deinit();

    const v1 = try graph.add_vertex(0);
    const v2 = try graph.add_vertex(0);
    const v3 = try graph.add_vertex(0);
    const v4 = try graph.add_vertex(0);
    const v5 = try graph.add_vertex(0);

    try graph.add_edge(v1, v2);
    try graph.add_edge(v2, v3);
    try graph.add_edge(v3, v4);
    try graph.add_edge(v4, v1);
    try graph.add_edge(v3, v5);

    const k = 3;

    try graph.print_as_graphml("original.graphml", k);

    var coloring = try graph.get_coloring_graph(k, gpa);
    defer coloring.deinit();

    const special = coloring.get_special_vertex(k).?;
    std.debug.print("special vertex is id {d}\n", .{special.id});

    var original = try coloring.original_from_coloring(special, gpa);
    defer original.deinit();

    try original.print_as_graphml("reconstructed_original.graphml", k);

    var bell_graph = try coloring.bell_from_coloring(k, gpa);

    try bell_graph.print_as_graphml("bell.graphml", k);

    try coloring.print_as_graphml("coloring.graphml", k); // after side effect

    try bell_graph.bell_to_all_reconstructions(&coloring, k, gpa);

    // var original_laplacian = try coloring.laplacian_matrix(gpa);
    // defer original_laplacian.deinit(gpa);
    //
    // const num_vertices: i32 = 72;
    // const num_edges: i32 = 138;
    //
    // var best: i32 = std.math.maxInt(i32);
    // while (true) {
    //     var random_graph = try GraphGen.random_connected_graph(num_vertices, num_edges, rng, gpa);
    //     defer random_graph.deinit();
    //
    //     const laplacian = try random_graph.laplacian_matrix(gpa);
    //     defer laplacian.deinit(gpa);
    //
    //     var l: usize = 1;
    //     var r: usize = @intCast(num_vertices);
    //     var m: usize = (l + r) / 2;
    //
    //     while (true) {
    //         m = (l + r) / 2;
    //
    //         std.debug.print("{d} {d} {d}\n", .{ l, m, r });
    //         var compressed = try laplacian.compressed_matrix(m, gpa);
    //         defer compressed.deinit(gpa);
    //         if (compressed.equals_compressed(laplacian)) {
    //             if (best > @as(i32, @intCast(m))) {
    //                 best = @intCast(m);
    //                 std.debug.print("new best: {}\n", .{m});
    //                 try random_graph.print_as_graphml("random.graphml", k);
    //             }
    //
    //             r = m;
    //         } else {
    //             l = m;
    //         }
    //
    //         if (@abs(r - l) == 1) {
    //             std.debug.print("new graph\n", .{});
    //             break;
    //         }
    //     }
    // }
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
