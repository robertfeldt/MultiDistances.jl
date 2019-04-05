# A Diversity sequencer is used to select a sequence of objects with high diversity.
abstract type DiversitySequencer end

# A div sequencer can either be updateable or not
isupdateable(ds::DiversitySequencer) = false # Default is to not be updateable

abstract type UpdateableDiversitySequencer <: DiversitySequencer end
isupdateable(ds::UpdateableDiversitySequencer) = true

struct DiversitySequence{A}
    maxsize::Int
    objects::Vector{A} # Objects in the sequence, unordered
    strings::Vector{String} # Strings for each object, unordered
    order::Vector{Int}   # Permutation vector, i.e. the order in which objects come in the sequence
end

# Given a distance matrix, calculate the maxi-min diversity sequence, i.e. add the object
# with the largest (maxi) minimum (min) distance to the objects already in the sequence.
# This means we start from the two objects that have the largest distance between them
# and then grow greedily from there.
function find_maximin_sequence(dm::AbstractMatrix{Float64}, maxsize::I = size(dm, 1)) where {I<:Integer}
    # Setup
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
        # Find the unselected one with maximum min distance to selected ones
        distval, idx = findmax(mindistances) # maxi-min
        push!(selected, idx)
        pop!(unselected, idx)

        # Now we need to update mindistances since we have a new selected one
        mindistances[idx] = 0.0 # Distance to itself is 0.0 so...
        for i in unselected
            if dm[i, idx] < mindistances[i]
                mindistances[i] = dm[i, idx]
            end
        end
    end

    selected # Return the order in which we selected them
end

function MaxiMinDiversitySequence(distance, objects::Vector{O}; showprogress = false) where O
    strings = String[string(o) for o in objects]
    dm = distance_matrix(distance, strings; showprogress = showprogress, precalc = true)
    selectionorder = find_maximin_sequence(dm)
    DiversitySequence{O}(length(objects), objects, strings, selectionorder)
end

function MaxiMinDiversitySequence(distance, objects::Vector{O}, strings::Vector{String}, dm::Matrix{Float64}) where O
    selectionorder = find_maximin_sequence(dm)
    DiversitySequence{O}(length(objects), objects, strings, selectionorder)
end

