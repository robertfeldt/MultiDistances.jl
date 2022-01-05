"""
    Supertype for counters of grams of type G.
"""
abstract type AbstractGramCounts{G} end

gramtype(gc::AbstractGramCounts{G}) where {G} = G
gramtype(gc::Type{AbstractGramCounts{G}}) where {G} = G

Base.size(gc::AbstractGramCounts) = numgrams(gc)
numgrams(gc::AbstractGramCounts) = 
    error("numgrams NOT implemented for type $(typeof(gc))")

numsymbols(gc::AbstractGramCounts) = 
    error("numsymbols NOT implemented for type $(typeof(gc))")

abstract type AbstractGramDict{G} <: AbstractGramCounts{G} end

mutable struct GramDict{G} <: AbstractGramDict{G}
    n::Int              # Total number of grams, sum of values in dict counts below
    counts::Dict{G,Int} # map each gram to the number of times it was found
end
GramDict(d::Dict{G,Int}) where {G} = GramDict{G}(sum(collect(values(d))), d)

counts(d::GramDict) = d.counts
numgrams(d::GramDict) = d.n
numsymbols(d::GramDict) = length(d.counts)


add(gd1::GramDict{G}, gd2::GramDict{G}) where {G} =
    GramDict{G}(numgrams(gd1)+numgrams(gd2), add(counts(gd1), counts(gd2)))

function add!(gd1::GramDict{G}, gd2::GramDict{G}) where {G}
    gd1.n += gd2.n
    add!(gd1.counts, gd2.counts)
    return gd1
end

"""
    Wrap a QGramDict from StringDistances package, so that it can work
    with our MultiDist package.
"""
struct WrappedQGramDict{G} <: AbstractGramDict{G}
    qd::StringDistances.QGramDict
end

counts(d::WrappedQGramDict) = d.qd.counts