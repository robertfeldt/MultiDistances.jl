using ProgressMeter

# Since eval sometimes returns NaN we have a safe version here for use in distance matrix
# calculations.
function safeevaluate(distance, s1, s2)
    d = evaluate(distance, s1, s2)
    if isnan(d)
        if string(s1) == string(s2)
            return 0.0
        else
            return 1.0 # This might not be safe for all distances though!!
        end
    else
        return d
    end
end

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
        Progress(numtotaldistances, 0.2, "Calculating distances...", 40)
    end

    for i in 1:n
        for j in (i+1):n
            dm[j, i] = dm[i, j] = safeevaluate(distance, precalced[i], precalced[j])
            showprogress && next!(p)
        end
    end

    return dm
end
