include("generic_diversity_sequence.jl")

"""
    A diversity sequence that tries to maximise the entropy at each step, i.e.
    the next object in the sequence is the one we have found (so far) that increases
    the entropy the most.
"""
struct MaxEntSequence{O} <: AbstractDictMergingDivSequence{O,GramDict}
    maxsize::Int                    # max number of objects in sequence
    fn::Function                    # maps an object to a GramDict used in entropy calculations
    objs::Vector{O}                 # objects added so far
    intermediates::Vector{GramDict} # intermediate objects (here: GramDicts) corresponding to the objects so far
    merged::Vector{GramDict}        # merged intermediate objects, i.e. merged[i] = merge(merged[i-1], intermediates[i])
    entropies::Vector{Float64}
end

seq(ds::MaxEntSequence) = ds.objs

function MaxEntSequence(objs::AbstractVector{O}, fn::Function = o -> lempel_ziv_dict(string(o)), maxsize::Int = 10) where {O}
    objs = collect(objs)
    intermediates = map(fn, objs)
    perm, ents, merged = sortperm_maxentropy_order(intermediates)
    r = 1:min(maxsize, length(objs))
    MaxEntSequence{O}(maxsize, fn,
        objs[perm][r], intermediates[perm][r], merged[r], ents[r])
end

calc_entropy_add(gd1::GramDict{G}, gd2::GramDict{G}) where {G} =
    calc_entropy_add(counts(gd1), numgrams(gd1), counts(gd2), numgrams(gd2))

calc_entropy_sub(gd1::GramDict{G}, gd2::GramDict{G}) where {G} =
    calc_entropy_sub(counts(gd1), numgrams(gd1), counts(gd2), numgrams(gd2))

entropy(gd1::GramDict) = entropy(counts(gd1), numgrams(gd1))

function sortperm_maxentropy_order(ds::Vector{GramDict{G}}) where {G}
    N = length(ds)
    MD = reduce((acc, n) -> add!(acc, n), ds[2:end]; init = deepcopy(ds[1]))
    perm, ents, mdicts = Int[], Float64[entropy(MD)], GramDict{G}[deepcopy(MD)]
    left = Set(1:N)
    while length(left) > 1
        maxent, maxi = -Inf, -1
        for i in left
            ent = calc_entropy_sub(MD, ds[i])
            if ent > maxent
                maxent, maxi = ent, i
            end
        end
        push!(perm, maxi)
        push!(ents, maxent)
        subtract!(MD, ds[maxi])
        push!(mdicts, deepcopy(MD))
        delete!(left, maxi)
    end
    lasti = first(left)
    push!(perm, lasti)
    return reverse(perm), reverse(ents), reverse(mdicts)
end
