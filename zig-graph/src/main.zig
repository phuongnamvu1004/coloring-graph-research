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
    // const v5 = try graph.add_vertex(0);

    try graph.add_edge(v1, v2);
    try graph.add_edge(v2, v3);
    try graph.add_edge(v3, v4);
    try graph.add_edge(v4, v1);
    // try graph.add_edge(v4, v3);

    const k = 4;

    var coloring_graph = try graph.get_coloring_graph(k, gpa);
    defer coloring_graph.deinit();

    var bell_graph = try coloring_graph.bell_from_coloring(k, gpa);
    defer bell_graph.deinit();

    var test_matrix = try Eigen.init(5, gpa);
    test_matrix.set(&.{
        1,      0.5,   0.25, 0.125, 0.0625,
        0.5,    1,     0.5,  0.25,  0.125,
        0.25,   0.5,   1,    0.5,   0.25,
        0.125,  0.25,  0.5,  1,     0.5,
        0.0625, 0.125, 0.25, 0.5,   1,
    });

    var eigens = try Eigen.init(5, gpa);
    var eigenvecs = try Eigen.init(5, gpa);
    test_matrix.compute_eigenvalues(&eigens, &eigenvecs);

    eigens.debug_print();
    std.debug.print("-----\n", .{});
    eigenvecs.debug_print();

    std.debug.print("----\n", .{});
    var thing = try Eigen.original_from_eigens(eigens, eigenvecs, gpa);
    thing.debug_print();
}
