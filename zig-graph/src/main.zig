const std = @import("std");

const Graph = @import("graph.zig");
const zlm = @import("zlm").as(f64);

const Eigen = @import("eigen.zig");

const GraphGen = @import("graph-generator.zig");

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

    try graph.add_edge(v1, v2);
    try graph.add_edge(v2, v3);
    try graph.add_edge(v3, v4);

    const k = 3;

    var coloring_graph = try graph.get_coloring_graph(k, gpa);
    defer coloring_graph.deinit();

    const laplacian = try coloring_graph.laplacian_matrix(gpa);
    defer laplacian.deinit(gpa);

    var vals = try Eigen.init(laplacian.num_rows, laplacian.num_cols, gpa);
    defer vals.deinit(gpa);
    var vecs = try Eigen.init(laplacian.num_rows, laplacian.num_cols, gpa);
    defer vecs.deinit(gpa);

    laplacian.compute_eigenvalues(&vals, &vecs);

    const original = try Eigen.original_from_eigens(vals, vecs, gpa);
    defer original.deinit(gpa);
    original.debug_print();

    var compressed = try laplacian.compressed_matrix(10, gpa);
    compressed.debug_print();
}

// As k increases, coloring graph of graph on n vertices "approaches" H(n, k)? a.k.a. take complete graph on k vertices and "expand" it into n dimensions
// for example, H(3, 2) is a cube, and is the coloring graph of 3 disconnected vertices for k=2
// try compressing the laplacian according to the first group of eigenvalues
