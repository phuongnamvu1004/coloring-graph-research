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

	Edge special_graph_edges[] = {
		Edge(0, 1),
		Edge(1, 2),
	};

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
