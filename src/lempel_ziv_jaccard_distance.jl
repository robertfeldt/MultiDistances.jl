abstract type AbstractGramDistance <: Distances.SemiMetric end

precalculate(dist::AbstractGramDistance, s::AbstractString) =
    LempelZivDict(s)

struct ProbabilityJaccard <: AbstractGramDistance
	countpre::Bool
    ProbabilityJaccard(countpre::Bool = true) = new(countpre)
end
precalc(d::ProbabilityJaccard, g::G) where {G} = LempelZivDict(g, d.countpre)

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

# The Probability Jaccard Similarity is a generalization of the Jaccard Similarity
# value to probiability/weight/count distributions as introduced in the paper:
# Moulton R. and Jiang Y., "Maximally Consistent Sampling and the Jaccard Index
# of Probability Distributions", 2018, https://arxiv.org/pdf/1809.04052.pdf
function probability_jaccard_similarity(x::Dict{K,R}, y::Dict{K,R}) where {K,R<:Real}
    jsim = 0.0
    for (kxi, cxi) in x
        if cxi > 0 && haskey(y, kxi)
            cyi = y[kxi]
            if cyi > 0
                # Both cxi and cyi > 0 so loop over all keys
                num = 0.0
                for (kxj, cxj) in x
                    cyj = get(y, kxj, 0)
                    num += max(cxj/cxi, cyj/cyi)
                end
                for (kyj, cyj) in y
                    # Only add the ones that are unique to y since we covered all the other ones above
                    if !haskey(x, kyj)
                        num += cyj/cyi
                    end
                end
                jsim += (1.0/num)
            end
        end
    end
    return jsim
end

function (dist::ProbabilityJaccard)(d1::LempelZivDict{G}, d2::LempelZivDict{G}) where {G}
    probability_jaccard_distance(d1.lzdict, d2.lzdict)    
end

probability_jaccard_distance(x::Dict{K,R}, y::Dict{K,R}) where {K,R<:Real} =
    1.0 - probability_jaccard_similarity(x, y)

probability_jaccard_distance(d1::LempelZivDict{G}, d2::LempelZivDict{G}) where {G} =
    probability_jaccard_distance(d1.lzdict, d2.lzdict)

probability_jaccard_distance(s1::S, s2::S) where {S<:AbstractString} =
    probability_jaccard_distance(LempelZivDict(s1), LempelZivDict(s2))

(d::ProbabilityJaccard)(d1::LempelZivDict{G}, d2::LempelZivDict{G}) where {G} =
    probability_jaccard_distance(d1, d2)

(d::ProbabilityJaccard)(d1::StringDistances.QGramDict, d2::StringDistances.QGramDict) =
    probability_jaccard_distance(d1.counts, d2.counts)

(dist::ProbabilityJaccard)(s1::S, s2::S) where {S<:AbstractString} =
    probability_jaccard_distance(precalc(dist, s1), precalc(dist, s2))
