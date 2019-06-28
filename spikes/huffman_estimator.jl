counts = Int[400, 350, 200, 50]

# HuffmanCalculator calculates the huffman code lengths given an array of
# counts per dictionary word. We assume the counts are sorted from high to low.
# NB! To save time we don't add 1 to all code words in the last step!!
function huffman_codelengths_from_sorted_min1(counts::Vector{Int})
    codelengths = zeros(Int, length(counts))

    leafqueue = Tuple{Int, Vector{Int}}[(counts[i], Int[i]) for i in 1:length(counts)]
    mergedqueue = Tuple{Int, Vector{Int}}[]

    @inbounds while length(leafqueue) > 1 || length(mergedqueue) > 1
        lc1 = (length(leafqueue) > 0) ? first(leafqueue[end]) : typemax(Int)
        lc2 = (length(leafqueue) > 1) ? first(leafqueue[end-1]) : typemax(Int)
        mc1 = (length(mergedqueue) > 0) ? first(mergedqueue[end]) : typemax(Int)
        mc2 = (length(mergedqueue) > 1) ? first(mergedqueue[end-1]) : typemax(Int)

        if lc2 < mc1
            w1, l1 = pop!(leafqueue)
            w2, l2 = pop!(leafqueue)
        elseif mc2 < lc1
            w1, l1 = pop!(mergedqueue)
            w2, l2 = pop!(mergedqueue)
        else
            w1, l1 = pop!(leafqueue)
            w2, l2 = pop!(mergedqueue)
        end

        for i in l1
            codelengths[i] += 1
        end
        for i in l2
            codelengths[i] += 1
            push!(l1, i)
        end
        push!(mergedqueue, (w1+w2, l1))
    end

    return codelengths
end

huffman_codelengths_from_sorted(counts::Vector{Int}) =
    1 .+ huffman_codelengths_from_sorted_min1(counts)

function num_huffman_bits(counts::Vector{Int})
    cs = sort(counts, rev=true)
    codelengths = huffman_codelengths_from_sorted_min1(cs)
    numbits = 0
    for i in 1:length(cs)
        # Add 1 here since we use the min1 version which lacks one bit for each word
        numbits += (cs[i] * (1 + codelengths[i]))
    end
    return numbits
end

# But why not simply use the entropy since that is what huffman coding approximates?
function entropy(counts::Vector{Int})
    probs = counts ./ sum(counts)
    ent = 0.0
    for p in probs
        ent -= p*log2(p)
    end
    return ent
end

function num_entropy_bits(counts::Vector{Int})
    probs = counts ./ sum(counts)
    bits = 0.0
    for i in 1:length(counts)
        p = probs[i]
        infocontent_in_bits = - log2(p)
        bits += (counts[i] * infocontent_in_bits)
    end
    return bits
end

counts2 = [10, 15, 30, 16, 29]
entropy(counts2)
num_entropy_bits(counts2)

# Calculate the delta effect on the number of entropy/optimal bits when one string
# with dictionary counts in a dict is deleted from a multiset of strings. This works
# on the dictionaries of counts and needs the sum of counts for the multiset and the 
# object.
function num_entropy_bits_after_delete(multisetcounts::Dict{K,Int}, totalcount::Int,
    objectcounts::Dict{K,Int}, totalobjectcount::Int) where {K}
    newtotal = totalcount - totalobjectcount
    bits = 0.0
    for (k, c) in multisetcounts
        newc = haskey(objectcounts, k) ? (c - objectcounts[k]) : c
        if newc > 0
            p = newc / newtotal
            bits += (newc * -log2(p))
        end
    end
    return bits, newtotal
end

function qgram_counts(s::S, q::Int=2) where {S<:AbstractString}
    counts = Dict{SubString{S}, Int}()
    numqgrams = max(length(s)-q+1, 0)
    totalcount = numqgrams
    for i in 1:numqgrams
        word = SubString(s, i, i+q-1)
        counts[word] = get!(counts, word, 0) + 1
    end
    if numqgrams == 0
        counts[s] = 1
        totalcount = 1
    end
    return counts, totalcount
end

# Update the counts of one dict with the counts of another.
function add!(d::Dict{K, Int}, d2::Dict{K,Int}) where {K}
    for (k, c) in d2
        d[k] = get!(d, k, 0) + c
    end
    d
end

# Subtract the counts of one dict from the counts of another.
function subtract!(d::Dict{K, Int}, d2::Dict{K,Int}) where {K}
    for (k, c) in d2
        d[k] = get!(d, k, 0) - c
    end
    d
