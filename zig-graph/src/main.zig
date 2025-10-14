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

    var v1 = try graph.add_vertex(0);

    const k = 3;

    var buf: [100]u8 = undefined;

    inline for (1..10) |i| {
        std.debug.print("i={d}\n", .{i});
        const filename = try std.fmt.bufPrint(&buf, "data{d}", .{i});

        std.debug.print("coloring...\t\tk={d}\n", .{k});
        var coloring_graph = try graph.get_coloring_graph(k, gpa);
        defer coloring_graph.deinit();

        std.debug.print("bell...\t\t\tk={d}\n", .{k});
        var bell_graph = try coloring_graph.bell_from_coloring(k, gpa);
        defer bell_graph.deinit();

        var file = try std.fs.cwd().createFile(filename, .{});
        defer file.close();

        var laplacian = try bell_graph.laplacian_matrix(gpa);
        defer laplacian.deinit(gpa);

        var it = try laplacian.get_eigenvalues(gpa);
        defer it.deinit(gpa);

        while (it.next()) |e| {
            _ = try file.writeAll(try std.fmt.bufPrint(&buf, "{d}\n", .{e}));
        }

        const v2 = try graph.add_vertex(0);
        _ = try graph.add_edge(v1, v2);
        v1 = v2;

        graph.debug_print();
    }
}
