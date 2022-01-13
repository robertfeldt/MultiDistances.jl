function entropy(d1::Dict{K,I}, N1::Integer) where {K,I<:Integer}
	ent = 0.0
	for (s1, n1) in d1
        p = n1/N1
        (p > 0.0) && (ent += (-p) * log2(p))
	end
    return ent
end

function entropy(d::Dict{K,I}) where {K,I<:Integer}
    M = length(d)
    N = sum(values(d))
    ent = 0.0
    for c in values(d)
        p = c / N
        (p > 0.0) && (ent += (-p) * log2(p))
    end
    return ent
end

"""
    Calculate the entropy of gd1+gd2, i.e. the entropy of the merging of two
    dicts.
"""
function calc_entropy_add(d1::Dict{K,I}, N1::Integer, d2::Dict{K,I}, N2::Integer) where {K,I<:Integer}
    N = N1+N2
	ent = 0.0
	for (s1, n1) in d1
		index = Base.ht_keyindex2!(d2, s1)
		p = (index <= 0) ? (n1/N) : ((n1+d2.vals[index])/N)
        (p > 0.0) && (ent += (-p) * log2(p))
	end
	for (s2, n2) in d2
		index = Base.ht_keyindex2!(d1, s2)
        if index <= 0
		    p = n2/N
            (p > 0.0) && (ent += (-p) * log2(p))
        end
	end
	return ent
end

"""
    Calculate the entropy of gd1-gd2, i.e. the entropy of what is left when gd2
    has been removed from gd1. This assumes that the counts in gd2 have previously
    been included in gd1.
"""
function calc_entropy_sub(d1::Dict{K,I}, N1::Integer, d2::Dict{K,I}, N2::Integer) where {K,I<:Integer}
    N = N1-N2
	ent = 0.0
	for (s1, n1) in d1
		index = Base.ht_keyindex2!(d2, s1)
		p = (index <= 0) ? (n1/N) : ((n1-d2.vals[index])/N)
        (p > 0.0) && (ent += (-p) * log2(p))
	end
    # We don't need to go through the entries in d2 since we assume they
    # were already included in d1!
	return ent
end
