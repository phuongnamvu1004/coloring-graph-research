const std = @import("std");

const Graph = @import("graph.zig");
const zlm = @import("zlm").as(f64);

const Eigen = @import("eigen.zig");

pub fn main() !void {
    var allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer allocator.deinit();

    const gpa = allocator.allocator();

    var graph = try Graph.init(gpa);
    defer graph.deinit();

    const v1 = try graph.add_vertex(0);
    const v2 = try graph.add_vertex(0);
    const v3 = try graph.add_vertex(0);
    const v4 = try graph.add_vertex(0);
    const v5 = try graph.add_vertex(0);
    const v6 = try graph.add_vertex(0);
    const v7 = try graph.add_vertex(0);
    const v8 = try graph.add_vertex(0);

    try graph.add_edge(v1, v2);
    try graph.add_edge(v2, v3);
    try graph.add_edge(v3, v4);
    try graph.add_edge(v4, v5);
    try graph.add_edge(v5, v6);
    try graph.add_edge(v6, v7);
    try graph.add_edge(v7, v8);

    const k = 4;

    std.debug.print("{d}\n", .{try graph.chromatic_polynomial(k, gpa)});

    var coloring_graph = try graph.get_coloring_graph(k, gpa);
    defer coloring_graph.deinit();

    try coloring_graph.print_as_graphml("coloring.graphml", k);

    // std.debug.print("bell\n", .{});
    // var bell_graph = try coloring_graph.bell_from_coloring(k, gpa);
    // defer bell_graph.deinit();
    //
    // std.debug.print("generating coloring graphml...\n", .{});
    // try coloring_graph.print_as_graphml("coloring.graphml", k);
    // std.debug.print("generating coloring graphml...\n", .{});
    // try bell_graph.print_as_graphml("bell.graphml", k);

    //
    // var buf: [100]u8 = undefined;
    //
    // inline for (1..10) |i| {
    //     std.debug.print("i={d}\n", .{i});
    //     const filename = try std.fmt.bufPrint(&buf, "data{d}", .{i});
    //
    //     std.debug.print("coloring...\t\tk={d}\n", .{k});
    //     var coloring_graph = try graph.get_coloring_graph(k, gpa);
    //     defer coloring_graph.deinit();
    //
    //     std.debug.print("bell...\t\t\tk={d}\n", .{k});
    //     var bell_graph = try coloring_graph.bell_from_coloring(k, gpa);
    //     defer bell_graph.deinit();
    //
    //     var file = try std.fs.cwd().createFile(filename, .{});
    //     defer file.close();
    //
    //     var laplacian = try bell_graph.laplacian_matrix(gpa);
    //     defer laplacian.deinit(gpa);
    //
    //     var it = try laplacian.get_eigenvalues(gpa);
    //     defer it.deinit(gpa);
    //
    //     while (it.next()) |e| {
    //         _ = try file.writeAll(try std.fmt.bufPrint(&buf, "{d}\n", .{e}));
    //     }
    //
    //     const v2 = try graph.add_vertex(0);
    //     _ = try graph.add_edge(v1, v2);
    //     v1 = v2;
    //
    //     graph.debug_print();
    // }
}
