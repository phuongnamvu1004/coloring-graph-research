const std = @import("std");

const Graph = @import("graph.zig");
const zlm = @import("zlm").as(f64);

const Eigen = @import("eigen.zig");

const GraphGen = @import("graph-generator.zig");

pub fn main() !void {
    var allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer allocator.deinit();

    const gpa = allocator.allocator();

    var test_matrix = try Eigen.init(5, 5, gpa);
    test_matrix.set(&.{
        1,      0.5,   0.25, 0.125, 0.0625,
        0.5,    1,     0.5,  0.25,  0.125,
        0.25,   0.5,   1,    0.5,   0.25,
        0.125,  0.25,  0.5,  1,     0.5,
        0.0625, 0.125, 0.25, 0.5,   1,
    });

    var eigens = try Eigen.init(5, 5, gpa);
    defer eigens.deinit(gpa);

    var eigenvecs = try Eigen.init(5, 5, gpa);
    defer eigenvecs.deinit(gpa);

    test_matrix.compute_eigenvalues(&eigens, &eigenvecs);

    eigens.debug_print();
    std.debug.print("-----\n", .{});

    eigenvecs.debug_print();
    std.debug.print("----\n", .{});

    var thing = try Eigen.original_from_eigens(eigens, eigenvecs, gpa);
    defer thing.deinit(gpa);

    thing.debug_print();
}
