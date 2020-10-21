# Q. Should we save Q-gram counts as a:
#     1. Dict{SubString, UInt64}
#     2. Dict{UInt64, UInt64} # for q-grams up to length 8 which should be fine
#     3. Array{Tuple{SubString, UInt64}} sorted by SubString
#     4. Array{Tuple{UInt64, UInt64}} sorted by q-gram-int
#
# Let's start by comparing 1 and 3.

using StringDistances

eachqgram(s, q::Int=2) = collect(StringDistances.qgrams(s, q))

s = "arnebeda"

eachqgram(s)

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

using BenchmarkTools
using Random

qgs = eachqgram(randstring(1000))
res = countdict(qgs)
@benchmark countdict(qgs)
typeof(res)

# Dict{SubString{String},UInt64}
# Size, Median time
# 5,    291ns
# 10,   462ns
# 50,   4.7us
# 100,  6.5us
# 500,  29.4us
# 1000, 118us

# Dict{SubString{String},Int}
# Size, Median time
# 5,    289ns
# 10,   447ns
# 50,   4.5us
# 100,  6.1us
# 500,  29.2us
# 1000, 115us

# Dict{SubString{String},Int32}
# Size, Median time
# 5,    289ns
# 50,   4.2us
# 500,  28.6us
# 1000, us

# Dict{SubString{String},UInt32}
# Size, Median time
# 5,    289ns
# 50,   4.2us
# 500,  29.4us
# 1000, 116.5us

# So for countdict the fastest is Dict{SubString{String},Int32}

# But what about comparing these dicts:
function _countkeys_manually(fn, d1::Dict{K,I}, d2::Dict{K,I}) where {K<:Any,I<:Integer}
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

mutable struct IntersectionCounter
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

abstract type StrDist end

struct Jaccard <: StrDist
    q::Int
end
newcounter(d::Jaccard) = IntersectionCounter()
q(d::Jaccard) = d.q
calc(d::Jaccard, c::IntersectionCounter) = 
    1.0 - c.nintersect / (c.ndistinct1 + c.ndistinct2 - c.nintersect)

function eval(d::StrDist, s1::AbstractString, s2::AbstractString)
    c = newcounter(d)
    qg1 = countdict(eachqgram(s1, q(d)))
    qg2 = countdict(eachqgram(s2, q(d)))
    _countkeys_manually(c, qg1, qg2)
    calc(d, c)
end

function eval(d::StrDist, qc1::Dict{S,I}, qc2::Dict{S,I}) where {S<:SubString,I<:Integer}
    c = newcounter(d)
    _countkeys_manually(c, qc1, qc2)
    calc(d, c)
end

d = Jaccard(2)
s1 = randstring(50)
s2 = randstring(50)
@benchmark eval(d, s1, s2)

# countdict + _countkeys_manually + IntersectionCounter + Jaccard on two Dict{SubString, Int32}
# Size, Time
# 50,   14.979us
# 500,  142.8us
# 5000, 1.947ms

d = Jaccard(2)
s1 = randstring(50)
s2 = randstring(50)
qc1 = countdict(eachqgram(s1, q(d)))
qc2 = countdict(eachqgram(s2, q(d)))
@benchmark eval(d, qc1, qc2)
# _countkeys_manually + IntersectionCounter + Jaccard on two Dict{SubString, Int32}
# Size, Time
# 50,   2.609us (5.7x)
# 500,  43.5us (3.3x)
# 5000, 281us (6.9x)

# So it is between 3-7 times faster to pre-calc the qgram count dictionaries!!

# What about using a dict for the overlap count pairs as is done in StringDistances?
function _countkeys_with_dict(fn, d1::Dict{K,I}, d2::Dict{K,I}) where {K<:Any,I<:Integer}
    d = Dict{K, Tuple{Int, Int}}()
    for (k1, c1) in d1
        index = Base.ht_keyindex2!(d, k1)
        # Since we know that d cannot yet contain the keys of d1 we take shortcut:
        @inbounds Base._setindex!(d, (c1, 0), k1, -index)
    end
    for (k2, c2) in d2
		index = Base.ht_keyindex2!(d, k2)
		if index > 0
			d.age += 1
			@inbounds d.keys[index] = k2
			@inbounds d.vals[index] = (d.vals[index][1], c2)
		else
			@inbounds Base._setindex!(d, (0, c2), k2, -index)
		end
    end
    for (c1, c2) in values(d)
        fn(c1, c2)
    end
end

function eval_with_dict(d::StrDist, s1::AbstractString, s2::AbstractString)
    c = newcounter(d)
    qg1 = countdict(eachqgram(s1, q(d)))
    qg2 = countdict(eachqgram(s2, q(d)))
    _countkeys_with_dict(c, qg1, qg2)
    calc(d, c)
end

d = Jaccard(2)
s1 = randstring(5000)
s2 = randstring(5000)
@benchmark eval_with_dict(d, s1, s2)
# countdict + _countkeys_with_dict + IntersectionCounter + Jaccard on two Dict{SubString, Int32}
# Size, Time
# 50,   20.139us (1.34x slower)
# 500,  260.32us (1.82x slower)
# 5000, 2.519ms  (1.29x slower)

function eval_with_dict(d::StrDist, qc1::Dict{S,I}, qc2::Dict{S,I}) where {S<:SubString,I<:Integer}
    c = newcounter(d)
    _countkeys_with_dict(c, qc1, qc2)
    calc(d, c)
end

d = Jaccard(2)
s1 = randstring(5000)
s2 = randstring(5000)
qc1 = countdict(eachqgram(s1, q(d)))
qc2 = countdict(eachqgram(s2, q(d)))
@benchmark eval_with_dict(d, qc1, qc2)
# _countkeys_with_dict + IntersectionCounter + Jaccard on two Dict{SubString, Int32}
# Size, Time
# 50,   6.943us (2.7x slower)
# 500,  43.5us (3.9x slower)
# 5000, 281us (3.1x)

# So the fastest solution which is also very general is to pre-calc qgram dicts and
# then manually co-count the qgrams!

# How to make this part of the StringDistances design:
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

mutable struct IntersectionCounter
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

mean(TimeEval) # About 3x faster on my machine
mean(TimeTotal) # About 0.5x faster on my machine

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

# Now, what about pre-calc Array{Tuple{SubString, Int32}} and pre-sorting them so we
# can then just manually step through the arrays?


