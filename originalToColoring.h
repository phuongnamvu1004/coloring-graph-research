#include "gtr.h"

Graph coloringFromOriginal(const Graph& original, int k, std::map<int, std::map<int, int> >& adj_list, std::set<int>& special_vertex_classes, std::map<int, int>& class_to_num_vertices, std::vector<int>& special_vertices, std::vector<int>& reconstructible_vertices);