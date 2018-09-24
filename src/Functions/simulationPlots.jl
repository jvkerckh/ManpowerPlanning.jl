# This file holds all the functions related to plotting simulation results.

export showPlotsFromFile,
       showFluxPlotsFromFile,
       plotSimulationResults,
       plotFluxResults,
       plotTransitionMap


"""
```
showPlotsFromFile( mpSim::ManpowerSimulation,
                   fName::String )
```
This function generates all the plots for manpower simulation `mpSim` that are
requested in the Excel file with name `fName`. If the simulation hasn't started
yet, the function will generate a warning to that effect, and will not create
the plots.

This function returns `nothing`.
"""
function showPlotsFromFile( mpSim::ManpowerSimulation, fName::String )::Void

    if now( mpSim ) == 0
        warn( "Simulation hasn't started yet. Can't create plots." )
        return
    end  # if now( mpSim ) == 0

    tmpFilename = fName * ( endswith( fName, ".xlsx" ) ? "" : ".xlsx" )

    XLSX.openxlsx( tmpFilename ) do xf
        if !XLSX.hassheet( xf, "Output plots" )
            warn( "Excel file doesn't have sheet 'Output plots'. Can't create plots." )
            return
        end  # if !hassheet( xf, "Outpot plots" )

        sheet = xf[ "Output plots" ]

        if sheet[ "B5" ] == "YES"
            readPlotInfoFromFile( mpSim, sheet, 2, "active" )
        end  # if sheet[ "B5" ] == "YES"

        nExtraPlots = sheet[ "D3" ]

        for colNum in (1:nExtraPlots) + 3
            state = sheet[ XLSX.CellRef( 5, colNum ) ]
            state = isa( state, Missings.Missing ) || ( state == "" ) ?
                "active" : state
            readPlotInfoFromFile( mpSim, sheet, colNum, state )
        end
    end  # XLSX.openxlsx( tmpFilename ) do xf

    return

end  # showPlotsFromFile( mpSim, fName )


"""
```
showPlotsFromFile( mpSim::ManpowerSimulation,
                   fName::String )
```
This function generates all the flux plots for manpower simulation `mpSim` that
are requested in the tab `Output plots (trans)` of the Excel file with name
`fName`. If the simulation hasn't started yet, the function will generate a
warning to that effect, and will not create the plots.

This function returns `nothing`.
"""
function showFluxPlotsFromFile( mpSim::ManpowerSimulation,
    fileName::String )::Void

    if now( mpSim ) == 0
        warn( "Simulation hasn't started yet. Can't create plots." )
        return
    end  # if now( mpSim ) == 0

    tmpFileName = endswith( fileName, ".xlsx" ) ? fileName : fileName * ".xlsx"

    if !ispath( tmpFileName )
        warn( "'$tmpFileName' is not a valid file. Can't create flux plots." )
        return
    end  # if !ispath( tmpFilename )

    XLSX.openxlsx( tmpFileName ) do xf
        if !XLSX.hassheet( xf, "Output plots (trans)" )
            warn( "Excel file has no sheet 'Output plots (trans)'. Can't create flux plots." )
            return
        end  # if !XLSX.hassheet( xf, "Output plots (trans)" )

        # Get the general info.
        plotSheet = xf[ "Output plots (trans)" ]
        showPlots = plotSheet[ "B3" ] == "YES"
        reportFileName = plotSheet[ "B4" ] == "YES" ? plotSheet[ "B5" ] : ""
        reportFileName = isa( reportFileName, Missings.Missing ) ? "" :
            reportFileName
        nPlots = plotSheet[ "B8" ]
        plotList = Dict{Float64, Vector{Union{String, Tuple{String, String}}}}()

        # Get all requested transitions and time resolutions.
        for ii in 1:nPlots
            jj = ii + 10
            isST = plotSheet[ "A$jj" ] == "YES"
            timeRes = Float64( plotSheet[ "E$jj" ] )

            # Add time resolution to list.
            if !haskey( plotList, timeRes )
                plotList[ timeRes ] = Vector{Union{String, Tuple{String, String}}}()
            end  # if !haskey( plotList, timeRes )

            if isST
                sourceName = plotSheet[ "C$jj" ]
                targetName = plotSheet[ "D$jj" ]
                sourceName = isa( sourceName, Missings.Missing ) ? "" :
                    string( sourceName )
                targetName = isa( targetName, Missings.Missing ) ? "" :
                    string( targetName )
                push!( plotList[ timeRes ], ( sourceName, targetName ) )
            else
                transName = plotSheet[ "B$jj" ]

                if isa( transName, String )
                    push!( plotList[ timeRes ], transName )
                end  # if isa( transName, String )
            end  # if isST
        end  # for ii in 1:nPlots

        overWrite = true

        # Make the plots.
        if showPlots
            for timeRes in keys( plotList )
                plotFluxResults( mpSim, timeRes, plotList[ timeRes ]...,
                    fileName = reportFileName, overWrite = overWrite )
                overWrite = false
            end  # for timeRes in keys( plotList )
        elseif reportFileName != ""
            for timeRes in keys( plotList )
                generateExcelFluxReport( mpSim, timeRes, plotList[ timeRes ]...,
                    fileName = reportFileName, overWrite = overWrite )
                overWrite = false
            end  # for timeRes in keys( plotList )
        end  # if showPlots
    end  # XLSX.openxlsx( tmpFileName ) do xf

    return

