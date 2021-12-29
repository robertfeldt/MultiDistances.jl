abstract type LempelZivIterator{S,SS} end

inputlength(lzi::LempelZivIterator) = length(lzi.s)

struct LempelZivSetIterator{S <: Union{AbstractString, AbstractVector},SS} <: LempelZivIterator{S,SS}
	s::S
    countpre::Bool # true iff we should count the prefix of a new lzgram in the dictionary, i.e. if adding a new lzgram "abc" should we also give credit to, i.e. count, one occurence of the previously seen "ab"?
    ilast::Int
    lzset::Set{SS}
end

LempelZivSetIterator(s::S, countpre::Bool = false) where {S <: AbstractString} =
    LempelZivSetIterator{S,SubString{S}}(s, countpre, ncodeunits(s)+1, Set{SubString{S}}())

count!(lzi::LempelZivSetIterator{S,SubString{S}}, g::SubString{S}) where {S<:AbstractString} =
    push!(lzi.lzset, g)

Base.in(g::SubString{S}, lzi::LempelZivSetIterator{S,SubString{S}}) where {S<:AbstractString} =
    in(g, lzi.lzset)

struct LempelZivDictIterator{S <: Union{AbstractString, AbstractVector},SS} <: LempelZivIterator{S,SS}
	s::S
    countpre::Bool # true iff we should count the prefix of a new lzgram in the dictionary, i.e. if adding a new lzgram "abc" should we also give credit to, i.e. count, one occurence of the previously seen "ab"?
    ilast::Int
    lzdict::Dict{SS,Int}
end

LempelZivDictIterator(s::S, countpre::Bool = false) where {S <: AbstractString} =
    LempelZivDictIterator{S,SubString{S}}(s, countpre, ncodeunits(s)+1, Dict{SubString{S},Int}())

count!(lzi::LempelZivDictIterator{S,SS}, g::SS) where {S<:AbstractString,SS} =
    lzi.lzdict[g] = get(lzi.lzdict, g, 0) + 1

Base.in(g::SubString{S}, lzi::LempelZivDictIterator{S,SubString{S}}) where {S<:AbstractString} =
    haskey(lzi.lzdict, g)

function Base.iterate(lzi::LempelZivIterator{S,SubString{S}},
    state = (inputlength(lzi) == 0) ? (1, lzi.ilast+1) : (1, nextind(lzi.s, 1, 1))
    ) where {S<:AbstractString}

	istart, iend = state
	iend > lzi.ilast && return nothing
	prevgram = lzgram = SubString(lzi.s, istart, iend-1)
    isold = in(lzgram, lzi)
    while isold && iend < lzi.ilast
        iend = nextind(lzi.s, iend)
        prevgram = lzgram
        lzgram = SubString(lzi.s, istart, iend-1)
        isold = in(lzgram, lzi)
    end
    if lzi.countpre && (isold || prevgram != lzgram)
        count!(lzi, prevgram)
    end
    if !isold
        count!(lzi, lzgram)
        nextstate = iend, (iend >= lzi.ilast ? iend+1 : nextind(lzi.s, iend))
        lzgram, nextstate
    else
        return nothing
    end
end

Base.eltype(qgram::LempelZivIterator{S,SubString{S}}) where {S} = SubString{S}

lzgrams(s::AbstractString, countpre::Bool = false) = 
    LempelZivDictIterator(s, countpre)

function Base.collect(lz::LempelZivIterator{S,SS}) where {S,SS}
    grams = SS[]
    for g in lz
        push!(grams, g)
    end
    grams
end

Base.getindex(lz::LempelZivIterator{S,SS}, g::SS) where {S,SS} =
    lz.lzdict[g]

substr(s::String) = SubString(s, 1, length(s))
Base.getindex(lz::LempelZivIterator{String,SubString{String}}, g::String) =
    lz.lzdict[substr(g)]

#function lempelzivset(s::S) where {S<:AbstractString}
#    lzset = Set{SubString{S}}()
#    starti, endi = 1, 2
#    while endi <= (length(s)+1)
#        seq = SubString(s, starti, endi-1)
#        if !in(seq, lzset)
#            push!(lzset, seq)
#            starti = endi
#        end
#        endi += 1
#    end
#    return lzset
#end
#
#function lempelzivcounts(s::S) where {S<:AbstractString}
#    lzcounts = Dict{SubString{S},Int}()
#    starti, endi = 1, 2
#    while endi <= (length(s)+1)
#        seq = SubString(s, starti, endi-1)
#        if !haskey(lzcounts, seq)
#            lzcounts[seq] = 1
#            # If a prefix exists it must be an existing one so increase its count
#            if endi-2 >= starti
#                lzcounts[SubString(s, starti, endi-2)] += 1
#            end
#            starti = endi
#        end
#        endi += 1
#    end
#    return lzcounts
#end