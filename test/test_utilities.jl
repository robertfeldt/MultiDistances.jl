using MultiDistances: add!, add, subtract!, subtract
using StringDistances

@testset "utilities" begin

@testset "file_distance and file_similarity" begin
    d = Levenshtein()

    @test 1.0 ≈ file_similarity(d, "data/martha.txt", "data/martha.txt") atol=0.001
    @test 0.0 ≈ file_distance(d,   "data/martha.txt", "data/martha.txt") atol=0.001

    @test 0.66667 ≈ file_similarity(d, "data/martha.txt", "data/marhta.txt") atol=0.001
    @test 0.33333 ≈ file_distance(d,   "data/martha.txt", "data/marhta.txt") atol=0.001

    @test 0.9444 ≈ file_similarity(Jaro(), "data/martha.txt", "data/marhta.txt") atol=0.001
    @test 0.9611 ≈ file_similarity(JaroWinkler(), "data/martha.txt", "data/marhta.txt") atol=0.001

    @test 0.923 ≈ file_similarity(QGram(2), "data/william.txt", "data/williams.txt") atol=0.001

    @test 0.4375 ≈ file_similarity(Levenshtein(), "data/new_york_yankees.txt", "data/yankees.txt") atol=0.001
    @test 1.0 ≈ file_similarity(Partial(Levenshtein()), "data/new_york_yankees.txt", "data/yankees.txt") atol=0.001
end

@testset "find_most_similar" begin
    @test MultiDistances.find_most_similar("a", ["a", "b"]) == "a"
    @test MultiDistances.find_most_similar("a", ["b3", "cd", "a2"]) == "a2"
end

@testset "dict add!" begin
    d1 = Dict(:a => 1, :b => 2, :d => 5)
    d2 = Dict(:a => 2, :b => 1, :c => 3, :d => 0)
    d3 = add!(d1, d2)
    @test d3 === d1
    @test length(d3) == 4
    @test d3[:a] == 3
    @test d3[:b] == 3
    @test d3[:c] == 3
    @test d3[:d] == 5
end

@testset "dict add" begin
    d1 = Dict("a" => 1, "b" => 2, "d" => 5)
    d2 = Dict("a" => 2, "b" => 1, "c" => 3, "d" => 0)
    d3 = add(d1, d2)
    @test d3 !== d1
    @test length(d3) == 4
    @test d3["a"] == 3
    @test d3["b"] == 3
    @test d3["c"] == 3
    @test d3["d"] == 5
    @test d1["a"] == 1
    @test d1["b"] == 2
    @test d1["d"] == 5
    @test !haskey(d1, "c")
end

@testset "dict subtract" begin
    d1 = Dict(:a => 2, :b => 2, :d => 5)
    d2 = Dict(:a => 1, :b => 2, :c => 3, :d => 0)

    d3 = subtract(d1, d2)
    @test d3 !== d1
    @test length(d3) == 4 # a, b, c, d
    @test d3[:a] == 1
    @test d3[:b] == 0
    @test d3[:c] == -3
    @test d3[:d] == 5

    d4 = subtract(d1, d2; minzero = true)
    @test d4 !== d1
    @test length(d4) == 4 # a, b, c, d
    @test d4[:a] == 1
    @test d4[:b] == 0
    @test d4[:c] == 0
    @test d4[:d] == 5

    d5 = subtract(d1, d2; minzero = true, clear = true)
    @test d5 !== d1
    @test length(d5) == 2 # a, d since rest are 0
    @test d5[:a] == 1
    @test d5[:d] == 5
    @test !haskey(d5, :b)
    @test !haskey(d5, :c)
end

@testset "dict subtract!" begin
    d1 = Dict(:a => 2, :b => 2, :d => 5)
    d2 = Dict(:a => 1, :b => 2, :c => 3, :d => 0)
    d3 = subtract!(d1, d2)
    @test d3 === d1
    @test length(d3) == 4
end

end