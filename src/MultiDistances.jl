module MultiDistances

import StringDistances: PreMetric, compare, evaluate, Levenshtein
using CodecZlib, CodecXz, CodecZstd, CodecBzip2

export file_distance, file_similarity,
       NCD, evaluate, compare

export ZlibCompressor, GzipCompressor, DeflateCompressor
export XzCompressor, ZstdCompressor, Bzip2Compressor

include("utilities.jl")
include("ncd.jl")
include("distance_matrix.jl")

end