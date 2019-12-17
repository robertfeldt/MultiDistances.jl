using StringDistances
using StringDistances: QGramIterator, QGramDistance

function qparam(d::QGramDistance)
    d.q
end

function qgram_count_dict(iter::QGramIterator{<:AbstractString})
	d = Dict{eltype(iter), UInt}()
    sizehint!(d, length(iter.s)) # Number of qgrams is on the order of the length of the orig string/sequence
    for qgram in iter
		index = Base.ht_keyindex2!(d, qgram)
		if index > 0
			d.age += 1
			@inbounds d.keys[index] = qgram
			@inbounds d.vals[index] = (d.vals[index][1] + UInt(1))
		else
			Base._setindex!(d, UInt(1), qgram, -index)
		end
    end
    d
end

struct SortedQGramCounts{T,S}
    qgramcounts::Array{Pair{T,UInt},1} # We assume these are sorted by key (T)
    s::S
end
function SortedQGramCounts(iter::QGramIterator{<:AbstractString})
    sorted = sort!(collect(qgram_count_dict(iter)), by = kv -> first(kv))
    SortedQGramCounts{eltype(iter), typeof(iter.s)}(sorted, iter.s)
end
import Base.string
string(sqc::SortedQGramCounts) = sqc.s

# Default is to not precalc.
precalculate(dist, s) = s

# But we introduce precalculation by the qgram count pairs sorted by qgram.
# This way we can just iterate through them later to compare their counts.
function precalculate(dist::QGramDistance, s::AbstractString)
    N = qparam(dist)
    iter = StringDistances.qgram(s, N)
    SortedQGramCounts(iter)
end

struct CountIteratorQGramCounts{T}
    sqc1::Array{Pair{T, UInt}, 1}
    sqc2::Array{Pair{T, UInt}, 1}
end

function evaluate(dist::QGramDistance, q1::SortedQGramCounts{T}, q2::SortedQGramCounts{T}) where {T}
	StringDistances.evaluate(dist, CountIteratorQGramCounts{T}(q1.qgramcounts, q2.qgramcounts))
end

function Base.iterate(iter::CountIteratorQGramCounts{T}, state = (0, 0)) where T
    idx1, idx2 = state
    if idx1 >= length(iter.sqc1)
        if idx2 >= length(iter.sqc2)
            return nothing
        else
            k2, c2 = iter.sqc2[idx2+1]
            return ((UInt(0), c2), (idx1, idx2+1))
        end
    elseif idx2 >= length(iter.sqc2)
        k1, c1 = iter.sqc1[idx1+1]
        return ((c1, UInt(0)), (idx1+1, idx2))
    else
        k1, c1 = iter.sqc1[idx1+1]
        k2, c2 = iter.sqc2[idx2+1]
        if k1 < k2
            return ((c1, UInt(0)),  (idx1+1, idx2))
        elseif k2 < k1
            return ((UInt(0),  c2), (idx1,   idx2+1))
        else
            return ((c1, c2), (idx1+1, idx2+1))
        end
    end    
end
