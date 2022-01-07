using MultiDistances: lempel_ziv_dict

@testset "interface StringDistances" begin

@testset "Use LempelZivDict with QGram distances" begin
    d1 = lempel_ziv_dict("arn")    # a 1, r 1, n 1
    d2 = lempel_ziv_dict("arnear") # a 2, r 1, n 1, e 1, ar 1
    @test StringDistances.Jaccard(2)(d1, d2) == (1 - (3 / 5))
    # The q of the distance doesn't matter:
    @test StringDistances.Jaccard(3)(d1, d2) == (1 - (3 / 5))
    @test StringDistances.Jaccard(5)(d1, d2) == (1 - (3 / 5))
end

end