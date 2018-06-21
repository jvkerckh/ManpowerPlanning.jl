# This file holds all the functions related to plotting simulation results.

export showPlotsFromFile,
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
function showPlotsFromFile( mpSim::ManpowerSimulation, fName::String )

    if now( mpSim ) == 0
        warn( "Simulation hasn't started yet. Can't create plots." )
        return
    end  # if now( mpSim ) == 0

    tmpFilename = fName * ( endswith( fName, ".xlsx" ) ? "" : ".xlsx" )
    w = Workbook( tmpFilename )
    s = getSheet( w, "Output plots" )

    if s.ptr === Ptr{Void}( 0 )
        warn( "Excel file doesn't have sheet 'Output plots'. Can't create plots." )
        return
    end  # if s.ptr === Ptr{Void}( 0 )

    if s[ "B", 5 ] == 1
        readPlotInfoFromFile( mpSim, s, 2, "active" )
    end  # if s[ "B", 5 ] == 1

    nExtraPlots = Int( s[ "F", 3 ] )
    stateList = collect( keys( merge( mpSim.initStateList,
        mpSim.otherStateList ) ) )

    for ii in 1:nExtraPlots
        colNum = 2 + 4 * ii
        state = s[ colNum, 5 ]
        state = isa( state, Void ) || ( state == "" ) ? "active" :
            String( state )

        # Only plot if state exists.
        if ( state == "active" ) || any( tmpState -> state == tmpState.name,
            stateList )
            readPlotInfoFromFile( mpSim, s, colNum, state )
        end  # if ( state == "active" ) ||
    end  # for ii in 1:nPlots

    return

end  # showPlotsFromFile( mpSim, fName )


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


function plotSimulationResults( mpSim::ManpowerSimulation, timeRes::T1,
    toShow::String...; state::String = "active", countBreakdownBy::String = "",
    isByType::Bool = false,
    showBreakdowns::Tuple{Bool, Bool, Bool} = ( false, false, false ),
    timeFactor::T2 = 1 )::Void where T1 <: Real where T2 <: Real

    # Make a list of all the requested plots.
    validPlots = [ "personnel", "flux in", "flux out", "net flux" ]
    tmpShow = unique( toShow )
    filter!( plotVar -> plotVar ∈ validPlots, tmpShow )

    if isempty( tmpShow )
        return
    end  # if isempty( tmpShow )

    tmpBreakdownBy = countBreakdownBy

    if !any( showBreakdowns )
        tmpBreakdownBy = ""
    end  # if !any( showBreakdowns )

    # Generate the reports for the requested state.
    personnelCounts = generateCountReport( mpSim, state, timeRes,
        tmpBreakdownBy )
    fluxInCounts = generateFluxInReport( mpSim, state, timeRes, !isByType )
    fluxOutCounts = generateFluxOutReport( mpSim, state, timeRes, !isByType )
    timeGrid = personnelCounts[ 1 ] / timeFactor

    # Make a plot of the totals.
    plotSimResults( state, timeGrid, personnelCounts[ 2 ], fluxInCounts[ 2 ],
        fluxOutCounts[ 2 ], tmpShow )

    if !any( showBreakdowns )
        return
    end  # if !any( showBreakdowns )

    plotTypes = [ :normal, :stacked, :percentage ]
    isUsed = Vector{Bool}( 3 )
    foreach( ii -> isUsed[ ii ] = showBreakdowns[ ii ], 1:3 )

    # Make a plot of the breakdown of the fluxes.
    for plotStyle in plotTypes[ isUsed ]
        if ( "personnel" ∈ tmpShow ) && ( tmpBreakdownBy != "" )
            plotBreakdown( state, timeGrid, personnelCounts[ 2 ],
                personnelCounts[ 4 ], personnelCounts[ 3 ], :pers, plotStyle )
        end  # if ( "personnel" ∈ tmpShow ) && ...

        if "flux in" ∈ tmpShow
            plotBreakdown( state, timeGrid[ 2:end ], fluxInCounts[ 2 ],
                fluxInCounts[ 4 ], fluxInCounts[ 3 ], :in, plotStyle )
        end  # if "flux in" ∈ tmpShow

        if "flux out" ∈ tmpShow
            plotBreakdown( state, timeGrid[ 2:end ], fluxOutCounts[ 2 ],
                fluxOutCounts[ 4 ], fluxOutCounts[ 3 ], :out, plotStyle )
        end  # if "flux in" ∈ tmpShow
    end  # for plotStyle in plotTypes[ isUsed ]

    return

