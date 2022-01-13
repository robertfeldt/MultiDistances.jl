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
    
    @test gd[g1] == 2
    c = counts(gd)
    @test c[g1] == 2
    for gr in [g2, g3, g4, g5]
        @test gd[gr] == 1
        @test c[gr] == 1
        @test in(gr, gd) == true
        @test in(string(gr), gd) == true
    end

    # Create another GramDict with the exact same content so we can check equality
    d2 = Dict(g1 => 2, g2 => 1, g3 => 1, g4 => 1, g5 => 1)    
    gd2 = GramDict(d2)
    @test gd == gd2

    d3 = Dict(g1 => 1, g2 => 1, g3 => 1, g4 => 1, g5 => 1)    
    gd3 = GramDict(d3)
    @test gd !== gd2
end