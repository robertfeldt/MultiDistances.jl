abstract type AbstractGramDistance <: Distances.SemiMetric end

precalculate(dist::AbstractGramDistance, s::AbstractString) = lempel_ziv_dict(s)

struct ProbabilityJaccard <: AbstractGramDistance
	countpre::Bool
    ProbabilityJaccard(countpre::Bool = true) = new(countpre)
end
precalculate(d::ProbabilityJaccard, g::G) where {G} = lempel_ziv_dict(g, d.countpre)
precalculate(d::ProbabilityJaccard, g::AbstractString) = lempel_ziv_dict(g, d.countpre)

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

probability_jaccard_distance(x::Dict{K,R}, y::Dict{K,R}) where {K,R<:Real} =
    1.0 - probability_jaccard_similarity(x, y)

const ProbabilityJaccardDist = ProbabilityJaccard()

probability_jaccard_distance(s1::S, s2::S) where {S<:AbstractString} =
    probability_jaccard_distance(
        precalculate(ProbabilityJaccardDist, s1),
        precalculate(ProbabilityJaccardDist, s2))

probability_jaccard_distance(d1::AbstractGramCounts{G}, d2::AbstractGramCounts{G}) where {G} =
    probability_jaccard_distance(counts(d1), counts(d2))

(dist::ProbabilityJaccard)(s1, s2) = probability_jaccard_distance(s1, s2)

(d::ProbabilityJaccard)(d1::StringDistances.QGramDict, d2::StringDistances.QGramDict) =
    probability_jaccard_distance(d1.counts, d2.counts)
