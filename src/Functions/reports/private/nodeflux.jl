const fluxTypes = [ :in, :out, :within ]


function generateNodeFluxReport( mpSim::MPsim, timeGrid::Vector{Float64},
    fluxType::Symbol, node::String )

    if lowercase( node ) == "active"
        return generatePopFluxReport( mpSim, timeGrid, fluxType )
    elseif haskey( mpSim.baseNodeList, node )
        return generateBaseNodeFluxReport( mpSim, timeGrid, fluxType, node )
    else
        return generateCompoundNodeFluxReport( mpSim, timeGrid, fluxType, node )
    end  # if lowercase( node ) == "active"

end  # generateNodeFluxReport( mpSim, timeGrid, fluxType, node )


function generatePopFluxReport( mpSim::MPsim, timeGrid::Vector{Float64},
    fluxType::Symbol )

    queryPartCmd = string( "SELECT *, count( `", mpSim.idKey,
        "` ) counts FROM `", mpSim.transDBname, "` WHERE" )

    # ! Change startState and endState to sourceNode and targetNode, and remove the IS NOT 'active' clause.
    # Construct (part of) the query.
    if fluxType === :in
        queryPartCmd = string( queryPartCmd, "\n    startState IS NULL AND",
            "\n    endState IS NOT NULL AND",
            "\n    endState IS NOT 'active'" )
    elseif fluxType === :out
        queryPartCmd = string( queryPartCmd, "\n    startState IS NOT NULL AND",
            "\n    endState IS NULL AND",
            "\n    startState IS NOT 'active'" )
    else
        queryPartCmd = string( queryPartCmd, "\n    startState IS NOT NULL AND",
            "\n    endState IS NOT NULL AND ",
            "\n    startState IS NOT endState" )
    end  # if fluxType === :in

    countDict = determineTransitionTypes( mpSim, queryPartCmd,
        length( timeGrid ) )
    performFluxCounts( mpSim, queryPartCmd, timeGrid, countDict )
    results, names = putFluxResultsInArray( mpSim, countDict,
        length( timeGrid ) )

    # Final touches.
    if fluxType === :in
        names = vcat( "external => active", names )
    elseif fluxType === :out
        names = vcat( "active => external", names )
    else
        names = vcat( "within active", names )
    end  # if fluxType === :in

    names = vcat( "timeStart", "timePoint", names )

    return DataFrame( hcat( vcat( 0.0, timeGrid[ 1:(end - 1) ] ), timeGrid,
        results ), Symbol.( names ) )

end  # generatePopFluxReport( mpSim, timeGrid, fluxType )


function generateBaseNodeFluxReport( mpSim::MPsim, timeGrid::Vector{Float64},
    fluxType::Symbol, node::String )

    queryPartCmd = string( "SELECT *, count( `", mpSim.idKey,
        "` ) counts FROM `", mpSim.transDBname, "` WHERE" )

    # ! Change startState and endState to sourceNode and targetNode, and remove the IS NOT 'active' clause.
    # Construct (part of) the query.
    if fluxType === :in
        queryPartCmd = string( queryPartCmd,
            "\n    startState IS NOT '", node, "' AND",
            "\n    endState IS '", node, "'" )
    else
        queryPartCmd = string( queryPartCmd,
            "\n    startState IS '", node, "' AND",
            "\n    endState IS NOT '", node, "'" )
    end  # if fluxType === :in

    countDict = determineTransitionTypes( mpSim, queryPartCmd,
        length( timeGrid ) )
    performFluxCounts( mpSim, queryPartCmd, timeGrid, countDict )
    results, names = putFluxResultsInArray( mpSim, countDict,
        length( timeGrid ) )

    # Final touches.
    if fluxType === :in
        names = vcat( string( "other => ", node ), names )
    else
        names = vcat( string( node, " => other" ), names )
    end  # if fluxType === :in

    names = vcat( "timeStart", "timePoint", names )

    return DataFrame( hcat( vcat( 0.0, timeGrid[ 1:(end - 1) ] ), timeGrid,
        results ), Symbol.( names ) )

end  # generateBaseNodeFluxReport( mpSim, timeGrid, fluxType, node )


