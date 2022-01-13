module MultiDistances

using Distances
import StringDistances: PreMetric, compare, evaluate, Levenshtein,
    AbstractQGramDistance, eval_start, eval_op, eval_end
using CodecZlib, CodecXz, CodecZstd, CodecBzip2, CodecLz4, TranscodingStreams

export file_distance, file_similarity,
       NCD, evaluate, compare

export ZlibCompressor, GzipCompressor, DeflateCompressor
export XzCompressor, ZstdCompressor, Bzip2Compressor, LZ4Compressor

include("utilities.jl")
include("precalc_string_distances.jl")
include("gram_counts.jl")
include("entropy.jl")

include("ncd.jl")
include("distance_matrix.jl")

include("lempel_ziv_iterator.jl")
include("lempel_ziv_jaccard_distance.jl")
include("probability_jaccard_distance.jl")

include("generic_diversity_sequence.jl")
include("maximum_entropy_sequence.jl")
include("diversity_sequence.jl") # Should change name of this one!

include("interface_StringDistances.jl")

end