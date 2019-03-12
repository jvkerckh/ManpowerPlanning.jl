# This file holds all the functions that are needed to create population flux
#   plots from the simulation results database.

export  plotTransitionMap


"""
```
plotTransitionMap( mpSim::ManpowerSimulation,
                   isShow::Bool,
                   isSave::Bool,
                   isGraphML::Bool,
                   states::String...;
                   fileName::String = "" )
```
This function returns `nothing`.
"""
function plotTransitionMap( mpSim::ManpowerSimulation, isShow::Bool,
    saveType::Symbol, isGraphML::Bool, states::String...;
    fileName::String = "" )::Void

    # Check if the state map has to be displayed or saved.
    if !any( [ isShow, saveType !== :none, isGraphML ] )
        return
    end  # if !any( [ isShow, ...

    # Generate the state map.
    graph, inNodeIndex, outNodeIndex = buildTransitionNetwork( mpSim,
        states... )
    graphPlot = gplot( graph,
        nodelabel = map( node -> get_prop( graph, node, :node ),
        vertices( graph ) ),
        edgelabel = map( edge -> get_prop( graph, edge, :trans ),
        edges( graph ) ) )

    # Show the plot if requested.
    if isShow
        display( graphPlot )
    end  # if isShow

    # Generate proper file names.
    tmpFileName = fileName == "" ? "networkPlot" : fileName
    tmpFileName = joinpath( mpSim.parFileName[ 1:(end-5) ], tmpFileName )

    # Save the graph as SVG if requested.
    if saveType !== :none
        sType = sTypes[ saveType ][ 2 ]
        sFun = sTypes[ saveType ][ 1 ]
        tmpSaveName = string( tmpFileName, endswith( tmpFileName, sType ) ?
            "" : sType )
        draw( sFun( tmpSaveName, 20cm, 20cm ), graphPlot )
    end  # if saveType !== :none

    # Generate the graphml file if requested.
    if !isGraphML
        return
    end  # if !isGraphML

    # Save the structure of the network.
    tmpGraphMLname = string( tmpFileName, endswith( tmpFileName, ".graphml" ) ?
        "" : ".graphml" )
    savegraph( tmpGraphMLname, graph, GraphMLFormat(); compress = false )

    # Grab it for editing.
    xmlGraph = readxml( tmpGraphMLname )
    graphRoot = root( xmlGraph )  # on Julia 0.6

    # Set link to yEd elements.
    graphRoot[ "xmlns:y" ] = "http://www.yworks.com/xml/graphml"
    # graphRoot = xmlGraph.root  # on Julia 0.7+

    # Add required keys for processing.
    key = ElementNode( "key" )
    key[ "for" ] = "node"
    key[ "id" ] = "d6"
    key[ "yfiles.type" ] = "nodegraphics"
    link!( graphRoot, key )
    key = ElementNode( "key" )
    key[ "for" ] = "edge"
    key[ "id" ] = "d10"
    key[ "yfiles.type" ] = "edgegraphics"
    link!( graphRoot, key )

    # Grab the contents of the graph.
    graphDef = elements( graphRoot )[ 1 ]
    graphElements = elements( graphDef )
    nElements = length( graphElements )
    nNodes = 0
    nEdges = 0
    nodeList = collect( vertices( graph ) )
    edgeList = collect( edges( graph ) )

    for ii in 1:nElements
        elementData = ElementNode( "data" )
        isNode = nodename( graphElements[ ii ] ) == "node"
        nNodes += isNode ? 1 : 0
        nEdges += isNode ? 0 : 1
        elementData[ "key" ] = isNode ? "d6" : "d10"
        elementForm = ElementNode( "y:" *
            ( isNode ? "ShapeNode" : "PolyEdgeLine" ) )
        elementLabelText = isNode ?
            get_prop( graph, nodeList[ nNodes ], :node ) :
            get_prop( graph, edgeList[ nEdges ], :trans )
        elementLabel = ElementNode( "y:" * ( isNode ? "Node" : "Edge" ) *
            "Label" )
        setnodecontent!( elementLabel, elementLabelText )
        elementShape = ElementNode( "y:" * ( isNode ? "Shape" : "Arrows" ) )

        if isNode
            elementShape[ "type" ] = elementLabelText ∈ states ? "ellipse" :
                "roundrectangle"
            elementGeometry = ElementNode( "y:Geometry" )
            elementGeometry[ "height" ] = nodeList[ nNodes ] ∈ [ inNodeIndex,
                outNodeIndex ] ? 80.0 : 40.0
            elementGeometry[ "width" ] = elementGeometry[ "height" ]
            link!( elementForm, elementGeometry )
        else
            elementShape[ "source" ] = "none"
            elementShape[ "target" ] = "standard"
        end  # if isNode

        link!( elementForm, elementLabel )
        link!( elementForm, elementShape )
        link!( elementData, elementForm )
        link!( graphElements[ ii ], elementData )
    end  # for ii in 1:nElements

    write( tmpGraphMLname, xmlGraph )

    return

end  # plotTransitionMap( mpSim, isShow, saveType, isGraphML, states...,
     #   fileName )


"""
```
plotTransitionMap( mpSim::ManpowerSimulation,
                   fileName::String )
```
This function plots a transition map of the manpower simulation `mpSim` with the
nodes requested in the Excel sheet `State Map` of the file with name `fileName`.
If the file name doesn't end in `.xlsx`, it will be added automatically.

This function returns `nothing`.
"""
function plotTransitionMap( mpSim::ManpowerSimulation, fileName::String )::Void

    tmpFileName = endswith( fileName, ".xlsx" ) ? fileName : fileName * ".xlsx"

    if !ispath( tmpFileName )
        warn( "'$tmpFileName' is not a valid file. Can't create network plot." )
        return
    end  # if !ispath( tmpFileName )

    XLSX.openxlsx( tmpFileName ) do xf
        # Check if file has the proper sheet.
        if !XLSX.hassheet( xf, "State Map" )
            warn( "File does not have a sheet 'State Map'. Can't create network plot." )
            return
        end  # if XLSX.hassheet( xf, "State Map" )

        plotTransitionMap( mpSim, xf[ "State Map"] )
    end  # XLSX.openxlsx( tmpFileName ) do xf

    return

end  # plotTransitionMap( mpSim::ManpowerSimulation, fileName::String )


"""
```
plotTransitionMap( mpSim::ManpowerSimulation,
                   sheet::XLSX.Worksheet )
```
This function plots a transition map of the manpower simulation `mpSim` with the
nodes requested in the Excel sheet `sheet`.

This function returns `nothing`.
"""
function plotTransitionMap( mpSim::ManpowerSimulation,
    sheet::XLSX.Worksheet )::Void

    numNodes = Int( sheet[ "B9" ] )

    if numNodes == 0
        warn( "No nodes/states to plot listed, can't generate network plot." )
        return
    end  # if numNodes == 0

    fileName = sheet[ "B6" ]
    fileName = fileName isa Missing ? "" : string( fileName )
    nodeList = string.( sheet[ XLSX.CellRange( 11, 2, 10 + numNodes, 2 ) ] )

    if !isempty( nodeList )
        plotTransitionMap( mpSim, sheet[ "B3" ] == "YES",
            Symbol( sheet[ "B4" ] ), sheet[ "B5" ] == "YES", nodeList...,
            fileName = fileName )
    end  # if !isempty( nodeList )

    return

end  # plotTransitionMap( mpSim, sheet )
