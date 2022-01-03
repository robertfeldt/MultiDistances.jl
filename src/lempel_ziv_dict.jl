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

function iterate!(lz::LempelZivIterator{S,SS}) where {S,SS}
    n = 0
    for g in lz
        n += 1
    end
    return n
end

abstract type LempelZivGrams{G} end

struct LempelZivSet{G} <: LempelZivGrams{G}
    n::Int
    lzset::Set{G}
end
Base.in(g::G, lzs::LempelZivSet{G}) where {G} = in(g, lzs.lzset)

function LempelZivSet(s::S) where {S<:AbstractString}
    lzi = LempelZivSetIterator(s)
    n = iterate!(lzi)
    LempelZivSet{eltype(lzi)}(n, lzi.lzset)
end

mutable struct LempelZivDict{G} <: LempelZivGrams{G}
    n::Int
    countpre::Bool
    lzdict::Dict{G,Int}
end
Base.in(g::G, lzd::LempelZivDict{G}) where {G} = haskey(lzd.lzdict, g)
Base.in(s::S, lzd::LempelZivDict{SubString{S}}) where {S<:AbstractString} = 
    haskey(lzd.lzdict, substr(s))

substr(s::String) = SubString(s, 1, length(s))

function LempelZivDict(s::S, countpre::Bool = true) where {S<:AbstractString}
    lzi = LempelZivDictIterator(s, countpre)
    n = iterate!(lzi)
    LempelZivDict{eltype(lzi)}(n, countpre, lzi.lzdict)
end

Base.getindex(lz::LempelZivIterator{S,SS}, g::SS) where {S,SS} =
    lz.lzdict[g]
Base.getindex(d::LempelZivDict{G}, g::G) where {G} = d.lzdict[g]
Base.getindex(d::LempelZivDict{SubString{S}}, g::S) where {S<:AbstractString} = 
    d.lzdict[substr(g)]
Base.getindex(lz::LempelZivIterator{String,SubString{String}}, g::String) =
    lz.lzdict[substr(g)]

function add!(d1::LempelZivDict{G}, d2::LempelZivDict{G}) where {G}
    for (g, c) in d2.lzdict
        d1.lzdict[g] = get(d1.lzdict, g, 0) + c
    end
    d1.n += d2.n
    return d1
end

function subtract!(d1::LempelZivDict{G}, d2::LempelZivDict{G}) where {G}
    for (g, c) in d2.lzdict
        if haskey(d1.lzdict, g)
            d1.lzdict[g] -= c
            if d1.lzdict[g] < 1
                delete!(d1.lzdict, g)
            end
        end
    end
    d1.n -= d2.n
    return d1
end

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