
#include "originalToColoring.h"
#include "graphSketcher.h"

int main() {
	Edge special_graph_edges[] = {
		Edge(0, 1),
		Edge(1, 2),
	};

	int number_of_vertices = 3;
	Graph original_graph(special_graph_edges, special_graph_edges + sizeof(special_graph_edges)/sizeof(Edge), number_of_vertices);

	int k = 3;

	std::map<int, std::map<int, int>> adj_list;
	std::set<int> special_vertex_classes;
	std::map<int, int> class_to_num_vertices;
	std::vector<int> special_vertices;
	std::vector<int> reconstructible_vertices;
	std::vector<int> n_complete_non_reconstructible_non_special_vertices;
	Graph coloring_graph = coloringFromOriginal(original_graph, k, adj_list, special_vertex_classes, class_to_num_vertices, special_vertices, reconstructible_vertices);

	boost::dynamic_properties dp;
	dp.property("color", get(vertex_color, coloring_graph));
	dp.property("node_id", get(boost::vertex_index, coloring_graph));

	print_graph_as_graphml(coloring_graph, "graph.graphml", dp);

}
