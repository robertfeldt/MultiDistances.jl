using Test
using MultiDistances

@testset "MultiDistances test suite" begin

include("test_utilities.jl")
include("test_precalc_string_distances.jl")
#include("test_common_prefix.jl")

end