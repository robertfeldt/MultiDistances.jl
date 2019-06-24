# Don't use CoedcZlib since it requires longer strings to start compressing...
#using CodecZlib # use compressor = ZlibCompressor below
using CodecBzip2 # use compressor = Bzip2Compressor below

function compressed_length(str::AbstractString, compressor = Bzip2Compressor)
    length(transcode(compressor, str))
end

function lexsortmerge(s1::AbstractString, s2::AbstractString)
    (s1 < s2) ? (s1 * s2) : (s2 * s1)
end

function ncdcalc(lenc1::I, lenc2::I, lenc12::I) where {I<:Integer}
    minval, maxval = minmax(lenc1, lenc2)
    (lenc12 - minval) / maxval
end

function ncd(s1::AbstractString, s2::AbstractString, compressor = Bzip2Compressor)
    lc1 = compressed_length(s1, compressor)
    lc2 = compressed_length(s2, compressor)
    lc12 = compressed_length(lexsortmerge(s1, s2), compressor)
    ncdcalc(lc1, lc2, lc12)
end

ncd(o1, o2, compressor = Bzip2Compressor) = ncd(string(o1), string(o2), compressor)

# s1 is closer to s2 than to s3
s1 = "arne"
s2 = "arnf"
s3 = "bdoe"
ncd(s1, s2, Bzip2Compressor)
ncd(s1, s3, Bzip2Compressor)