"""
```
generateSubpopPlots( mpSim::ManpowerSimulation,
                     timeRes::Real,
                     subpops::Subpopulation...;
                     plotType::Symbol = :single,
                     savePlots::Bool = false,
                     timeFactor::Real = 12.0 )
```
This function generates plots of the evolution of the subpopulations in
`subpops` for the manpower simulation `mpSim` on a time grid with resolution
`tmieRes`. The type of plot is given by `plotType` and can have the following
values:
* `:single` (default): one plot is created showing all the subpopulations;
* `:separate`: one plot is created per subpopulation;
* `:byNode`: subpopulatios bassed on the same source node are on the same plot.

If `savePlots` is `true`, the plots will be saved to disk. The simulation times
are compressed by a factor 'timeFactor' (e.g. sim times in months, horizontal
axis in years).

This function returns `nothing`.
"""
function generateSubpopPlots( mpSim::ManpowerSimulation, timeRes::Real,
    subpops::Subpopulation...; plotType::Symbol = :single,
    savePlots::Bool = false, timeFactor::Real = 12.0 )::Void

    # Issue warning if time resolution is negative.
    if timeRes <= 0.0
        warn( "Negative time resolution for grid. Resolution must be > 0.0" )
        return
    end  # if timeRes <= 0.0

    # Issue warning if time factor is negative.
    if timeFactor <= 0.0
        warn( "Negative time compression factor. Factor must be > 0.0" )
        return
    end  # if timeFactor <= 0.0

    # Issue warning when trying to generate report of a simultation that hasn't
    #   started.
    if now( mpSim ) == 0.0
        warn( "Simulation hasn't started yet. Cannot generate report." )
        return
    end  # if now( mpSim ) == 0.0

    # Issue a warning if the plot type is unknown and default to showing all
    #   subpopulations in one plot.
    tmpPlotType = plotType

    if plotType ∉ [ :single, :byNode, :separate ]
        warn( "Unknown plot type. Defaulting to showing all subpopulations on a single plot." )
        tmpPlotType = :single
    end  # if plotType ∉ [ :single, :byNode, :separate ]

    subpopReport = generateSubpopulationReport( mpSim, timeRes, subpops... )
    plotSubpopData( mpSim, subpopReport, collect( subpops ), tmpPlotType,
        savePlots, Float64( timeFactor ) )

    return

end  # generateSubpopPlots( mpSim, timeRes, subpops, plotType, savePlots,
     #   timefactor )


"""
```
plotSubpopData( mpSim::ManpowerSimulation,
                subpopReport::DataFrame,
                subpops::Vector{Subpopulation},
                plotType::Symbol,
                savePlots::Bool,
                timeFactor::Float64 )
```
This function plots the data in the subpopulation report `subpopReport` of the
manpower simulation `mpSim`, with the subpopulations are defined in `subpops`.
The type of the plot is determined by `plotType`, and if `savePlots` is `true`,
the plots are saved to disk. The simulation times are compressed by a factor
'timeFactor' (e.g. sim times in months, horizontal axis in years).

This function returns `nothing`.
"""
function plotSubpopData( mpSim::ManpowerSimulation, subpopReport::DataFrame,
    subpops::Vector{Subpopulation}, plotType::Symbol, savePlots::Bool,
    timeFactor::Float64 )::Void

    timeGrid = deepcopy( subpopReport[ :timePoints ] ) ./ timeFactor
    plotDirName = joinpath( mpSim.parFileName[ 1:(end - 5) ],
        "subpop plots" )

    if savePlots && !ispath( plotDirName )
        mkpath( plotDirName )
    end  # if savePlots && !ispath( plotDirName )

    if plotType === :single
        makeSingleSubpopPlot( timeGrid, subpopReport[ 2:end ], savePlots,
            plotDirName )
    elseif plotType === :separate
        makeSeparateSubpopPlots( timeGrid, subpopReport[ 2:end ], savePlots,
            plotDirName )
    else
        makeSubpopPlotsByNode( timeGrid, subpopReport[ 2:end ], subpops,
            savePlots, plotDirName )
    end  # if plotType === :single

    return

end  # plotSubpopData( mpSim, subpopReport, subpops, plotType, savePlots,
     #   timeFactor )


"""
```
makeSingleSubpopPlot( timeGrid::Vector{Float64},
                      subpopReport::DataFrame,
                      savePlots::Bool,
                      plotDirName::String )
```
This function makes plots of the data in the subpopulation report
`subpopReport`, with the time grid (horizontal axis information) in `timeGrid`.
There is one plot per subpopulation. If the parameter `savePlots` is `true`, the
plots are saved to disk, in the folder `plotDirName`. The function does not
check if this folder exists.

This function returns `nothing`.
"""
function makeSingleSubpopPlot( timeGrid::Vector{Float64},
    subpopReport::DataFrame, savePlots::Bool, plotDirName::String )::Void

    timeRes = timeGrid[ 2 ] - timeGrid[ 1 ]
    plotTitle = string( "Subpopulation plot (res ", timeRes, ")" )
    plt = plot( title = plotTitle, size = ( 960, 540 ), formatter = :plain,
        xlabel = "Sim time in y" )

    for subpopName in names( subpopReport )
        plt = plot!( timeGrid, subpopReport[ subpopName ],
            label = string( subpopName ), lw = 2,
            hover = string.( subpopName, ": ", subpopReport[ subpopName ] ) )
    end  # for subpopName in names( subpopReport )

    gui( plt )

    if savePlots
        plotFileName = joinpath( plotDirName, string( "subpopulations (",
            timeRes, ").html" ) )
        savefig( plt, plotFileName )
    end  # if savePlots

    return

