using MultiDistances: compare, ncdcalc, NCD, lexsortmerge

@testset "NCD" begin

@testset "ncdcalc" begin
    for _ in 1:100
        l1 = rand(1:100)
        l2 = rand(1:100)
        l12 = rand(max(l1, l2):(l1+l2-1))
        @test ncdcalc(l1, l2, l12) == ncdcalc(l2, l1, l12)
    end
end

@testset "lexsortmerge String" begin
    @test lexsortmerge("a", "b") == "ab"
    @test lexsortmerge("b", "a") == "ab"
end

@testset "lexsortmerge UInt8 array" begin
    s1 = b"DATA\xff\u2200"
    s2 = b"2222\xff\u2200"
    @test lexsortmerge(s1, s2) == lexsortmerge(s2, s1)
    @test length(lexsortmerge(s1, s2)) == (length(s1) + length(s2))
end

@testset "NCD compressors" begin
    for C in [Bzip2Compressor, ZlibCompressor, GzipCompressor, DeflateCompressor, 
        XzCompressor, ZstdCompressor, LZ4Compressor]
        d = NCD(C)
        ed = evaluate(d, "a", "b")
        @test 0.0 <= ed <= 1.0
        @test compare("a", "b", d) == (1.0 - ed)

        # We found a bug with LZ4Compressor and Base.CodeUnits{UInt8,String} so try it here:
        @test 0.0 <= evaluate(d, b"DATA\xff\u2200", b"KATA\xff\u2200") <= 1.0
    end
end

end