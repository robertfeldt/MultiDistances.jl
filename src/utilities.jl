function file_similarity(distance, file1, file2)
    s1 = read(file1, String)
    s2 = read(file2, String)
    compare(s1, s2, distance)
end

function file_distance(distance, file1, file2)
    1.0 - file_similarity(distance, file1, file2)
end

function find_most_similar(query::S, 
    strings::Vector{S}, distance = Levenshtein()) where {S<:AbstractString}

    similarities = map(s -> compare(s, query, distance), strings)
    strings[last(findmax(similarities))]
end

function add!(d1::Dict{K,N}, d2::Dict{K,N}) where {K,N<:Number}
    for (k,v) in d2
        d1[k] = get(d1, k, 0) + v
    end
    return d1
end

add(d1::Dict{K,N}, d2::Dict{K,N}) where {K,N<:Number} = add!(deepcopy(d1), d2)

function subtract!(d1::Dict{K,N}, d2::Dict{K,N}; 
    minzero = false, clear = false) where {K,N<:Number}
    for (k,v) in d2
        currval = get(d1, k, 0)
        if minzero
            d1[k] = max(0, currval - v)
        else
            d1[k] = currval - v
        end
        if clear
            if v >= currval
                delete!(d1, k)
            end
        end
    end
    return d1
end

subtract(d1::Dict{K,N}, d2::Dict{K,N}; 
    minzero = false, clear = false) where {K,N<:Number} = 
    subtract!(deepcopy(d1), d2; minzero, clear)