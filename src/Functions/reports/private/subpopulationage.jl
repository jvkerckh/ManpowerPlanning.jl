function getAgesAtTime( mpSim::MPsim, timePoint::Float64, subpopulations::Vector{Subpopulation}, ageType::Symbol )

    # Get the ids in each subpopulation at the time point.
    result = Vector{Vector{Float64}}( undef, length( subpopulations ) )
    idsInSubpop = getSubpopulationAtTime( mpSim, timePoint, subpopulations )

    # ! No longer necessary after overhaul.
    if ageType === :timeInNode
        queryPrefix = string( "SELECT ", timePoint,
            " - max( timeIndex ) `time in node` FROM `", mpSim.transDBname,
            "` WHERE",
            "\n    timeIndex <= ", timePoint, " AND ",
            "\n    `", mpSim.idKey, "` IN ( '" )
        querySuffix = string( "' )",
            "\n    GROUP BY `", mpSim.idKey, "`" )

        for ii in eachindex( subpopulations )
            if isempty( idsInSubpop[ii] )
                result[ii] = Vector{Float64}()
            else
                queryCmd = string( queryPrefix, join( idsInSubpop[ii],
                    "', '" ), querySuffix )
                result[ii] = DataFrame( DBInterface.execute( mpSim.simDB,
                    queryCmd ) )[:, 1]
            end  # if isempty( idsInSubpop )[ii]
        end  # for ii in eachindex( subpopulations )

        return result
    end  # if ageType === :timeInNode

    queryCmdTmp = string( "SELECT ", timePoint, " - timeEntered",
        ageType === :age ? " + ageAtRecruitment age" : " tenure",
        " FROM `", mpSim.persDBname, "` WHERE ",
        "\n    `", mpSim.idKey, "` IN ( '" )
    
    for ii in eachindex( subpopulations )
        if isempty( idsInSubpop[ii] )
            result[ii] = Vector{Float64}()
        else
            queryCmd = string( queryCmdTmp, join( idsInSubpop[ii], "', '" ),
                "' )" )
            result[ii] = DataFrame( DBInterface.execute( mpSim.simDB,
                queryCmd ) )[:, 1]
        end  # if isempty( idsInSubpop )[ii]
    end  # for ii in eachindex( subpopulations )

    return result
    
end  # getAgesAtTime( mpSim, timePoint, subpopulationulations, ageType )


function processSubpopulationAges( personnelAges::Array{Vector{Float64}, 2},
    subpopulations::Vector{Subpopulation}, timeGrid::Vector{Float64},
    ageRes::Float64 )

    result = Dict{String, DataFrame}()
    baseNames = [:timePoint, :mean, :median, :stdev, :min, :max]

    for ii in eachindex( subpopulations )
        subpopName = subpopulations[ii].name
        agesOfSubpop = personnelAges[ii, :]
        ageSummary = zeros( Union{Float64, Missing}, length( timeGrid ), 6 )
        ageSummary[:, 1] = timeGrid
        emptySubpop = isempty.( agesOfSubpop )

        if all( emptySubpop )
            ageSummary[:, 2:end] .= missing
            result[subpopName] = DataFrame( ageSummary, baseNames )
        else
            minAge = minimum( minimum.( agesOfSubpop[.!emptySubpop] ) )
            minAge = floor( minAge / ageRes ) * ageRes
            maxAge = maximum( maximum.( agesOfSubpop[.!emptySubpop] ) )
            maxAge = floor( maxAge / ageRes ) * ageRes
            ageGrid = collect( minAge:ageRes:maxAge )

            counts = zeros( Int, length( timeGrid ), length( ageGrid ) )

            for jj in eachindex( timeGrid )
                subpopAgesAtTime = agesOfSubpop[jj]

                if isempty( subpopAgesAtTime )
                    ageSummary[jj, 2:6] .= missing
                else
                    ageSummary[jj, 2:6] = [mean( subpopAgesAtTime ),
                        median( subpopAgesAtTime ),
                        length( subpopAgesAtTime ) == 1 ? missing :
                            std( subpopAgesAtTime ),
                        minimum( subpopAgesAtTime ),
                        maximum( subpopAgesAtTime )]
                end  # if isempty( subpopAgesAtTime )

                tmpCounts = map( age -> count( subpopAgesAtTime .>= age ),
                    ageGrid )
                tmpCounts -= vcat( tmpCounts[2:end], 0 )
                counts[jj, :] = tmpCounts
            end  # for jj in eachindex( timeGrid )

            result[subpopName] = DataFrame( hcat( ageSummary, counts ),
                vcat( baseNames, Symbol.( ageGrid ) ) )
        end  # if all( emptySubpop )
    end  # for ii in eachindex( subpopulations )

    return result

end  # processSubpopulationAges( personnelAges,subpopulations, timeGrid,
     #   ageRes )