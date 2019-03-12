# This file holds all the functions that are needed to create population flux
#   plots from the simulation results database.

export  showFluxPlotsFromFile,
        plotFluxResults


sTypes = Dict{Symbol, Tuple{Union{DataType, Function}, String}}(
    :SVG => ( SVG, ".svg" ),
    :PNG => ( PNG, ".png" ),
    :PDF => ( PDF, ".pdf" )
)


"""
```
showFluxPlotsFromFile( mpSim::ManpowerSimulation,
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
        warn( string( "'", tmpFileName,
            "' is not a valid file. Can't create flux plots." ) )
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
            warn( "No flux plots requested." )
            return
        end  # if nPlots == 0

        plotList = generateFluxPlotList( plotSheet, nPlots )
        generateFluxPlots( mpSim, plotList, showPlots, savePlots,
            reportFileName )
    end  # XLSX.openxlsx( tmpFileName ) do xf

    return

end  # showFluxPlotsFromFile( mpSim, fileName )


"""
```
plotFluxResults( mpSim::ManpowerSimulation,
                 timeRes::Real,
                 transList::Union{String, Tuple{String, String}, Tuple{String, String, String}}...;
                 fileName::String = "",
                 overWrite::Bool = true,
                 timeFactor::Real = 12.0 )
```
This function creates a report on fluxes in the manpower simulation `mpSim` on a
grid with time resolution `timeRes`, showing all the transitions
(transition types) listed in `transList`. These transitions can be entered by
transition name (as `String`), as source/target state pairs (as
`Union{String, Tuple{String, String}}`), or as transition/source/target tuples.
Non existing transitions are ignored, names of recruitment schemes are accepted,
the outflows `retirement`, `attrition`, and `fired` are accepted, and the empty
state or state `external` is accepted to describe in and out transitions. The
results are then plotted in separate plots. If the parameter `fileName` is not
blank, the results are then saved in the Excel file with that name, with the
extension `".xlsx"` added if necessary. If the flag `overWrite` is `true`, a new
Excel file is created. Otherwise, the report is added to the Excel file. Times
are compressed by a factor `timeFactor`.

This function returns `nothing`.
"""
function plotFluxResults( mpSim::ManpowerSimulation, timeRes::Real,
    isShow::Bool, isSave::Bool, transList::Union{String, Tuple{String, String},
        Tuple{String, String, String}}...;
    fileName::String = "", overWrite::Bool = true,
    timeFactor::Real = 12.0 )::Void

    # Issue warning if time resolution is negative.
    if timeRes <= 0
        warn( "Negative time resolution for grid. Resolution must be > 0.0" )
        return
    end

    # Issue warning when trying to generate report of a simultation that hasn't
    #   started.
    if now( mpSim ) == 0
        warn( "Simulation hasn't started yet. Cannot generate report." )
        return
    end  # if now( mpSim ) == 0

    # Issue warninig when trying to apply a negative time compression factor.
    if timeFactor <= 0.0
        warn( "Time compression factor must be greater than 0. Cannot generate report." )
        return
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
        plotTitle = string( "Flux plot of transition '", tNames[ ii ],
            "' per interval of ", timeRes / timeFactor )
        plt = Plots.plot( tNodes, fluxData[ ii + 2 ], size = ( 960, 540 ),
            lw = 2, ylim = [ 0, yMax ], title = plotTitle, legend = false,
            hover = fluxData[ ii + 2 ], show = isShow, yformatter = :plain )

        # Save the plot if requested.
        if isSave
            plotFileName = mpSim.parFileName[ 1:(end - 5) ]
            plotFileName = joinpath( plotFileName, "flux plot" )
            plotFileName = joinpath( plotFileName, string( tNames[ ii ], " (",
                timeRes / timeFactor, ").html" ) )
            savefig( plt, plotFileName )
        end  # if isSave
    end  # for ii in eachindex( tNames )

    tElapsed = ( now() - tStart ).value / 1000.0

    println( "Plots for time resolution ", timeRes / timeFactor, " generated. ",
        "Elapsed time: ", tElapsed, " seconds." )

    # Write Excel report if desired.
    if fileName != ""
        tmpFileName = endswith( fileName, ".xlsx" ) ? fileName :
            fileName * ".xlsx"
        dumpFluxData( mpSim, fluxData, timeRes, tmpFileName, overWrite,
            timeFactor, tElapsed )
    end  # if fileName != ""

    return

end  # plotFluxResults( mpSim, timeRes, isShow, isSave, transList, fileName,
     #   overWrite, timeFactor )


# ==============================================================================
# Non-exported methods.
# ==============================================================================

"""
```
plotFluxBreakdown( node::String,
                   counts::DataFrame,
                   isIn:Bool,
                   isShow::Bool,
                   plotStyle::Symbol,
                   timeFactor::Float64,
                   fileName::String )
```
This function creates a line graph plot of the breakdown of the flux into or out
of the node with name `node`. The data used for plotting is found in `counts`.
If `isIn` is true, the plot is of the flux into the node, otherwise the flux out
of the node. If `isShow` is `true`, the plots get displayed in the browser. The
argument `plotStyle` determines the type of plot, and can take the values
`:normal`, `:stacked`, or `: percentage`. The simulation times get compressed by
`timeFactor` (for example simulation time is in months, and values on time axis
are in years), and the plot gets saved to a file with name `fileName` is it is
not an empty string.

