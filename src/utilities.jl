function file_similarity(distance, file1, file2)
    s1 = read(file1, String)
    s2 = read(file2, String)
    compare(distance, s1, s2)
end

function file_distance(distance, file1, file2)
    1.0 - file_similarity(distance, file1, file2)
end

function find_most_similar(query::AbstractString, 
    strings::Vector{AbstractString}, distance = Levenshtein())

    similarities = map(s -> compare(distance, s, query), strings)
    strings[last(findmax(similarities))]

end