--

bell graph - neighboring partial reconstructions

go from incomplete reconstruction to the coloring which created it, i.e. permutation class
take coloring graph of the incomoplete reconstruction for some more information

can also reconstruct a ~k from a partial reconstruction (which is maybe correct, and will be from special vertex)

try greedy vs random walk

when walking, lazily generate valid adjacent colorings to check, so no need to make the whole coloring graph

lemma:
    if, for some vertex on the bell graph x, if reconstructing on x has more edges than reconstructions on all neighbors of x, then x is reconstructible

equivalent to greedy is correct (?)
