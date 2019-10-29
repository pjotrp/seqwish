#ifndef TRANSCLOSURE_HPP_INCLUDED
#define TRANSCLOSURE_HPP_INCLUDED

#include <string>
#include <fstream>
#include <iostream>
#include <unordered_set>
#include <set>
#include "sdsl/bit_vectors.hpp"
#include "seqindex.hpp"
#include "mmiitree.hpp"
#include "iitii_types.hpp"
#include "pos.hpp"

namespace seqwish {


size_t compute_transitive_closures(
    seqindex_t& seqidx,
    range_pos_iitii& aln_iitree, // input alignment matches between query seqs
    const std::string& seq_v_file,
    range_pos_iitii::builder& node_iitree_builder,
    range_pos_iitii::builder& path_iitree_builder,
    uint64_t repeat_max,
    uint64_t min_transclose_len);

}

#endif
