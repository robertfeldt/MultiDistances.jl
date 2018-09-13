module MultiDistances

import StringDistances: PreMetric, compare, evaluate
import CodecZlib, CodecXz, CodecZstd, CodecBzip2

export file_distance, file_similarity,
       NCD, ZlibCompressor, evaluate, compare

include("utilities.jl")
include("ncd.jl")
include("distance_matrix.jl")

end