end  # makeSingleSubpopPlot( timeGrid, subpopReport, savePlots, plotDirName )


"""
```
makeSeparateSubpopPlots( timeGrid::Vector{Float64},
                         subpopReport::DataFrame,
                         savePlots::Bool,
                         plotDirName::String )
```
This function makes plots of the data in the subpopulation report
`subpopReport`, with the time grid (horizontal axis information) in `timeGrid`.
There is one plot per subpopulation. If the parameter `savePlots` is `true`, the
plots are saved to disk, in the folder `plotDirName`. The function does not
check if this folder exists.

This function returns `nothing`.
"""
function makeSeparateSubpopPlots( timeGrid::Vector{Float64},
    subpopReport::DataFrame, savePlots::Bool, plotDirName::String )::Void

    timeRes = timeGrid[ 2 ] - timeGrid[ 1 ]

    for subpopName in names( subpopReport )
        plotTitle = string( "Subpopulation '", subpopName, "' (res ", timeRes,
            ")" )
        plt = plot( timeGrid, subpopReport[ subpopName ], lw = 2,
            title = plotTitle, size = ( 960, 540 ), formatter = :plain,
            xlabel = "Sim time in y", label = string( subpopName ),
            hover = subpopReport[ subpopName ] )
        gui( plt )

        if savePlots
            plotFileName = joinpath( plotDirName, string( subpopName, " (",
                timeRes, ").html" ) )
            savefig( plt, plotFileName )
        end  # if savePlots
    end  # for subpopName in names( subpopReport )

    return

end  # makeSeparateSubpopPlots( timeGrid, subpopReport, savePlots, plotDirName )


"""
```
makeSubpopPlotsByNode( timeGrid::Vector{Float64},
                       subpopReport::DataFrame,
                       subpops::Vector{Subpopulation},
                       savePlots::Bool,
                       plotDirName::String )
```
This function makes a plot of the data in the subpopulation report
`subpopReport`, with the time grid (horizontal axis information) in `timeGrid`.
The plots are grouped by source node of the subpopulations, and the function
uses the information in `subpops`, the list of subpopulations, to determine the
groups. If the parameter `savePlots` is `true`, the plots are saved to disk, in
the folder `plotDirName`. The function does not check if this folder exists.

This function returns `nothing`.
"""
function makeSubpopPlotsByNode( timeGrid::Vector{Float64},
    subpopReport::DataFrame, subpops::Vector{Subpopulation}, savePlots::Bool,
    plotDirName::String )::Void

    subpopsByNode = Dict{String, Vector{Symbol}}()

    for subpop in subpops
        if Symbol( subpop.name ) ∈ names( subpopReport )
            if !haskey( subpopsByNode, subpop.sourceNodeName )
                subpopsByNode[ subpop.sourceNodeName ] = Vector{Symbol}()
            end  # if !haskey( subpop.sourceNodeName, subpopsByNode )

            push!( subpopsByNode[ subpop.sourceNodeName ],
                Symbol( subpop.name ) )
        end  # if Symbol( subpop.name ) ∈ names( subpopReport )
    end  # for subpop in subpops

    timeRes = timeGrid[ 2 ] - timeGrid[ 1 ]

    for sourceNode in keys( subpopsByNode )
        plotTitle = string( "Subpopulation of node '", sourceNode,
            "' plot (res ", timeRes, ")" )
        plt = plot( title = plotTitle, size = ( 960, 540 ), formatter = :plain,
            xlabel = "Sim time in y" )

        for subpopName in subpopsByNode[ sourceNode ]
            plt = plot!( timeGrid, subpopReport[ subpopName ],
                label = string( subpopName ), lw = 2,
                hover = string.( subpopName, ": ", subpopReport[ subpopName ] ) )
        end  # for subpopName in subpopsByNode[ sourceNode ]

        gui( plt )

        if savePlots
            plotFileName = joinpath( plotDirName, string( "subpops of ",
                sourceNode, " (", timeRes, ").html" ) )
            savefig( plt, plotFileName )
        end  # if savePlots
    end  # for sourceNode in keys( subpopsByNode )

    return

end  # makeSubpopPlotsByNode( timeGrid, subpopReport, subpops, savePlots,
     #   plotDirName )


include( "subpopReports.jl" )

#=
cond1 = MP.processCondition( "had transition", "IS", "Spec" )[ 1 ]
cond2 = MP.processCondition( "had transition", "NOT IN", "Spec" )[ 1 ]
cond3 = MP.processCondition( "started as", "IS", "Trainee" )[ 1 ]
cond4 = MP.processCondition( "was", "IS NOT", "Senior B" )[ 1 ]
cond5 = MP.processCondition( "tenure", ">=", 20 )[ 1 ]
cond6 = MP.processCondition( "gender", "IS", "F" )[ 1 ]

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
subpop7 = Subpopulation( "SP7", "Test" )

tRes = 12
aRes = 12
subpops = [ subpop1, subpop2, subpop3, subpop4, subpop5, subpop6, subpop7 ]
ageType = :age

@time generateSubpopExcelReport( mpSim, tRes, subpops...,
    fileName = "agglomNode test 20190404/config1/subpopReport.xlsx" )
println()
=#
