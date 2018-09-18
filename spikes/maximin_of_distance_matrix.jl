using LinearAlgebra

# One way to create a diversity sequence of objects given their pair-wise
# distances.
function generate_distance_matrix(n::I) where {I<:Integer}
    dm = rand(n, n)
    for i in 1:n
        dm[i, i] = 0.0
        if i < n
            for j in (i+1):n
                dm[j,i] = dm[i, j]
            end
        end
    end
    dm
end

# Cannot use UT below so skip this:
function ut_generate_distance_matrix(n::I) where {I<:Integer}
    dm = UpperTriangular(rand(n, n))
    for i in 1:n
        dm[i,i] = 0.0
    end
    dm
end

# Find the sequence of objects that maximises the minimum distance
# to the already selected objects, in each step. The initial two elements
# are selected as the ones with the highest pair-wise distance.
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
