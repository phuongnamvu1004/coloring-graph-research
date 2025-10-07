const std = @import("std");

const Eigen = @import("eigen.zig");

const Self = @This();

const Vertex = struct {
    id: i32,
    label: i32,
    permutation: i32 = -1,
};
const Edge = struct {
    a: *Vertex,
    b: *Vertex,
};
const Color = i32;

allocator: std.mem.Allocator,
vertices: std.AutoHashMap(Vertex, void),
adjacency_list: std.ArrayList(Edge),
max_vertex_id: i32 = 0,
num_original_vertices: i32 = 0, // useful metadata for a couple functions

pub fn init(gpa: std.mem.Allocator) !Self {
    return .{
        .adjacency_list = .empty,
        .vertices = .init(gpa),
        .allocator = gpa,
    };
}

pub fn deinit(self: *Self) void {
    self.adjacency_list.deinit(self.allocator);
    self.vertices.deinit();
}

pub fn copy(self: Self, gpa: std.mem.Allocator) !Self {
    var new = try Self.init(gpa);

    new.allocator = gpa;
    new.num_original_vertices = self.num_original_vertices;

    new.vertices = .init(gpa);
    new.adjacency_list = try .initCapacity(gpa, 2);

    var it = self.vertices.iterator();
    while (it.next()) |v| {
        var vertex = try new.add_vertex(v.key_ptr.label);
        vertex.permutation = v.key_ptr.permutation;
        vertex.id = v.key_ptr.id; // !
    }

    for (self.adjacency_list.items) |e| {
        _ = try new.add_edge(new.get_vertex_by_id(e.a.id).?, new.get_vertex_by_id(e.b.id).?); // unwrapping is safe since I just added it
    }

    return new;
}

pub fn add_vertex(self: *Self, label: i32) !*Vertex {
    const new_vertex: Vertex = .{ .id = self.max_vertex_id, .label = label };
    try self.vertices.put(new_vertex, undefined);
    self.max_vertex_id += 1;
    return self.vertices.getKeyPtr(new_vertex).?; // will always be present
}

pub fn get_vertex_by_id(self: Self, id: i32) ?*Vertex {
    var it = self.vertices.iterator();
    while (it.next()) |v| {
        if (v.key_ptr.id == id)
            return v.key_ptr;
    }
    return null;
}

pub fn add_edge(self: *Self, a: *Vertex, b: *Vertex) !Edge {
    if (!self.adjacent(a, b)) {
        try self.adjacency_list.append(self.allocator, .{ .a = a, .b = b });
    }
    return .{ .a = a, .b = b };
}

pub fn adjacent(self: Self, a: *Vertex, b: *Vertex) bool {
    for (self.adjacency_list.items) |edge| {
        if (std.meta.eql(edge, .{ .a = a, .b = b }) or std.meta.eql(edge, .{ .a = b, .b = a }))
            return true;
    }
    return false;
}

pub fn neighbors(self: *Self, vertex: *Vertex) NeighborsIterator {
    return NeighborsIterator{
        .g = self,
        .vertex = vertex,
        .current_index = 0,
    };
}

pub const NeighborsIterator = struct {
    g: *Self, // graph
    vertex: *Vertex,
    current_index: usize,

    pub fn next(self: *NeighborsIterator) ?*Vertex {
        for (self.g.adjacency_list.items[self.current_index..]) |e| {
            self.current_index += 1;
            if (e.a == self.vertex)
                return e.b;
            if (e.b == self.vertex)
                return e.a;
        }
        return null; // at the end of the list
    }

    pub fn reset(self: *NeighborsIterator) void {
        self.current_index = 0;
    }
};

pub fn remove_edge(self: *Self, a: *Vertex, b: *Vertex) void {
    for (0.., self.adjacency_list.items) |i, e| {
        if ((e.a == a and e.b == b) or (e.a == b and e.b == a)) {
            _ = self.adjacency_list.swapRemove(i);
            return;
        }
    }
}

pub fn remove_vertex(self: *Self, vertex: *Vertex) void {
    if (self.num_neighbors(vertex) == 0)
        _ = self.vertices.removeByPtr(vertex);
}

pub fn num_vertices(self: Self) usize {
    return self.vertices.count();
}

pub fn num_neighbors(self: Self, vertex: *Vertex) i32 {
    var count: i32 = 0;
    for (self.adjacency_list.items) |e| {
        if (e.a.id == vertex.id or e.b.id == vertex.id)
            count += 1;
    }
    return count;
}

pub fn is_coloring_valid(self: Self, coloring: []const Color) bool {
    for (self.adjacency_list.items) |e| {
        if (coloring[@intCast(e.a.id)] == coloring[@intCast(e.b.id)])
            return false;
    }
    return true;
}

