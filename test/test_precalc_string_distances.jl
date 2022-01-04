using MultiDistances: precalculate, evaluate
using Random

@testset "precalculate for string distances" begin

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