This function returns `nothing`.
"""
function plotFluxBreakdown( node::String, counts::DataFrame, isIn::Bool,
    isShow::Bool, plotStyle::Symbol, timeFactor::Float64,
    fileName::String )::Void

    if plotStyle === :normal
        plotFluxBreakdownNormal( node, counts, isIn, isShow, timeFactor,
            fileName )
    else
        plotFluxBreakdownStacked( node, counts, isIn, plotStyle === :percentage,
        isShow, timeFactor, fileName )
    end  # if plotStyle === :normal

    return

end  # plotFluxBreakdown( node, counts, isIn, isShow, plotStyle, timeFactor,
     #   fileName )


"""
```
plotFluxBreakdownNormal( node::String,
                         counts::DataFrame,
                         isIn:Bool,
                         isShow::Bool,
                         timeFactor::Float64,
                         fileName::String )
```
This function creates a line graph plot of the breakdown of the flux into or out
of the node with name `node`. The data used for plotting is found in `counts`.
If `isIn` is true, the plot is of the flux into the node, otherwise the flux out
of the node. If `isShow` is `true`, the plots get displayed in the browser. The
simulation times get compressed by `timeFactor` (for example simulation time is
in months, and values on time axis are in years), and the plot gets saved to a
file with name `fileName` is it is not an empty string.

