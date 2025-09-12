#include <algorithm>
#include <boost/graph/compressed_sparse_row_graph.hpp>
#include <iostream>

#include "eigen/Eigen/Core"
#include "originalToColoring.h"
#include "graphSketcher.h"

#include "eigen/Eigen/Dense"

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

	graph_traits<Graph>::edge_iterator ei, ei_end;


	int num_coloring_vertices = coloring_graph.m_vertices.size();

	Eigen::MatrixXd adjacency_matrix = Eigen::MatrixXd::Zero(num_coloring_vertices, num_coloring_vertices);

	for (tie(ei, ei_end) = edges(coloring_graph); ei != ei_end; ++ei) { // loop through each edge
		auto u = source(*ei, coloring_graph); // vertex label of "source"
		auto v = target(*ei, coloring_graph); // vertex label of "destination"

		adjacency_matrix(u, v) = 1;
		adjacency_matrix(v, u) = 1;
	}

	// std::cout << adjacency_matrix << std::endl;

	std::cout << adjacency_matrix.eigenvalues() << std::endl; // really small numbers might be actually 0

	boost::dynamic_properties dp;
	dp.property("color", get(vertex_color, coloring_graph));
	dp.property("node_id", get(boost::vertex_index, coloring_graph));

	print_graph_as_graphml(coloring_graph, "graph.graphml", dp);

}