end  # showFluxPlotsFromFile( mpSim, fileName )


"""
```
plot( mpSim::ManpowerSimulation,
      timeRes::T1,
      toShow::String...;
      ageRes::T2 = 1,
      timeFactor::T3 = 1 )
    where T1 <: Real
    where T2 <: Real
    where T3 <: Real
```
This function plots various information of the manpower simulation `mpSim` on a
time grid with resolution `timeRes`. The series that are plotted are defined in
`toShow`. If a plot of the age distribution is requested, the used age grid has
a resolution of `ageRes`. The simulation time and ages are reduced by a factor
`timeFactor`. This is typically done if the simulation time unit is months, and
the user wishes time to be expressed in years.

This function returns `nothing`. If any plots are impossible to produce, the
function will show a warning to that effect.
"""
function Plots.plot( mpSim::ManpowerSimulation, timeRes::T1, toShow::String...;
    ageRes::T2 = 1, timeFactor::T3 = 1 ) where T1 <: Real where T2 <: Real where T3 <: Real

    # Don't generate any plots report if there's no flux out breakdown report
    #   available. This means that either the time resolution ⩽ 0 or that the
    #   simulation hasn't started yet.
    nFluxOutBreakdown = getFluxOutBreakdown( mpSim, timeRes )

    if nFluxOutBreakdown === nothing
        warn( "Since no reports can be created, no plots can be made." )
        return
    end  # if nRec === nothing

    # Don't generate plots if the time factor is ⩽ 0.
    if timeFactor <= 0
        warn( "Can't generate plots, simtime factor must be > 0." )
        return
    end  # if timeFactor <= 0

    # List which plots to generate.
    validPlots = [ "personnel", "flux in", "flux out", "net flux", "age dist",
        "age stats" ]
    tmpShow = unique( toShow )

    # Add the flux out reasons to the valid plot types if needed.
    if any( plotVar -> plotVar ∉ validPlots, tmpShow )
        validPlots = vcat( validPlots,
            collect( keys( nFluxOutBreakdown[ 2 ] ) ) )
    end  # if any( plotVar -> plotVar ∉ validPlots, tmpShow )

    filter!( plotVar -> plotVar ∈ validPlots, tmpShow )

    # If requested, make the age distribution plot first.
    if "age dist" ∈ tmpShow
        plotAgeDist( mpSim, timeRes, ageRes, timeFactor )
    end  # if "age dist" ∈ tmpShow

    # Then make the age statistics plot if requested.
    if "age stats" ∈ tmpShow
        plotAgeStats( mpSim, timeRes, timeFactor )
    end  # if "age stats" ∈ tmpShow

    # Plot the rest
    filter!( plotVar -> plotVar ∉ [ "age dist", "age stats" ], tmpShow )

    if !isempty( tmpShow )
        plotSimResults( mpSim, timeRes, timeFactor, tmpShow )
    end  # if !isempty( tmpShow )

end  # plot( mpSim, timeRes, toShow; ageRes, timeFactor )


