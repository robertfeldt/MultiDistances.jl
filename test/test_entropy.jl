using MultiDistances: entropy, calc_entropy_add, calc_entropy_sub

@testset "entropy" begin

    d = Dict(:a => 1, :b => 2)
    @test entropy(d) == (-1/3 * log2(1/3) + -2/3 * log2(2/3))
    @test entropy(d, 3) == (-1/3 * log2(1/3) + -2/3 * log2(2/3))

@testset "calc_entropy_add and calc_entropy_sub" begin
    d1 = Dict(:a => 1, :b => 2)
    d2 = Dict(:a => 1, :c => 3)
    d12 = add(d1, d2)
    @test calc_entropy_add(d1, 3, d2, 4) == entropy(d12)
    @test calc_entropy_sub(d12, 7, d2, 4) == entropy(d1)
    @test calc_entropy_sub(d12, 7, d1, 3) == entropy(d2)
end

end