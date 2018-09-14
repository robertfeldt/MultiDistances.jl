# By cloning the main package all its dependencies gets installed 
# so we should not need to do more. We might need to ensure precompilation though?
using Pkg

Pkg.add(PackageSpec(url="https://github.com/robertfeldt/MultiDistances.jl", rev="master"))
using MultiDistances

Pkg.add("Distances")
using Distances

Pkg.add("ArgParse")
using ArgParse

Pkg.add("StringDistances")
using StringDistances

Pkg.add("CodecZlib")
using CodecZlib

Pkg.add("CodecXz")
using CodecXz

Pkg.add("CodecZstd")
using CodecZstd

Pkg.add("CodecBzip2")
using CodecBzip2

Pkg.add("JSON")
using JSON

# For now we use the rf fork of CodecLz4 since the main one doesn't build on julia 1.0
Pkg.add(PackageSpec(url="https://github.com/robertfeldt/CodecLz4.jl", rev="master"))
using CodecLz4
