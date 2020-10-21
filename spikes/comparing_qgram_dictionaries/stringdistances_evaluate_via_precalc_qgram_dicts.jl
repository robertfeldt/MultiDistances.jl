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

struct QgramDict{Q,K}
    qdict::Dict{K,Int}
end
function QgramDict(s::Union{AbstractString, AbstractVector}, q::Integer = 2)
    @assert q >= 1
    qgs = StringDistances.qgrams(s, q)
    QgramDict{q, eltype(qgs)}(countdict(qgs))
end
QgramDict(s, q::Integer = 2) = QgramDict(collect(s), q)
q(qd::QgramDict{I,K}) where {I,K} = I

abstract type QgramCounter end
@inline (c::QgramCounter)(s, n1::Integer, n2::Integer) = c(n1, n2) # Fallback for counters that don't care about the qgram itself

mutable struct IntersectionCounter <: QgramCounter
    ndistinct1::Int
    ndistinct2::Int
    nintersect::Int
    IntersectionCounter() = new(0, 0, 0)
end

function (c::IntersectionCounter)(n1::Integer, n2::Integer)
    c.ndistinct1 += (n1 > 0)
    c.ndistinct2 += (n2 > 0)
    c.nintersect += (n1 > 0) & (n2 > 0)
end

newcounter(d::StringDistances.QGramDistance) = IntersectionCounter()

calc(d::StringDistances.Jaccard, c::IntersectionCounter) = 
    1.0 - c.nintersect / (c.ndistinct1 + c.ndistinct2 - c.nintersect)

function _yield_on_co_count_pairs(fn, d1::Dict{K,I}, d2::Dict{K,I}) where {K,I<:Integer}
    for (k1, c1) in d1
        index = Base.ht_keyindex2!(d2, k1)
        if index > 0
            fn(c1, d2.vals[index])
        else
            fn(c1, 0)
        end
    end
    for (k2, c2) in d2
        index = Base.ht_keyindex2!(d1, k2)
        if index <= 0
            fn(0, c2)
        end
    end
end

function StringDistances.evaluate(d::StringDistances.QGramDistance, qc1::Dict{S,I}, qc2::Dict{S,I}) where {S,I<:Integer}
    c = newcounter(d)
    _yield_on_co_count_pairs(c, qc1, qc2)
    calc(d, c)
end

function StringDistances.evaluate(d::StringDistances.QGramDistance, qd1::QgramDict, qd2::QgramDict)
    @assert d.q == q(qd1)
    @assert d.q == q(qd2)
    evaluate(d, qd1.qdict, qd2.qdict)
end

using Random, Test, BenchmarkTools

TimeEval  = Float64[]
TimeTotal = Float64[]

@testset "compare evaluate with and without pre-calculation" begin

for _ in 1:1000
    qlen = rand(2:9)
    d = StringDistances.Jaccard(qlen)
    s1 = randstring(rand(5:10000))
    ci1 = rand(2:div(length(s1), 2))
    ci2 = rand((ci1+1):(length(s1)-1))
    s2 = randstring(ci1-1) * s1[ci1:ci2] * randstring(length(s1)-ci2)
    p1 = @elapsed qd1 = QgramDict(s1, qlen)
    p2 = @elapsed qd2 = QgramDict(s2, qlen)

    #@test evaluate(d, s1, s2) == evaluate(d, qd1, qd2)
    t1 = @elapsed distval1 = evaluate(d, s1, s2)
    t2 = @elapsed distval2 = evaluate(d, qd1, qd2)
    @test distval1 == distval2
    
    push!(TimeEval, t1/t2)
    push!(TimeTotal, t1/(t2+p1+p2))
end

end

mean(TimeEval) # About 2.5-3x faster on my machine
mean(TimeTotal) # About 0.5x slower on my machine

# So we 'loose' 50% performance when pre-calculating if we are only comparing two strings once,
# but we can gain quite some if we need to calculate distance repeatedly, say for example
# when calculating a distance matrix.
function dist_matrix(d::StringDistances.QGramDistance, strs::AbstractVector{<:AbstractString}; precalc = true)
    ss = precalc ? map(s -> QgramDict(s, d.q), strs) : strs
    N = length(strs)
    dm = zeros(Float64, N, N)
    for i in 1:N
        for j = (i+1):N
            dm[i, j] = dm[j, i] = evaluate(d, ss[i], ss[j])
        end
    end
    return dm
end

N = 100
strs = map(_ -> randstring(rand(2:1000)), 1:N)
d = Jaccard(2)
t1 = @elapsed dist_matrix(d, strs; precalc = true)
t2 = @elapsed dist_matrix(d, strs; precalc = false)
t2/t1 # 1.5x to 3.7x faster to pre-calc on my machine (depending on N)

@benchmark dist_matrix(d, strs; precalc = true)
@benchmark dist_matrix(d, strs; precalc = false)


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

@inline pfn(args...) = println(args)

function _yield_on_co_count_pairs_single_loop(fn::Union{Function,IntersectionCounter}, d1::Vector{Pair{K,I}}, d2::Vector{Pair{K,I}}) where {K,I<:Integer}
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

function _yield_on_co_count_pairs(fn::Union{Function,IntersectionCounter}, d1::Vector{Pair{K,I}}, d2::Vector{Pair{K,I}}) where {K,I<:Integer}
    i2 = 1
    for i1 in 1:length(d1)
        k1, c1 = d1[i1]
        if i2 > length(d2)
            fn(c1, 0)
            continue
        else
            k2, c2 = d2[i2]
        end
        if k1 == k2
            fn(c1, c2)
            i2 += 1
        elseif k2 < k1
            fn(0, c2)
            for i in (i2+1):length(d2)
                k2, c2 = d2[i]
                if k2 < k1
                    fn(0, c2)
                elseif k2 == k1
                    fn(c1, c2)
                    i2 = i
                    break
                elseif k2 > k1
                    fn(c1, c2)
                    i2 = i
                    break
                end
            end
        else # k2 > k1
            fn(c1, 0)
        end
    end
end

function StringDistances.evaluate(d::StringDistances.QGramDistance, p1::Vector{Pair{K,I}}, p2::Vector{Pair{K,I}}) where {K,I<:Integer}
    c = newcounter(d)
    _yield_on_co_count_pairs_single_loop(c, p1, p2)
    calc(d, c)
end

function StringDistances.evaluate(d::StringDistances.QGramDistance, qc1::QgramCounts, qc2::QgramCounts)
    @assert d.q == q(qc1)
    @assert d.q == q(qc2)
    evaluate(d, qc1.pairs, qc2.pairs)
end

using Debugger
s1 = "arnearne"
qc1 = QgramCounts(s1, 2)
s2 = "arnebeda"
qc2 = QgramCounts(s2, 2)
qd1 = qc1.pairs
qd2 = qc2.pairs
fn = IntersectionCounter()
fn2(c1, c2) = @show (c1, c2)
@enter _yield_on_co_count_pairs_single_loop(fn, qd1, qd2)
@assert evaluate(Jaccard(2), s1, s2) == evaluate(Jaccard(2), qc1, qc2)

using Random, Test, BenchmarkTools

TimeEval  = Float64[]
TimeTotal = Float64[]

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
    @test distval1 == distval2
    
    push!(TimeEval, t1/t2)
    push!(TimeTotal, t1/(t2+p1+p2))
end

end

mean(TimeEval) # About 11-12x faster on my machine
mean(TimeTotal) # About 0.45x slower on my machine