This function returns `nothing`.
"""
function plotFluxBreakdownNormal( node::String, counts::DataFrame, isIn::Bool,
    isShow::Bool, timeFactor::Float64, fileName::String )::Void

    yMax = maximum( counts[ end ] )
    timeGrid = counts[ 2 ] ./ timeFactor

    # Create graph title.
    title = string( "Breakdown of ", isIn ? "in" : "out", " flux of ",
        node == "active" ? "total population" : string( "node '", node, "'" ),
        " with resolution ", timeGrid[ 2 ] - timeGrid[ 1 ] )

    # Create graph labels.
    labels = string.( names( counts )[ 3:(end - 1) ] )

    map!( label -> split( label, isIn ? " to " : " from ")[ 1 ], labels,
        labels )

    # Create plot.
    plt = Plots.plot( timeGrid, counts[ end ], lw = 3,
        label = string( "Total ", isIn ? "in" : "out", " flux" ),
        xlim = [ 0, maximum( timeGrid ) * 1.01 ], yformatter = :plain,
        ylim = [ 0, yMax ] + 0.025 * yMax * [ -1, 1 ], hover = counts[ end ],
        xlabel = "Sim time in y", size = ( 960, 540 ), title = title  )

    for ii in eachindex( labels )
        jj = ii + 2
        plt = plot!( timeGrid, counts[ jj ], lw = 2, label = labels[ ii ],
            hover = counts[ jj ] )
    end  # for ii in eachindex( fluxLabels )

    # Show plot if needed.
    if isShow
        gui( plt )
    end  # if isShow

    # Save plot if needed.
    if fileName != ""
        savefig( plt, fileName )
    end  # if fileName != ""

    return

end  # plotFluxBreakdownNormal( state, counts, isIn, isShow, timeFactor,
     #   fileName )


"""
```
plotFluxBreakdownStacked( node::String,
                          counts::DataFrame,
                          isIn:Bool,
                          isPercent::Bool,
                          isShow::Bool,
                          timeFactor::Float64,
                          fileName::String )
```
This function creates a stacked area plot of the breakdown of the flux into or
out of the node with name `node`. The data used for plotting is found in
`counts`. If `isIn` is true, the plot is of the flux into the node, otherwise
the flux out of the node. If `isPercent` is true, the plot is a percentage plot,
otherwise a regular stacked area plot. If `isShow` is `true`, the plots get
displayed in the browser. The simulation times get compressed by `timeFactor`
(for example simulation time is in months, and values on time axis are in
years), and the plot gets saved to a file with name `fileName` is it is not an
empty string.

This function returns `nothing`.
"""
function plotFluxBreakdownStacked( node::String, counts::DataFrame, isIn::Bool,
    isPercent::Bool, isShow::Bool, timeFactor::Float64, fileName::String )::Void

    yMax = maximum( counts[ end ] )
    timeGrid = counts[ 2 ] ./ timeFactor
    tmpFileName = replace( fileName, ".html", string( " ", isPercent ?
        "percentage" : "stacked", ".html" ) )

    # Retrieve cumulative sums to build plots.
    tmpCounts = cumsum( Array( counts[ 3:(end-1) ] ), 2 )

    if isPercent
        foreach( ii -> tmpCounts[ ii, : ] /= counts[ ii, end ] / 100.0,
            eachindex( timeGrid ) )
        yMax = 100.0
    end  # if isPercent

    # Create graph title.
    title = string( isIn ? "In" : "Out", " flux ",
        isPercent ? "percentage " : "", "breakdown of ",
        state == "active" ? "total population" : string( "node '", node, "'" ),
        " with resolution ", timeGrid[ 2 ] - timeGrid[ 1 ] )

    # Create plot.
    plt = Plots.plot( xlim = [ 0, maximum( timeGrid ) * 1.01 ],
        ylim = [ 0.0, yMax ] + 0.025 * yMax * [ -1, 1 ],
        xlabel = "Sim time in y", size = ( 960, 540 ),
        title = title, yformatter = :plain )

    # For the percentage counts, set all undefined entries to 0 (Excel-like
    #   behaviour for stacked percentage plots if the total is 0).
    tmpCounts[ isnan.( tmpCounts ) ] = 0

    # Create graph labels.
    labels = string.( names( counts )[ 3:(end-1) ] )

    map!( label -> split( label, isIn ? " to " : " from " )[ 1 ], labels,
        labels )

    for ii in length( labels ):-1:1
        fRange = ii == 1 ? 0 : tmpCounts[ :, ii - 1 ]
        plt = plot!( timeGrid, tmpCounts[ :, ii ], lw = 2, fillalpha = 0.5,
            linealpha = 1.0, label = labels[ ii ], fillrange = fRange )
    end  # for ii in length( labels ):-1:1

    # Show plot if needed.
    if isShow
        gui( plt )
    end  # if isShow

    # Save plot if needed.
    if fileName != ""
        savefig( plt, tmpFileName )
    end  # fileName != ""

    return

end  # plotFluxBreakdownStacked( state, counts, isIn, isPercent, isShow,
     #   timeFactor, fileName )


"""
```
generateFluxPlotList( plotSheet::XLSX.Worksheet,
                      nPlots::Int )
```
This function generates a list of every requested flux plot, grouped by time
resolution, as requested from the Excel sheet `plotSheet`. The parameter
`nPlots`, the njumber of requested plots, is passed along for convenience.