"""
```
plotSimulationResults( mpSim::ManpowerSimulation,
                       timeRes::T1,
                       toShow::String...;
                       state::String = "active",
                       isByTransition::Bool = false,
                       showBreakdowns::Tuple{Bool, Bool, Bool} = ( false, false, false ),
                       timeFactor::T2 = 12 )::Void
    where T1 <: Real where T2 <: Real
```
This function generates a (number of) plot(s) for the manpower simulation
`mpSim`. The time grid of the plots has resolution `timeRes`, and the plots show
the information in `toShow`. Only the values `"personnel"`, `"flux in"`,
`"flux out"`, and `"net flux"` are processed, any other values are ignored.
* The parameter `state` plots only the personnel members in the given state,
  where state `"active"`, or empty, means the entire population.
* The parameter `countBreakdownBy` indicates the attribute by which the
  (sub)population counts are broken down. If this is empty, or a non-existent
  attribute, no breakdown occurs.
* The flag `isByTransition` indicates whether the in/out fluxes are broken down
  by transition, or by target/source state.
* The flags in the parameter `showBreakdowns` indicate which types of breakdown
  plots are shown. The first flag is for regular line plots, the second for
  stacked area plots, the third for stacked percentage area plots.
* The parameter `timeFactor` indicates the factor by which the time axis is
  compressed. This is useful if for example the simulation time unit is months,
  but the visualization should be with the time axis in years (use default
  factor 12 in this case).

This function returns `nothing`. The function will generate the general line
plot of the requested information, and then all requested breakdown plots.
Remark that the percentage plots show a total of 0 at the times the investigated
(sub)population is empty [similar to Excel].
"""
function plotSimulationResults( mpSim::ManpowerSimulation, timeRes::T1,
    toShow::String...; state::String = "active", isByTransition::Bool = true,
    showBreakdowns::Tuple{Bool, Bool, Bool} = ( false, false, false ),
    timeFactor::T2 = 12 )::Void where T1 <: Real where T2 <: Real

    # Make a list of all the requested plots.
    validPlots = [ "personnel", "flux in", "flux out", "net flux" ]
    tmpShow = unique( toShow )
    filter!( plotVar -> plotVar ∈ validPlots, tmpShow )

    if isempty( tmpShow )
        return
    end  # if isempty( tmpShow )

    # Generate the reports for the requested state.
    personnelCounts = generateCountReport( mpSim, timeRes, state )
    fluxInCounts = generateFluxReport( mpSim, timeRes, true, isByTransition,
        state )
    fluxOutCounts = generateFluxReport( mpSim, timeRes, false, isByTransition,
        state )
    timeGrid = personnelCounts[ 1 ] ./ timeFactor

    # Make a plot of the totals.
    plotSimResults( state, timeGrid, Vector{Int}( personnelCounts[ 2 ] ),
        Vector{Int}( fluxInCounts[ end ] ), Vector{Int}( fluxOutCounts[ end ] ),
        tmpShow )

    if !any( showBreakdowns )
        return
    end  # if !any( showBreakdowns )

    # Plot the flux breakdown plots.
    plotTypes = [ :normal, :stacked, :percentage ]
    isUsed = map(  ii -> showBreakdowns[ ii ], 1:3 )

    # Make a plot of the breakdown of the fluxes.
    for plotStyle in plotTypes[ isUsed ]
        # if ( "personnel" ∈ tmpShow ) && ( length( personnelCounts ) == 4 )
        #     plotBreakdown( state, timeGrid, personnelCounts[ 2 ],
        #         personnelCounts[ 4 ], personnelCounts[ 3 ], :pers, plotStyle )
        # end  # if ( "personnel" ∈ tmpShow ) && ...

        if "flux in" ∈ tmpShow
            plotBreakdown( state, fluxInCounts, :in, plotStyle,
                Float64( timeFactor ) )
        end  # if "flux in" ∈ tmpShow

        if "flux out" ∈ tmpShow
            plotBreakdown( state, fluxOutCounts, :out, plotStyle,
                Float64( timeFactor ) )
        end  # if "flux out" ∈ tmpShow
    end  # for plotStyle in plotTypes[ isUsed ]

    return

end  # plotSimulationResults( mpSim, timeRes, toShow...; state,
     #   countBreakdownBy, isBreakdown, isByTransition, breakdownPlotStyle,
     #   timeFactor )


