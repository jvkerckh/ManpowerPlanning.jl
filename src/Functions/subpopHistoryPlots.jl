function plotSubpopHistory( mpSim::ManpowerSimulation, tPoint::Real,
    subpop::Subpopulation )::Void

    plotName = mpSim.parFileName[ 1:(end - 5) ]
    plotName = joinpath( plotName, "subpop histories",
        string( subpop.name, " (sim time ", tPoint, ").svg" ) )
    plotSubpopHistory( mpSim, tPoint, subpop, plotName )
    return

end  # plotSubpopHistory( mpSim, tPoint, subpop )


function plotSubpopHistory( mpSim::ManpowerSimulation, tPoint::Real,
    subpop::Subpopulation, plotName::String )::Void

    nodeInfo, transInfo, pathInfo = summariseSubpopHistory( mpSim, tPoint,
        subpop )

    info( "Nodes" )
    println( nodeInfo )
    info( "Transitions" )
    println( transInfo )
    info( "Paths" )
    println( pathInfo )

    grf = generateHistoryGraph( nodeInfo, transInfo )
    info( grf )
    println( "Edges: ", join( collect( edges( grf ) ), "; " ) )

    doubleEdges, flippedEdges = removeCycles!( grf )
    info( doubleEdges, " -- ", flippedEdges )
    println( "Edges: ", join( collect( edges( grf ) ), "; " ) )

    dgrf = generateRanks( grf )
    println( "Ranks of nodes: ", get_prop.( dgrf, vertices( grf ), :rank ) )
    dNodes = length( vertices( dgrf ) ) - length( vertices( grf ) )
    println( "Dummy nodes: ", dNodes )

    if dNodes > 0
        println( "Ranks of dummy nodes: ", get_prop.( dgrf,
            length( vertices( grf ) ) + (1:dNodes), :rank ) )
    end

    #=
    # Find the main history path(s).
    paths = collect( keys( pathInfo ) )
    mainPath = paths[ 1 ]

    for histPath in paths[ 2:end ]
        if pathInfo[ histPath ] > pathInfo[ mainPath ]
            mainPath = histPath
        end  # if pathInfo[ histPath ] > pathInfo[ mainPath ]
    end  # for histPath in paths[ 2:end ]

    deleteat!( paths,
        findfirst( map( histPath -> histPath == mainPath, paths ) ) )

    # Arrange the states on a grid.
    nodes = nodeInfo[ :state ]
    nodePos = Dict{String, Tuple{Float64, Float64}}()
    posH = 0
    posV = 0

    for node in mainPath
        nodePos[ node ] = ( posH, posV )
        deleteat!( nodes, findfirst( node .== nodes ) )
        posH += 2
    end  # for node in mainPath

    hSpread = posH
    vSpread = 1

    while !isempty( nodes )
        pathDiffs = zeros( Int, length( paths ) )

        for ii in eachindex( paths )
            histPath = paths[ ii ]
            pathDiffs[ ii ] = count( map( node -> node ∈ nodes, histPath ) )
        end  # for ii in eachindex( paths )

        diffPath = paths[ findmax( pathDiffs )[ 2 ] ]
        deleteat!( paths,
            findfirst( map( histPath -> histPath == diffPath, paths ) ) )
        posV = - posV + ( posV > 0 ? 0 : 1 )
        posH = isodd( posV ) ? 1 : 0

        for node in diffPath
            if !haskey( nodePos, node )
                nodePos[ node ] = ( posH, posV )
                deleteat!( nodes, findfirst( node .== nodes ) )
            end  # if !haskey( nodePos, node )

            posH += 2
        end  # for node in diffPath

        hSpread = max( posH, hSpread )
        vSpread += 1
    end  # while !isempty( nodes )

    if !ispath( dirname( plotName ) )
        mkpath( dirname( plotName ) )
    end  # if !ispath( dirname( plotName ) )

    Drawing( ( hSpread * 4 )Luxor.cm, ( vSpread * 4 )Luxor.cm, :svg, plotName )
    background( "white" )
    origin()
    setline( 0.8mm )
    sethue( "black" )

    for node in keys( nodePos )
        hCentre = 4 * ( nodePos[ node ][ 1 ] ) - 2 * ( hSpread - 2 )
        vCentre = 4 * ( nodePos[ node ][ 2 ] ) - 2 * ( vSpread - 1 )
        box( (hCentre)Luxor.cm, (vCentre)Luxor.cm, 4cm, 2cm, :stroke )
        fontsize( 14 )
        Luxor.text( node, (hCentre)Luxor.cm, (vCentre)Luxor.cm,
            halign = :center )
        fontsize( 10 )
        vCentre += 0.9
        hCentre -= 1.9
        Luxor.text( "#", (hCentre)Luxor.cm, (vCentre)Luxor.cm,
            halign = :left )
        hCentre += 3.8
        Luxor.text( "time", (hCentre)Luxor.cm, (vCentre)Luxor.cm,
            halign = :right )
    end

    finish()
    =#

    return

end  # plotSubpopHistory( mpSim, tPoint, subpop, plotName )


function generateHistoryGraph( nodeInfo::DataFrame,
    transInfo::DataFrame )::SimpleDiGraph

    nodeList = nodeInfo[ :state ]
    grf = SimpleDiGraph( length( nodeList ) + 1 )

    for ii in eachindex( transInfo[ :transition ] )
        startNode = transInfo[ ii, :startState ]
        startNode = startNode isa Missing ? length( nodeList ) + 1 :
            findfirst( startNode .== nodeList )
        endNode = findfirst( transInfo[ ii, :endState ] .== nodeList )
        add_edge!( grf, startNode, endNode )
    end  # for ii in eachindex( transInfo[ :transition ] )

    return grf

end  # generateHistoryGraph( nodeInfo, transInfo )


include( "hierarchicalGraphPlot.jl" )
