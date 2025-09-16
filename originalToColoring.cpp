#include "originalToColoring.h"
#include <math.h>
#include <queue>

// ASSUMES K > KAI

int next_vertex() {
	static int next = 0;
	return next++;
}

void print_coloring(const std::vector<int>& coloring) {
	for (int i = 0; i < coloring.size(); i++) {
		std::cout << coloring[i] << "";
	}
}

void print_coloring_to_vertex_map(const std::map<std::vector<int>, int>& coloring_to_vertex_map) {
	for (const auto [coloring, vertex_number] : coloring_to_vertex_map) {
		print_coloring(coloring);
		std::cout << "above was the coloring for vertex " << vertex_number << std::endl;
	}
}

/**
 * @brief Validates if a coloring is proper after changing one vertex's color
 * @param original The original graph structure
 * @param next_coloring The proposed new coloring
 * @param changed_vertex The vertex whose color was changed
 * @return true if coloring is valid (no adjacent vertices share same color)
 * 
 * Checks only the neighbors of the changed vertex for efficiency, assuming
 * the rest of the coloring was already valid.
 */
bool is_valid_coloring(const Graph& original, const std::vector<int>& next_coloring, int changed_vertex) {
	// check all adjacent vertices of changed_vertex
	const auto& neighbors_of_changed_vertex = make_iterator_range(out_edges(changed_vertex, original));
	for (const auto& e : neighbors_of_changed_vertex) {
		const auto& neighbor_of_changed_vertex = target(e, original);
		if (next_coloring[neighbor_of_changed_vertex] == next_coloring[changed_vertex]) return false;
	}

	return true;
}


int find_num_colors(const std::vector<int>& coloring) {
	std::set<int> used_colors;
	for (int i : coloring) {
		used_colors.insert(i);
	} 

	return used_colors.size();
}

bool is_special_class(const std::vector<int>& coloring, int k) {
	// type 1 special: return if the number of colors is strictly less than k, assuming k > chromatic number
	return find_num_colors(coloring) < k;
}


/**
 * @brief Converts a coloring to its canonical lowest permutation form
 * @param coloring Input coloring vector (passed by value for local modification)
 * @return Canonical form where colors are relabeled 0,1,2,... in order of first appearance
 * 
 * This creates equivalence classes of colorings. For example:
 * - [5, 2, 5, 7, 2] becomes [0, 1, 0, 2, 1]
 * - [3, 1, 3, 9, 1] becomes [0, 1, 0, 2, 1] (same as above)
 * 
 * Algorithm:
 * 1. First pass: Build mapping from original colors to canonical labels (0,1,2,...)
 * 2. Second pass: Apply mapping to create result vector
 */
std::vector<int> lowest_permutation(std::vector<int> coloring) {
	std::map<int, int> colorsToLowestColor;
	int next_color = 0;
	for (int color : coloring) {
		if (!colorsToLowestColor.count(color)) {
			colorsToLowestColor[color] = next_color;
			next_color++;
		}
	}

	std::vector<int> result;
	for (int color : coloring) {
		result.push_back(colorsToLowestColor[color]);
	}

	return result;
}

/**
 * @brief Determines if original graph structure can be reconstructed from a coloring
 * @param coloring The k-coloring to test (uses exactly k colors)
 * @param original The original graph structure
 * @param k Total number of available colors
 * @return true if original graph edges can be inferred from the coloring
 * 
 * Type 2 special (reconstructible) vertices are colorings where:
 * 1. Exactly k colors are used
 * 2. For every edge (u,v) in original graph, vertices u and v share at least one "free color"
 * 
 * Free colors for a vertex are colors not used by the vertex itself or any of its neighbors.
 * If adjacent vertices share free colors, we can deduce they were originally connected.
 */
