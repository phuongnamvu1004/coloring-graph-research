#ifndef GRAPH_THEORY_RESEARCH_H
#define GRAPH_THEORY_RESEARCH_H

// use boost graph library for graph manipulation
// use graphviz for graph visualization
#include <iostream>                  // for std::cout
#include <utility>                   // for std::pair
#include <algorithm>                 // for std::for_each
#include "boost/graph/graph_traits.hpp"
#include "boost/graph/adjacency_list.hpp"
#include "boost/graph/dijkstra_shortest_paths.hpp"
#include <boost/graph/graphviz.hpp>
#include <boost/graph/graphml.hpp>
#include <boost/graph/edge_coloring.hpp>
#include <boost/graph/sequential_vertex_coloring.hpp>
#include  <boost/graph/properties.hpp>
#include <assert.h>
#include <random>

using namespace boost;

// typedef adjacency_list<vecS, setS, undirectedS, property<vertex_color_t, std::string>> Graph;
typedef adjacency_list<vecS, vecS, undirectedS, property<vertex_color_t, std::string>> Graph;
typedef graph_traits<Graph>::vertex_descriptor Vertex;
typedef std::pair<int, int> Edge;

#endif