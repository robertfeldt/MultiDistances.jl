using MultiDistances: file_similarity, file_distance

@testset "utilities" begin

@testset "file_distance and file_similarity" begin
    @test 0.66667 ≈ file_similarity("data/martha.txt", "data/marhta.txt")
    @test 0.33333 ≈ file_distance("data/martha.txt", "data/marhta.txt")
end

end