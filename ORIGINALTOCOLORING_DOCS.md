# Original to Coloring Graph Documentation

## Key Concepts

### Coloring Graph Construction
Given an original graph G and k colors, the coloring graph C(G) is constructed where:
- **Vertices**: Each valid k-coloring of G
- **Edges**: Connect colorings that differ by exactly one vertex's color

### Coloring Classes
Colorings are grouped into equivalence classes based on their lowest permutation representation, constructed by `lowest_permutation()` method. All colorings with the same lowest permutation are considered equivalent.

## Core Data Structures

### Maps and variables
- `coloring_from_vertex_number`: Maps vertex IDs to their coloring vectors
- `vertex_number_from_coloring`: Maps coloring vectors to vertex IDs  
- `coloring_class_number_from_lowest_permutation`: Maps lowest permutations to class numbers
- `seen_colorings`: Set of all discovered lowest permutations
- `adj_list`: Compressed adjacency representation counting edges between classes

### Special Vertex Types
- **Type 1 Special**: Colorings using fewer than k colors
- **Type 2 Special (Reconstructible)**: Colorings using exactly k colors but can reconstruct original graph

## Algorithm Flow

1. **Initialization**: Start with sequential vertex coloring of original graph
2. **BFS Exploration**: Explore all reachable colorings by changing one vertex at a time
3. **Permutation Symmetry**: Add all k! permutations of each valid transition
4. **Classification**: Identify special and reconstructible vertices
5. **Representation**: Build adjacency list