function generateCompoundNodeFluxReport( mpSim::MPsim,
    timeGrid::Vector{Float64}, fluxType::Symbol, node::String )

    queryPartCmd = string( "SELECT *, count( `", mpSim.idKey,
        "` ) counts FROM `", mpSim.transDBname, "` WHERE" )
    
    compoundNode = mpSim.compoundNodeList[ node ]
    nodeList = compoundNode.baseNodeList
    names = Vector{String}()
    results = zeros( Int, length( timeGrid ) )

    if !isempty( nodeList )
        # ! Change startState and endState to sourceNode and targetNode, and remove the IS NOT 'active' clause.
        if fluxType === :in
            # The clause "OR startState IS NULL" is needed because the SQL
            # statement "field NOT IN (values)" gives FALSE for missing values.
            queryPartCmd = string( queryPartCmd,
                "\n    (startState NOT IN ('", join( nodeList, "', '" ),
                "') OR startState IS NULL) AND",
                "\n    endState IN ('", join( nodeList, "', '" ), "')" )
        elseif fluxType === :out
            queryPartCmd = string( queryPartCmd,
                "\n    startState IN ('", join( nodeList, "', '" ), "') AND",
                "\n    (endState NOT IN ('", join( nodeList, "', '" ),
                "') OR endState IS NULL)" )
        else
            queryPartCmd = string( queryPartCmd,
                "\n    startState IN ('", join( nodeList, "', '" ), "') AND",
                "\n    endState IN ('", join( nodeList, "', '" ), "') AND",
                "\n    startState IS NOT endState" )
        end  # if fluxType === :in    

        countDict = determineTransitionTypes( mpSim, queryPartCmd,
            length( timeGrid ) )
        performFluxCounts( mpSim, queryPartCmd, timeGrid, countDict )
        results, names = putFluxResultsInArray( mpSim, countDict,
            length( timeGrid ) )
    end  # if !isempty( nodeList )

    # Final touches.
    if fluxType === :in
        names = vcat( string( "other => ", node ), names )
    elseif fluxType === :out
        names = vcat( string( node, " => other" ), names )
    else
        names = vcat( string( "within ", node ), names )
    end  # if fluxType === :in

    names = vcat( "timeStart", "timePoint", names )
    
    return DataFrame( hcat( vcat( 0.0, timeGrid[ 1:(end - 1) ] ), timeGrid,
        results ), Symbol.( names ) )

end  # generateCompoundNodeFluxReport( mpSim, timeGrid, fluxType, node )


function determineTransitionTypes( mpSim::MPsim, queryCmd::String,
    nTimePoints::Int )

    # Determine transition types.
    result = DataFrame( SQLite.Query( mpSim.simDB, string( queryCmd,
        "\n   GROUP BY transition, startState, endState" ) ) )
    countDict = Dict{Tuple, Vector{Int}}()

    for ii in eachindex( result[ :, :transition ] )
        countDict[ (result[ ii, :transition ], result[ ii, :startState ],
            result[ ii, :endState ]) ] = zeros( Int, nTimePoints )
    end  # for ii in eachindex( result[ :transition ] )

    return countDict

end  # determineTransitionTypes( mpSim, queryCmd, nTimePoints )


function performFluxCounts( mpSim::MPsim, queryPartCmd::String, timeGrid::Vector{Float64}, countDict::Dict{Tuple, Vector{Int}} )

    queryPartCmd = string( queryPartCmd, " AND\n    " )

    for ii in eachindex( timeGrid )
        queryCmd = string( queryPartCmd, generateTimeFork( ii == 1 ?
            timeGrid[ 1 ] : timeGrid[ ii - 1 ], timeGrid[ ii ] ) )

        queryCmd = string( queryCmd,
            "\n   GROUP BY transition, startState, endState" )
        result = DataFrame( SQLite.Query( mpSim.simDB, queryCmd ) )

        for jj in eachindex( result[ :, :transition ] )
            countDict[ (result[ jj, :transition ], result[ jj, :startState ],
                result[ jj, :endState ]) ][ ii ] = result[ jj, :counts ]
        end  # for jj in eachindex( result[ :transition ] )
    end  # for ii in eachindex( timeGrid )

end  # performFluxCounts( mpSim, queryPartCmd, timeGrid, countDict )


function putFluxResultsInArray( mpSim::MPsim,
    countDict::Dict{Tuple, Vector{Int}}, nTimePoints::Int )

    dictNames = collect( keys( countDict ) )
    results = zeros( Int, nTimePoints, length( dictNames ) )
    names = Vector{String}( undef, length( dictNames ) )

    for ii in eachindex( dictNames )
        results[ :, ii ] = countDict[ dictNames[ ii ] ]
        transitionName = dictNames[ ii ][ 1 ]
        sourceNode = dictNames[ ii ][ 2 ] isa Missing ? "external" :
            dictNames[ ii ][ 2 ]
        targetNode = dictNames[ ii ][ 3 ] isa Missing ? "external" :
            dictNames[ ii ][ 3 ]
        names[ ii ] = string( transitionName, ": ", sourceNode, " => ",
            targetNode )
    end  # for ii in eachindex( dictNames )

    results = hcat( sum( results, dims = 2 ), results )
    return results, names

end