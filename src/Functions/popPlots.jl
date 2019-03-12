# This file holds all the functions that are needed to create population
#   plots from the simulation results database.

export  showPlotsFromFile,
        plotSimulationResults


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

    if !ispath( tmpFilename )
        warn( "File '$tmpFilename' does not exist. Not generating plots." )
        return
    end  # if !ispath( tmpFileName )

    XLSX.openxlsx( tmpFilename ) do xf
        if !XLSX.hassheet( xf, "Output plots (pop)" )
            warn( "Excel file doesn't have sheet 'Output plots'. Can't create plots." )
            return
        end  # if !hassheet( xf, "Outpot plots (pop)" )

        # Get the general info.
        plotSheet = xf[ "Output plots (pop)" ]
        showPlots = plotSheet[ "B3" ] == "YES"
        savePlots = plotSheet[ "B4" ] == "YES"
        reportFileName = plotSheet[ "B5" ] == "YES" ? plotSheet[ "B6" ] : ""
        reportFileName = isa( reportFileName, Missings.Missing ) ? "" :
            reportFileName
        reportFileName = reportFileName == "" ? "" :
            joinpath( mpSim.parFileName[ 1:(end-5) ], reportFileName )

        if !showPlots && ( reportFileName == "" )
            return
        end  # if !showPlots && ...

        nPlots = plotSheet[ "B9" ]

        if nPlots == 0
            warn( "No population plots requested." )
            return
        end  # if nPlots == 0

        plotNodes = plotSheet[ XLSX.CellRange( 13, 1, nPlots + 12, 1 ) ]
        isMissing = isa.( plotNodes, Missings.Missing )
        plotNodes[ isMissing ] = "active"
        plotNodes = string.( plotNodes )
        generateRequiredCompounds( mpSim, plotNodes... )
        plotList = Dict{Float64, Vector{Tuple{String, Vector{Bool}}}}()

        # Get all requested transitions and time resolutions.
        potentialStates = vcat( collect( keys( mpSim.stateList ) ),
            collect( keys( mpSim.compoundStateList ) ), "active" )

        for ii in 1:nPlots
            plotFlags = Vector{Bool}( 7 )
            jj = ii + 12
            stateName = plotNodes[ ii ]

            if stateName in potentialStates
                timeRes = plotSheet[ "B$jj" ]

                if !haskey( plotList, timeRes )
                    plotList[ timeRes ] = Vector{String}()
                end  # if !haskey( plotList, timeRes )

                plotFlags[ 1:4 ] = plotSheet[ "C$jj:F$jj" ] .== "YES"
                plotFlags[ 5:7 ] = plotSheet[ "H$jj:J$jj" ] .== "YES"

                push!( plotList[ timeRes ], ( stateName, plotFlags ) )
            end  # if stateName in potentialStates
        end  # for ii in 1:nPlots

        overWrite = true
        toShow = [ "personnel", "flux in", "flux out", "net flux" ]

        if showPlots || savePlots
            if savePlots
                popPlotName = mpSim.parFileName[ 1:(end - 5) ]
                popPlotName = joinpath( popPlotName, "population plot" )
                inBreakdownName = replace( popPlotName, "population plot",
                    "in flux breakdown" )
                outBreakdownName = replace( popPlotName, "population plot",
                    "out flux breakdown" )

                # Wipe and create the necessary folders.
                for dName in [ popPlotName, inBreakdownName,
                    outBreakdownName ]
                    rm( dName, force = true, recursive = true )
                    mkdir( dName )
                end  # for dName in dirname.( ...
            end  # if isSave

            for timeRes in keys( plotList ), plotInfo in plotList[ timeRes ]
                nodeName, plotFlags = plotInfo
                plotSimulationResults( mpSim, timeRes, showPlots,
                    savePlots, toShow[ plotFlags[ 1:4 ] ]..., node = nodeName,
                    timeFactor = 12, showBreakdowns = ( plotFlags[ 5 ],
                        plotFlags[ 6 ], plotFlags[ 7 ] ) )
            end  # for timeRes in keys( plotList )
        end  # if showPlots

        if reportFileName != ""
            for timeRes in keys( plotList )
                nodeList = map( plotInfo -> plotInfo[ 1 ],
                    plotList[ timeRes ] )
                generateExcelReport( mpSim, timeRes, nodeList...,
                    fileName = reportFileName, overWrite = overWrite,
                    timeFactor = 12 )
                overWrite = false
            end  # for timeRes in keys( plotList )
        end  # if reportFileName != ""
    end  # XLSX.openxlsx( tmpFilename ) do xf

    return

end  # showPlotsFromFile( mpSim, fName )


