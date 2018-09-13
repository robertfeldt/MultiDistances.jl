function distance_matrix(distance, strings::Vector{String})
    n = length(strings)
    dm = zeros(Float64, n, n)
    for i in 1:n
        for j in i:n
            dm[i, j] = evaluate(distance, strings[i], strings[j])
            dm[j, i] = dm[i, j]
        end
    end
    dm
end
