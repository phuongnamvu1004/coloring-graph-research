const std = @import("std");
const Graph = @import("graph.zig");


pub fn graph_from_edge_pairs(
    gpa: std.mem.Allocator,
    num_vertices: i32,
    edges: []const [2]i32,
    labels: ?[]const i32,
) !Graph {
    var g = try Graph.init(gpa);
    errdefer g.deinit();

    // Keep pointers to created vertices in ID order for wiring edges.
    var verts = try std.ArrayList(*Graph.Vertex).initCapacity(gpa, @intCast(num_vertices));
    defer verts.deinit(gpa);

    var i: i32 = 0;
    while (i < num_vertices) : (i += 1) {
        const label = if (labels) |ls| blk: {
            const idx: usize = @intCast(i);
            break :blk if (idx < ls.len) ls[idx] else 0;
        } else 0;
        const v = try g.add_vertex(label);
        try verts.append(gpa, v);
    }

    // Add edges according to the provided relationships.
    for (edges) |e| {
        const u_id: usize = @intCast(e[0]);
        const v_id: usize = @intCast(e[1]);
        // Guard against bad input
        if (u_id >= verts.items.len or v_id >= verts.items.len) {
            return error.InvalidEdgeIndex;
        }
        _ = try g.add_edge(verts.items[u_id], verts.items[v_id]);
    }

    return g;
}