this function returns a `Dict{Float64, Vector{Any}}`, with the keys the
different time resolutions for which a plot is requested, and the value the list
of requested plots for that time resolution.
"""
function generateFluxPlotList( plotSheet::XLSX.Worksheet,
    nPlots::Int )::Dict{Float64, Vector{Any}}

    plotList = Dict{Float64, Vector{Any}}()

    for ii in 1:nPlots
        jj = ii + 11
        isST = plotSheet[ XLSX.CellRef( jj, 1 ) ] == "YES"
        timeRes = Float64( plotSheet[ XLSX.CellRef( jj, 5 ) ] )

        # Add time resolution to list.
        if !haskey( plotList, timeRes )
            plotList[ timeRes ] = Vector()
        end  # if !haskey( plotList, timeRes )

        # Get source/target states.
        sourceName = plotSheet[ XLSX.CellRef( jj, 3 ) ]
        targetName = plotSheet[ XLSX.CellRef( jj, 4 ) ]
        sourceName = isa( sourceName, Missings.Missing ) ? "" :
            string( sourceName )
        targetName = isa( targetName, Missings.Missing ) ? "" :
            string( targetName )

        # Add the plot to the list in the correct form.
        if isST
            push!( plotList[ timeRes ], ( sourceName, targetName ) )
        else
            transName = plotSheet[ XLSX.CellRef( jj, 2 ) ]

            if isa( transName, String )
                if ( sourceName == "" ) && ( targetName == "" )
                    push!( plotList[ timeRes ], transName )
                else
                    push!( plotList[ timeRes ],
                        ( transName, sourceName, targetName ) )
                end  # if ( sourceName == "" ) &&
            end  # if isa( transName, String )
        end  # if isST
    end  # for ii in 1:nPlots

    return plotList

end  # generateFluxPlotList( plotSheet, nPlots )


"""
```
generateFluxPlots( mpSim::ManpowerSimulation,
                   plotList::Dict{Float64, Vector{Any}},
                   showPlots::Bool,
                   savePlots::Bool,
                   reportFileName::String )
```
This function generates the flux plots in the list `plotList` for the simulation
results of the manpower simulation `mpSim`. The plots are displayed in the
browser if `showPlots` is `true`, are saved to disk if `savePlots` is `true`,
and Excel report is generated if `reportFileName` is not an empty string. The
list of plotsmay contain elements of the following types: `String`,
`Tuple{String, String}`, and `Tuple{String, String, String}`.

This function returns `nothing`.
"""
function generateFluxPlots( mpSim::ManpowerSimulation,
    plotList::Dict{Float64, Vector{Any}}, showPlots::Bool, savePlots::Bool,
    reportFileName::String )::Void

    overWrite = true

    # Make the plots.
    if showPlots || savePlots
        # Wipe folder if needed
        if savePlots
            plotDir = mpSim.parFileName[ 1:(end - 5) ]
            plotDir = joinpath( plotDir, "flux plot" )

            # Wipe and create folder.
            rm( plotDir, force = true, recursive = true )
            mkdir( plotDir )
        end  # if savePlots

        for timeRes in keys( plotList )
            plotFluxResults( mpSim, timeRes, showPlots, savePlots,
                plotList[ timeRes ]..., fileName = reportFileName,
                overWrite = overWrite )
            overWrite = false
        end  # for timeRes in keys( plotList )
    elseif reportFileName != ""
        for timeRes in keys( plotList )
            generateExcelFluxReport( mpSim, timeRes, plotList[ timeRes ]...,
                fileName = reportFileName, overWrite = overWrite )
            overWrite = false
        end  # for timeRes in keys( plotList )
    end  # if showPlots
end  # generateFluxPlots( mpSim, plotList, showPlots, savePlots,
     #   reportFileName )
