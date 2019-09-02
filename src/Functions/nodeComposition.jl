"""
```
plotNodeComposition( mpSim::ManpowerSimulation,
                     timeRes::Real,
                     isShow::Bool,
                     isSave::Bool,
                     nodeNames::String...;
                     fileName::String = "",
                     singleSheet::Bool = false,
                     timeFactor::Real = 12 )
```
This function generates node composition node composition plots of the manpower
simulation `mpSim` on a time grid with time resolution `timeRes`, making reports
for all (unique) nodes with names in `nodeNames`. The other parameters are
* `isShow`: show the plots in the browser or not;
* `isSave`: save the plots or not;
* `nodeNames`: the names of the nodes for which to generate the plots;
* `fileName`: the name of the Excel file to which to save the report. Leave
  blank if no Excel report is needed;
* `singleSheet`: whether to save the reports in a single Excel sheet, or one
  sheet per node;
* `timeFactor`: the factor by which simulation times are compressed. For
  example, the simulation is in months but the reports are requested in years.

This function returns a `Dict{String, DataFrame}`, with the key the name of the
node and the `DataFrame` the report for that node.
"""
function plotNodeComposition( mpSim::ManpowerSimulation, timeRes::Real,
    isShow::Bool, isSave::Bool, nodeNames::String...; fileName::String = "",
    singleSheet::Bool = false, timeFactor::Real = 12 )::Void

    if !isShow && !isSave && ( fileName == "" )
        return
    end  # if !isShow && ...

    # Issue warning if time resolution is negative.
    if timeRes <= 0.0
        warn( "Negative time resolution for grid. Resolution must be > 0.0" )
        return
    end  # if timeRes <= 0.0

    # Issue warning when trying to generate report of a simultation that hasn't
    #   started.
    if now( mpSim ) == 0.0
        warn( "Simulation hasn't started yet. Cannot generate report." )
        return
    end  # if now( mpSim ) == 0.0

    # Issue warninig when trying to apply a negative time compression factor.
    if timeFactor <= 0.0
        warn( "Time compression factor must be greater than 0. Cannot generate report." )
        return
    end  # if timeFactor <= 0.0

    # Create the reports.
    tStart = now()
    compReports = generateCompositionReport( mpSim, timeRes, nodeNames... )

    tReport = ( now() - tStart ).value
    msTimePart = tReport % 1000
    timeStr = string( floor( Int, tReport / 1000 ), '.',
        msTimePart < 100 ? '0' : "", msTimePart < 10 ? '0' : "", msTimePart )
    println( "Node composition reports generated in ", timeStr, " seconds." )

    # If there are no valid entries in the report, don't continue.
    if isempty( compReports )
        return
    end  # if isempty( compReports )

    # Prepare generation of plots.
    tStart = now()

    if isShow || isSave
        generateCompositionPlots( mpSim, compReports, isShow, isSave,
            Float64( timeFactor ) )
    end  # if isShow || isSave

    tPlots = ( now() - tStart ).value
    msTimePart = tPlots % 1000
    timeStr = string( floor( Int, tPlots / 1000 ), '.',
        msTimePart < 100 ? '0' : "", msTimePart < 10 ? '0' : "", msTimePart )
    println( "Node composition plots generated in ", timeStr, " seconds." )

    # If no filename is provided, don't continue.
    if fileName == ""
        return
    end

    # Write Excel reports if needed.
    tmpFileName = endswith( fileName, ".xlsx" ) ? fileName :
        fileName * ".xlsx"
    dumpCompositionData( mpSim, compReports, tmpFileName, singleSheet,
        Float64( timeFactor ), tReport )

    return

end  # plotNodeComposition( mpSim, timeRes, isShow, isSave, nodeNames,
     #   timeFactor )


function generateNodeCompExcelReport( mpSim::ManpowerSimulation, timeRes::Real,
    nodeNames::String...; fileName::String = "nodeCompReport",
    overWrite::Bool = true, singleSheet::Bool = false,
    timeFactor::Real = 12.0 )::Void

    # Issue warning if time resolution is negative.
    if timeRes <= 0.0
        warn( "Negative time resolution for grid. Resolution must be > 0.0" )
        return
    end  # if timeRes <= 0.0

    # Issue warning when trying to generate report of a simultation that hasn't
    #   started.
    if now( mpSim ) == 0.0
        warn( "Simulation hasn't started yet. Cannot generate report." )
        return
    end  # if now( mpSim ) == 0.0

    # Issue warninig when trying to apply a negative time compression factor.
    if timeFactor <= 0.0
        warn( "Time compression factor must be greater than 0. Cannot generate report." )
        return
    end  # if timeFactor <= 0.0

    # Create the reports.
    tStart = now()
    compReports = generateCompositionReport( mpSim, timeRes, nodeNames... )
    tReport = ( now() - tStart ).value

    # If there are no valid entries in the report, don't continue.
    if isempty( compReports )
        return
    end  # if isempty( compReports )

    tmpFileName = string( fileName, endswith( fileName, ".xlsx" ) ? "" :
        ".xlsx" )
    dumpCompositionData( mpSim, compReports, tmpFileName, singleSheet,
        Float64( timeFactor ), tReport )

    return

