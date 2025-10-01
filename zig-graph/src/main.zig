const std = @import("std");

const Graph = @import("graph.zig");
const zlm = @import("zlm").as(f64);

pub fn main() !void {
    var allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer allocator.deinit();

    const gpa = allocator.allocator();

    var graph = try Graph.init(gpa);
    defer graph.deinit();

    const v1 = try graph.add_vertex(1);
    const v2 = try graph.add_vertex(2);
    const v3 = try graph.add_vertex(3);
    const v4 = try graph.add_vertex(3);
    // const v5 = try graph.add_vertex(3);
    // const v6 = try graph.add_vertex(3);

    _ = try graph.add_edge(v1, v2);
    _ = try graph.add_edge(v2, v3);
    _ = try graph.add_edge(v3, v4);
    // _ = try graph.add_edge(v4, v5);
    // _ = try graph.add_edge(v5, v6);
    // _ = try graph.add_edge(v6, v1);

    const k = 4;

    std.debug.print("generating coloring graph...\n", .{});
    var coloring_graph = try graph.get_coloring_graph(k, gpa);
    defer coloring_graph.deinit();

    std.debug.print("generating bell graph...\n", .{});
    var bell_graph = try coloring_graph.bell_from_coloring(k, gpa); // generating the bell graph has a side effect of assigning permutation values to the input
    defer bell_graph.deinit();

    try coloring_graph.print_as_graphml("coloring.graphml", k);

    try bell_graph.print_as_graphml("bell.graphml", k);

    try graph.print_as_graphml("file.graphml", k);
}
