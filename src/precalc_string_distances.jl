using StringDistances

# Default is to not precalc.
precalculate(dist, s) = s

qparam(d::StringDistances.AbstractQGramDistance) = d.q

# But we introduce precalculation by the qgram count pairs sorted by qgram.
# This way we can just iterate through them later to compare their counts.
precalculate(dist::StringDistances.AbstractQGramDistance, s::AbstractString) =
    StringDistances.QGramSortedVector(s, qparam(dist))