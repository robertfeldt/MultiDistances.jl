function compressed_length(str::AbstractString, compressor = ZlibCompressor)
    length(transcode(compressor, str))
end

function lexsortmerge(s1::AbstractString, s2::AbstractString)
    (s1 < s2) ? (s1 * s2) : (s2 * s1)
end

abstract type CompressionDistance <: PreMetric end

struct NCD <: CompressionDistance
    compressor
end

function ncdcalc(lenc1::I, lenc2::I, lenc12::I) where {I<:Integer}
    minval, maxval = minmax(lenc1, lenc2)
    (lenc12 - minval) / maxval
end

function evaluate(ncd::NCD, s1::AbstractString, s2::AbstractString)
    lc1 = compressed_length(s1, ncd.compressor)
    lc2 = compressed_length(s2, ncd.compressor)
    lc12 = compressed_length(lexsortmerge(s1, s2), ncd.compressor)
    ncdcalc(lc1, lc2, lc12)
end

# Note that ncd can return negative similarity values since it is not
# using a perfect compressor, i.e. Kolmogorov.
compare(ncd::NCD, s1::AbstractString, s2::AbstractString) = 1.0 - evaluate(ncd, s1, s2)