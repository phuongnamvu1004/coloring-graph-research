const std = @import("std");

const Graph = @import("graph.zig");
const zlm = @import("zlm").as(f64);

const Eigen = @import("eigen.zig");

pub fn main() !void {
    var allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer allocator.deinit();

    const gpa = allocator.allocator();

    // var matrix = try Eigen.init(3, gpa);
    // defer matrix.deinit(gpa);
    //
    // matrix.set(&.{
    //     0, 1, 0,
    //     1, 0, 1,
    //     0, 1, 0,
    // });
    //
    // var eigens = try matrix.compute_eigenvalues(gpa);
    // defer eigens.deinit(gpa);
    //
    // for (0..3) |i| {
    //     std.debug.print("{d} ", .{eigens.get(i, i).*});
    // }
    // std.debug.print("\n", .{});

    var graph = try Graph.init(gpa);
    defer graph.deinit();

    const v1 = try graph.add_vertex(1);
    const v2 = try graph.add_vertex(2);
    const v3 = try graph.add_vertex(3);
    // const v4 = try graph.add_vertex(3);
    // const v5 = try graph.add_vertex(3);
    // const v6 = try graph.add_vertex(3);

    _ = try graph.add_edge(v1, v2);
    _ = try graph.add_edge(v2, v3);
    // _ = try graph.add_edge(v3, v4);
    // _ = try graph.add_edge(v4, v5);
    // _ = try graph.add_edge(v5, v6);

    // _ = try graph.add_edge(v1, v4);
    // _ = try graph.add_edge(v1, v6);
    //
    // _ = try graph.add_edge(v2, v5);
    // _ = try graph.add_edge(v3, v6);

    // _ = try graph.add_edge(v1, v4);
    // _ = try graph.add_edge(v2, v5);
    // _ = try graph.add_edge(v5, v6);
    // _ = try graph.add_edge(v6, v1);

    const k = 3;

    std.debug.print("generating coloring graph...\n", .{});
    var coloring_graph = try graph.get_coloring_graph(k, gpa);
    defer coloring_graph.deinit();

    var coloring_laplacian = try Eigen.init(coloring_graph.num_vertices(), gpa);
    defer coloring_laplacian.deinit(gpa);

    coloring_laplacian.zero();

    for (coloring_graph.adjacency_list.items) |e| {
        coloring_laplacian.get(@intCast(e.a.id), @intCast(e.b.id)).* = -1;
        coloring_laplacian.get(@intCast(e.b.id), @intCast(e.a.id)).* = -1;
    }

    var it = coloring_graph.vertices.iterator();
    while (it.next()) |v| {
        coloring_laplacian.get(@intCast(v.key_ptr.id), @intCast(v.key_ptr.id)).* = @floatFromInt(coloring_graph.num_neighbors(v.key_ptr));
    }

    var eigens = try coloring_laplacian.compute_eigenvalues(gpa);
    defer eigens.deinit(gpa);

    for (0..eigens.size) |i| {
        std.debug.print("{d} ", .{eigens.get(i, i).*});
    }
    std.debug.print("\n", .{});

    std.debug.print("generating bell graph...\n", .{});
    var bell_graph = try coloring_graph.bell_from_coloring(k, gpa); // generating the bell graph has a side effect of assigning permutation values to the input
    defer bell_graph.deinit();

    try coloring_graph.print_as_graphml("coloring.graphml", k);

    try bell_graph.print_as_graphml("bell.graphml", k);

    try graph.print_as_graphml("original.graphml", k);
}