pub fn print_as_graphml(self: Self, filename: [:0]const u8, k: i32) !void {
    var file = try std.fs.cwd().createFile(filename, .{});
    _ = try file.write(
        \\<?xml version="1.0" encoding="UTF-8"?>
        \\<graphml xmlns="http://graphml.graphdrawing.org/xmlns"
        \\xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        \\xsi:schemaLocation="http://graphml.graphdrawing.org/xmlns/1.0/graphml.xsd">
        \\<key id="d0" for="node" attr.name="coloring" attr.type="string">
        \\<default>none</default>
        \\</key>
        \\<key id="d1" for="node" attr.name="permutation" attr.type="int">
        \\<default>-1</default>
        \\</key>
        \\<graph id="G" edgedefault="undirected">\n
    );
    var it = self.vertices.keyIterator();
    var buf: [100:0]u8 = undefined;
    var itoabuf: [100:0]u8 = undefined;
    while (it.next()) |v| {
        const coloring_str = itoa(v.*.label, &itoabuf, k, self.num_original_vertices);
        const v_string = try std.fmt.bufPrint(&buf, "<node id=\"{d}\"><data key=\"d0\">{s}</data><data key=\"d1\">{d}</data></node>\n", .{ v.id, coloring_str, v.permutation });
        _ = try file.write(v_string);
    }

    for (0.., self.adjacency_list.items) |i, e| {
        const e_string = try std.fmt.bufPrint(&buf, "<edge id=\"{d}\" source=\"{d}\" target=\"{d}\"/>\n", .{ i, e.a.id, e.b.id });
        _ = try file.write(e_string);
    }
    _ = try file.write("</graph>\n</graphml>");
    file.close();
}

pub fn get_coloring_graph(self: Self, k: i32, allocator: std.mem.Allocator) !Self {
    const num_of_vertices = self.num_vertices();
    const num_permutations = std.math.pow(i32, k, @intCast(num_of_vertices));

    const coloring: []i32 = try allocator.alloc(i32, num_of_vertices);
    defer allocator.free(coloring);

    var new_graph = try Self.init(allocator);

    for (0..@intCast(num_permutations)) |num| {
        for (0..@intCast(num_of_vertices)) |i| {
            const digit = @mod(@divFloor(@as(i32, @intCast(num)), std.math.pow(i32, k, @intCast(i))), k);
            coloring[i] = digit;
        }
        if (self.is_coloring_valid(coloring))
            _ = try new_graph.add_vertex(@intCast(num));
    }

    var it = new_graph.vertices.iterator();
    while (it.next()) |a| {
        var it2 = new_graph.vertices.iterator();
        while (it2.next()) |b| {
            const col1 = a.key_ptr.label;
            const col2 = b.key_ptr.label;

            var diff: i32 = 0;
            for (0..@intCast(num_of_vertices)) |i| {
                const digit1 = @mod(@divFloor(@as(i32, @intCast(col1)), std.math.pow(i32, k, @intCast(i))), k);
                const digit2 = @mod(@divFloor(@as(i32, @intCast(col2)), std.math.pow(i32, k, @intCast(i))), k);
                if (digit1 != digit2)
                    diff += 1;
            }

            if (diff == 1)
                _ = try new_graph.add_edge(a.key_ptr, b.key_ptr);
        }
    }

    new_graph.num_original_vertices = @intCast(self.num_vertices());

    return new_graph;
}

pub fn bell_from_coloring(self: Self, k: i32, allocator: std.mem.Allocator) !Self { // side effect: applies permutation info
    var bell_graph = try Self.init(allocator);
    bell_graph.num_original_vertices = self.num_original_vertices;

    var itoabuf: [100]u8 = undefined;
    var permutations = try std.ArrayList(i32).initCapacity(allocator, 2);
    defer permutations.deinit(allocator);

    var it = self.vertices.iterator();
    while (it.next()) |v| {
        const coloring_raw = v.key_ptr.label;
        const coloring = itoa(coloring_raw, &itoabuf, k, self.num_original_vertices);
        var lowest_permutation_str = try allocator.dupe(u8, coloring);
        defer allocator.free(lowest_permutation_str);

        var seen = try allocator.alloc(i32, @intCast(k));
        defer allocator.free(seen); // so many allocations :(

        for (seen) |*a| {
            a.* = -1;
        }

        var cur: i32 = 0;

        for (0.., coloring) |i, c| { // turn coloring into lowest permutation
            if (seen[c - '0'] == -1) { // unseen
                seen[c - '0'] = cur;
                lowest_permutation_str[i] = @intCast(cur + '0');
                cur += 1;
            } else { // seen, value stored in memo
                lowest_permutation_str[i] = @intCast(seen[@intCast(c - '0')] + '0'); // I love these parseint hacks
            }
        }

        const lowest_permutation = try std.fmt.parseInt(i32, lowest_permutation_str, @intCast(k));
        if (std.mem.indexOfScalar(i32, permutations.items, lowest_permutation) == null) { // not already found
            try permutations.append(allocator, lowest_permutation);
        }

        v.key_ptr.permutation = @intCast(std.mem.indexOfScalar(i32, permutations.items, lowest_permutation).?);
    }

    for (0.., permutations.items) |i, p| {
        var v = try bell_graph.add_vertex(@intCast(p));
        v.permutation = @intCast(i);
    }

    var bell_it1 = bell_graph.vertices.iterator();
    while (bell_it1.next()) |bell_a| {
        var bell_it2 = bell_graph.vertices.iterator();
        while (bell_it2.next()) |bell_b| {
            if (bell_a.key_ptr.permutation != bell_b.key_ptr.permutation) {
                for (self.adjacency_list.items) |e| { // look through adjacent nodes in coloring graph
                    if ((e.a.permutation == bell_a.key_ptr.permutation and bell_b.key_ptr.permutation == e.b.permutation) or (e.a.permutation == bell_b.key_ptr.permutation and bell_a.key_ptr.permutation == e.b.permutation)) { // the or is probably unnecessary as it will look through both orders
                        _ = try bell_graph.add_edge(bell_a.key_ptr, bell_b.key_ptr);
                        // if (e.a.permutation == 1 and e.b.permutation == 7 or e.a.permutation == 7 and e.b.permutation == 1)
                        //     std.debug.print("{d} {d}\n", .{ e.a.id, e.b.id });
                        break;
                    }
                }
            }
        }
    }

    return bell_graph;
}

