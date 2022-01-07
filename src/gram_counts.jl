"""
    Supertype for counters of grams of type G.
"""
abstract type AbstractGramCounts{G} end

gramtype(gc::AbstractGramCounts{G}) where {G} = G
gramtype(gc::Type{AbstractGramCounts{G}}) where {G} = G

Base.size(gc::AbstractGramCounts) = numgrams(gc)
numgrams(gc::AbstractGramCounts) = length(grams(gc))
grams(gc::AbstractGramCounts) =
    error("grams NOT implemented for type $(typeof(gc))")

numsymbols(gc::AbstractGramCounts) = 
    error("numsymbols NOT implemented for type $(typeof(gc))")

counts(gc::AbstractGramCounts) =
    error("counts NOT implemented for type $(typeof(gc))")

Base.in(g::G, d::AbstractGramCounts{G}) where {G} = haskey(counts(d), g)

Base.getindex(d::AbstractGramCounts{G}, g::G) where {G} = get(counts(d), g, 0)

substr(s::String) = SubString(s, 1, length(s))

Base.in(g::S, d::AbstractGramCounts{SubString{S}}) where {S<:AbstractString} =
    haskey(counts(d), substr(g))

Base.getindex(d::AbstractGramCounts{SubString{S}}, g::S) where {S<:AbstractString} =
    d[substr(g)]

# A GramSet only has the grams and not any counts so they are essentially count 1.
abstract type AbstractGramSet{G} <: AbstractGramCounts{G} end

grams(gs::AbstractGramSet) =
    error("grams NOT implemented for type $(typeof(gs))")

Base.in(g::G, d::AbstractGramSet{G}) where {G} = in(g, grams(d))
Base.getindex(d::AbstractGramSet{G}, g::G) where {G} = in(g, grams(d)) ? 1 : 0

abstract type AbstractGramDict{G} <: AbstractGramCounts{G} end

mutable struct GramDict{G} <: AbstractGramDict{G}
    n::Int              # Total number of grams, sum of values in dict counts below
    counts::Dict{G,Int} # map each gram to the number of times it was found
end
GramDict(d::Dict{G,Int}) where {G} = GramDict{G}(sum(collect(values(d))), d)

counts(d::GramDict) = d.counts
numgrams(d::GramDict) = d.n
numsymbols(d::GramDict) = length(d.counts)

function add!(d1::GramDict{G}, d2::GramDict{G}) where {G}
    d1.n += d2.n
    add!(d1.counts, d2.counts)
    return d1
end

add(d1::GramDict{G}, d2::GramDict{G}) where {G} = add!(deepcopy(d1), d2)

function subtract!(d1::GramDict{G}, d2::GramDict{G}) where {G}
    c1 = counts(d1)
    for (g, c) in counts(d2)
        if haskey(c1, g)
            c1[g] -= c
            if c1[g] < 1
                delete!(c1, g)
            end
        end
    end
    d1.n -= d2.n
    return d1
end

subtract(d1::GramDict{G}, d2::GramDict{G}) where {G} = subtract!(deepcopy(d1), d2)

"""
    Wrap a QGramDict from StringDistances package, so that it can work
    with our MultiDist package.
"""
struct WrappedQGramDict{G} <: AbstractGramDict{G}
    qd::StringDistances.QGramDict
end

counts(d::WrappedQGramDict) = d.qd.counts