bool can_reconstruct_original(std::vector<int>& coloring, const Graph& original, int k) {
	graph_traits<Graph>::edge_iterator ei, ei_end;
	std::set<int> all_colors;
	for (int i = 0; i < k; i++) all_colors.insert(i);
	std::vector<std::set<int> > free_colors_for_vertex(num_vertices(original), all_colors);
	for (tie(ei, ei_end) = edges(original); ei != ei_end; ++ei) {
		auto u = source(*ei, original);
		auto v = target(*ei, original);
		// erase color[u], color[v] from the set of free colors for u
		free_colors_for_vertex[u].erase(coloring[u]);
		free_colors_for_vertex[u].erase(coloring[v]);
		// erase color[u], color[v] from the set of free colors for v
		free_colors_for_vertex[v].erase(coloring[u]);
		free_colors_for_vertex[v].erase(coloring[v]);
	}

	for (tie(ei, ei_end) = edges(original); ei != ei_end; ++ei) {
		auto u = source(*ei, original);
		auto v = target(*ei, original);
		auto& set_of_free_colors_for_u = free_colors_for_vertex[u];
		auto& set_of_free_colors_for_v = free_colors_for_vertex[v];
		bool share_common_free_color = false;
		for (int i : set_of_free_colors_for_u) {
			if (set_of_free_colors_for_v.count(i)) share_common_free_color = true;
		}

		if (!share_common_free_color) {
			return false;
		}

	}
	return true;
}

/**
 * @brief Populates the mapping from coloring class numbers to vertex counts
 * @param class_to_num_vertices Output map from class number to count of vertices in that class
 * @param total_vertices Total number of vertices in the coloring graph
 * @param coloring_from_vertex_number Map from vertex numbers to their colorings
 * @param coloring_class_number_from_lowest_permutation Map from lowest permutations to class numbers
 * 
 * Counts how many vertices belong to each equivalence class (same lowest permutation).
 */
void populate_class_to_num_vertices(std::map<int, int>& class_to_num_vertices, int total_vertices, std::map<int, std::vector<int> >& coloring_from_vertex_number, std::map<std::vector<int>, int>& coloring_class_number_from_lowest_permutation) {
	for (const auto& coloring : coloring_from_vertex_number) {
		class_to_num_vertices[coloring_class_number_from_lowest_permutation[lowest_permutation(coloring.second)]]++;
	}
}

/**
 * @brief Builds the compressed adjacency list representation
 * @param adj_list Output map: class_number -> {neighbor_class_number -> edge_count}
 * @param seen_colorings Set of all discovered lowest permutation colorings
 * @param vertex_number_from_coloring Map from colorings to vertex numbers
 * @param coloring_from_vertex_number Map from vertex numbers to colorings
 * @param coloring_graph The constructed coloring graph
 * @param coloring_class_number_from_lowest_permutation Map from lowest permutations to class numbers
 * 
 * Creates a compressed representation where instead of storing individual vertex edges,
 * we count edges between equivalence classes of colorings.
 */
void populate_adj_list(std::map<int, std::map<int, int> >& adj_list, std::set<std::vector<int> >& seen_colorings, std::map<std::vector<int>, int >& vertex_number_from_coloring, std::map<int, std::vector<int> >& coloring_from_vertex_number, Graph& coloring_graph, std::map<std::vector<int>, int>& coloring_class_number_from_lowest_permutation) {
	// for every seen coloring, make entry in adj list
	for (const auto& seen_coloring : seen_colorings) {
		int u = vertex_number_from_coloring[seen_coloring];
		int c = coloring_class_number_from_lowest_permutation[seen_coloring];
		// for every neighbor of u, update adj list
		for (const auto& e : make_iterator_range(out_edges(u, coloring_graph))) {
				const auto& neighbor = target(e, coloring_graph);
				if (edge(u, neighbor, coloring_graph).second) {
						int v = coloring_class_number_from_lowest_permutation[lowest_permutation(coloring_from_vertex_number[neighbor])];
						adj_list[c][v]++;
				}
		}
	}
}

