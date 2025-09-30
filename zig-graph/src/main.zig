const std = @import("std");

const Graph = @import("graph.zig");

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

    // graph.remove_edge(.{ .a = v1, .b = v4 });
    // if (graph.is_coloring_valid(&.{ 1, 2, 2, 2 }))
    //     std.debug.print("valid\n", .{});

    const k = 5;

    std.debug.print("generating coloring graph...\n", .{});
    var coloring_graph = try graph.get_coloring_graph(k, gpa);
    defer coloring_graph.deinit();

    try coloring_graph.print_as_graphml("coloring.graphml", k);

    std.debug.print("generating bell graph...\n", .{});
    var bell_graph = try coloring_graph.bell_from_coloring(k, gpa);
    defer bell_graph.deinit();

    try bell_graph.print_as_graphml("bell.graphml", k);

    // var neighbors = graph.neighbors(v1);
    // while (neighbors.next()) |v| {
    //     std.debug.print("{d}\n", .{v});
    // }
    // graph.debug_print();

    try graph.print_as_graphml("file.graphml", k);
}
