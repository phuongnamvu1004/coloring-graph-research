#include "chromaticPolynomial.h"

#include "eigen/Eigen/Core"
#include <boost/graph/graph_traits.hpp>
#include <boost/graph/adjacency_list.hpp>

/*
Contract vertices u and v in graph g

Params:
  - Graph &g to be modified
  - u: "survivor" vertex
  - v: "sacrificed" vertex, will be merged into u and then removed

Algorithm:
  - Collect neighbors of v in a vector `neighbors`
  - Add edges (u, w) for each neighbor w of v, only add if the edge does not exist
  - Remove v and incident edges
*/
static void contract_vertices(Graph &g, graph_traits<Graph>::vertex_descriptor u, graph_traits<Graph>::vertex_descriptor v)
{
  // Collect neighbors of v
  std::vector<graph_traits<Graph>::vertex_descriptor> neighbors;
  graph_traits<Graph>::out_edge_iterator ei, ei_end;
  for (tie(ei, ei_end) = out_edges(v, g); ei != ei_end; ++ei)
  {
    auto w = target(*ei, g);
    if (w != v) neighbors.push_back(w);
  }

  // Add edges (u, w) for each neighbor of v, check if the edge already exists
  for (auto w : neighbors)
  {
    if (w != u && !edge(u, w, g).second) // check for self-loops and avoid parallel edges
    { 
      add_edge(u, w, g);
    }
  }

  clear_vertex(v, g);  // Remove incident edges to v
  remove_vertex(v, g); // Delete v from the graph
}

// Chromatic Polynomial formula: P(G, k) = P(G - e, k) - P(G / e, k)
int compute_chromatic_polynomial(const Graph &original, int k)
{
  // Base case: Graph with no edges, return k^n where n = |V|
  if (num_edges(original) == 0)
  {
    const int n = static_cast<int>(num_vertices(original));
    return pow(k, n);
  }

  // Pick an arbitrary edge e = (u, v)
  auto ei_pair = edges(original);
  auto e = *ei_pair.first;
  auto u = source(e, original);
  auto v = target(e, original);

  // Deletion
  Graph g_minus = original;
  remove_edge(u, v, g_minus);
  int p_minus = compute_chromatic_polynomial(g_minus, k);

  // Contraction
  Graph g_contract = original;
  contract_vertices(g_contract, u, v);

  int p_contract = compute_chromatic_polynomial(g_contract, k);

  return p_minus - p_contract;
}
