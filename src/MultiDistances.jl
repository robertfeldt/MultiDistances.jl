module MultiDistances

import StringDistances: PreMetric, compare, evaluate, Levenshtein
using CodecZlib, CodecXz, CodecZstd, CodecBzip2, CodecLz4, TranscodingStreams

export file_distance, file_similarity,
       NCD, evaluate, compare

export ZlibCompressor, GzipCompressor, DeflateCompressor
export XzCompressor, ZstdCompressor, Bzip2Compressor, LZ4Compressor

include("utilities.jl")
include("precalc_string_distances.jl")
#include("common_prefix.jl")

include("ncd.jl")
include("distance_matrix.jl")
include("diversity_sequence.jl")

include("lempel_ziv_dict.jl")

end