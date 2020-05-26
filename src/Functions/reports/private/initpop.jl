function processInitPopAges( ages::Vector{Float64}, ageRes::Float64 )

    result = DataFrame()

    # Summary statistics.
    minAge = minimum( ages )
    maxAge = maximum( ages )
    ageSummary = [mean( ages ), median( ages ),
        length( ages ) == 1 ? missing : std( ages ), minAge, maxAge]

    # Age binning.
    minAge = floor( minAge / ageRes ) * ageRes
    maxAge = floor( maxAge / ageRes ) * ageRes
    ageGrid = collect( minAge:ageRes:maxAge )
    counts = map( age -> count( ages .>= age ), ageGrid )
    counts -= vcat( counts[2:end], 0 )

    # Collating.
    result[:, :age] = vcat( ageGrid, ["mean", "median", "stdev", "min", "max"] )
    result[:, :counts] = vcat( counts, ageSummary )
    return result

end  # processInitPopAges( ages::Vector{Float64}, ageRes::Float64 )