pub fn debug_print(self: Self) void {
    std.debug.print("edges: {{\n", .{});
    for (self.adjacency_list.items) |e| {
        std.debug.print("\t{{{d}, {d}}}\n", .{ e.a.id, e.b.id });
    }
    std.debug.print("}}\n", .{});
}

pub fn laplacian_matrix(self: Self, gpa: std.mem.Allocator) !Eigen {
    var laplacian = try Eigen.init(self.num_vertices(), gpa);
    laplacian.zero();

    for (self.adjacency_list.items) |e| {
        laplacian.get(@intCast(e.a.id), @intCast(e.b.id)).* = -1;
        laplacian.get(@intCast(e.b.id), @intCast(e.a.id)).* = -1;
    }

    var it = self.vertices.iterator();
    while (it.next()) |v| {
        laplacian.get(@intCast(v.key_ptr.id), @intCast(v.key_ptr.id)).* = @floatFromInt(self.num_neighbors(v.key_ptr));
    }
    return laplacian;
}

fn itoa(value: i64, buf: []u8, base: i32, digits: i32) []u8 { // modified from https://ziggit.dev/t/how-do-i-write-this-itoa-better/7560/4
    var pos = buf.len;
    var v: i128 = value;
    const neg = v < 0;
    if (neg) v = -v;
    while (true) {
        const c: u8 = @intCast(@mod(v, base));
        v = @divTrunc(v, base);
        pos -= 1;
        buf[pos] = c + '0';
        if (v == 0) break;
    }
    if (neg) {
        pos -= 1;
        buf[pos] = '-';
    }

    while (pos > @as(i32, @intCast(buf.len)) - digits) {
        pos -= 1;
        buf[pos] = '0';
    }
    return buf[pos..];
}

pub fn chromatic_polynomial(self: Self, k: i32, gpa: std.mem.Allocator) !i32 {
    // base case: num edges = 0 -> return k ^ num vertices
    if (self.adjacency_list.items.len == 0) {
        return std.math.pow(i32, k, @intCast(self.num_vertices()));
    }

    // Chromatic Polynomial formula: P(G, k) = P(G - e, k) - P(G / e, k)
    // get a random edge in the graph

    var graph_del = try self.copy(gpa);
    defer graph_del.deinit();

    // Deletion
    const random_edge_del = graph_del.adjacency_list.items[0];
    graph_del.remove_edge(random_edge_del.a, random_edge_del.b);

    // Contraction
    var graph_contract = try graph_del.copy(gpa);
    defer graph_contract.deinit();

    const u = graph_contract.get_vertex_by_id(random_edge_del.a.id).?;
    const v = graph_contract.get_vertex_by_id(random_edge_del.b.id).?;
    try graph_contract.contract_vertices(u, v);

    return try graph_del.chromatic_polynomial(k, gpa) - try graph_contract.chromatic_polynomial(k, gpa);
}

pub fn contract_vertices(self: *Self, u: *Vertex, v: *Vertex) !void {
    self.remove_edge(u, v); // in case
    var it = self.neighbors(u);

    while (it.next()) |vertex| {
        _ = try self.add_edge(vertex, v); // already check if exists
    }

    // clear edges
    // remove all edges to u
    it.reset();
    while (it.next()) |vertex| {
        self.remove_edge(u, vertex);
    }

    // remove u as a vertex
    self.remove_vertex(u);
}
