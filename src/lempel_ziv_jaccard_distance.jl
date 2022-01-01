lempel_ziv_jaccard_distance(s1::Set{G}, s2::Set{G}) where {G} =
    1.0 - (length(intersect(s1, s2)) / length(union(s1, s2)))

lempel_ziv_jaccard_distance(s1::LempelZivSet{G}, s2::LempelZivSet{G}) where {G} =
    lempel_ziv_jaccard_distance(s1.lzset, s2.lzset)

function faster_lempel_ziv_jaccard_distance(s1::Set{G}, s2::Set{G}) where {G}
    numone = numboth = 0
    for qg in s1
        if in(qg, s2)
            numboth += 1
        end
        numone += 1
    end
    for qg in s2
        if !in(qg, s1)
            numone += 1
        end
    end
    1.0 - numboth/numone
end

faster_lempel_ziv_jaccard_distance(s1::LempelZivSet{G}, s2::LempelZivSet{G}) where {G} =
    faster_lempel_ziv_jaccard_distance(s1.lzset, s2.lzset)

lempel_ziv_jaccard_distance(s1::S, s2::S) where {S<:AbstractString} =
    lempel_ziv_jaccard_distance(LempelZivSet(s1), LempelZivSet(s2))

faster_lempel_ziv_jaccard_distance(s1::S, s2::S) where {S<:AbstractString} =
    faster_lempel_ziv_jaccard_distance(LempelZivSet(s1), LempelZivSet(s2))