end  # generateNodeCompExcelReport( mpSim, timeRes, nodeNames, fileName,
     #   overWrite, singleSheet, timeFactor )


"""
```
generateCompositionReport( mpSim::ManpowerSimulation,
                           timeRes::Real,
                           nodeNames::String... )
```
This function generates node composition reports of the manpower simulation
`mpSim` on a time grid with time resolution `timeRes`, making reports for all
(unique) nodes with names in `nodeNames`. If the node is a base node, the report
is just a population evolution report for the node; if the node is a compound
node, the report also shows the composition (how many personnel members in each
compound node) of the node.

This function returns a `Dict{String, DataFrame}`, with the key the name of the
node and the `DataFrame` the report for that node.
"""
function generateCompositionReport( mpSim::ManpowerSimulation, timeRes::Real,
    nodeNames::String... )::Dict{String, DataFrame}

    results = Dict{String, DataFrame}()

    # Issue warning if time resolution is negative.
    if timeRes <= 0.0
        warn( "Negative time resolution for grid. Resolution must be > 0.0" )
        return results
    end  # if timeRes <= 0.0

    # Issue warning when trying to generate report of a simultation that hasn't
    #   started.
    if now( mpSim ) == 0.0
        warn( "Simulation hasn't started yet. Cannot generate report." )
        return results
    end  # if now( mpSim ) == 0.0

    # Get a list of the valid nodes.
    tmpNodes = unique( collect( nodeNames ) )
    MP.generateRequiredCompounds( mpSim, nodeNames... )
    filter!( nodeName -> haskey( mpSim.stateList, nodeName ) ||
        haskey( mpSim.compoundStateList, nodeName ), tmpNodes )

    # Perform the counting.
    for nodeName in tmpNodes
        # If it's a base node, do it efficiently.
        if haskey( mpSim.stateList, nodeName )
            fluxInCounts = generateNodeFluxReport( mpSim, timeRes, true,
                nodeName )
            fluxOutCounts = generateNodeFluxReport( mpSim, timeRes, false,
                nodeName )
            persCounts = MP.generateCountReport( mpSim, nodeName, fluxInCounts,
                fluxOutCounts )
            results[ nodeName ] = persCounts
        else
            results[ nodeName ] = generateCompReport( mpSim, Float64( timeRes ),
                nodeName )
        end  # if haskey( mpSim.stateList, nodeName )
    end  # for nodeName in tmpNodes

    return results

end  # generateCompositionReport( mpSim, timeRes, nodeNames )


