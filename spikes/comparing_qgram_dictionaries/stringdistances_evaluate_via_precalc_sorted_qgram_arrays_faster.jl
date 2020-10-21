using StringDistances

function countdict(qgrams)
    d = Dict{eltype(qgrams), Int32}()
    for qg in qgrams
        index = Base.ht_keyindex2!(d, qg)
		if index > 0
			d.age += 1
			@inbounds d.keys[index] = qg
			@inbounds d.vals[index] = d.vals[index][1] + 1
		else
			@inbounds Base._setindex!(d, 1, qg, -index)
		end
    end
    d
end

abstract type QgramCounter end
@inline (c::QgramCounter)(s, n1::Integer, n2::Integer) = c(n1, n2) # Fallback for counters that don't care about the qgram itself

# This only counts if pairs overlap/intersect but doesn't care how "much"...
mutable struct PairIntersectionCounter <: QgramCounter
    ndistinct1::Int
    ndistinct2::Int
    nintersect::Int
    PairIntersectionCounter() = new(0, 0, 0)
end

function (c::PairIntersectionCounter)(n1::Integer, n2::Integer)
    c.ndistinct1 += (n1 > 0)
    c.ndistinct2 += (n2 > 0)
    c.nintersect += (n1 > 0) & (n2 > 0)
end

newcounter(d::StringDistances.QGramDistance) = PairIntersectionCounter()

calc(d::StringDistances.Jaccard, c::PairIntersectionCounter) = 
    1.0 - c.nintersect / (c.ndistinct1 + c.ndistinct2 - c.nintersect)

# Now let's try if we can make it even faster by using a pre-sorted array of counts.
struct QgramCounts{Q,K}
    pairs::Vector{Pair{K,Int}}
end
function QgramCounts(s::Union{AbstractString, AbstractVector}, q::Integer = 2)
    @assert q >= 1
    qgs = StringDistances.qgrams(s, q)
    countpairs = collect(countdict(qgs))
    sort!(countpairs, by = first)
    QgramCounts{q, eltype(qgs)}(countpairs)
end
QgramCounts(s, q::Integer = 2) = QgramCounts(collect(s), q)
q(qd::QgramCounts{I,K}) where {I,K} = I

function _yield_on_co_count_pairs(fn::Union{Function,QgramCounter}, d1::Vector{Pair{K,I}}, d2::Vector{Pair{K,I}}) where {K,I<:Integer}
    i1 = i2 = 1
    while i1 <= length(d1) || i2 <= length(d2)
        if i2 > length(d2)
            fn(d1[i1][1], d1[i1][2], 0)
            i1 += 1
            continue
        elseif i1 > length(d1)
            fn(d2[i2][1], 0, d2[i2][2])
            i2 += 1
            continue
        end
        k1, c1 = d1[i1]
        k2, c2 = d2[i2]
        if k1 < k2
            fn(k1, c1, 0)
            i1 += 1
        elseif k2 < k1
            fn(k2, 0, c2)
            i2 += 1
        else
            fn(k1, c1, c2)
            i1 += 1
            i2 += 1
        end
    end
end

function _yield_on_co_count_pairs2(fn::Union{Function,QgramCounter}, d1::Vector{Pair{K,I}}, d2::Vector{Pair{K,I}}) where {K,I<:Integer}
    i1 = i2 = 1
    while i1 <= length(d1) || i2 <= length(d2)
        if i2 > length(d2)
            for i in i1:length(d1)
                fn(d1[i][1], d1[i][2], 0)
            end
            return
        elseif i1 > length(d1)
            for i in i2:length(d2)
                fn(d2[i][1], 0, d2[i][2])
            end
            return
        end
        k1, c1 = d1[i1]
        k2, c2 = d2[i2]
        cmpval = Base.cmp(k1, k2)
        if cmpval == -1 # k1 < k2
            fn(k1, c1, 0)
            i1 += 1
        elseif cmpval == +1 # k2 < k1
            fn(k2, 0, c2)
            i2 += 1
        else
            fn(k1, c1, c2)
            i1 += 1
            i2 += 1
        end
    end
end