"""
```
plotFluxResults( mpSim::ManpowerSimulation,
                 timeRes::T1,
                 transList::Union{String, Tuple{String, String}}...;
                 fileName::String = "",
                 overWrite = true,
                 timeFactor::T2 = 12.0 )
    where T1 <: Real where T2 <: Real
```
This function creates a report on fluxes in the manpower simulation `mpSim` on a
grid with time resolution `timeRes`, showing all the transitions
(transition types) listed in `transList`. These transitions can be entered by
transition name (as `String`) or as source/target state pairs (as
`Union{String, Tuple{String, String}}`). Non existing transitions are ignored,
names of recruitment schemes are accepted, the outflows `retired`,
`resigned`, and `fired` are accepted, and the empty state or state `external` is
accepted to describe in and out transitions. The results are then plotted in
separate plots. If the parameter `fileName` is not blank, the results are then
saved in the Excel file with that name, with the extension `".xlsx"` added if
necessary. If the flag `overWrite` is `true`, a new Excel file is created.
Otherwise, the report is added to the Excel file. Times are compressed by a
factor `timeFactor`.

This function returns `nothing`.
"""
function plotFluxResults( mpSim::ManpowerSimulation, timeRes::T1,
    transList::Union{String, Tuple{String, String}}...;
    fileName::String = "", overWrite = true, timeFactor::T2 = 12.0 ) where T1 <: Real where T2 <: Real

    # Issue warning if time resolution is negative.
    if timeRes <= 0
        warn( "Negative time resolution for grid. Resolution must be > 0.0" )
        return resultReport
    end

    # Issue warning when trying to generate report of a simultation that hasn't
    #   started.
    if now( mpSim ) == 0
        warn( "Simulation hasn't started yet. Cannot generate report." )
        return resultReport
    end  # if now( mpSim ) == 0

    # Issue warninig when trying to apply a negative time compression factor.
    if timeFactor <= 0.0
        warn( "Time compression factor must be greater than 0. Cannot generate report." )
        return resultReport
    end  # if timeFactor <= 0.0

    tStart = now()

    # Generate the data.
    fluxData = generateFluxReport( mpSim, timeRes, transList... )
    fluxData[ 1 ] /= timeFactor
    fluxData[ 2 ] /= timeFactor
    tNames = string.( names( fluxData )[ 3:end ] )
    tNodes = fluxData[ 2 ]

    for ii in eachindex( tNames )
        yMax = max( maximum( fluxData[ ii + 2 ] ), 1 )
        plotTitle = "Flux plot of transition '$(tNames[ ii ])' per interval of " *
            string( timeRes / timeFactor )
        gui( Plots.plot( tNodes, fluxData[ ii + 2 ], size = ( 960, 540 ),
            lw = 2, ylim = [ 0, yMax ], title = plotTitle, legend = false ) )
    end  # for ii in eachindex( tNames )

    tElapsed = ( now() - tStart ).value / 1000.0

    println( "Plots for time resolution $(timeRes / timeFactor) generated. ",
        "Elapsed time: $tElapsed seconds." )

    # Write Excel report if desired.
    if fileName != ""
        tmpFileName = endswith( fileName, ".xlsx" ) ? fileName :
            fileName * ".xlsx"
        tmpFileName = joinpath( mpSim.parFileName[ 1:(end-5) ], tmpFileName )
        dumpFluxData( mpSim, fluxData, timeRes, tmpFileName, overWrite,
            timeFactor, tElapsed )
    end  # if fileName != ""

    return

end  # plotFluxResults( mpSim, timeRes, transList, fileName, overWrite,
     #   timeFactor )


