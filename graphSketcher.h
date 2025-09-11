#ifndef GRAPH_SKETCHER_H
#define GRAPH_SKETCHER_H

#include "gtr.h"

Graph create_graph();
std::pair<Graph, int> get_random_tree(int n);
void print_graph_as_dot(const Graph& graph, const std::string& graph_name);
void print_graph_as_dot(const Graph& graph, const std::string& graph_name, const boost::dynamic_properties& dp);
void print_graph_as_graphml(const Graph& graph, const std::string& graph_name, const boost::dynamic_properties& dp);

#endif