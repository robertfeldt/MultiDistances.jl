using Distances, StringDistances

""" A DiversitySequencer selects and maintains a sequence of objects that 
    have a maximum diversity. 

    It has a maxsize which is the maximum size of the sequence it selects
    and maintains.

    In the selection phase it has not yet reached the maxsize so it will
    add new objects and keep an order in which to add them that gives
    maximum diversity at each moment. This may happen lazily, i.e.
    the sequence is only calculated when it is needed.

    In the maintenance phase it will insert a newly added object at the 
    point in the sequence where it would add the most diversity, then
    recalculate the rest of the sequence, and, finally, "throw out" the
    least diversity-enhancing object (now at the end of the sequence).
"""
abstract type DiversitySequencer{T <: Any} end;

""" maxsize of DiversitySequencer is the max size of the sequence it selects
    and maintains. """
function maxsize(ds::DiversitySequencer{T}) where {T <: Any}
    ds.maxsize # We assume it is in a field. Override if not.
end

function add(ds::DiversitySequencer{T}, o::T) where {T<:Any}
    error("TBI")
end

function add!(ds::DiversitySequencer{T}, objs::Vector{T}) where {T<:Any}
    for o in objs
        add!(ds, o)
    end
    ds
end

# Assume objects are saved to field as added while while the field perm has
# the permutation to return them in order.
@inline objects(ds::DiversitySequencer{T}) where {T<:Any} = ds.objects
@inline sequence(ds::DiversitySequencer{T}) where {T<:Any} = ds.objects[ds.perm]
@inline seq(ds::DiversitySequencer{T}) where {T<:Any} = sequence(ds)

""" Maintain a maximin distance sequence given a distance (function). """
mutable struct MaxiMinDistanceSequencer{T<:Any} <: DiversitySequencer{T}
    d::Distances.PreMetric
    maxsize::Int
    objects::Vector{T}     # Objects in sequence (as added, not in diversity order)
    perm::Vector{Int}      # Permutation of objects to get the ordered sequence
    dists::Vector{Float64} # Pairwise distance value for why this object was added at this position in the order
    distto::Vector{Int}    # Object for which the dists value was calculated (distance to object at this perm order index)
end

function MaxiMinDistanceSequencer{T}(d::D, maxsize::Int) where {T<:Any, D<:StringDistances.PreMetric}
    MaxiMinDistanceSequencer{T}(d, maxsize, T[], Int[], Float64[], Int[])
end

function add!(ds::MaxiMinDistanceSequencer{T}, o::T) where {T<:Any}
    if length(ds.objects) < 2
        push!(ds.objects, o)
        push!(ds.perm, length(ds.objects)) # Length is index to just added object so is also index for permutation order
        if length(ds.objects) == 2
            dist = evaluate(ds.d, ds.objects[1], ds.objects[2])
            push!(ds.dists, dist)
            push!(ds.dists, dist)
            push!(ds.distto, ds.perm[2]) # First object was compared to second
            push!(ds.distto, ds.perm[1]) # Second object was compared to first
        end
    else
        newdists = map(i -> evaluate(ds.d, o, ds.objects[i]), ds.perm)
        mindist, minidx = findmin(newdists) # Of existing objects, which one are we closest to?
        for i in 1:length(ds.perm)
            if mindist > ds.dists[i]
                if length(ds.objects) == maxsize(ds)
                    # Replace current last object in sequence
                    lastidx = ds.perm[end]
                    ds.objects[lastidx] = o
                    insert!(ds.dists, i, mindist)
                    insert!(ds.distto, i, ds.perm[minidx])
                    insert!(ds.perm, i, lastidx)
                    pop!(ds.dists)
                    pop!(ds.distto)
                    pop!(ds.perm)
                    # We need to delete the object at this index => this new one should replace it.
                    # Can it happen that any of the objects that are left in the sequence are there
                    # because of their min distance was to the one we are now deleting? I'm not sure
                    # we can assume this cannot happen. For now let's just warn about it.
                    if in(lastidx, ds.distto)
                        warn("The object we are replacing had an effect on earlier object in sequence!!! Maybe we need to recalc the whole sequence!?")
                    end
                else
                    push!(ds.objects, o)
                    insert!(ds.dists, i, mindist)
                    insert!(ds.distto, i, ds.perm[minidx])
                    insert!(ds.perm, i, min(length(ds.objects), maxsize(ds)))
                end
                return ds
            end
        end
        # Since we did not return we could not insert in sequence so we should
        # insert new object if there is room at end of sequence.
        if length(ds.objects) < maxsize(ds)
            push!(ds.objects, o)
            push!(ds.perm, length(ds.objects))
            push!(ds.dists, mindist)
            push!(ds.distto, ds.perm[minidx])
        end
    end
    ds
end

ds = MaxiMinDistanceSequencer{String}(StringDistances.Jaccard(), 5)
add!(ds, "arne")
add!(ds, "beda")
add!(ds, "ceda")
add!(ds, "bekt") # bekt is more different than ceda so should come before in seq
add!(ds, "fghi") # fghi is more different to all the others so should enter after beda
add!(ds, "fghj") # This has min distance 0.5 so not added
map(o -> evaluate(ds.d, "armo", o), ds.objects)
add!(ds, "armo") # This has min distance 0.8 so added instead of ceda
map(o -> evaluate(ds.d, "pqsu", o), ds.objects)
add!(ds, "pqsu") # This has min distance 1.0 so added instead of armo
map(o -> evaluate(ds.d, "PQSU", o), ds.objects)
add!(ds, "PQSU") # This has min distance 1.0 so added instead of bekt

ds2 = MaxiMinDistanceSequencer{String}(StringDistances.Jaccard(), 5)
@time add!(ds2, String["arne", "beda", "ceda", "bekt", "fghi", "fghj", "armo", "pqsu", "PQSU"])

ds3 = MaxiMinDistanceSequencer{String}(StringDistances.Levenshtein(), 10)
using Random
for i in 1:100
    s = randstring(2)
    add!(ds3, s)
end


function find_maximin_sequence(dm::AbstractMatrix{Float64}, maxsize::I = size(dm, 1)) where {I<:Integer}
    N = size(dm, 1)
    selected = Int[]
    unselected = Set(1:N)
    # Add the two elements with largest distance
    maxdist, idx = findmax(dm)
    push!(selected, idx[1])
    push!(selected, idx[2])
    pop!(unselected, idx[1])
    pop!(unselected, idx[2])
    mindistances = vec(minimum(view(dm, :, selected), dims=2))
    while length(selected) < min(maxsize, N)
        distval, idx = findmax(mindistances)
        push!(selected, idx)
        pop!(unselected, idx)
        mindistances[idx] = 0.0 # Distance to itself is 0.0 so...
        for i in unselected
            if dm[i, idx] < mindistances[i]
                mindistances[i] = dm[i, idx]
            end
        end
    end
    selected
end
