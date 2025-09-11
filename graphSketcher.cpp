#include "gtr.h"
#include "graphSketcher.h"

auto select_random(const std::set<int> &s, size_t n) {
	auto it = std::begin(s);
	// 'advance' the iterator n times
	std::advance(it,n);
	return it;
}

// generate a random tree of size n and return max(du + dv)
std::pair<Graph, int> get_random_tree(int n) {
	srand(time(NULL));
	int maximal_degree = 0;
	std::vector<int> degree(n);
	std::set<int> connected = {0};
	std::set<int> isolated = {};
	std::vector<std::vector<int> > tree(n);
	for (int i = 1; i < n; i++) {
		isolated.insert(i);
	}


	std::cout << "Tree consists of the following edges:" << std::endl;
	for (int i = 0; i < n - 1; i++) {
		// pick an isolated vertex at random
		auto r = rand() % isolated.size();
		auto u_itr = select_random(isolated, r);
		auto u = *u_itr;
		// make an edge from a random connected vertex to this vertex
		r = rand() % connected.size();
		auto v_itr = select_random(connected, r);
		auto v = *v_itr;
		tree[u].push_back(v);
		tree[v].push_back(u);
		degree[u]++;
		degree[v]++;
		std::cout << u << ", " << v << std::endl;
		isolated.erase(u_itr);
		connected.insert(u);
	}

	std::cout << std::endl;
	Edge tree_edges[2 * n - 2];
	int next = 0;
	for (int u = 0; u < n; u++) {
		for (int v : tree[u]) {
			maximal_degree = std::max(maximal_degree, degree[u] + degree[v]);
			tree_edges[next] = Edge(u, v);
			next++;
		}
	}
	
	std::cout << std::endl;
	Graph final_tree(tree_edges, tree_edges + sizeof(tree_edges)/sizeof(Edge), n);
	return {final_tree, maximal_degree};
}

