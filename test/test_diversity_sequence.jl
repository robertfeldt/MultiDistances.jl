using MultiDistances: MaxiMinDiversitySequence, DiversitySequence
using MultiDistances: MaxiMeanDiversitySequence, find_maximean_sequence

has_same_elements(a, b) = (length(a) == length(b)) && all(be -> in(be, a), b)

@testset "Diversity sequences" begin

@testset "MaxiMin diversity sequence" begin
    d = Jaccard(2)
    objects = [:Arne, :Arke, :Robertke]
    seq = MaxiMinDiversitySequence(d, objects)

    @test isa(seq, DiversitySequence{Symbol})
    @test has_same_elements(seq.order, 1:3)
    @test has_same_elements(seq.objects, objects)
    @test has_same_elements(seq.strings, map(string, objects))

    # We have the distances:
    #   d(:Arne, :Arke) = 0.8
    #   d(:Arne, :Robertke) = 1.0
    #   d(:Arke, :Robertke) = 0.88
    # so the maximin sequence should be: 1, 3, 2 or 3, 1, 2
    o = seq.order
    @test last(o) == 2
    if o[1] == 1
        @test o[2] == 3
    elseif o[1] == 3
        @test o[2] == 1
    else
        @test false, "Order $(o) is not [1,3,2] or [3,1,2]"
    end
end

@testset "MaxiMean/MaxiSum diversity sequence" begin
    d = Jaccard(2)
    objects = [:Arne, :Arke, :Robertke, :Rorne]
    seq = MaxiMeanDiversitySequence(d, objects)

    @test isa(seq, DiversitySequence{Symbol})
    @test has_same_elements(seq.order, 1:4)
    @test has_same_elements(seq.objects, objects)
    @test has_same_elements(seq.strings, map(string, objects))

    # We have the distances:
    #   d(:Arne, :Arke) = 0.8
    #   d(:Arne, :Robertke) = 1.0
    #   d(:Arne, :Rorne) = 0.6
    #   d(:Arke, :Robertke) = 0.88
    #   d(:Arke, :Rorne) = 1.0
    #   d(:Robertke, :Rorne) = 0.9
    # so the maximean sequence should be one of: [1, 3, 2, 4] or [3, 1, 2, 4] or [1, 4, 3, 2] or [4, 1, 3, 2]
    o = seq.order
    @test in(o, [[1, 3, 2, 4], [3, 1, 2, 4], [1, 4, 3, 2], [4, 1, 3, 2]])

    # Distance Matrix for the next case below. Using Jaccard (2)
    # Used Levenshtein since its easier to debug, and skip qgram sizes
    other_objects = ["Hello", "Helo", "Oi", "Ola", "Heja"]
    sequence = MaxiMeanDiversitySequence(Levenshtein(), other_objects)
    object_ranking = sequence.order
    # The first pair (highest distance) is added to first,
    # and it could be: [a,b] or [b,a]
    # Expected Result: ["Oi", "Hello", "Heja", "Ola", "Helo"]
    @test in(object_ranking, [[3,1,5,4,2], [1,3,5,4,2]])

end

@testset "Few objects" begin
    d = Jaccard(2)
    @test_throws AssertionError MaxiMinDiversitySequence(d, [1])
    @test_throws AssertionError MaxiMeanDiversitySequence(d, [1])
end

@testset "Right matrix removal order" begin
dm = [[0.0, 5.0, 10.0, 2.0, 1.0] [5.0, 0.0, 7.0, 1.0, 1.0] [10.0, 7.0, 0.0 ,1.0, 1.0] [ 2.0, 1.0, 1.0 ,0.0, 1.0] [ 2.0, 1.0, 1.0 ,1.0, 0.0]]
object_ranking = find_maximean_sequence(dm)     
@test in(object_ranking, [[1,3,2,4,5], [3,1,2,4,5]])
end

end