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
    const v2 = try graph.add_vertex(1);
    const v3 = try graph.add_vertex(1);
    const v4 = try graph.add_vertex(1);

    _ = try graph.add_edge(v1, v2);
    _ = try graph.add_edge(v2, v3);
    _ = try graph.add_edge(v4, v3);
    _ = try graph.add_edge(v1, v3);

    const k = 5;

    std.debug.print("coloring...\n", .{});
    var coloring_graph = try graph.get_coloring_graph(k, gpa);
    defer coloring_graph.deinit();

    std.debug.print("chromatic poly...\n", .{});

    std.debug.print("chromatic polynomial is {d}, coloring graph size is {d}\n", .{ try graph.chromatic_polynomial(k, gpa), coloring_graph.num_vertices() });
}