"""
```
plotTransitionMap( mpSim::ManpowerSimulation,
                   states::String...;
                   fileName::String = "" )
```
This function returns `nothing`.
"""
function plotTransitionMap( mpSim::ManpowerSimulation, states::String...;
    fileName::String = "" )::Void

    # Filter out non-existing nodes.
    stateList = merge( mpSim.initStateList, mpSim.otherStateList )
    tmpStates = collect( Iterators.filter(
        stateName -> any( state -> state.name == stateName, keys( stateList ) ),
        states ) )
    graphStates = tmpStates
    graphTrans = Vector{String}()

    # Initialise directed graph.
    nStates = length( graphStates )
    graph = MetaDiGraph( DiGraph( nStates ) )
    isInitCreated = false

    # Add node labels and transitions for initial states.
    for ii in eachindex( tmpStates )
        set_prop!( graph, ii, :state, tmpStates[ ii ] )

        if any( state -> state.name == tmpStates[ ii ],
            keys( mpSim.initStateList ) )
            if !isInitCreated
                add_vertex!( graph )
                push!( graphStates, "External" )
                nStates += 1
                set_prop!( graph, nStates, :state, "External" )
                isInitCreated = true
            end  # if !isInitCreated

            add_edge!( graph, nStates, ii )
            set_prop!( graph, nStates, ii, :trans, "Recruitment" )
        end  # if any( state -> state.name == tmpStates[ ii ], ...
    end  # for ii in eachindex( tmpStates )

    # Add all other transitions.
    for state in keys( stateList )
        # Is the state in the original list?
        if state.name ∈ tmpStates
            # Find its index.
            startStateIndex = findfirst( tmpState -> tmpState == state.name,
                tmpStates )

            # Add all transitions starting from there.
            for trans in stateList[ state ]
                endStateIndex = findfirst(
                    tmpState -> tmpState == trans.endState.name, graphStates )

                # If end state hasn't been put in the list, add it.
                if endStateIndex == 0
                    add_vertex!( graph )
                    push!( graphStates, trans.endState.name )
                    nStates += 1
                    set_prop!( graph, nStates, :state, trans.endState.name )
                    endStateIndex = nStates
                end  # if endStateIndex == 0

                add_edge!( graph, startStateIndex, endStateIndex )
                set_prop!( graph, startStateIndex, endStateIndex, :trans,
                    trans.name )
            end  # for trans in stateList[ state ]
        else
            startStateIndex = findfirst( tmpState -> tmpState == state.name,
                graphStates )
            isStateCreated = startStateIndex > 0

            for trans in stateList[ state ]
                endStateIndex = findfirst(
                    tmpState -> tmpState == trans.endState.name, tmpStates )
                # Add the transition if the end state is in the list of original
                #   states.
                if endStateIndex > 0
                    # Create the state if it isn't in the list.
                    if !isStateCreated
                        add_vertex!( graph )
                        push!( graphStates, trans.startState.name )
                        nStates += 1
                        set_prop!( graph, nStates, :state,
                            trans.startState.name )
                        startStateIndex = nStates
                        isstateCreated = true
                    end  # if !isStateCreated

                    add_edge!( graph, startStateIndex, endStateIndex )
                    set_prop!( graph, startStateIndex, endStateIndex, :trans,
                        trans.name )
                end  # if trans.endState.name ∈ tmpStates
            end  # for trans in stateList[ state ]
        end  # if state.name ∈ graphStates
    end  # for state in keys( stateList )

    display( gplot( graph,
        nodelabel = map( node -> get_prop( graph, node, :state ),
        vertices( graph ) ),
        edgelabel = map( edge -> get_prop( graph, edge, :trans ),
        edges( graph ) ) ) )

    # XXX Add code to save to GraphML.
    if fileName == ""
        return
    end  # if fileName == ""

    # Save the structure of the network.
    tmpFileName = joinpath( mpSim.parFileName[ 1:(end-5) ], fileName )
    savegraph( tmpFileName, graph, GraphMLFormat(); compress = false )

    # Grab it for editing.
    xmlGraph = readxml( tmpFileName )
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
            get_prop( graph, nodeList[ nNodes ], :state ) :
            get_prop( graph, edgeList[ nEdges ], :trans )
        elementLabel = ElementNode( "y:" * ( isNode ? "Node" : "Edge" ) *
            "Label" )
        setnodecontent!( elementLabel, elementLabelText )
        elementShape = ElementNode( "y:" * ( isNode ? "Shape" : "Arrows" ) )

        if isNode
            elementShape[ "type" ] = elementLabelText ∈ states ? "ellipse" :
                "roundrectangle"
        else
            elementShape[ "source" ] = "none"
            elementShape[ "target" ] = "standard"
        end  # if isNode

        link!( elementForm, elementLabel )
        link!( elementForm, elementShape )
        link!( elementData, elementForm )
        link!( graphElements[ ii ], elementData )
    end  # for ii in 1:nElements

    write( tmpFileName, xmlGraph )

    return

end  # plotTransitionMap( mpSim, states, fileName )


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

    fileName = sheet[ "B4" ]
    fileName = isa( fileName, Void ) ? "" : fileName * ".graphml"
    numNodes = Int( sheet[ "B7" ] )
    nodeList = Vector{String}()

    for ii in 1:numNodes
        push!( nodeList, sheet[ "B$(8 + ii)" ] )
    end  # for ii in 1:numNodes

    if !isempty( nodeList )
        plotTransitionMap( mpSim, nodeList...; fileName = fileName )
    end  # if !isempty( nodeList )

    return

end  # plotTransitionMap( mpSim, sheet )



# ==============================================================================
# Non-exported methods.
# ==============================================================================

