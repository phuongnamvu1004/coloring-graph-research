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

pub fn connected_graph(num_vertices: usize, gpa: std.mem.Allocator) !Graph {
    var graph = try Graph.init(gpa);

    for (0..num_vertices) |_| {
        _ = try graph.add_vertex(0);
    }

    for (0..num_vertices) |a| {
        for (a + 1..num_vertices) |b| {
            try graph.add_edge_by_id(@intCast(a), @intCast(b));
        }
    }

    return graph;
}

pub fn random_graph(num_vertices: usize, num_edges: usize, rand: std.Random, gpa: std.mem.Allocator) !Graph {
    var graph = try Graph.init(gpa);

    for (0..num_vertices) |_| {
        _ = try graph.add_vertex(0);
    }

    var added: usize = 0;
    while (added < num_edges) {
        const rand1: i32 = @intCast(rand.int(usize) % num_vertices);
        const rand2: i32 = @intCast(rand.int(usize) % num_vertices);
        if (!graph.adjacent_id(rand1, rand2)) {
            added += 1;
            try graph.add_edge_by_id(rand1, rand2);
        }
    }

    return graph;
}

pub fn random_connected_graph(num_vertices: usize, num_edges: usize, rng: std.Random, gpa: std.mem.Allocator) !Graph { // assume num_edges > num_vertices
    var graph = try Graph.init(gpa);

    for (0..num_vertices) |_| {
        _ = try graph.add_vertex(0);
    }

    for (0..num_vertices) |a| {
        var rand: i32 = @intCast(a);
        while (rand == @as(i32, @intCast(a))) {
            rand = @intCast(rng.int(usize) % num_vertices);
        }
        try graph.add_edge_by_id(@intCast(a), rand);
    }

    var added: usize = 0;
    while (added < num_edges - num_vertices) {
        const rand1: i32 = @intCast(rng.int(usize) % num_vertices);
        const rand2: i32 = @intCast(rng.int(usize) % num_vertices);
        if (!graph.adjacent_id(rand1, rand2)) {
            added += 1;
            try graph.add_edge_by_id(rand1, rand2);
        }
    }

    return graph;
}
