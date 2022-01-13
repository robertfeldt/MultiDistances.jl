using MultiDistances: MaxEntSequence, sortperm_maxentropy_order, seq
using MultiDistances: lempel_ziv_dict, add

@testset "sortperm_maxentropy_order" begin
    strs = ["arne", "arnearne", "beda"]
    ds = map(lempel_ziv_dict, strs)
    perm, entropies, mergeddicts = sortperm_maxentropy_order(ds)

    @test perm == [2, 3, 1] # 2 has most entropy, then 3 adds the most entropy given 2, then 1 left

    @test entropies[1] == entropy(ds[2])
    @test mergeddicts[1] == ds[2]

    ds23 = add(ds[2], ds[3])
    @test entropies[2] == entropy(ds23)
    @test mergeddicts[2] == ds23

    ds231 = add(ds23, ds[1])
    @test entropies[3] == entropy(ds231)
    @test mergeddicts[3] == ds231
end

@testset "MaxEntSequence" begin
    strs = ["beda", "arne", "arnearne"]
    s = MaxEntSequence(strs)
    @test isa(s, MaxEntSequence)
    @test seq(s) == ["arnearne", "beda", "arne"]
end