end  # plotSimulationResults( mpSim, timeRes, toShow...; state,
     #   countBreakdownBy, isBreakdown, isByType, breakdownPlotStyle,
     #   timeFactor )


# ==============================================================================
# Non-exported methods.
# ==============================================================================

function readPlotInfoFromFile( mpSim::ManpowerSimulation, sheet::Taro.Sheet,
    colNum::Int, state::String )::Void

    toShow = [ "personnel", "flux in", "flux out", "net flux" ]
    plotRes = sheet[ colNum, 6 ]
    tmpToShow = [ sheet[ colNum, 7 ] == 1, sheet[ colNum, 8 ] == 1,
        sheet[ colNum, 9 ] == 1, sheet[ colNum, 10 ] == 1 ]
    breakdownBy = isa( sheet[ colNum, 12 ], Void ) ? "" : sheet[ colNum, 12 ]
    plotSimulationResults( mpSim, plotRes, toShow[ tmpToShow ]...;
        state = state, countBreakdownBy = breakdownBy,
        timeFactor = 12, isByType = sheet[ colNum, 13 ] == 1,
        showBreakdowns = ( sheet[ colNum, 14 ] == 1, sheet[ colNum, 15 ] == 1,
        sheet[ colNum, 16 ] == 1 ) )
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

    plt = plot( timeSteps, ageStats[ :, 1 ], size = ( 960, 540 ),
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
            plt = plot( tmpTimes, yCoords, label = toShow[ ii ], lw = 2,
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
    counts = hcat( personnelCounts, vcat( NaN, fluxInCounts ),
        vcat( NaN, fluxOutCounts[ :, 1 ] ) )
    counts = hcat( counts, counts[ :, 2 ] - counts[ :, 3 ] )

    if "net flux" ∈ toShow
        yMin = minimum( counts[ 2:end, 4 ] )
    end  # if "net flux" ∈ validPlots

    yMax = maximum( counts[ :, 1 ] )

    if "personnel" ∉ toShow
        yMax = maximum( counts[ 2:end, 2:4 ] )
    end  # if "personnel" ∉ toShow

    plt = plot( xlim = [ 0, maximum( timeGrid ) * 1.01 ],
        ylim = [ yMin, yMax ] + 0.025 * ( yMax - yMin ) * [ -1, 1 ],
        xlabel = "Sim time in y", size = ( 800, 600 ),
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


function plotBreakdown( state::String, timeGrid::Vector{Float64},
    totals::Vector{Int}, counts::Array{Int,2}, labels::Vector{String},
    countType::Symbol, plotStyle::Symbol )::Void

    if plotStyle === :normal
        plotBreakdownNormal( state, timeGrid, totals, counts, labels,
            countType )
    else
        plotBreakdownStacked( state, timeGrid, totals, counts, labels,
            countType, plotStyle === :percentage )
    end  # if plotStyle === :normal

end  # plotBreakdown( state, timeGrid, fluxCounts, countType, plotStyle )


function plotBreakdownNormal( state::String, timeGrid::Vector{Float64},
    totals::Vector{Int}, counts::Array{Int, 2}, labels::Vector{String},
    countType::Symbol )::Void

    yMin = 0
    yMax = maximum( totals )

    title = "Breakdown of "
    title *= countType === :pers ? "personnel counts" :
        ( countType === :in ? "in" : "out" ) * " flux"
    title *= " of "
    title *= state == "active" ? "total population" : "state '$state'"

    plt = plot( timeGrid, totals, lw = 3, label = "Total " *
        ( countType === :pers ? "count" :
        ( countType === :in ? "in" : "out" ) * " flux" ),
        xlim = [ 0, maximum( timeGrid ) * 1.01 ],
        ylim = [ yMin, yMax ] + 0.025 * ( yMax - yMin ) * [ -1, 1 ],
        xlabel = "Sim time in y", size = ( 800, 600 ), title = title  )

    for ii in eachindex( labels )
        plt = plot!( timeGrid, counts[ :, ii ], lw = 2,
            label = labels[ ii ] )
    end  # for ii in eachindex( fluxLabels )

    gui( plt )
    return

end  # plotBreakdownNormal( state, timeGrid, counts, labels, countType )


function plotBreakdownStacked( state::String, timeGrid::Vector{Float64},
    totals::Vector{Int}, counts::Array{Int, 2}, labels::Vector{String},
    countType::Symbol, isPercent::Bool )::Void

    tmpTimeGrid = timeGrid
    tmpCounts = Array{Float64}( cumsum( counts, 2 ) )
    yMax = maximum( totals )

    if isPercent
        foreach( ii -> tmpCounts[ ii, : ] /= totals[ ii ] / 100.0,
            eachindex( timeGrid ) )
        yMax = 100.0
        #=
        # XXX: Plotting function throws an error when asked to plot a value
        #   sandwiched between two NaNs. This needs to be taken care of first.
        xDel = timeGrid[ 1 ] / 20.0
        nTimes = length( timeGrid )

        zeroInds = find( fluxCounts[ :, 1 ] .== 0 )
        dists = zeroInds[ 2:end ] - zeroInds[ 1:(end - 1) ]
        problemInds = zeroInds[ find( dists .== 2 ) + 1 ]

        if fluxCounts[ end, 1 ] == 0
            tmpCounts = vcat( tmpCounts, tmpCounts[ end, : ] )
            insert!( tmpTimeGrid, nTimes, tmpTimeGrid - xDel )
        end  # if fluxCounts[ end, 1 ] == 0

        reverse!( problemInds )

        if fluxCounts[ 2, 1 ] == 0
            push!( problemInds, 2 )
        end  # if fluxCounts[ 2, 1 ] == 0

        for ii in problemInds
            tmpCounts = vcat( tmpCounts[ 1:(ii - 1), : ],
                tmpCounts[ ii - 1, : ], tmpCounts[ ii:end, : ] )
            insert!( tmpTimeGrid, ii, tmpTimeGrid[ ii - 1 ] + xDel )
            tmpTimeGrid[ ii - 1 ] -= xDel
        end  # for ii in problemInds
        =#
    end  # if isPercent

    plt = plot( xlim = [ 0, maximum( timeGrid ) * 1.01 ],
        ylim = [ 0.0, yMax ] + 0.025 * yMax * [ -1, 1 ],
        xlabel = "Sim time in y", size = ( 800, 600 ),
        title = ( countType === :pers ? "Personnel " :
            ( countType === :in ? "In" : "Out" ) * " flux " ) *
            ( isPercent ? "percentage " : "" ) * "breakdown of " *
            ( state == "active" ? "total population" : "state '$state'" ) )

    nTypes = length( labels )
    xDel = timeGrid[ 1 ] / 20.0

    #=
    # Define plotblocks.
    numInds = find( cnt -> !isnan( cnt ), tmpCounts[ :, 1 ] )
    gapInds = find( numInds[ 2:end ] - numInds[ 1:( end - 1 ) ] .!= 1 )
    endInds = vcat( numInds[ gapInds ], numInds[ end ] )
    startInds = vcat( numInds[ 1 ], numInds[ gapInds + 1 ] )
    println( hcat( startInds, endInds ) )

    for ii in nTypes:-1:1, jj in eachindex( startInds )
        indR = startInds[ jj ]:endInds[ jj ]
        tPoints = timeGrid[ indR ]
        toPlot = tmpCounts[ indR, ii ]
        fRange = ii == 1 ? 0 : tmpCounts[ indR, ii - 1 ]

        if length( indR ) == 1
            tPoints = vcat( tPoints - xDel, tPoints + xDel )
            toPlot = vcat( toPlot, toPlot )
            fRange = vcat( fRange, fRange )
        end  # if length( indR ) == 1

        plt = plot!( tPoints, toPlot, lw = 2, fillalpha = 0.5, linealpha = 1.0,
            label = fluxLabels[ ii + 1 ], fillrange = fRange )
    end  # for ii in nTypes:-1:1, ...
    =#

    tmpCounts[ isnan.( tmpCounts ) ] = 0

    for ii in nTypes:-1:1
        tPoints = timeGrid
        toPlot = tmpCounts[ :, ii ]
        fRange = ii == 1 ? 0 : tmpCounts[ :, ii - 1 ]

        plt = plot!( tPoints, toPlot, lw = 2, fillalpha = 0.5, linealpha = 1.0,
            label = labels[ ii ], fillrange = fRange )
    end

    gui( plt )
    return

end
