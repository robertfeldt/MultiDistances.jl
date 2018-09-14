module MultiDistances

import StringDistances: PreMetric, compare, evaluate
using CodecZlib, CodecXz, CodecZstd, CodecBzip2

export file_distance, file_similarity,
       NCD, ZlibCompressor, evaluate, compare

export ZlibCompressor, XzCompressor, ZstdCompressor, Bzip2Compressor

include("utilities.jl")
include("ncd.jl")
include("distance_matrix.jl")

end