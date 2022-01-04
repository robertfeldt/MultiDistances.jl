using MultiDistances: lempel_ziv_jaccard_distance, faster_lempel_ziv_jaccard_distance
using MultiDistances: probability_jaccard_distance, LempelZivDict
using MultiDistances: ProbabilityJaccard, precalc

@testset "lempel_ziv_jaccard_distance" begin
    s1 = LempelZivSet("arnear") # a, r, n, e, ar
    s2 = LempelZivSet("arne") # a, r, n, e
    @test lempel_ziv_jaccard_distance(s1, s2) == (1.0 - 4/5)
    @test faster_lempel_ziv_jaccard_distance(s1, s2) == (1.0 - 4/5)

    s3 = LempelZivSet("arnearne") # a, r, n, e, ar, ne
    @test lempel_ziv_jaccard_distance(s3, s2) == (1.0 - 4/6)
    @test faster_lempel_ziv_jaccard_distance(s3, s2) == (1.0 - 4/6)
end

@testset "probability_jaccard_distance manual check" begin
    d1 = Dict{String,Int}("a" => 2, "r" => 3, "n" => 1, "e" => 4, "ar" => 3, "ne" => 7)
    d2 = Dict{String,Int}("a" => 1, "r" => 3, "n" => 2, "e" => 4,            "ne" => 1)
    # "a": xi=2, yi=1 => 1+max(3/2,3/1)+max(1/2,2/1)+max(4/2,4/1)+max(3/2,0/1)+max(7/2,1/1)=15.0
    # "r": xi=3, yi=3 => max(2/3,1/3)+1+max(1/3,2/3)+max(4/3,4/3)+max(3/3,0/3)+max(7/3,1/3)=7.0
    # "n": xi=1, yi=2 => max(2/1,1/2)+max(3/1,3/2)+1+max(4/1,4/2)+max(3/1,0/2)+max(7/1,1/2)=20.0
    # "e": xi=4, yi=4 => max(2/4,1/4)+max(3/4,3/4)+max(1/4,2/4)+1+max(3/4,0/4)+max(7/4,1/4)=5.25
    # "ar": skipped since "ar" not in c2
    # "ne": xi=7, yi=1 => max(2/7,1/1)+max(3/7,3/1)+max(1/7,2/1)+max(4/7,4/1)+max(3/7,0/1)+1=11.428571428571429
    # So Prob Jaccard Similarity is: 1/15+1/7+1/20+1/5.25+1/11.428571428571429=0.5375
    # and Prob Jaccard Distance is 1.0-05375 = 0.4625
    @test probability_jaccard_distance(d1, d2) == 0.4625
end

@testset "probability_jaccard_distance with strings" begin
    s1, s2 = "arne", "arnearne"
    d1, d2 = LempelZivDict(s1), LempelZivDict(s2)
    @test probability_jaccard_distance(d1, d2) == probability_jaccard_distance(s1, s2)
end

@testset "ProbabilityJaccard distance" begin
    d = ProbabilityJaccard()
    s1, s2 = "arne", "arnearne"
    @test evaluate(d, s1, s2) == probability_jaccard_distance(s1, s2)
    @test isa(precalc(d, s1), LempelZivDict)

    d1, d2 = precalc(d, s1), precalc(d, s2)
    @test d(d1, d2) == probability_jaccard_distance(s1, s2)
end

@testset "ProbabilityJaccard on QGramDict" begin
    s1, s2 = "arne", "arnearne"
    qc1, qc2 = StringDistances.QGramDict(s1, 2), StringDistances.QGramDict(s2, 2)
    d = ProbabilityJaccard()
    @test d(qc1, qc2) == probability_jaccard_distance(qc1.counts, qc2.counts)
end