"""
```
generateCompositionPlots( mpSim::ManpowerSimulation,
                          compReports::Dict{String, DataFrame},
                          isShow::Bool,
                          isSave::Bool,
                          timeFactor::Float64 )
```

"""
function generateCompositionPlots( mpSim::ManpowerSimulation,
    compReports::Dict{String, DataFrame}, isShow::Bool, isSave::Bool,
    timeFactor::Float64 )::Void

    plotDir = mpSim.parFileName[ 1:(end - 5) ]
    plotDir = joinpath( plotDir, "node composition plot" )

    if isSave && !ispath( plotDir )
        mkpath( plotDir )
    end  # if isSave && ...

    # Set up plots.
    nodeNames = collect( keys( compReports ) )
    timeGrid = deepcopy( compReports[ nodeNames[ 1 ] ][ :timePoints ] )
    timeGrid ./= timeFactor
    timeRes = timeGrid[ 2 ] - timeGrid[ 1 ]

    for nodeName in nodeNames
        compReport = compReports[ nodeName ]
        yMax = maximum( compReport[ end ] )
        plt = plot( xlim = [ 0, maximum( timeGrid ) * 1.01 ],
            size = ( 960, 540 ), ylim = [ -0.025, 1.025 ], showaxis = false,
            gridalpha = 0, xlabel = "Sim time in y",
            title = string( "Composition breakdown of node ", nodeName,
                " with resolution ", timeRes ) )
        twinx()

        # If the node is not a base node, add composition percentage plot.
        if ( length( compReport ) > 2 ) && ( sum( compReport[ end ] ) > 0 )
            nodeNames = string.( names( compReport )[ 2:(end - 1) ] )
            counts = Array( compReport[ 2:(end - 1) ] )
            counts = cumsum( counts, 2 )

            for ii in eachindex( nodeNames )
                counts[ :, ii ] ./= compReport[ end ] +
                    ( compReport[ end ] .== 0 )
            end  # for ii in eachindex( nodeNames )

            for ii in length( nodeNames ):-1:1
                fRange = ii == 1 ? zeros( timeGrid ) : counts[ :, ii - 1 ]
                plt = plot!( timeGrid, counts[ :, ii ], subplot = 1, lw = 2,
                    linealpha = 1.0, fillalpha = 0.5, fillrange = fRange,
                    label = string( "Contribution of node ", nodeNames[ ii ] ) )
            end  # for ii in eachindex( nodeNames )
        end  # if ( length( compReport ) > 2 ) && ...

        # Add the population evolution plot.
        plt = plot!( timeGrid, compReport[ end ], hover = compReport[ end ],
            lw = 3, color = :black, label = "", subplot = 2,
            label = string( "Total pop. of node ", nodeName ),
            xlim = [ 0, maximum( timeGrid ) * 1.01 ], yformatter = :plain,
            ylim = [ 0, yMax ] + 0.025 * yMax * [ -1, 1 ] )

        if isShow
            gui( plt )
        end  # if isShow

        if isSave
            plotFileName = joinpath( plotDir, string( nodeName, " (", timeRes,
                ").html" ) )
            savefig( plt, plotFileName )
        end  # if isSave
    end  # for nodeName in tmpNodes

    return

end  # generateCompositionPlots( mpSim, compReports, isShow, isSave,
     #   timeFactor )


