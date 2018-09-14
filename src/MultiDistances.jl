module MultiDistances

import StringDistances: PreMetric, compare, evaluate
using CodecZlib, CodecXz, CodecZstd, CodecBzip2, CodecLz4

export file_distance, file_similarity,
       NCD, evaluate, compare

export ZlibCompressor, XzCompressor, ZstdCompressor, Bzip2Compressor
#export LZ4Compressor # seems buggy exclude for now

include("utilities.jl")
include("ncd.jl")
include("distance_matrix.jl")

end