end

strs = ["arne", "beda", "teki", "12ar"]

# NCDm-Cohen-Entropy ordering, i.e. use the retain-most-information ordering of Cohen
# but use entropy as compressor when considering which object to exclude next.
function inverse_least_informative_entropy_ordering(strs::Vector{S}, q::Int=2) where {S<:AbstractString}
    N = length(strs)
    counts = zeros(Int, N)
    objectcountdicts = Array{Dict{SubString{S},Int}}(undef, N)
    totalcount = 0
    # Get the dicts of qgram counts for each string. Also add them up
    # to get the total counts per word.
    multisetcountdict = Dict{SubString{S},Int}()
    for i in 1:N
        objectcountdicts[i], counts[i] = qgram_counts(strs[i], q)
        totalcount += counts[i]
        add!(multisetcountdict, objectcountdicts[i])
    end

    included = collect(1:N)
    exclusion_order = Int[]
    while length(included) > 2
        maxclen = -1
        maxi = 0
        # Find the x_i that maximizes max(G(X \ {x_i})) for G num_entropy_bits
        @inbounds for i in 1:length(included)
            c, newtotal = num_entropy_bits_after_delete(multisetcountdict, totalcount,
                    objectcountdicts[i], counts[i])
            #global maxclen, maxi
            if c > maxclen
                maxi = i
                maxclen = c
            end
        end
        i = included[maxi]
        #println("Excluded $i, bits = $(maxclen)")
        push!(exclusion_order, i)
        totalcount -= counts[i]
        deleteat!(included, maxi)
        subtract!(multisetcountdict, objectcountdicts[i])
    end

    push!(exclusion_order, included[2])
    push!(exclusion_order, included[1])
    return reverse(exclusion_order)
end

using Random
xs100 = String[randstring(100) for _ in 1:100]
@time seq = retain_info_ordering_entropy(xs100) # 1.3 seconds

xs200 = String[randstring(100) for _ in 1:200]
@time seq = retain_info_ordering_entropy(xs200) # 6.0 seconds

xs500 = String[randstring(100) for _ in 1:500]
@time seq = retain_info_ordering_entropy(xs500) # 38 seconds ()

xs1000 = String[randstring(100) for _ in 1:1000]
@time seq = retain_info_ordering_entropy(xs1000) # 156 seconds

@time seq = retain_info_ordering_entropy(xs)

#using TimerOutputs
#const TO = TimerOutput()

# Idea in this version is to create an initial ordering and then
# deleting in that order and stopping the comparisons as soon as
# for min(k, numleft) comparisons in a row the current candidate
# to exclude have not been supplanted. This should cut down
# considerably on the number of entropy calculations needed.
function earlystopping_inverse_least_informative_entropy_ordering(strs::Vector{S}, 
    q::Int=2, k::Int=3) where {S<:AbstractString}

    N = length(strs)
    counts = zeros(Int, N)
    objectcountdicts = Array{Dict{SubString{S},Int}}(undef, N)
    totalcount = 0
    # Get the dicts of qgram counts for each string. Also add them up
    # to get the total counts per word.
    multisetcountdict = Dict{SubString{S},Int}()

    @inbounds for i in 1:N
        objectcountdicts[i], counts[i] = qgram_counts(strs[i], q)
        totalcount += counts[i]
        #totalcount += counts[i]
        add!(multisetcountdict, objectcountdicts[i])
    end

    bits = Float64[
        first(num_entropy_bits_after_delete(multisetcountdict, totalcount,
                    objectcountdicts[i], counts[i])) for i in 1:N
    ]
    inclusion_order = sortperm(bits)

    i = inclusion_order[end]
    subtract!(multisetcountdict, objectcountdicts[i])
    totalcount -= counts[i]

    # Step through and exclude more while stopping early if no better exclusion
    # candidate found in k consecutive tries.
    for pos in (N-1):-1:3
        # We start from current (i) candidate and walk backwards from there
        consecutive_comparison_failures = 0
        i = ibest = inclusion_order[pos]
        bits[ibest], nc = num_entropy_bits_after_delete(multisetcountdict, totalcount,
            objectcountdicts[i], counts[i])
        jbest = 0
        j = 1
        while j < pos && consecutive_comparison_failures < min(k, pos)
            i = inclusion_order[pos-j]
            bits[i], nc = num_entropy_bits_after_delete(multisetcountdict, totalcount,
                    objectcountdicts[i], counts[i])
            if bits[i] > bits[ibest]
                ibest = i
                jbest = j
                consecutive_comparison_failures = 0
            else
                consecutive_comparison_failures += 1 # We failed to find a new and better...
            end
            j += 1
        end
        if jbest > 0
            # We need to switch position from pos to jbest. Note that are multiple ways to do this here so we might want to investigate...
            inclusion_order[pos], inclusion_order[pos-jbest] = inclusion_order[pos-jbest], inclusion_order[pos]
        end
        subtract!(multisetcountdict, objectcountdicts[ibest])
        totalcount -= counts[ibest]
    end

    return inclusion_order