/**
 * @brief Main function to construct coloring graph from original graph
 * @param original The input graph to transform
 * @param k Number of colors available for coloring
 * @param adj_list Output: compressed adjacency list (class -> {class -> edge_count})
 * @param special_vertex_classes Output: set of class numbers for Type 1 special vertices
 * @param class_to_num_vertices Output: map from class number to vertex count in that class
 * @param special_vertices Output: vector of Type 1 special vertex IDs
 * @param reconstructible_vertices Output: vector of Type 2 special (reconstructible) vertex IDs
 * @return The constructed coloring graph
 * 
 * Algorithm Overview:
 * 1. Start with sequential vertex coloring of original graph
 * 2. Use BFS to explore all reachable valid colorings
 * 3. For each valid transition, add all k! color permutations for symmetry
 * 4. Classify vertices as special (Type 1) or reconstructible (Type 2)
 * 5. Build compressed adjacency representation
 * 
 */
Graph coloringFromOriginal(const Graph& original, int k, std::map<int, std::map<int, int> >& adj_list, std::set<int>& special_vertex_classes, std::map<int, int>& class_to_num_vertices, std::vector<int>& special_vertices, std::vector<int>& reconstructible_vertices) { 
	std::map<int, std::vector<int> > coloring_from_vertex_number;
	std::map<std::vector<int>, int> vertex_number_from_coloring;
	std::map<std::vector<int>, int> coloring_class_number_from_lowest_permutation;
	Graph coloring_graph;
	std::vector<int> color_map(num_vertices(original));
	boost::iterator_property_map<std::vector<int>::iterator, boost::property_map<Graph, boost::vertex_index_t>::const_type> color_property_map(color_map.begin(), get(boost::vertex_index, original));

	// Perform vertex coloring, color_map stores the colorings
	boost::sequential_vertex_coloring(original, color_property_map);
	// Get lowest coloring
	const auto lowest_permutation_of_initial_coloring = lowest_permutation(color_map);

	// Set the 'class number' for the coloring to 0
	coloring_class_number_from_lowest_permutation[lowest_permutation_of_initial_coloring] = 0;

	// Set the current class number to 1
	int current_class_number = 1;

	std::vector<int> current_permutation(k);
	std::vector<std::vector<int> > all_permutations;
	for (int i = 0; i < current_permutation.size(); i++) 
		current_permutation[i] = i;
	do {
		all_permutations.push_back(current_permutation);
	} while (std::next_permutation(current_permutation.begin(), current_permutation.end()));

	std::queue<std::vector<int> > bfs_queue;
	bfs_queue.push(lowest_permutation_of_initial_coloring);
	std::set<std::vector<int> > seen_colorings;
	seen_colorings.insert(lowest_permutation_of_initial_coloring);

	int n = num_vertices(original);
	while (!bfs_queue.empty()) {
		std::vector<int> alpha = bfs_queue.front();
		bfs_queue.pop();
		// create vertex for alpha immediately
		if (!vertex_number_from_coloring.count(alpha)) {
			int vertex_for_alpha = next_vertex();
			add_vertex(coloring_graph);
			if (!coloring_from_vertex_number.count(vertex_for_alpha)) coloring_from_vertex_number[vertex_for_alpha] = alpha;
			vertex_number_from_coloring[alpha] = vertex_for_alpha;
		}

		for (int nextColor = 0; nextColor < k; nextColor++) {
			for (int vertex = 0; vertex < n; vertex++) {
				int previousColor = alpha[vertex];
				if (nextColor == previousColor) continue;
				// color alpha to get an adjacent vertex beta
				std::vector<int> beta = alpha;
				beta[vertex] = nextColor;
				if (!is_valid_coloring(original, beta, vertex)) {
					continue;
				}

				if (!vertex_number_from_coloring.count(beta)) {
					int vertex_for_beta = next_vertex();
					add_vertex(coloring_graph);
					coloring_from_vertex_number[vertex_for_beta] = beta;
					vertex_number_from_coloring[beta] = vertex_for_beta;
				}

				if (!seen_colorings.count(lowest_permutation(beta))) {
					seen_colorings.insert(lowest_permutation(beta));
					bfs_queue.push(lowest_permutation(beta));
					coloring_class_number_from_lowest_permutation[lowest_permutation(beta)] = current_class_number;
					current_class_number++;
				}

				for (const auto& permutation : all_permutations) {
					// look at all permutations of beta
					std::vector<int> sigma_i_alpha = alpha;
					std::vector<int> sigma_i_beta = beta;
					for (int i = 0; i < n; i++) {
						int current_color_in_alpha = alpha[i];
						sigma_i_alpha[i] = permutation[current_color_in_alpha];

						int current_color_in_beta = beta[i];
						sigma_i_beta[i] = permutation[current_color_in_beta];
						// need to make an edge between sigma of beta and sigma of alpha
					}

					//sigma_i(beta),sigma_i(alpha)
					if (!vertex_number_from_coloring.count(sigma_i_alpha)) {
						add_vertex(coloring_graph);
						int sigma_i_alpha_vertex_number = next_vertex();
						vertex_number_from_coloring[sigma_i_alpha] = sigma_i_alpha_vertex_number;
						coloring_from_vertex_number[sigma_i_alpha_vertex_number] = sigma_i_alpha;
					}

					if (!vertex_number_from_coloring.count(sigma_i_beta)) {
						add_vertex(coloring_graph);
						int sigma_i_beta_vertex_number = next_vertex();
						vertex_number_from_coloring[sigma_i_beta] = sigma_i_beta_vertex_number;
						coloring_from_vertex_number[sigma_i_beta_vertex_number] = sigma_i_beta;
					}

					// both sigma_i(alpha), sigma_i(beta) exist in the graph
					int u = vertex_number_from_coloring[sigma_i_alpha];
					int v = vertex_number_from_coloring[sigma_i_beta];
					if (!edge(u, v, coloring_graph).second)
						add_edge(u, v, coloring_graph);
				}
			}
		}
	}

	int t = boost::num_vertices(coloring_graph);
	for (int i = 0; i < t; i++) {
		// assertion for isolated vertices
		assert(std::distance(boost::adjacent_vertices(i, coloring_graph).first, boost::adjacent_vertices(i, coloring_graph).second) != 0);
	}

	// get every vertex from every 'seen permutation'
	for (const auto& coloring_class : seen_colorings) {
		int u = coloring_class_number_from_lowest_permutation[lowest_permutation(coloring_class)];
		for (const auto& e : make_iterator_range(out_edges(u, coloring_graph))) {
				const auto& neighbor = target(e, coloring_graph);
				if (edge(u, neighbor, coloring_graph).second) {
						int v = coloring_class_number_from_lowest_permutation[lowest_permutation(coloring_from_vertex_number[neighbor])];
				}
		}
	}

	int chromatic_number = INT_MAX;
	// get chromatic number
	for (auto& seen_coloring: seen_colorings) {
		int number_of_colors = find_num_colors(seen_coloring);
		chromatic_number = std::min(chromatic_number, number_of_colors);
	}


	// get special vertices
	for (int vertex = 0; vertex < num_vertices(coloring_graph); vertex++) {
		if (is_special_class(coloring_from_vertex_number[vertex], k)) {
			special_vertices.push_back(vertex);
		} else {
			// check for type 2 special vertices, num_colors = k here
			if (can_reconstruct_original(coloring_from_vertex_number[vertex], original, k)) {
				reconstructible_vertices.push_back(vertex);
			}
		}
	}

	// get all special vertex classes
	for (auto& seen_coloring: seen_colorings) {
		if (is_special_class(seen_coloring, k)) {
			special_vertex_classes.insert(coloring_class_number_from_lowest_permutation[seen_coloring]);
		}
	}

	populate_adj_list(adj_list, seen_colorings, vertex_number_from_coloring, coloring_from_vertex_number, coloring_graph, coloring_class_number_from_lowest_permutation);
	populate_class_to_num_vertices(class_to_num_vertices, num_vertices(coloring_graph), coloring_from_vertex_number, coloring_class_number_from_lowest_permutation);
	return coloring_graph;
}
