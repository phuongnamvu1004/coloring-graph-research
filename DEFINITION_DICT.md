# Definitions

### Coloring graph
Given k colors to color graph G, examine all possible colorings of that graph using k colors.
A coloring graph of graph G, C(G), is contructed by:
- Vertices: Each possible coloring represent a vertex, with label being its coloring
- Edges: Between any vertices, if the color differences of their labels is only one color, make an edge

### Adjacency list (Rohit's definition)
```c++
std::map<int, std::map<int, int>> adj_list;
```
**Example:** 
`{ 2: {3: 4}}` 

This is saying group of vertices "2" and group of vertices "3" has 4 edges in between.

**Detailed Explanation:**
- **Outer key (int)**: Represents a coloring class number (from `coloring_class_number_from_lowest_permutation`)
- **Inner key (int)**: Represents another coloring class number 
- **Inner value (int)**: Count of edges between vertices in these two classes

**How it works:**
1. Each vertex in the coloring graph has a specific coloring (e.g., `[2, 0, 2, 1]`)
2. This coloring is converted to its **lowest permutation** (e.g., `[0, 1, 0, 2]`)
3. All colorings with the same lowest permutation belong to the same **group/class**
4. Each class gets a unique **coloring class number** (0, 1, 2, ...)
5. The adjacency list counts how many edges exist between different classes

**Example:**
- Vertices with colorings `[0, 1, 2]`, `[1, 2, 0]`, `[2, 0, 1]` all have lowest permutation `[0, 1, 2]`
- They form one group with class number (say) 5
- If this group has 4 edges to another group (class number 7), then `adj_list[5][7] = 4`

**Subdefinition**
- **Group of vertices**: All vertices whose colorings have the same lowest permutation (same equivalence class under color relabeling)

### Lowest Permutation
A canonical representation of a coloring where colors are relabeled to start from 0 in order of first appearance.
**Example:** Coloring `[2, 0, 2, 1]` becomes `[0, 1, 0, 2]`

### Valid Coloring
A coloring where no two adjacent vertices in the original graph have the same color. Checked by ensuring that when a vertex's color is changed, none of its neighbors share the same color.

### Special Vertex Classes (Type 1)
Colorings that use strictly fewer than `k` colors. These represent "incomplete" colorings in the k-coloring space and are determined by `is_special_class()`.

### Reconstructible Vertices (Type 2 Special)
Colorings that use exactly `k` colors but can still reconstruct the original graph structure. Determined by checking if adjacent vertices share common "free colors" (colors not used by them or their neighbors).

### Free Colors
For each vertex, the set of colors that are neither used by the vertex itself nor by any of its neighbors. Used to determine if the original graph structure can be reconstructed.

### Coloring Class Number
An integer identifier assigned to each unique lowest permutation of colorings. Used to group equivalent colorings together in `coloring_class_number_from_lowest_permutation`.

### Vertex Number from Coloring
A mapping (`vertex_number_from_coloring`) that assigns a unique vertex ID to each distinct coloring in the coloring graph.

### BFS Exploration
The algorithm uses breadth-first search to explore all reachable colorings by trying to change each vertex to each possible color, ensuring validity at each step.

### Permutation Symmetry
For each valid coloring transition, all k! permutations of colors are also added as edges, creating symmetry in the coloring graph. This ensures the graph represents all equivalent colorings under color relabeling.

### Chromatic Number
The minimum number of colors needed to properly color the original graph, computed by finding the coloring with the fewest distinct colors among all seen colorings.

### Sequential Vertex Coloring
Initial coloring strategy using Boost's `sequential_vertex_coloring()` to provide a starting valid coloring of the original graph.
