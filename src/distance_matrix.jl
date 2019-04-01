using ProgressMeter

# Default is to not precalc. Override for Distances later.
precalculate(dist, s) = s

function distance_matrix(distance, strings::Vector{String}; 
            showprogress = true,
            precalc = true)

    n = length(strings)
    dm = zeros(Float64, n, n)

    precalced = if precalc
        map(s -> precalculate(distance, s), strings)
    else
        strings
    end

    p = if showprogress
        numtotaldistances = n + div(n * (n - 1),  2)
        Progress(numtotaldistances, 1.0, "Calculating distances...", 40)
    end

    for i in 1:n
        for j in i:n
            dm[j, i] = dm[i, j] = evaluate(distance, precalced[i], precalced[j])
            if showprogress
                next!(p)
            end
        end
    end

    return dm
end