Graph create_graph() {
	// Edge special_graph_edges[] = {
	//	 // k_4 edges
	//	 Edge(0, 1),
	//	 Edge(1, 2),
	//	 Edge(2, 0),
	//	 Edge(3, 1),
	//	 Edge(3, 2),
	//	 Edge(3, 0),
	//	 // k_3 edges
	//	 Edge(0, 4),
	//	 Edge(0, 5),
	//	 Edge(4, 5),
	//	 // k_2 edges
	//	 Edge(0, 6),
	//	 // special vertex 0: draw edge to every other vertex
	// };

	// six cycle:
	// Edge special_graph_edges[] = {
	//		 Edge(0, 1),
	//		 Edge(1, 2),
	//		 Edge(2, 3),
	//		 Edge(3, 4),
	//		 Edge(4, 5),
	//		 Edge(5, 0),
	// };

	// three cycle with extra edge:
	// Edge special_graph_edges[] = {
	//		 Edge(0, 1),
	//		 Edge(1, 2),
	//		 Edge(2, 0),
	//		 Edge(3, 0),
	// };

	// seven cycle with extra edge:
	// Edge special_graph_edges[] = {
	//	 Edge(0, 1),
	//	 Edge(1, 2),
	//	 Edge(2, 3),
	//	 Edge(3, 4),
	//	 Edge(4, 5),
	//	 Edge(5, 6),
	//	 Edge(6, 0),
	//	 Edge(0, 7),
	// };
	

	 // nine cycle with extra edge:
	// Edge special_graph_edges[] = {
	//	 Edge(0, 1),
	//	 Edge(1, 2),
	//	 Edge(2, 3),
	//	 Edge(3, 4),
	//	 Edge(4, 5),
	//	 Edge(5, 6),
	//	 Edge(6, 7),
	//	 Edge(7, 8),
	//	 Edge(8, 0),
	//	 Edge(0, 9),
	// };

	// six cycle
	// Edge special_graph_edges[] = {
	//	 Edge(0, 1),
	//	 Edge(1, 2),
	//	 Edge(2, 3),
	//	 Edge(3, 4),
	//	 Edge(4, 5),
	//	 Edge(5, 0),
	// };

	// Edge special_graph_edges[] = {
		// Edge(0, 1),
		// Edge(1, 2),
		// Edge(2, 3),
		// Edge(3, 4),
		// Edge(4, 5),
		// Edge(5, 0),
	//	 Edge(0,1),
	//	 Edge(0,2),
	//	 Edge(0,3),
	//	 Edge(0,4),
	//	 Edge(0,5),

	//	 Edge(1,6),
	//	 Edge(1,7),

	//	 Edge(2,8),
	//	 Edge(3,9),
	//	 Edge(3,10),

	//	 Edge(4,5),
	//	 Edge(4,7),
	//	 Edge(4,9),

	//	 Edge(5,6),
	//	 Edge(5,8),
	//	 Edge(5,10),
	// };

	// Edge special_graph_edges[] = {
	//	 //First square
	//	 Edge(1,2),
	//	 Edge(1,3),
	//	 Edge(2,4),
	//	 Edge(3,4),
	//	 //Second square
	//	 Edge(5,6),
	//	 Edge(5,7),
	//	 Edge(6,8),
	//	 Edge(7,8),
	//	 //Square 3
	//	 Edge(9,10),
	//	 Edge(9,11),
	//	 Edge(10,0),
	//	 Edge(11,0),
	//	 //Connecting the squares
	//	 Edge(2,5),
	//	 Edge(3,9),
	//	 Edge(8,0)
	// };

	// Edge special_graph_edges[] = {
	//	 Edge(0, 1),
	// };

	// line graph
	// Edge special_graph_edges[] = {
	//	 Edge(0, 1),
	//	 Edge(1, 2),
	//	 Edge(2, 3),
	// };


// seven cycle:
	// Edge special_graph_edges[] = {
	//	 Edge(0, 1),
	//	 Edge(1, 2),
	//	 Edge(2, 3),
	//	 Edge(3, 4),
	//	 Edge(4, 5),
	//	 Edge(5, 6),
	//	 Edge(6, 0),
	// };

	// five cycle:
	// Edge special_graph_edges[] = {
	//	 Edge(0, 1),
	//	 Edge(1, 2),
	//	 Edge(2, 3),
	//	 Edge(3, 4),
	//	 Edge(4, 0),
	// };



	// line graph 6 vertices
	// Edge special_graph_edges[] = {
	//	 Edge(0, 1),
	//	 Edge(1, 2),
	//	 Edge(2, 3),
	//	 Edge(3, 4),
	//	 Edge(4, 5),
	// };

	// K_2_3
	// Edge special_graph_edges[] = {
	//	 Edge(0, 2),
	//	 Edge(0, 3),
	//	 Edge(0, 4),
	//	 Edge(1, 2),
	//	 Edge(1, 3),
	//	 Edge(1, 4),
	// };

	// 3 isolated vertices
	// Edge special_graph_edges[] = {
	// };

	// line graph with 4 vertices
	// Edge special_graph_edges[] = {
	//	 Edge(0, 1),
	//	 Edge(1, 2),
	//	 Edge(2, 3),
	// };

	// S6
	// Edge special_graph_edges[] = {
	//	 Edge(0, 1),
	//	 Edge(0, 2),
	//	 Edge(0, 3),
	//	 Edge(0, 4),
	//	 Edge(0, 5),
	//	 Edge(0, 6),
	// };

	// S7
	// Edge special_graph_edges[] = {
	//	 Edge(0, 1),
	//	 Edge(0, 2),
	//	 Edge(0, 3),
	//	 Edge(0, 4),
	//	 Edge(0, 5),
	//	 Edge(0, 6),
	//	 Edge(0, 7),
	// };

	// S7
	// Edge special_graph_edges[] = {
	//	 Edge(0, 1),
	//	 Edge(0, 2),
	//	 Edge(0, 3),
	//	 Edge(0, 4),
	//	 Edge(0, 5),
	//	 Edge(0, 6),
	//	 Edge(0, 7),
	// };

	// 3 cycle with line graph IMPORTANT EXAMPLE
	// Edge special_graph_edges[] = {
	//	 Edge(0, 1),
	//	 Edge(1, 2),
	//	 Edge(2, 3),
	//	 Edge(3, 4),
	//	 Edge(4, 5),
	//	 Edge(3, 5),
	// };

	// 5 cycle with extra edge
	// Edge special_graph_edges[] = {
	//	 Edge(0, 1),
	//	 Edge(1, 2),
	//	 Edge(2, 3),
	//	 Edge(3, 4),
	//	 Edge(4, 0),
	//	 Edge(5, 0),
	// };


	// K(2,3)->special
	// Edge special_graph_edges[] = {
	//	 Edge(0,2),
	//	 Edge(0,3),
	//	 Edge(0,4),
	//	 Edge(1,2),
	//	 Edge(1,3),
	// }; 

	// incomplete k4
	// Edge special_graph_edges[] = {
	//	 Edge(0,1),
	//	 Edge(1,2),
	//	 Edge(2,3),
	//	 Edge(0,3),
	//	 Edge(1,3),
	// };

	// Edge complete tripartite graph
	// Edge special_graph_edges[] = {
	// 	Edge(0, 2),
	// 	Edge(0, 3),
	// 	Edge(0, 4),
	//
	// 	Edge(0, 5),
	// 	Edge(0, 6),
	// 	Edge(0, 7),
	// 	Edge(0, 8),
	//
	//
	// 	Edge(1, 2),
	// 	Edge(1, 3),
	// 	Edge(1, 4),
	//
	// 	Edge(1, 5),
	// 	Edge(1, 6),
	// 	Edge(1, 7),
	// 	Edge(1, 8),
	//
	//
	// 	Edge(5, 2),
	// 	Edge(5, 3),
	// 	Edge(5, 4),
	//
	// 	Edge(6, 2),
	// 	Edge(6, 3),
	// 	Edge(6, 4),
	//
	// 	Edge(7, 2),
	// 	Edge(7, 3),
	// 	Edge(7, 4),
	//
	// 	Edge(8, 2),
	// 	Edge(8, 3),
	// 	Edge(8, 4),
	// };

	Edge special_graph_edges[] = {
		Edge(0, 1),
		Edge(1, 2),
	};

	// Edge special_graph_edges[] = {
	// 	Edge(0, 1),
	// 	Edge(1, 2),
	// 	Edge(2, 3),
	// 	Edge(3, 4),
	// 	Edge(4, 5),
	// 	Edge(5, 0),
	// };
	

	int number_of_vertices = 3;
	Graph special_graph(special_graph_edges, special_graph_edges + sizeof(special_graph_edges)/sizeof(Edge), number_of_vertices);
	return special_graph;
}

void print_graph_as_dot(const Graph& graph, const std::string& graph_name) {
	std::ofstream output_graph_stream;
	output_graph_stream.open(graph_name);
	write_graphviz(output_graph_stream, graph);
	output_graph_stream.close();
}

void print_graph_as_dot(const Graph& graph, const std::string& graph_name, const boost::dynamic_properties& dp) {
	std::ofstream output_graph_stream;
	output_graph_stream.open(graph_name);
	write_graphviz_dp(output_graph_stream, graph, dp);
	output_graph_stream.close();
}

void print_graph_as_graphml(const Graph& graph, const std::string& graph_name, const boost::dynamic_properties& dp) {
	std::ofstream output_graph_stream;
	output_graph_stream.open(graph_name);
	write_graphml(output_graph_stream, graph, dp);
}
