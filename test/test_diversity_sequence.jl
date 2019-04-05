using MultiDistances: MaxiMinDiversitySequence, DiversitySequence

@testset "Diversity sequences" begin

@testset "MaxiMin diversity sequence" begin
    d = Jaccard(2)
    objects = [:Arne, :Arke, :Robertke]
    seq = MaxiMinDiversitySequence(d, objects)

    @test isa(seq, DiversitySequence{Symbol})
    @test sort(seq.order) == collect(1:3) # All 3 objects are in the sequence
    @test sort(seq.objects) == sort(objects)
    @test sort(map(string, seq.objects)) == sort(map(string, objects))

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

end