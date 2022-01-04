using MultiDistances: lzgrams, LempelZivDictIterator, LempelZivSetIterator
using MultiDistances: LempelZivSet, LempelZivDict, add!, subtract!

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
    @test MultiDistances.hasgramcounts(s) == false
    @test s.n == 5
    @test in(SubString("arnear", 1, 1), s)
    @test in(SubString("arnear", 2, 2), s)
    @test in(SubString("arnear", 3, 3), s)
    @test in(SubString("arnear", 4, 4), s)
    @test in(SubString("arnear", 5, 6), s)
end

@testset "LempelZivDict" begin
    s = LempelZivDict("arn")
    @test MultiDistances.hasgramcounts(s) == true
    @test s.n == 3
    @test in(SubString("arn", 1, 1), s)
    @test in(SubString("arn", 2, 2), s)
    @test in(SubString("arn", 3, 3), s)

    d = LempelZivDict("arnea")
    @test d.n == 4
    @test in(SubString("arne", 1, 1), d)
    @test in(SubString("arne", 2, 2), d)
    @test in(SubString("arne", 3, 3), d)
    @test in(SubString("arne", 4, 4), d)
    @test d[SubString("arne", 4, 4)] == 1
    @test d["e"] == 1
    @test d["n"] == 1
    @test d["r"] == 1
    @test d["a"] == 2

    d2 = LempelZivDict("arnea", false)
    @test d2["e"] == 1
    @test d2["n"] == 1
    @test d2["r"] == 1
    @test d2["a"] == 1
end

@testset "add and subtract LempelZivDicts" begin
    d1 = LempelZivDict("arn") # a 1, r 1, n 1
    orignd1 = d1.n
    d2 = LempelZivDict("arnear") # a 2, r 1, n 1, e 1, ar 1

    add!(d1, d2)
    @test d1.n == (orignd1 + d2.n)
    @test d1["a"] == 3
    @test d1["r"] == 2
    @test d1["n"] == 2
    @test d1["e"] == 1
    @test d1["ar"] == 1

    subtract!(d1, d2)
    @test d1.n == orignd1
    @test d1["a"] == 1
    @test d1["r"] == 1
    @test d1["n"] == 1
    @test !in("e", d1)
    @test !in("ar", d1)

    od1 = deepcopy(d1)
    add!(d1, d2)
    subtract!(d1, od1)
    # d1 + d2 - d1 should be d2:
    @test d1.n == d2.n
    @test d1["a"] == 2
    @test d1["r"] == 1
    @test d1["n"] == 1
    @test d1["e"] == 1
    @test d1["ar"] == 1
end