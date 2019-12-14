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
    #similarities = map(s -> compare(distance, s, query), strings)
    strings[last(findmax(similarities))]
end