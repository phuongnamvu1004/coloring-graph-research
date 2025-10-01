#include <boost/graph/adjacency_list.hpp>
#include <boost/graph/compressed_sparse_row_graph.hpp>
#include <iostream>
#include <iterator>

#include "eigen/Eigen/Core"
#include "originalToColoring.h"
#include "graphSketcher.h"
#include "chromaticPolynomial.h"

#include "eigen/Eigen/Dense"

int main() {
	// Edge special_graph_edges[] = {
	// 	Edge(0, 1),
	// 	Edge(1, 2),
	// };
	//
	// int number_of_vertices = 3;
	// Graph original_graph(special_graph_edges, special_graph_edges + sizeof(special_graph_edges)/sizeof(Edge), number_of_vertices);
	Graph original_graph;

	auto v1 = boost::add_vertex(original_graph);
	auto v2 = boost::add_vertex(original_graph);
	auto v3 = boost::add_vertex(original_graph);

	boost::add_edge(v1, v2, original_graph);
	boost::add_edge(v2, v3, original_graph);

	int k = 3;
	// int k = 4; // uncomment to check for chromatic polynomial, should be 36

	std::map<int, std::map<int, int>> adj_list;
	std::set<int> special_vertex_classes;
	std::map<int, int> class_to_num_vertices;
	std::vector<int> special_vertices;
	std::vector<int> reconstructible_vertices;
	std::vector<int> n_complete_non_reconstructible_non_special_vertices;
	Graph coloring_graph = coloringFromOriginal(original_graph, k, adj_list, special_vertex_classes, class_to_num_vertices, special_vertices, reconstructible_vertices);

	int num_coloring_vertices = coloring_graph.m_vertices.size();

	Eigen::MatrixXd adjacency_matrix = Eigen::MatrixXd::Zero(num_coloring_vertices, num_coloring_vertices);
	Eigen::MatrixXd laplacian_matrix = Eigen::MatrixXd::Zero(num_coloring_vertices, num_coloring_vertices);

	graph_traits<Graph>::edge_iterator ei, ei_end;
	for (tie(ei, ei_end) = edges(coloring_graph); ei != ei_end; ++ei) { // loop through each edge
		auto u = source(*ei, coloring_graph); // vertex label of "source"
		auto v = target(*ei, coloring_graph); // vertex label of "destination"
		
		auto u_edges = boost::out_edges(u, coloring_graph);
		auto v_edges = boost::out_edges(v, coloring_graph);

		auto u_degree = std::distance(u_edges.first, u_edges.second);
		auto v_degree = std::distance(v_edges.first, v_edges.second);
		
		adjacency_matrix(u, v) = 1;
		adjacency_matrix(v, u) = 1;

		laplacian_matrix(u, v) = -1;
		laplacian_matrix(v, u) = -1;

		laplacian_matrix(u, u) = u_degree;
		laplacian_matrix(v, v) = v_degree;
	}

	std::cout << laplacian_matrix << std::endl;

	std::cout << adjacency_matrix.eigenvalues() << std::endl; // really small numbers might be actually 0

	std::cout << "chromatic polynomial P(G, " << k << ") = " << compute_chromatic_polynomial(original_graph, k) << std::endl;

	boost::dynamic_properties dp;
	dp.property("color", get(vertex_color, coloring_graph));
	dp.property("node_id", get(boost::vertex_index, coloring_graph));

	print_graph_as_graphml(coloring_graph, "graph.graphml", dp);

}