function readPlotInfoFromFile( mpSim::ManpowerSimulation, sheet::XLSX.Worksheet,
    colNum::Int, state::String )::Void

    toShow = [ "personnel", "flux in", "flux out", "net flux" ]
    plotRes = sheet[ XLSX.CellRef( 6, colNum ) ]
    tmpToShow = [ sheet[ XLSX.CellRef( 7, colNum ) ] == "YES",
        sheet[ XLSX.CellRef( 8, colNum ) ] == "YES",
        sheet[ XLSX.CellRef( 9, colNum ) ] == "YES",
        sheet[ XLSX.CellRef( 10, colNum ) ] == "YES" ]
    plotSimulationResults( mpSim, plotRes, toShow[ tmpToShow ]...;
        state = state, timeFactor = 12,
        isByTransition = sheet[ XLSX.CellRef( 12, colNum ) ] == "YES",
        showBreakdowns = ( sheet[ XLSX.CellRef( 13, colNum ) ] == "YES",
            sheet[ XLSX.CellRef( 14, colNum ) ] == "YES",
            sheet[ XLSX.CellRef( 15, colNum ) ] == "YES" ) )
    return

end  # readPlotInfoFromFile( mpSim, sheet, colNum, state )


"""
```
plotAgeDist( mpSim::ManpowerSimulation,
             timeRes::T1,
             ageRes::T2,
             timeFactor::T3 )
    where T1 <: Real
    where T2 <: Real
    where T3 <: Real
```
This function plots the age distribution of the active personnel in the manpower
simulation `mpSim` on a time grid with resolution `timeRes` and an age grid with
resolution `ageRes`. The simulation time and ages are reduced by a factor
`timeFactor`. This is typically done if the simulation time unit is months, and
the user wishes time to be expressed in years.

This function returns `nothing`. If the age distribution report can't be
retrieved for whatever reason, the function issues warnings to that effect.
"""
function plotAgeDist( mpSim::ManpowerSimulation, timeRes::T1, ageRes::T2,
    timeFactor::T3 ) where T1 <: Real where T2 <: Real where T3 <: Real

    ageDist = getAgeDistributionReport( mpSim, timeRes, ageRes )

    # Don't do anything if there's no age distribution report.
    if ageDist === nothing
        warn( "Since no age distribution report can be created, no plot can be made." )
        return
    end  # if ageDist === nothing

    gui( surface( ageDist[ 2 ] / timeFactor, ageDist[ 1 ] / timeFactor,
        ageDist[ 3 ], size = ( 960, 540 ), xlabel = "Age",
        ylabel = "Simulation time", zlabel = "Personnel" ) )

end  # plotAgeDist( mpSim, timeRes, ageRes, timeComp )


"""
```
plotAgeStats( mpSim::ManpowerSimulation,
              timeRes::T1,
              timeFactor::T2 )
    where T1 <: Real
    where T2 <: Real
```
This function plots basic statistics of the age distribution of active personnel
members in the manpower simulation `mpSim` on a time grid with resolution
`timeRes`. The simulation time and ages are reduced by a factor `timeFactor`.
This is typically done if the simulation time unit is months, and the user
wishes time to be expressed in years. The following statistics are plotted: mean
age (blue), median age (red), minimum/maximum ages (black).

This function returns `nothing`.
"""
function plotAgeStats( mpSim::ManpowerSimulation, timeRes::T1, timeFactor::T2 ) where T1 <: Real where T2 <: Real

    ageStats = getAgeStatsReport( mpSim, timeRes )
    timeSteps = ageStats[ 1 ] / timeFactor
    ageStats = ageStats[ 2 ] / timeFactor
    minAge = minimum( ageStats[ :, 4 ] )
    maxAge = maximum( ageStats[ :, 5 ] )

    plt = Plots.plot( timeSteps, ageStats[ :, 1 ], size = ( 960, 540 ),
        xlabel = "Simulation time", ylabel = "Age", label = "Mean age", lw = 2,
        color = :blue,
        ylim = [ minAge, maxAge ] + 0.01 * ( maxAge - minAge ) * [ -1, 1 ] )
    plt = plot!( timeSteps, ageStats[ :, 3 ], label = "Median age", lw = 2,
        color = :red )
    plt = plot!( timeSteps, ageStats[ :, 4 ], label = "", color = :black )
    plt = plot!( timeSteps, ageStats[ :, 5 ], label = "", color = :black )
    gui( plt )

end  # plotAgeStats( mpSim, timeRes, timeComp )