function StringDistances.evaluate(d::StringDistances.QGramDistance, p1::Vector{Pair{K,I}}, p2::Vector{Pair{K,I}}) where {K,I<:Integer}
    c = newcounter(d)
    _yield_on_co_count_pairs(c, p1, p2)
    calc(d, c)
end

function evaluate2(d::StringDistances.QGramDistance, p1::Vector{Pair{K,I}}, p2::Vector{Pair{K,I}}) where {K,I<:Integer}
    c = newcounter(d)
    _yield_on_co_count_pairs2(c, p1, p2)
    calc(d, c)
end

function StringDistances.evaluate(d::StringDistances.QGramDistance, qc1::QgramCounts, qc2::QgramCounts)
    @assert d.q == q(qc1)
    @assert d.q == q(qc2)
    evaluate(d, qc1.pairs, qc2.pairs)
end

evaluate2(d::StringDistances.QGramDistance, s1, s2) = evaluate(d, s1, s2)

function evaluate2(d::StringDistances.QGramDistance, qc1::QgramCounts, qc2::QgramCounts)
    @assert d.q == q(qc1)
    @assert d.q == q(qc2)
    evaluate2(d, qc1.pairs, qc2.pairs)
end

using Random, Test, BenchmarkTools

TimeEval_1_2  = Float64[]
TimeEval_1_3  = Float64[]
TimeEval_2_3  = Float64[]
TimeTotal1_2 = Float64[]
TimeTotal1_3 = Float64[]

@testset "compare evaluate with and without pre-calculation (sorted arrays)" begin

for _ in 1:1000
    qlen = rand(2:9)
    d = StringDistances.Jaccard(qlen)
    s1 = randstring(rand(5:10000))
    ci1 = rand(2:div(length(s1), 2))
    ci2 = rand((ci1+1):(length(s1)-1))
    s2 = randstring(ci1-1) * s1[ci1:ci2] * randstring(length(s1)-ci2)
    p1 = @elapsed qd1 = QgramCounts(s1, qlen)
    p2 = @elapsed qd2 = QgramCounts(s2, qlen)

    #@test evaluate(d, s1, s2) == evaluate(d, qd1, qd2)
    t1 = @elapsed distval1 = evaluate(d, s1, s2)
    t2 = @elapsed distval2 = evaluate(d, qd1, qd2)
    t3 = @elapsed distval3 = evaluate2(d, qd1, qd2)
    @test distval1 == distval2
    @test distval2 == distval3
    
    push!(TimeEval_1_2, t1/t2)
    push!(TimeEval_1_3, t1/t3)
    push!(TimeEval_2_3, t2/t3)
    push!(TimeTotal1_2, t1/(t2+p1+p2))
    push!(TimeTotal1_3, t1/(t3+p1+p2))
end

end

mean(TimeEval_1_2) # About 11-14x faster on my machine
mean(TimeEval_1_3) # About 17-20x faster on my machine
mean(TimeEval_2_3) # About 1.4-1.6x faster on my machine
mean(TimeTotal1_2) # About 0.45-0.52x slower on my machine
mean(TimeTotal1_3) # About 0.45-0.53x slower on my machine

# So we 'loose' 55% performance when pre-calculating if we are only comparing two strings once,
# but we can gain quite some if we need to calculate distance repeatedly, say for example
# when calculating a distance matrix.
function dist_matrix(d::StringDistances.QGramDistance, strs::AbstractVector{<:AbstractString}; precalc = true)
    ss = precalc ? map(s -> QgramCounts(s, d.q), strs) : strs
    N = length(strs)
    dm = zeros(Float64, N, N)
    for i in 1:N
        for j = (i+1):N
            dm[i, j] = dm[j, i] = evaluate2(d, ss[i], ss[j])
        end
    end
    return dm
end

N = 1000
strs = map(_ -> randstring(rand(2:1000)), 1:N)
d = Jaccard(2)
t1 = @elapsed dist_matrix(d, strs; precalc = true)
t2 = @elapsed dist_matrix(d, strs; precalc = false)
t2/t1 # 3x to 10x faster to pre-calc on my machine (depending on N)

@benchmark dist_matrix(d, strs; precalc = true)
@benchmark dist_matrix(d, strs; precalc = false)
