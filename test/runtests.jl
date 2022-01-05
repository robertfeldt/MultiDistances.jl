using Test
using MultiDistances

@testset "MultiDistances test suite" begin

include("test_ncd.jl")
include("test_utilities.jl")
include("test_precalc_string_distances.jl")
include("test_distance_matrix.jl")
include("test_diversity_sequence.jl")

include("test_gram_counts.jl")

include("test_lempel_ziv_dict.jl")
include("test_lempel_ziv_jaccard_distances.jl")
include("test_interface_StringDistances.jl")

end