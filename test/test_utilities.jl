using StringDistances

@testset "utilities" begin

@testset "file_distance and file_similarity" begin
    d = Levenshtein()

    @test 1.0 ≈ file_similarity(d, "data/martha.txt", "data/martha.txt") atol=0.001
    @test 0.0 ≈ file_distance(d,   "data/martha.txt", "data/martha.txt") atol=0.001

    @test 0.66667 ≈ file_similarity(d, "data/martha.txt", "data/marhta.txt") atol=0.001
    @test 0.33333 ≈ file_distance(d,   "data/martha.txt", "data/marhta.txt") atol=0.001

    @test 0.9444 ≈ file_similarity(Jaro(), "data/martha.txt", "data/marhta.txt") atol=0.001
    @test 0.9611 ≈ file_similarity(Winkler(Jaro()), "data/martha.txt", "data/marhta.txt") atol=0.001

    @test 0.923 ≈ file_similarity(QGram(2), "data/william.txt", "data/williams.txt") atol=0.001
    @test 0.953 ≈ file_similarity(Winkler(QGram(2)), "data/william.txt", "data/williams.txt") atol=0.001

    @test 0.4375 ≈ file_similarity(Levenshtein(), "data/new_york_yankees.txt", "data/yankees.txt") atol=0.001
    @test 1.0 ≈ file_similarity(Partial(Levenshtein()), "data/new_york_yankees.txt", "data/yankees.txt") atol=0.001
end

@testset "find_most_similar" begin
    @test MultiDistances.find_most_similar("a", ["a", "b"]) == "a"
    @test MultiDistances.find_most_similar("a", ["b3", "cd", "a2"]) == "a2"
end

end