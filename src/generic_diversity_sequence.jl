"""
    A diversity sequence for objects of type O. A sequence is an ordering
    based on large to lower diversity. It is typically used as a filter
    when going through a large number of objects and wanting to keep
    a subset of diverse ones.
"""
abstract type AbstractDiversitySequence{O} end

seq(ds::AbstractDiversitySequence) = 
    error("seq not implemented by type $(typeof(ds))")

"""
    A diversity sequence that uses intermediate, precalculated objects of 
    type I in the diversity calculations.
"""
abstract type AbstractIntermediateDiversitySequence{O,I} <: AbstractDiversitySequence{O} end

"""
    A diversity sequence that uses intermediate, precalculated objects GramCount
    objects in the diversity calculations. The GramCount
"""
abstract type AbstractDictMergingDivSequence{O,I<:AbstractGramCounts} <: AbstractIntermediateDiversitySequence{O,I} end
