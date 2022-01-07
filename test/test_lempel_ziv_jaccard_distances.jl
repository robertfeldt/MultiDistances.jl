using MultiDistances: lempel_ziv_jaccard_distance, faster_lempel_ziv_jaccard_distance
using MultiDistances: LempelZivSet

@testset "lempel_ziv_jaccard_distance" begin
    s1 = LempelZivSet("arnear") # a, r, n, e, ar
    s2 = LempelZivSet("arne") # a, r, n, e
    @test lempel_ziv_jaccard_distance(s1, s2) == (1.0 - 4/5)
    @test faster_lempel_ziv_jaccard_distance(s1, s2) == (1.0 - 4/5)

    s3 = LempelZivSet("arnearne") # a, r, n, e, ar, ne
    @test lempel_ziv_jaccard_distance(s3, s2) == (1.0 - 4/6)
    @test faster_lempel_ziv_jaccard_distance(s3, s2) == (1.0 - 4/6)
end