"""
```
plotSimResults( mpSim::ManpowerSimulation,
                timeRes::T1,
                timeFactor::T2,
                toShow::Vector{String} )
    where T1 <: Real
    where T2 <: Real
```
This function generates a plot of the results of the manpower simulation `mpSim`
on a time grid with resolution `timeRes`. The simulation time is reduced by a
factor `timeFactor`. This is typically done if the simulation time unit is
months, and the user wishes time to be expressed in years. The function plots
the series in `toShow`.

The function returns `nothing`.
"""
function plotSimResults( mpSim::ManpowerSimulation, timeRes::T1, timeFactor::T2,
    toShow::Vector{String} ) where T1 <: Real where T2 <: Real

    yMin = 0
    yMax = mpSim.personnelTarget

    # Retrieve all the information.
    nPers = getCountReport( mpSim, timeRes )
    timeSteps = nPers[ 1 ] / timeFactor
    nPers = nPers[ 2 ]
    nFluxIn = getFluxInReport( mpSim, timeRes )[ 2 ]
    nFluxOut = getFluxOutReport( mpSim, timeRes )[ 2 ]
    netFlux = nFluxIn - nFluxOut
    nFluxOutBreakdown = getFluxOutBreakdown( mpSim, timeRes )[ 2 ]

    # Adjust the minimum if a graph of the net flux is requested.
    if "net flux" ∈ toShow
        yMin = min( 0, minimum( netFlux ) )
    end  # if "net flux" ∈ toShow

    # Adjust the maximum if a graph of the personnel count is not requested.
    if "personnel" ∉ toShow
        yMax = max( maximum( nFluxIn ), maximum( nFluxOut ) )
    else
        yMax = maximum( nPers )
    end  # if "personnel" ∉ toShow

    # These need to be initialised, otherwise there will be issues with knowing
    #   the values of these variables.
    yCoords = nothing
    plt = nothing

    for ii in eachindex( toShow )
        # Retrieve the X-coorrdinates of the graph points.
        tmpTimes = timeSteps

        if toShow[ ii ] != "personnel"
            tmpTimes = timeSteps[ 2:end ]
        end  # if toShow[ ii ] != "personnel"

        # Retrieve the Y-coordinates of the graph points.
        if toShow[ ii ] == "personnel"
            yCoords = nPers
        elseif toShow[ ii ] == "flux in"
            yCoords = nFluxIn
        elseif toShow[ ii ] == "flux out"
            yCoords = nFluxOut
        elseif toShow[ ii ] == "net flux"
            yCoords = netFlux
        else
            yCoords = nFluxOutBreakdown[ toShow[ ii ] ]
        end  # if toShow[ ii ] == "personnel"

        # Plot the requested series.
        if ii == 1
            plt = Plots.plot( tmpTimes, yCoords, label = toShow[ ii ], lw = 2,
                size = ( 960, 540 ), xlim = [ 0, timeSteps[ end ] ],
                ylim = [ yMin, yMax ] + 0.01 * ( yMax - yMin ) * [ -1, 1 ] )
        else
            plt = plot!( tmpTimes, yCoords, label = toShow[ ii ], lw = 2 )
        end  # if ii == 1
    end  # for ii in eachindex( toShow )

    gui( plt )

end  # plotSimResults( mpSim, timeRes, timeComp, toShow... )


function plotSimResults( state::String, timeGrid::Vector{Float64},
    personnelCounts::Vector{Int}, fluxInCounts::Vector{Int},
    fluxOutCounts::Vector{Int}, toShow::Vector{String} )::Void

    yMin = 0.0
    counts = hcat( personnelCounts, fluxInCounts, fluxOutCounts )
    counts = hcat( counts, counts[ :, 2 ] - counts[ :, 3 ] )

    if "net flux" ∈ toShow
        yMin = minimum( counts[ 2:end, 4 ] )
    end  # if "net flux" ∈ validPlots

    yMax = maximum( counts[ :, 1 ] )

    if "personnel" ∉ toShow
        yMax = maximum( counts[ 2:end, 2:4 ] )
    end  # if "personnel" ∉ toShow

    plt = Plots.plot( xlim = [ 0, maximum( timeGrid ) * 1.01 ],
        ylim = [ yMin, yMax ] + 0.025 * ( yMax - yMin ) * [ -1, 1 ],
        xlabel = "Sim time in y", size = ( 960, 540 ),
        title = "Evolution of personnel" *
            ( state == "active" ? "" : " in state '$state'" ) )
    validPlots = [ "personnel", "flux in", "flux out", "net flux" ]

    for ii in eachindex( validPlots )
        if validPlots[ ii ] ∈ toShow
            plt = plot!( timeGrid, counts[ :, ii ], lw = 2,
                label = ii == 1 ? state : validPlots[ ii ] )
        end  # if validPlots[ ii ] ∈ toShow
    end  # for ii in eachindex( validPlots )

    gui( plt )
    return

