using MultiDistances: precalculate, CountIteratorQGramCounts, evaluate
using Random

@testset "precalculate for string distances" begin

@testset "CountIteratorQGramCounts" begin
    dist = StringDistances.Jaccard(2)
    s1 = "arnern"
    q1 = precalculate(dist, s1)
    s2 = "arke"
    q2 = precalculate(dist, s2)
    iter = CountIteratorQGramCounts{String}(q1.qgramcounts, q2.qgramcounts)
    qgramcounts = Any[]
    for p in iter
        push!(qgramcounts, p)
    end
    @test length(qgramcounts) == 6
    @test qgramcounts[1] == (UInt(1), UInt(1)) # qgram "ar"
    @test qgramcounts[2] == (UInt(1), UInt(0)) # qgram "er"
    @test qgramcounts[3] == (UInt(0), UInt(1)) # qgram "ke"
    @test qgramcounts[4] == (UInt(1), UInt(0)) # qgram "ne"
    @test qgramcounts[5] == (UInt(0), UInt(1)) # qgram "rk"
    @test qgramcounts[6] == (UInt(2), UInt(0)) # qgram "rn"

    @test evaluate(dist, q1, q2) == StringDistances.evaluate(dist, s1, s2)
end

@testset "random testing" begin

    for _ in 1:100
        dist = StringDistances.Jaccard(rand(2:9))
        s1 = randstring(rand(1:42000))
        s2 = randstring(rand(1:42000))
        q1 = precalculate(dist, s1)
        q2 = precalculate(dist, s2)
        dorig = StringDistances.evaluate(dist, s1, s2)
        dprecalced = evaluate(dist, q1, q2)
        @test dprecalced == dorig 
    end

end

end