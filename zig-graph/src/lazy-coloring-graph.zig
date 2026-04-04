const Self = @This();

const std = @import("std");

const Graph = @import("graph.zig");

original: Graph,
k: i32,
allocator: std.mem.Allocator,

pub const Vertex = struct {
    coloring: []i32,
    id: u64,
};

pub fn init(original: Graph, k: i32, gpa: std.mem.Allocator) !Self {
    return .{
        .original = try original.copy(gpa),
        .k = k,
        .allocator = gpa,
    };
}

pub fn deinit(self: Self) void {
    self.original.deinit();
}

pub fn get_vertex(self: Self, coloring: []i32) !?Vertex {
    if (self.original.is_coloring_valid(coloring)) {
        const new_coloring = try self.allocator.alloc(i32, coloring.len);
        for (new_coloring, 0..) |*c, i| {
            c.* = coloring[i];
        }
        return Vertex{
            .coloring = new_coloring,
            .id = self.coloring_hash(new_coloring),
        };
    }
    return null;
}

pub fn deinit_vertex(self: Self, vertex: Vertex) void {
    self.allocator.free(vertex.coloring);
}

pub fn get_special_vertex(self: *Self) !Vertex {
    const coloring = try self.allocator.alloc(i32, self.original.num_vertices());
    for (coloring) |*c| c.* = -1;

    for (coloring, 0..) |*c, i| {
        var col: i32 = 0;

        const vertex = self.original.get_vertex_by_id(@intCast(i)).?.*;
        var it = self.original.neighbors(vertex);
        while (it.next()) |v| {
            if (coloring[@intCast(v.id)] == col) {
                col += 1;
                it.reset();
            }
        }

        c.* = col;
    }

    return Vertex{ .coloring = coloring, .id = self.coloring_hash(coloring) };
}

fn clone_coloring(self: Self, coloring: []i32) ![]i32 {
    const new_coloring = try self.allocator.alloc(i32, coloring.len);
    for (new_coloring, 0..) |*c, i| {
        c.* = coloring[i];
    }
    return new_coloring;
}

fn clone_vertex(self: Self, v: Vertex) !Vertex {
    const new_coloring = try self.allocator.alloc(i32, v.coloring.len);
    for (new_coloring, 0..) |*c, i| {
        c.* = v.coloring[i];
    }
    return Vertex{ .coloring = new_coloring, .id = self.coloring_hash(new_coloring) };
}

fn equal_coloring(a: []i32, b: []i32) bool {
    for (a, b) |c1, c2| {
        if (c1 != c2)
            return false;
    }
    return true;
}

fn coloring_hash(self: Self, v: []i32) u64 { // WARNING: collisions here limit the number of vertices in the original for coherent reconstructions!!!!
    var hash: u64 = 0;
    for (v) |c| {
        hash *= @intCast(self.k); // the hash is the coloring as a base k number
        hash += @intCast(c);
    }
    return hash;
}

pub fn print_coloring(self: Self, v: Vertex) void {
    _ = self;
    for (v.coloring) |c| {
        std.debug.print("{d}", .{c});
    }
    std.debug.print("\n", .{});
}

pub const NeighborsIterator = struct {
    g: *Self,
    vertex: Vertex,
    index_v: usize,
    index_c: i32,

    fn next_raw(self: *NeighborsIterator) !?[]i32 {
        if (self.index_v >= self.vertex.coloring.len) return null;
        const new_coloring = try self.g.clone_coloring(self.vertex.coloring);
        new_coloring[self.index_v] = self.index_c;
        self.increment_index();
        return new_coloring;
    }

    pub fn next(self: *NeighborsIterator) !?Vertex {
        var new_coloring = try self.next_raw() orelse return null;

        while (!self.g.original.is_coloring_valid(new_coloring) or equal_coloring(new_coloring, self.vertex.coloring)) {
            self.g.allocator.free(new_coloring);
            new_coloring = try self.next_raw() orelse return null;
        }

        return Vertex{ .coloring = new_coloring, .id = self.g.coloring_hash(new_coloring) };
    }

    pub fn increment_index(self: *NeighborsIterator) void {
        self.index_c += 1;
        if (self.index_c == self.g.k) {
            self.index_c = 0;
            self.index_v += 1;
        }
    }

    pub fn reset(self: *NeighborsIterator) void {
        self.index_c = 0;
        self.index_v = 0;
    }
};