end  # plotSimResults( state, timeGrid, personnelCounts, fluxInCounts,
     #   fluxOutCounts, toShow )


function plotBreakdown( state::String, counts::DataFrames.DataFrame,
    countType::Symbol, plotStyle::Symbol, timeFactor::Float64 )::Void

    if plotStyle === :normal
        plotBreakdownNormal( state, counts, countType, timeFactor )
    else
        plotBreakdownStacked( state, counts, countType,
            plotStyle === :percentage, timeFactor )
    end  # if plotStyle === :normal

end  # plotBreakdown( state, counts, countType, plotStyle, timeFactor )


function plotBreakdownNormal( state::String, counts::DataFrames.DataFrame,
    countType::Symbol, timeFactor::Float64 )::Void

    yMax = maximum( counts[ end ] )
    isFlux = countType !== :pers
    timeGrid = ( isFlux ? counts[ 2 ] : counts[ 1 ] ) ./ timeFactor

    # Create graph title.
    title = "Breakdown of "
    title *= countType === :pers ? "personnel counts" :
        ( countType === :in ? "in" : "out" ) * " flux"
    title *= " of "
    title *= state == "active" ? "total population" : "state '$state'"

    # Create graph labels.
    labels = string.( names( counts )[ ( isFlux ? 3 : 2 ):(end - 1) ] )

    if isFlux
        map!( label -> split( label, countType === :in ? " to " :
            " from ")[ 1 ], labels, labels )
    end  # if isFlux

    plt = Plots.plot( timeGrid, counts[ end ], lw = 3, label = "Total " *
        ( countType === :pers ? "count" :
        ( countType === :in ? "in" : "out" ) * " flux" ),
        xlim = [ 0, maximum( timeGrid ) * 1.01 ],
        ylim = [ 0, yMax ] + 0.025 * yMax * [ -1, 1 ],
        xlabel = "Sim time in y", size = ( 960, 540 ), title = title  )

    for ii in eachindex( labels )
        jj = ii + ( isFlux ? 2 : 1 )
        plt = plot!( timeGrid, counts[ jj ], lw = 2, label = labels[ ii ] )
    end  # for ii in eachindex( fluxLabels )

    gui( plt )
    return

end  # plotBreakdownNormal( state, counts, countType, timeFactor )


function plotBreakdownStacked( state::String, counts::DataFrames.DataFrame,
    countType::Symbol, isPercent::Bool, timeFactor::Float64 )::Void

    yMax = maximum( counts[ end ] )
    isFlux = countType !== :pers
    timeGrid = ( isFlux ? counts[ 2 ] : counts[ 1 ] ) ./ timeFactor

    # Retrieve cumulative sums to build plots.
    tmpCounts = cumsum( Array( counts[ ( isFlux ? 3 : 2 ):(end-1) ] ), 2 )

    if isPercent
        foreach( ii -> tmpCounts[ ii, : ] /= counts[ ii, end ] / 100.0,
            eachindex( timeGrid ) )
        yMax = 100.0
    end  # if isPercent

    plt = Plots.plot( xlim = [ 0, maximum( timeGrid ) * 1.01 ],
        ylim = [ 0.0, yMax ] + 0.025 * yMax * [ -1, 1 ],
        xlabel = "Sim time in y", size = ( 960, 540 ),
        title = ( countType === :pers ? "Personnel " :
            ( countType === :in ? "In" : "Out" ) * " flux " ) *
            ( isPercent ? "percentage " : "" ) * "breakdown of " *
            ( state == "active" ? "total population" : "state '$state'" ) )

    # For the percentage counts, set all undefined entries to 0 (Excel-like
    #   behaviour for stacked percentage plots if the total is 0).
    tmpCounts[ isnan.( tmpCounts ) ] = 0

    # Create graph labels.
    labels = string.( names( counts )[ ( isFlux ? 3 : 2 ):(end-1) ] )

    if isFlux
        map!( label -> split( label, countType === :in ? " to " :
            " from ")[ 1 ], labels, labels )
    end  # if isFlux

    for ii in length( labels ):-1:1
        plt = plot!( timeGrid, tmpCounts[ :, ii ], lw = 2, fillalpha = 0.5,
            linealpha = 1.0, label = labels[ ii ],
            fillrange = ii == 1 ? 0 : tmpCounts[ :, ii - 1 ] )
    end  # for ii in length( labels ):-1:1

    gui( plt )
    return

end  # plotBreakdownStacked( state, counts, countType, isPercent, timeFactor )
