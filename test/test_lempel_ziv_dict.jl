using MultiDistances: lzgrams, LempelZivDictIterator, LempelZivSetIterator, LempelZivSet

sameset(it1, it2) = sort(collect(it1)) == sort(collect(it2))

@testset "LempelZivIterator" begin

for LZI in [LempelZivDictIterator, LempelZivSetIterator]
    it = LZI("abcab")
    @test eltype(it) == SubString{String}
    @test sameset(it, ["a", "b", "c", "ab"])

    @test length(collect(LZI(""))) == 0
    @test length(collect(LZI("a"))) == 1
    @test length(collect(LZI("ab"))) == 2
    @test length(collect(LZI("abc"))) == 3

    @test length(collect(LZI("abb"))) == 2
    @test length(collect(LZI("aba"))) == 2

    @test length(collect(LZI("abcabc"))) == 4
    @test length(collect(LZI("abcabca"))) == 5

    @test sameset(LZI("abcabcabc"), ["a", "b", "c", "ab", "ca", "bc"])
    @test sameset(LZI("abcabcabcd"), 
        ["a", "b", "c", "ab", "ca", "bc", "d"])
end

end

@testset "LempelZivDictIterator" begin

    lzi = LempelZivDictIterator("ab")
    collect(lzi) # To ensure it has counted the grams
    @test lzi["a"] == 1
    @test lzi["b"] == 1

    # Now count every time also an old prefix is seen
    lzi = LempelZivDictIterator("aba", true)
    collect(lzi)
    @test lzi["a"] == 2
    @test lzi["b"] == 1

    lzi = LempelZivDictIterator("ababc", true)
    collect(lzi)
    @test lzi["a"] == 2
    @test lzi["b"] == 1
    @test lzi["ab"] == 1
    @test lzi["c"] == 1

    lzi = LempelZivDictIterator("abcabcabcbcac", true)
    collect(lzi)
    @test lzi["a"] == 2
    @test lzi["b"] == 2
    @test lzi["c"] == 3
    @test lzi["ab"] == 1
    @test lzi["ca"] == 1
    @test lzi["bc"] == 2
    @test lzi["bca"] == 1

end

@testset "LempelZivSet" begin
    s = LempelZivSet("arnear")
    @test s.n == 5
    @test in(SubString("arnear", 1, 1), s)
end