"""
```
plotSimulationResults( mpSim::ManpowerSimulation,
                       timeRes::Real,
                       isShow::Bool,
                       isSave::Bool,
                       toShow::String...;
                       node::String = "active",
                       showBreakdowns::Tuple{Bool, Bool, Bool} = ( false, false, false ),
                       timeFactor::Real = 12 )
```
This function generates a (number of) plot(s) for the manpower simulation
`mpSim`. The time grid of the plots has resolution `timeRes`, and the plots show
the information in `toShow`. Only the values `"personnel"`, `"flux in"`,
`"flux out"`, and `"net flux"` are processed, any other values are ignored.
* The parameter `node` plots only the personnel members in the given node,
  where node `"active"`, or empty, means the entire population.
* The parameter `countBreakdownBy` indicates the attribute by which the
  (sub)population counts are broken down. If this is empty, or a non-existent
  attribute, no breakdown occurs.
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
function plotSimulationResults( mpSim::ManpowerSimulation, timeRes::Real,
    isShow::Bool, isSave::Bool, toShow::String...; node::String = "active",
    showBreakdowns::Tuple{Bool, Bool, Bool} = ( false, false, false ),
    timeFactor::Real = 12 )::Void

    # Make a list of all the requested plots.
    validPlots = [ "personnel", "flux in", "flux out", "net flux" ]
    tmpShow = unique( toShow )
    filter!( plotVar -> plotVar ∈ validPlots, tmpShow )

    if isempty( tmpShow )
        return
    end  # if isempty( tmpShow )

    # Generate file names.
    popPlotName = ""
    inBreakdownName = ""
    outBreakdownName = ""

    if isSave
        popPlotName = mpSim.parFileName[ 1:(end - 5) ]
        popPlotName = joinpath( popPlotName, "population plot", string( node,
            " (", timeRes / timeFactor, ").html" ) )
        inBreakdownName = replace( popPlotName, "population plot",
            "in flux breakdown" )
        outBreakdownName = replace( popPlotName, "population plot",
            "out flux breakdown" )
    end  # if isSave

    # Generate the reports for the requested node.
    fluxInCounts = generateNodeFluxReport( mpSim, timeRes, true, node )
    fluxOutCounts = generateNodeFluxReport( mpSim, timeRes, false, node )
    personnelCounts = generateCountReport( mpSim, node, fluxInCounts,
        fluxOutCounts )
    timeGrid = personnelCounts[ 1 ] ./ timeFactor
    nodeTargets = retrieveNodeTarget( mpSim, node )
    nodeTarget = sum( map( tmpNode -> nodeTargets[ tmpNode ],
        collect( keys( nodeTargets ) ) ) )

    # Make a plot of the totals.
    plotSimResults( node, timeGrid, Vector{Int}( personnelCounts[ 2 ] ),
        nodeTarget, Vector{Int}( fluxInCounts[ end ] ),
        Vector{Int}( fluxOutCounts[ end ] ), isShow, tmpShow, popPlotName )

    if !any( showBreakdowns )
        return
    end  # if !any( showBreakdowns )

    # Plot the flux breakdown plots.
    plotTypes = [ :normal, :stacked, :percentage ]
    isUsed = map(  ii -> showBreakdowns[ ii ], 1:3 )

    # Make a plot of the breakdown of the fluxes.
    for plotStyle in plotTypes[ isUsed ]
        if "flux in" ∈ tmpShow
            plotFluxBreakdown( node, fluxInCounts, true, isShow, plotStyle,
                Float64( timeFactor ), inBreakdownName )
        end  # if "flux in" ∈ tmpShow

        if "flux out" ∈ tmpShow
            plotFluxBreakdown( node, fluxOutCounts, false, isShow, plotStyle,
                Float64( timeFactor ), outBreakdownName )
        end  # if "flux out" ∈ tmpShow
    end  # for plotStyle in plotTypes[ isUsed ]

    return

end  # plotSimulationResults( mpSim, timeRes, isShow, isSave, toShow..., node,
     #   showBreakdowns, timeFactor )


# ==============================================================================
# Non-exported methods.
# ==============================================================================

"""
```
plotSimResults( node::String,
                timeGrid::Vector{Float64},
                personnelCounts::Vector{Int},
                target::Int,
                fluxInCounts::Vector{Int},
                fluxOutCounts::Vector{Int},
                isShow::Bool,
                toShow::Vector{String},
                fileName::String )
```
This function generates a population plot for the node `node` on the time grid
`timeGrid`. The data used to generate this plot are the personnelcounts in
`personnelCounts`, the total flux into the node in `fluxInCounts`, and the total
flux out of the node in `fluxOutCounts`. If the flag `isShow` is `true`, the
plot is shown in the browser, and the plot is saved to a fine with name
`fileName` if it is not an empty string. The plot shows the elements given in
the vector `toShow`, with valid entries `personnel`, `flux in`, `flux out`, and
`net flux`.

This function returns `nothing`.
"""
function plotSimResults( node::String, timeGrid::Vector{Float64},
    personnelCounts::Vector{Int}, target::Int, fluxInCounts::Vector{Int},
    fluxOutCounts::Vector{Int}, isShow::Bool, toShow::Vector{String},
    fileName::String )::Void

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

    title = string( "Evolution of personnel",
        node == "active" ? "" : string( " in node '", node, "'" ),
        " with resolution ", timeGrid[ 2 ] - timeGrid[ 1 ] )

    plt = Plots.plot( xlim = [ 0, maximum( timeGrid ) * 1.01 ],
        ylim = [ yMin, yMax ] + 0.025 * ( yMax - yMin ) * [ -1, 1 ],
        xlabel = "Sim time in y", size = ( 960, 540 ),
        title = title, yformatter = :plain )
    validPlots = [ "personnel", "flux in", "flux out", "net flux" ]

    for ii in eachindex( validPlots )
        if validPlots[ ii ] ∈ toShow
            plt = plot!( timeGrid, counts[ :, ii ], lw = 2,
                label = ii == 1 ? node : validPlots[ ii ],
                hover = counts[ :, ii ] )
        end  # if validPlots[ ii ] ∈ toShow
    end  # for ii in eachindex( validPlots )

    # Add target population line if needed.
    if target >= 0
        plt = plot!( timeGrid, target .* ones( length( timeGrid ) ), lw = 2,
            lc = :black, ls = :dash, la = 0.5, label = "pop. target" )
    end  # if target >= 0

    # Show plot if needed.
    if isShow
        gui( plt )
    end  # if isShow

    # Save plot if needed.
    if fileName != ""
        savefig( plt, fileName )
    end  # if isSave

    return

end  # plotSimResults( node, timeGrid, personnelCounts, fluxInCounts,
     #   fluxOutCounts, isShow, toShow, fileName )
