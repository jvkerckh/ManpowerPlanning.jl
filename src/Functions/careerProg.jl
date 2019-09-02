function plotCareerProgression( mpSim::ManpowerSimulation, isShow::Bool,
    isSave::Bool, idList::String...; timeFactor::Real = 12,
    isByAge::Bool = false )::Void

    progReport = generateCareerProgression( mpSim, idList... )
    plt = plot( xlim = [ 0, mpSim.simLength / timeFactor * 1.01 ],
        size = ( 960, 540 ), xlabel = isByAge ? "age" : "Sim time",
        ylabel = "node" )
    xMin, xMax = typemin( Float64 ), typemax( Float64 )

    for id in keys( progReport )
        report = progReport[ id ][ 1 ]
        tmpT = sort( collect( keys( report ) ) )

        lastEntry = report[ tmpT[ end ]]
        tPoints = repeat( tmpT[ 1:(end - ( lastEntry[ 2 ] == "OUT" ? 1 : 0 )) ],
            inner = 2 )
        tmpNodes = get.( report, tPoints, nothing )
        tPoints[ 2:2:end ] = lastEntry[ 2 ] == "OUT" ? tmpT[ 2:end ] :
            vcat( tmpT[ 2:end ], mpSim.simLength )

        if isByAge
            tPoints -= tPoints[ 1 ] - progReport[ id ][ 2 ]
            xMin = min( xMin, tPoints[ 1 ] ) / timeFactor
            xMax = max( xMax, tPoints[ end ] ) / timeFactor
        end  # if isByAge

        tPoints /= timeFactor
        lbl = string( "Career of ", id, " (", lastEntry[ 2 ] == "OUT" ?
            lastEntry[ 1 ] : "active", ")" )
        tmpNodes = map( node -> node[ 2 ], tmpNodes )
        plt = plot!( tPoints, tmpNodes, lw = 2, label = lbl,
            hover = repeat( [ id ], length( tmpNodes ) ) )
    end  # for id in progReport

    if isByAge
        plt = plot!( xlim = [ floor( xMin ), ceil( xMax ) ] )
    end  # if isByAge

    if isShow
        gui( plt )
    end  # if isShow

    return

end  # plotCareerProgression( mpSim, isShow, isSave, idList, timeFactor )


function generateCareerProgression( mpSim::ManpowerSimulation,
    idList::String... )::Dict{String, Tuple{Dict{Float64, Tuple}, Float64}}

    # First, find which of these IDs are actually in the simulation.
    queryCmd = string( "SELECT `", mpSim.idKey, "`, ageAtRecruitment FROM `",
        mpSim.personnelDBname, "`
        WHERE `", mpSim.idKey, "` IN ( '", join( idList, "', '" ),
        "' )" )
    validIDs = SQLite.query( mpSim.simDB, queryCmd )

    # Generate the career progressions.
    queryCmd = string( "SELECT * FROM `", mpSim.transitionDBname, "`
        WHERE `", mpSim.idKey, "` IN ( '", join( validIDs[ 1 ], "', '" ), "' )
        GROUP BY timeIndex, `", mpSim.idKey, "`
        ORDER BY `", mpSim.idKey, "`, timeIndex" )
    sqLiteOut = SQLite.query( mpSim.simDB, queryCmd )

    careerProgs = Dict{String, Tuple{Dict{Float64, Tuple{String, String}},
        Float64}}()

    for jj in eachindex( validIDs[ 1 ] )
        id = validIDs[ jj, 1 ]
        sqLiteSnip = sqLiteOut[ sqLiteOut[ 1 ] .== id, : ]
        careerProg = Dict{Float64, Tuple{String, String}}()

        for ii in eachindex( sqLiteSnip[ 1 ] )
            targetNode = sqLiteSnip[ ii, :endState ]
            targetNode = sqLiteSnip[ ii, :endState ] isa Missing ? "OUT" :
                targetNode
            careerProg[ sqLiteSnip[ ii, :timeIndex ] ] = (
                sqLiteSnip[ ii, :transition ], targetNode )
        end  # for ii in eachindex( sqLiteOut[ 1 ] )

        careerProgs[ id ] = ( careerProg, validIDs[ jj, :ageAtRecruitment ] )
    end  # for id in tmpIDlist

    return careerProgs

end  # generateCareerProgression( mpSim, idList )
