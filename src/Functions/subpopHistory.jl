function summariseSubpopHistory( mpSim::ManpowerSimulation, tPoint::Real,
    subpop::Subpopulation )

    # Get the IDS of personnel in the subpopulation at time tPoint.
    subpopIDs = getSubpopAtTime( mpSim, tPoint, [ subpop ] )[ 1 ]

    if isempty( subpopIDs )
        return
    end  # if isempty( subpopIDs )

    # Get all transitions of those personnel members up to time tPoint.
    queryCmd = string( "SELECT * FROM ", mpSim.transitionDBname, "
        WHERE timeIndex <= ", tPoint, " AND id IN ( '",
        join( subpopIDs, "', '"), "' ) AND endState IS NOT 'active'
        ORDER BY timeIndex" )
    queryRes = SQLite.query( mpSim.simDB, queryCmd )

    stateInfo = generateStateSummary( queryRes, tPoint )   # DataFrame
    transInfo = generateTransitionSummary( queryRes )      # DataFrame
    pathInfo = generatePathSummary( queryRes, subpopIDs )  # Dict{Vector{String}, Int}

    return stateInfo, transInfo, pathInfo

end  # summariseSubpopHistory( mpSim, tPoint, subpop )


function generateStateSummary( queryRes::DataFrame, tPoint::Float64 )::DataFrame

    states = unique( queryRes[ :endState ] )
    stateCounts = map( state -> count( state .== queryRes[ :endState ] ),
        states )
    stateAgeRange = Array{Float64}( length( states ), 2 )

    for ii in eachindex( states )
        stateName = states[ ii ]

        # Find times of entry in the state.
        entryInds = find( stateName .== queryRes[ :endState ] )
        ids = queryRes[ entryInds, :id ]
        tEntry = queryRes[ entryInds, :timeIndex ]

        # Find times of exit out of the state.
        exitInds = find( .!isa.( queryRes[ :startState ], Missing ) .&
            ( stateName .== queryRes[ :startState ] ) )
        exitIDs = queryRes[ exitInds, :id ]
        tExit = fill( tPoint, length( ids ) )
        exitIDinds = map( jj -> findfirst( queryRes[ jj, :id ] .== ids ),
            exitInds )
        tExit[ exitIDinds ] = queryRes[ exitInds, :timeIndex ]

        stateAgeRange[ ii, : ] = collect( extrema( tExit .- tEntry ) )
    end  # for state in states

    return DataFrame( hcat( states, stateCounts, stateAgeRange ),
        [ :state, :count, :minTime, :maxTime ] )

end  # function generateStateSummary( queryRes::DataFrame )


function generateTransitionSummary( queryRes::DataFrame )::DataFrame

    trans = map( eachindex( queryRes[ :id ] ) ) do ii
        return ( queryRes[ ii, :transition ], queryRes[ ii, :startState ],
            queryRes[ ii, :endState ] )
    end
    trans = unique( trans )
    transCounts = zeros( Int, length( trans ) )
    transitions = Array{Union{Missing, String}}( length( trans ), 3 )

    for ii in eachindex( trans )
        transitions[ ii, : ] = collect( trans[ ii ] )

        if transitions[ ii, 2 ] isa Missing
            transCounts[ ii ] = count(
                ( queryRes[ :transition ] .== transitions[ ii, 1 ] ) .&
                isa.( queryRes[ :startState ], Missing ) .&
                ( queryRes[ :endState ] .== transitions[ ii, 3 ] ) )
        else
            transCounts[ ii ] = count(
                ( queryRes[ :transition ] .== transitions[ ii, 1 ] ) .&
                ( queryRes[ :startState ] .== transitions[ ii, 2 ] ) .&
                ( queryRes[ :endState ] .== transitions[ ii, 3 ] ) )
        end  # if transitions[ ii, 2 ] isa Missing
    end  # for ii in eachindex( trans )

    return DataFrame( hcat( transitions, transCounts ),
        [ :transition, :startState, :endState, :count ] )

end  # generateTransitionSummary( queryRes::DataFrame )


function generatePathSummary( queryRes::DataFrame,
    subpopIDs::Vector{String} )::Dict

    pathDict = Dict{Vector{String}, Int}()

    for id in subpopIDs
        idPath = string.( queryRes[ queryRes[ :id ] .== id, :endState ] )

        if !haskey( pathDict, idPath )
            pathDict[ idPath ] = 0
        end  # if !haskey( pathDict )

        pathDict[ idPath ] += 1
    end  # for id in subpopIDs

    return pathDict

end


function generateSubpopHistory( mpSim::ManpowerSimulation, tPoint::Real,
    subpop::Subpopulation )

    info( "Paths" )

    pathDict = Dict{Vector{String}, Int}()

    for id in subpopIDs
        idPath = string.( queryRes[ queryRes[ :id ] .== id, :endState ] )

        if !haskey( pathDict, idPath )
            pathDict[ idPath ] = 0
        end  # if !haskey( pathDict )

        pathDict[ idPath ] += 1
    end  # for id in subpopIDs

    for idPath in keys( pathDict )
        println( idPath, ": ", pathDict[ idPath ] )
    end

    println( length( pathDict ), " different path(s)" )

    busyPath = first( keys( pathDict ) )
    longPath = first( keys( pathDict ) )

    for idPath in keys( pathDict )
        if pathDict[ idPath ] > pathDict[ busyPath ]
            busyPath = idPath
        end  # if pathDic[ idPath ] > pathDic[ busyPath ]

        if length( pathDict[ idPath ] ) > length( pathDict[ longPath ] )
            longPath = idPath
        end  # if length( pathDict[ idPath ] ) > length( pathDict[ longPath ] )
    end  # for idPath in keys( pathDic )

    if length( busyPath ) == length( longPath )
        longPath = busyPath
    end  # if length( busyPath ) == length( longPath )

    println( "Principal path is ", busyPath )
    println( "Longest path is ", longPath )

    return

end  # generateSubpopHistory( mpSim, tPoint, subpop )


include( "subpopHistoryPlots.jl" )


cond1 = MP.processCondition( "had transition", "IS", "Spec" )[ 1 ]
cond2 = MP.processCondition( "had transition", "NOT IN", "Spec" )[ 1 ]
cond3 = MP.processCondition( "started as", "IS", "Trainee" )[ 1 ]
cond4 = MP.processCondition( "was", "IS NOT", "Senior B" )[ 1 ]
cond5 = MP.processCondition( "tenure", ">=", 20 )[ 1 ]
cond6 = MP.processCondition( "gender", "IS", "F" )[ 1 ]
cond7 = MP.processCondition( "tenure", "<=", 20 )[ 1 ]

subpop1 = Subpopulation( "SP1", "Master A" )
addCondition!( subpop1, cond5, cond6 )
subpop2 = Subpopulation( "SP2", "Master Spec" )
addCondition!( subpop2, cond1, cond5, cond6 )
subpop3 = Subpopulation( "SP3", "Master Spec" )
addCondition!( subpop3, cond5, cond2, cond6 )
subpop4 = Subpopulation( "SP4", "Master A" )
addCondition!( subpop4, cond5, cond3, cond6 )
subpop5 = Subpopulation( "SP5", "Master Spec" )
addCondition!( subpop5, cond4, cond5, cond6 )
subpop6 = Subpopulation( "SP6", "Master Spec" )
addCondition!( subpop6, cond4, cond5, cond3, cond6 )
subpop7 = Subpopulation( "SP7", "Senior A" )
addCondition!( subpop7, cond6 )

tPoint = 480.0
subpops = [ subpop1, subpop2, subpop3, subpop4, subpop5, subpop6, subpop7 ]

#=
for subpop in subpops
    plotSubpopHistory( mpSim, tPoint, subpop )
    println()
end
=#
plotSubpopHistory( mpSim, tPoint, subpop1 )