end

# Most conditionally informative order (inverse least informative):

# 1.43 seconds, we will use this as ground truth for average_absolute_rank_difference.
@time mci_100_2 = inverse_least_informative_entropy_ordering(xs100, 2)

# 1.21 seconds
@time esmci_100_2_50 = earlystopping_inverse_least_informative_entropy_ordering(xs100, 2, 50)

# 0.89 seconds
@time esmci_100_2_25 = earlystopping_inverse_least_informative_entropy_ordering(xs100, 2, 25)

# 0.52 seconds
@time esmci_100_2_10 = earlystopping_inverse_least_informative_entropy_ordering(xs100, 2, 10)

# 0.33 seconds
@time esmci_100_2_5 = earlystopping_inverse_least_informative_entropy_ordering(xs100, 2, 5)

# 0.24 seconds
@time esmci_100_2_3 = earlystopping_inverse_least_informative_entropy_ordering(xs100, 2, 3)

# 0.18 seconds:
@time esmci_100_2_2 = earlystopping_inverse_least_informative_entropy_ordering(xs100, 2, 2)

function absolute_rank_differences(seq1::Vector{Int}, seq2::Vector{Int})
    rankdiffs = Array{Int}(undef, length(seq1))
    for i1 in 1:length(seq1)
        r1 = seq1[i1]
        i2 = findfirst(r -> r == r1, seq2)
        rankdiffs[i1] = abs(i1 - i2)
    end
    return rankdiffs
end

using Statistics

mard(s1, s2) = mean(absolute_rank_differences(s1, s2))
medard(s1, s2) = median(absolute_rank_differences(s1, s2))

mard(mci_100_2, esmci_100_2_50)
medard(mci_100_2, esmci_100_2_50)
medard(mci_100_2, esmci_100_2_25)
medard(esmci_100_2_50, esmci_100_2_25)
medard(esmci_100_2_50, esmci_100_2_10)
medard(esmci_100_2_50, esmci_100_2_5)
medard(esmci_100_2_50, esmci_100_2_3)
medard(esmci_100_2_50, esmci_100_2_2)
medard(esmci_100_2_3, esmci_100_2_2)
medard(esmci_100_2_5, esmci_100_2_2)
medard(esmci_100_2_10, esmci_100_2_2)

function evaluate_most_conditionally_informative_approximations(datums::Vector{String}, 
    qs = Int[2, 3, 5],
    ks = Int[1, 2, 3, 5, 10, 25, 50, 100])

    # We take the qs from high to low
    for q in sort(qs, rev=true)
        # Ground truth is the NCDm-Cohen-Entropy method, i.e. most conditionally informative order
        # using entropy to estimate the compression level.
        tgt = @elapsed gt = inverse_least_informative_entropy_ordering(datums, q)
        println("Full ordering took $tgt secs")
        seqs = []
        for k in sort(ks)
            t = @elapsed seq = earlystopping_inverse_least_informative_entropy_ordering(datums, q, k)
            push!(seqs, (q, k, seq))
            m1 = medard(gt, seq)
            m2 = mard(gt, seq)
            pct = round(100.0*t/tgt, digits=2)
            println("q = $q, k = $k: medard = $m1, mard = $m2 ($t secs $pct%)")
        end

        # Check what the random shuffle would give
        medards = []
        for i in 1:10
            push!(medards, medard(gt, shuffle(gt)))
        end
        println("random: mean medard = $(mean(medards))")
    end
end

# Seems to me that the early stopping variants are very far from the NCDm-Cohen-Entropy results.
# It is quite some faster though so interesting to see how it fairs for finding faults.

evaluate_most_conditionally_informative_approximations(xs100, [2, 3, 5, 7], [1, 3, 5, 10, 25])
evaluate_most_conditionally_informative_approximations(xs200, [2, 3, 5, 7], [1, 3, 5, 10, 25])

# We should investigate more aggresive simplifications such as deleting elements in blocks
# and then "recalibrating" by doing occasional, full scans. This might be done in fixed-size 
# blocks or in relative size blocks or it can maybe be adaptive.