pub fn neighbors(self: *Self, vertex: Vertex) NeighborsIterator {
    return NeighborsIterator{
        .g = self,
        .vertex = vertex,
        .index_c = 0,
        .index_v = 0,
    };
}

pub fn adjacent(self: Self, a: Vertex, b: Vertex) bool {
    _ = self;
    var times_different: i32 = 0;
    for (a.coloring, b.coloring) |c1, c2| {
        if (c1 != c2) times_different += 1;
    }
    return times_different == 1;
}

pub fn reconstruct(self: *Self, vertex: Vertex, gpa: std.mem.Allocator) !Graph {
    var original = try Graph.init(gpa);

    var subgraphs = try std.ArrayList(std.ArrayList(Vertex)).initCapacity(gpa, 1);
    var subgraph = try std.ArrayList(Vertex).initCapacity(gpa, 1);
    defer subgraphs.deinit(gpa);

    var seen_vertices = std.AutoHashMap(u64, void).init(gpa);

    var it = self.neighbors(vertex);
    while (try it.next()) |v| { // starting vertex
        defer self.deinit_vertex(v);

        if (seen_vertices.contains(v.id)) continue;

        var it2 = self.neighbors(vertex);

        try subgraph.append(gpa, try self.clone_vertex(v));

        while (try it2.next()) |v2| {
            defer self.deinit_vertex(v2);

            if (v.id != v2.id and self.adjacent(v, v2)) { // forms complete graph
                try seen_vertices.put(v2.id, undefined);
                try subgraph.append(gpa, try self.clone_vertex(v2));
            }
        }

        const clone = try subgraph.clone(gpa);
        try subgraphs.append(gpa, clone);

        subgraph.clearAndFree(gpa);
    }

    subgraph.deinit(gpa);

    // for (subgraphs.items) |s| {
    //     std.debug.print("{{\n\t", .{});
    //     for (s.items) |v| {
    //         // std.debug.print("{d}, ", .{v.id});
    //         self.print_coloring(v);
    //     }
    //     std.debug.print("\n}}\n", .{});
    // }

    // For every pair in subgraphs, check for all pair of vertices that make a square. If one of the vertices pair doesn't make a square -> there must be an edge between them
    // Initializing the vertices
    const len: usize = subgraphs.items.len;

    for (0..len) |_| {
        _ = try original.add_vertex(0); // the id is the index of the subgraphs
    }

    // The big loop
    for (0..(len - 1)) |i| {
        for ((i + 1)..len) |j| {
            const subgraph1 = subgraphs.items[i];
            const subgraph2 = subgraphs.items[j];

            var all_have_squares = true;

            for (subgraph1.items) |v1| {
                for (subgraph2.items) |v2| {
                    var it1 = self.neighbors(v1);
                    var it2 = self.neighbors(v2);

                    var has_square = false;
                    while (try it1.next()) |neighbor_v1| {
                        defer self.deinit_vertex(neighbor_v1);

                        it2.reset();
                        while (try it2.next()) |neighbor_v2| {
                            defer self.deinit_vertex(neighbor_v2);

                            if (neighbor_v1.id != vertex.id and neighbor_v2.id != vertex.id) {
                                if (neighbor_v1.id == neighbor_v2.id) {
                                    has_square = true;
                                    break;
                                }
                            }
                        }

                        if (has_square) {
                            break;
                        }
                    }

                    if (!has_square) {
                        all_have_squares = false;
                        break;
                    }
                }

                if (!all_have_squares) {
                    break;
                }
            }

            if (!all_have_squares) {
                // proceed to add the edges
                try original.add_edge_by_id(@intCast(i), @intCast(j));
            }
        }
    }

    for (subgraphs.items) |*s| {
        s.deinit(gpa);
    }

    return original;
}
