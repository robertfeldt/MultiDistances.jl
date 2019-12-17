using MultiDistances: distance_matrix, safeevaluate
using StringDistances: Jaccard

@testset "distance_matrix" begin
    strs = ["Qr", "C", "d"] # Needs at least 2 strings that both have length < 2
    dm = distance_matrix(Jaccard(2), strs; showprogress = false)
    @test size(dm) == (3, 3)
    # For strings of length < q-gram length evaluate can return NaN. See below.
    # However, we should always return a valid distance so this should hold:
    @test !any(isnan.(dm)) 
end # @testset "Diversity sequences" begin

@testset "Q-gram StringDistances for strings shorter than Q" begin
    d = Jaccard(2)
    @test 0.0 <= evaluate(d, "ab", "bb") <= 1.0
    @test 0.0 <= evaluate(d, "a", "bb") <= 1.0
    @test isnan(evaluate(d, "a", "b")) # Since StringDistances currently returns NaN in these cases...

    @test safeevaluate(d, "a", "b") == 1.0
    @test safeevaluate(d, "a", "a") == 0.0
end
