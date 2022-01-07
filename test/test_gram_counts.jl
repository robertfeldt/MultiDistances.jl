using MultiDistances: GramDict, counts, numgrams, numsymbols, gramtype
using MultiDistances: AbstractGramDict, AbstractGramCounts
using StringDistances: qgrams

@testset "GramDict" begin
    s = "arnear"
    g1 = SubString(s, 1, 1)
    g2 = SubString(s, 2, 2)
    g3 = SubString(s, 3, 3)
    g4 = SubString(s, 4, 4)
    g5 = SubString(s, 5, 6)
    d = Dict(g1 => 2, g2 => 1, g3 => 1, g4 => 1, g5 => 1)    
    gd = GramDict(d)

    @test isa(gd, AbstractGramCounts)
    @test isa(gd, AbstractGramDict)
    @test gramtype(gd) == SubString{String}
    @test numgrams(gd) == 6
    @test size(gd) == 6
    @test numsymbols(gd) == 5
    
    c = counts(gd)
    @test c[g1] == 2
    for gr in [g2, g3, g4, g5]
        @test c[gr] == 1
    end
end