"""
```
generateCompReport( mpSim::ManpowerSimulation,
                    timeRes::Float64,
                    nodeName::String )
```
This function generates a composition report for the compound/agglomeration
node with name `nodeName` of the manpower simulation `mpSim`, on a grid with
time resolution `timeRes`.

This function returns a `DataFrame`, where the first column holds the time
points, the last column the total number of personnel members in the compound
node, and the other columns the number of personnel members in each component
node.
"""
function generateCompReport( mpSim::ManpowerSimulation, timeRes::Float64,
    nodeName::String )::DataFrame

    MP.generateRequiredCompounds( mpSim, nodeName )
    compNode = mpSim.compoundStateList[ nodeName ]
    baseNodeList = compNode.stateList
    stateList = string( "endState IN ( '", join( baseNodeList, "', '" ), "' )" )
    queryCmdPre = string( "SELECT endState, count( endState ) pop FROM (
        SELECT endState FROM `", mpSim.transitionDBname, "`
        WHERE ( timeIndex <= " )
    queryCmdSuf = string( " ) AND ( ( ",
        replace( stateList, "endState IN ", "startState IN " ), " ) OR ( ",
        stateList, " ) )
        GROUP BY `", mpSim.idKey, "`
        HAVING ", stateList, " )
        GROUP BY endState" )

    # Pre-allocate the data containers.
    timeGrid = MP.generateTimeGrid( mpSim, timeRes )
    compCounts = zeros( Int, length( timeGrid ), length( baseNodeList ) )
    indexedNodeList = Dict{String, Int}()

    for ii in eachindex( baseNodeList )
        indexedNodeList[ baseNodeList[ ii ] ] = ii
    end  # for ii in eachindex( baseNodeList )

    # Compute the composition of the compound node at each time index with most
    #   of the work done in SQLite.
    for ii in eachindex( timeGrid )
        compData = SQLite.query( mpSim.simDB, string( queryCmdPre,
            timeGrid[ ii ], queryCmdSuf ) )

        for jj in eachindex( compData[ :endState ] )
            kk = indexedNodeList[ compData[ jj, :endState ] ]
            compCounts[ ii, kk ] = compData[ jj, :pop ]
        end  # for jj in eachindex( compData[ :endState ] )
    end  # for ii in eachindex( timeGrid )

    return DataFrame( hcat( timeGrid, compCounts, sum( compCounts, 2 ) ),
        Symbol.( vcat( "timePoints", baseNodeList, nodeName ) ) )

end  # generateCompReport( mpSim, timeRes, nodeName )


function dumpCompositionData( mpSim::ManpowerSimulation,
    compReports::Dict{String, DataFrame}, fileName::String, singleSheet::Bool,
    timeFactor::Float64, tReport::Int )::Void

    if !ispath( dirname( fileName ) )
        mkpath( dirname( fileName ) )
    end  # if !ispath( dirname( fileName ) )

    tStart = now()
    tExcel = 0

    XLSX.openxlsx( fileName, mode = "w" ) do xf
        nodeNames = collect( keys( compReports ) )
        timeGrid = deepcopy( compReports[ nodeNames[ 1 ] ][ :timePoints ] )
        timeGrid ./= timeFactor
        timeRes = timeGrid[ 2 ] - timeGrid[ 1 ]
        fSheet = xf[ 1 ]
        XLSX.rename!( fSheet, singleSheet ?
            string( "Composition report (res ", timeRes, ")" ) : "Summary" )

        # Generate summary.
        fSheet[ "A1" ] = "Simulation length"
        fSheet[ "B1" ] = timeGrid[ end ]
        fSheet[ "C1" ] = "years"
        fSheet[ "A2" ] = "Simulation length"
        fSheet[ "B2" ] = timeRes
        fSheet[ "C2" ] = "years"
        fSheet[ "A3" ] = "Report timestamp"
        fSheet[ "B3" ] = now()
        fSheet[ "A4" ] = "Data generation time"
        fSheet[ "B4" ] = tReport / 1000
        fSheet[ "C4" ] = "seconds"
        fSheet[ "A5" ] = "Excel generation time"
        fSheet[ "C5" ] = "seconds"

        # Generate report.
        if singleSheet
            XLSX.writetable!( fSheet, DataFrame( reshape( timeGrid, :, 1 ) ),
                [ "Sim time" ], anchor_cell = XLSX.CellRef( "A7" ) )
            currentCol = 2

            for nodeName in nodeNames
                compReport = compReports[ nodeName ]
                colNames = string.( names( compReport ) )

                if length( colNames ) == 2
                    XLSX.writetable!( fSheet,
                        DataFrame( reshape( compReport[ 2 ], :, 1 ) ),
                        [ colNames[ 2 ] ],
                        anchor_cell = XLSX.CellRef( 7, currentCol ) )
                else
                    XLSX.writetable!( fSheet, compReport[ 2:end ],
                        colNames[ 2:end ],
                        anchor_cell = XLSX.CellRef( 7, currentCol ) )
                end  # if length( colNames ) == 2

                currentCol += length( colNames )
            end  # for nodeName in nodeNames

            #=
            currentCol = 0

            for nodeName in nodeNames
                compReport = compReports[ nodeName ]
                colNames = String.( names( compReport ) )

                for ii in 2:length( colNames )
                    colNr = ii + currentCol
                    fSheet[ XLSX.CellRef( 7, colNr ) ] = colNames[ ii ]

                    for jj in eachindex( timeGrid )
                        fSheet[ XLSX.CellRef( jj + 7, colNr ) ] =
                            compReport[ jj, ii ]
                    end  # for jj in eachindex( timeGrid )
                end  # for ii in 2:length( colNames )

                currentCol += length( colNames )
            end  # for nodeName in nodeNames
            =#
        else
            for nodeName in nodeNames
                fSheet = XLSX.addsheet!( xf,
                    string( nodeName, " (" , timeRes, ")" ) )
                compReport = deepcopy( compReports[ nodeName ] )
                compReport[ :timePoints ] ./= timeFactor
                XLSX.writetable!( fSheet, compReport,
                    string.( names( compReport ) ) )
                fSheet[ "A1" ] = "Sim time"
            end  # for nodeName in nodeNames

            fSheet = xf[ "Summary" ]
        end  # if singleSheet

        tExcel = ( now() - tStart ).value
        fSheet[ "B5" ] = tExcel / 1000
    end  # XLSX.openxlsx( fileName, mode = "w" ) do xf

    msTimePart = tExcel % 1000
    timeStr = string( floor( Int, tExcel / 1000 ), '.',
        msTimePart < 100 ? '0' : "", msTimePart < 10 ? '0' : "", msTimePart )
    println( "Node composition Excel report generated in ", timeStr,
        " seconds." )

    return

end  # dumpCompositionData( mpSim, compReports, tmpFileName, singleSheet,
     #   timeFactor, tReport )


# tRes = 12
# nodeNames = [ "Entry", "Career", "Specialist", "Boop", "Master A" ]
# @time generateNodeCompExcelReport( mpSim, tRes, nodeNames...,
#     fileName = "agglomNode test 20190404/config1/nodeCompReport.xlsx" )
# @time generateNodeCompExcelReport( mpSim, tRes, nodeNames...,
#     singleSheet = true,
#     fileName = "agglomNode test 20190404/config1/nodeCompReport2.xlsx" )
# println()
