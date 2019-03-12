# This file holds all the functions that are needed to distill population
#   reports from the simulation results database.

export  generateExcelReport


"""
```
generateExcelReport( mpSim::ManpowerSimulation,
                     timeRes::Real,
                     nodeList::String...;
                     fileName::String = "testReport",
                     overWrite::Bool = true,
                     timeFactor::Real = 12.0 )
```
This function creates a report on desired populations in the manpower simulation
`mpSim` on a grid with time resolution `timeRes`, showing all the populations of
the nodes listed in `nodeList`. The fluxes in and out of these nodes are
broken down by transition and by source/target node. Non existing nodes are
ignored, and the node `active`, indicating the entire population, is accepted.
The report is then saved in the Excel file `fileName`, with the extension
`.xlsx` added if necessary. If the flag `overWrite` is `true`, a new Excel file
is created. Otherwise, the report is added to the Excel file. Times are
compressed by a factor `timeFactor`.

The report will always include the information for the entire population.

This function returns `nothing`.
"""
function generateExcelReport( mpSim::ManpowerSimulation, timeRes::Real,
    nodeList::String...; fileName::String = "testReport",
    overWrite::Bool = true, timeFactor::Real = 12.0 )::Void

    tStart = now()
    tElapsed = [ 0.0, 0.0 ]
    tmpFileName = endswith( fileName, ".xlsx" ) ? fileName : fileName * ".xlsx"

    # Don't generate the Excel report if there's no count report available. This
    #   means that either the time resolution ⩽ 0 or that the simulation hasn't
    #   started yet.
    fluxInCounts = generateNodeFluxReport( mpSim, timeRes, true, "active" )

    if size( fluxInCounts ) == ( 0, 2 )
        return
    end  # if length( fluxInCounts ) == 2

    generateRequiredCompounds( mpSim, nodeList... )

    # Generate the list of actually existing nodes.
    potentialNodes = vcat( collect( keys( mpSim.stateList ) ),
        collect( keys( mpSim.compoundStateList ) ) )
    tmpNodes = Iterators.filter( nodeName -> nodeName ∈ potentialNodes,
        nodeList )
    tmpNodes = unique( tmpNodes )
    tElapsedOther = zeros( Float64, length( tmpNodes ), 2 )

    XLSX.openxlsx( tmpFileName, mode = overWrite ? "w" : "rw" ) do xf
        fluxOutCounts = generateNodeFluxReport( mpSim, timeRes, false, "active" )
        nodeTargets = retrieveNodeTarget( mpSim, "active" )
        persCounts = generateCountReport( mpSim, "active", fluxInCounts,
            fluxOutCounts, nodeTargets )
        tElapsed[ 1 ] = ( now() - tStart ).value / 1000
        tElapsed[ 2 ] = dumpCountData( mpSim, "active", persCounts,
            fluxInCounts, fluxOutCounts, timeRes, xf, overWrite, timeFactor,
            tElapsed[ 1 ] )

        for ii in eachindex( tmpNodes )
            tStart = now()
            fluxInCounts = generateNodeFluxReport( mpSim, timeRes, true,
                tmpNodes[ ii ] )
            fluxOutCounts = generateNodeFluxReport( mpSim, timeRes, false,
                tmpNodes[ ii ] )
            nodeTargets = retrieveNodeTarget( mpSim, tmpNodes[ ii ] )
            persCounts = generateCountReport( mpSim, tmpNodes[ ii ],
                fluxInCounts, fluxOutCounts, nodeTargets )
            tElapsedOther[ ii, 1 ] = ( now() - tStart ).value / 1000
            tElapsedOther[ ii, 2 ] = dumpCountData( mpSim, tmpNodes[ ii ],
                persCounts, fluxInCounts, fluxOutCounts, timeRes, xf, false,
                timeFactor, tElapsedOther[ ii, 1 ] )
        end  # for ii in eachindex( tmpNodes )
    end  # XLSX.openxlsx( tmpFileName, mode = overWrite ? "w" : "rw" )

    println( "Excel population count report generated. Elapsed time: ",
        sum( tElapsed ) + sum( tElapsedOther ), " seconds." )

    return

end  # generateExcelReport( mpSim, timeRes, nodeList; fileName, overWrite,
     #   timeFactor )


# ==============================================================================
# Non-exported methods.
# ==============================================================================

"""
```
generateTimeGrid( mpSim::ManpowerSimulation,
                  timeRes::Real,
                  addCurrentTime::Bool = true )
```
This function generates a time grid for the manpower simulation `mpSim` with
time resolution `timeRes`. The resulting grid will span from 0 to the current
simulation time or the length of the simulation, whichever is smaller. If the
flag `addCurrentTime` is set to `true`, the current simulation time will be
added at the end.

This function returns a `Vector{Float64}`. If the time resolution is negative,
or if the current simulation time is zero, the function gives a warning and
returns `nothing` instead.
"""
function generateTimeGrid( mpSim::ManpowerSimulation, timeRes::Real,
    addCurrentTime::Bool = true )::Vector{Float64}

    if timeRes <= 0
        warn( "Negative time resolution entered. No time grid generated." )
        return
    end  # if timeRes <= 0

    currentTime = min( now( mpSim ), mpSim.simLength )

    if currentTime == 0
        warn( "Simulation hasn't started yet. No time grid generated." )
        return
    end  # if currentTime == 0

    tmpGrid = collect( 0:timeRes:currentTime )

    if addCurrentTime && ( tmpGrid[ end ] < currentTime )
        push!( tmpGrid, currentTime )
    end  # if tmpGrid[ end ] < currentTime

    return tmpGrid

end  # generateTimeGrid( mpSim, timeRes, addCurrentTime )


"""
```
generateRequiredCompounds( mpSim::ManpowerSimulation,
                           nodeList::String... )
```
This function ensures that the manpower simulation `mpSim` has all the compound
nodes which are in the list of nodes `nodeList`.

This function returns `nothing`.
"""
function generateRequiredCompounds( mpSim::ManpowerSimulation,
    nodeList::String... )::Void

    # Add catalogue states ot the compound state list if possible.
    XLSX.openxlsx( mpSim.catFileName ) do catXF
        if XLSX.hassheet( catXF, "General" ) &&
            XLSX.hassheet( catXF, "States" )
            nCatStates = catXF[ "General" ][ "B6" ]
            stateCat = catXF[ "States" ]
            catStateList = string.(
                stateCat[ XLSX.CellRange( 2, 1, nCatStates + 1, 1 ) ][ : ] )

            processCompoundStates( mpSim )
            includeCatNodes( mpSim, collect( nodeList ), stateCat,
                catStateList )
        end  # if XLSX.hassheet( catXF, "General" ) && ...
    end  # XLSX.openxlsx( mpSim.catFileName ) do catXF

    return

end  # generateRequiredCompounds( mpSim, nodeList )


"""
```
includeCatNodes( mpSim::ManpowerSimulation,
                 nodeList::Vector,
                 stateCat::XLSX.Worksheet,
                 catStateList::Vector{String} )
```
This function adds all the valid compound nodes in `nodeList` to the manpower
simulation `mpSim`, using the state catalogue `stateCat` which has the states in
`catStateList` defined. The latter argument is added for convenience. The
`nodeList` argument is a vector that holds elements that are either
`Missings.missing` or the name of a node as a `String`.

This function returns `nothing`.
"""
function includeCatNodes( mpSim::ManpowerSimulation, nodeList::Vector,
    stateCat::XLSX.Worksheet, catStateList::Vector{String} )::Void

    for nodeName in nodeList
        # Check if the node name is
        # 1. empty (whole population)
        # 2. a node name
        # 3. a custom defined agglomeration node name
        # If none of the above, check if it's in the list of
        #   catalogue state names
        if !isa( nodeName, Missings.Missing ) &&
            !haskey( mpSim.stateList, nodeName ) &&
            !haskey( mpSim.compoundStateList, nodeName ) &&
            ( nodeName ∈ catStateList )
            # Find the line in the state catalogue describing the desired
            #   compound node.
            catLine = findfirst( catStateList, nodeName )
            # Read the requirements of the compound node and save them.
            catState = readStateFromCatalogue( nodeName, stateCat,
                catLine )[ 1 ]
            # Figure out which are the base nodes forming the compound node and
            #   add it to the list of compound nodes in the simulation.
            newCompNode = processCompoundState( mpSim, catState )

            if length( newCompNode.stateList ) > 1
                addCompoundState!( mpSim, newCompNode )
            end  # if length( newCompNode.stateList ) > 1
        end  # if !isa( nodeName, Missings.Missing ) && ...
    end  # for nodeName in nodeList

end  # includeCatStates( mpSim, nodeList, stateCat, catStateList )


"""
```
retrieveNodeTarget( mpSim::ManpowerSimulation,
                    node::String )
```
This function retrieves the target population for node `node` in the manpower
simulation `mpSim`.

This function returns a `Dict{String, Int}`, a list of the targets for each
component base node of the node. Any component without a target said will have
-1 as its target.
"""
function retrieveNodeTarget( mpSim::ManpowerSimulation,
    node::String )::Dict{String, Int}

    if node == "active"
        return Dict( node => ( mpSim.personnelTarget == 0 ? -1 :
            mpSim.personnelTarget ) )
    end  # if node == "active"

    if haskey( mpSim.stateList, node )
        return Dict( node => mpSim.stateList[ node ].stateTarget )
    end  # if haskey( mpSim.stateList, node )

    targets = Dict{String, Int}()

    for compNode in mpSim.compoundStateList[ node ].stateList
        targets[ compNode ] = mpSim.stateList[ compNode ].stateTarget
    end  # for compNode in mpSim.compoundStateList[ node ].stateList

    return targets

end  # retrieveNodeTarget( mpSim, node )


"""
```
generateCountReport( mpSim::ManpowerSimulation,
                     nodeName::String,
                     fluxInCount::DataFrame,
                     fluxOutCount::DataFrame )
```
This function generates a report of the number of persons in the manpower
simulation `mpSim` who are in the node with name `nodeName`, using the flux
information contained in the reports `fluxInCount` and `fluxOutCount`.
Attention: this function should not be called directly as it does not perform
any sanity checks on the flux reports.

This function returns a `DataFrame`.
"""
function generateCountReport( mpSim::ManpowerSimulation, nodeName::String,
    fluxInCount::DataFrame, fluxOutCount::DataFrame )::DataFrame

    nodeNames = haskey( mpSim.compoundStateList, nodeName ) ?
        join( mpSim.compoundStateList[ nodeName ].stateList, "', '" ) :
        nodeName
    nodeNames = string( "( '", nodeNames, "' )" )

    queryCmd = string( "SELECT count(`", mpSim.idKey,
        "`) initialPopulation FROM `", mpSim.transitionDBname, "`
        WHERE timeIndex < 0 AND endState IN ", nodeNames )
    initPop = SQLite.query( mpSim.simDB, queryCmd )[ 1, 1 ]
    timeGrid = fluxInCount[ :timeEnd ]
    counts = cumsum( fluxInCount[ end ] - fluxOutCount[ end ] ) + initPop

    return DataFrame( hcat( timeGrid, counts ),
        [ :timePoint, Symbol( nodeName ) ] )

end  # generateCountReport( mpSim, nodeName, fluxInCounts, fluxOutCounts )

"""
```
generateCountReport( mpSim::ManpowerSimulation,
                     nodeName::String,
                     fluxInCount::DataFrame,
                     fluxOutCount::DataFrame,
                     nodeTargets::Dict{String, Int} )
```
This function generates a report of the number of persons in the manpower
simulation `mpSim` who are in the node with name `nodeName`, using the flux
information contained in the reports `fluxInCount` and `fluxOutCount`. The final
parameter, `nodeTargets`, is used to generate a report on the under or over-
occupation of the node. Attention: this function should not be called directly
as it does not perform any sanity checks on the flux reports.

This function returns a `DataFrame`.
"""
function generateCountReport( mpSim::ManpowerSimulation, nodeName::String,
    fluxInCount::DataFrame, fluxOutCount::DataFrame,
    nodeTargets::Dict{String, Int} )::DataFrame

    # First, get population count information.
    popCounts = generateCountReport( mpSim, nodeName, fluxInCount,
        fluxOutCount )

    # If the node is a base node (or the entire population), the under and over
    #   occupation can be computed easily.
    if !haskey( mpSim.compoundStateList, nodeName )
        if nodeTargets[ nodeName ] == -1
            return popCounts
        end  # if nodeTargets[ nodeName ] == -1

        balance = nodeTargets[ nodeName ] - popCounts[ 2 ]
        popCounts[ :vacancies ] = max.( balance, 0 )
        popCounts[ :excess ] = max.( -balance, 0 )
        return popCounts
    end  # if !haskey( mpSim.compoundStateList, nodeName )

    nodeNames = filter( node -> nodeTargets[ node ] != -1,
        collect( keys( nodeTargets ) ) )
    componentDiffs = Array{Int}( length( popCounts[ 1 ] ), length( nodeNames ) )
    timeRes = popCounts[ 2, 1 ] - popCounts[ 1, 1 ]

    for ii in eachindex( nodeNames )
        compName = nodeNames[ ii ]
        compFluxIn = generateNodeFluxReport( mpSim, timeRes, true, compName )
        compFluxOut = generateNodeFluxReport( mpSim, timeRes, false, compName )
        compPop = generateCountReport( mpSim, compName, compFluxIn,
            compFluxOut )
        componentDiffs[ :, ii ] = nodeTargets[ compName ] - compPop[ 2 ]
    end  # for ii in eachindex( nodeNames )

    popCounts[ :vacancies ] = sum( max.( 0, componentDiffs ), 2 )[ : ]
    popCounts[ :excess ] = sum( max.( 0, -componentDiffs ), 2 )[ : ]
    return popCounts

end  # generateCountReport( mpSim, nodeName, fluxInCounts, fluxOutCounts )


"""
```
dumpCountData( mpSim::ManpowerSimulation,
               node::String,
               countData::DataFrame,
               nodeTargets::Dict{String, Int},
               fluxInData::DataFrame,
               fluxOutData::DataFrame,
               timeRes::Real,
               xf::XLSX.XLSXFile,
               overWrite::Bool,
               timeFactor::Real,
               reportGenerationTime::Float64 )
```
This function writes the population data in `countData`, `fluxInData`, and
`fluxOutData` to the Excel file `fileName`, using the other parameters as
guidance. If the flag `overWrite` is `true`, a new file is created, otherwise a
new sheet is added to the file.

This function returns a `Float64`, the time (in seconds) it took to write the
Excel report.
"""
function dumpCountData( mpSim::ManpowerSimulation, node::String,
    countData::DataFrame, fluxInData::DataFrame, fluxOutData::DataFrame,
    timeRes::Real, xf::XLSX.XLSXFile, overWrite::Bool, timeFactor::Real,
    reportGenerationTime::Float64 )::Float64

    tStart = now()
    tElapsed = 0.0
    fSheet = xf[ 1 ]

    # Time adjustment.
    fluxInData[ :, 1 ] /= 12
    fluxInData[ :, 2 ] /= 12

    # Create sheet.
    if overWrite
        XLSX.rename!( fSheet, string( node, " (res ", timeRes, ")" ) )
    else
        fSheet = XLSX.addsheet!( xf, string( node, " (res ", timeRes, ")" ) )
    end  # if overWrite

    # Sheet header
    fSheet[ "A1" ] = "Simulation length"
    fSheet[ "B1" ] = mpSim.simLength / timeFactor
    fSheet[ "C1" ] = "years"
    fSheet[ "A2" ] = "Time resolution of report"
    fSheet[ "B2" ] = timeRes / timeFactor
    fSheet[ "C2" ] = "years"
    fSheet[ "A3" ] = "Report of node:"
    fSheet[ "B3" ] = node == "active" ? "Whole population" : node
    fSheet[ "A4" ] = "Report timestamp"
    fSheet[ "B4" ] = now()
    fSheet[ "A5" ] = "Data generation time"
    fSheet[ "B5" ] = reportGenerationTime
    fSheet[ "C5" ] = "seconds"
    fSheet[ "A6" ] = "Excel generation time"
    fSheet[ "C6" ] = "seconds"

    # Table header
    tmp = [ "Start time", "End time", "Pop at end time", "Flux into node",
        "Flux out of node", "Net flux (in - out)" ]
    hasVacancies = length( countData ) == 4

    if hasVacancies
        append!( tmp, [ "Vacancies at end time", "Over target at end time" ] )
    end  # if length( countData ) == 4

    foreach( ii -> fSheet[ XLSX.CellRef( 8, ii ) ] = tmp[ ii ],
        eachindex( tmp ) )
    fluxInNames = string.( names( fluxInData[ 3:(end-1) ] ) )
    map!( fluxName -> split( fluxName, " to " )[ 1 ], fluxInNames,
        fluxInNames )
    fluxOutNames = string.( names( fluxOutData[ 3:(end-1) ] ) )
    map!( fluxName -> split( fluxName, " from " )[ 1 ], fluxOutNames,
        fluxOutNames )

    inCol = length( tmp ) + 1
    foreach( ii -> fSheet[ XLSX.CellRef( 8, inCol + ii ) ] =
        fluxInNames[ ii ], eachindex( fluxInNames ) )

    if isempty( fluxInNames )
        fSheet[ XLSX.CellRef( 8, inCol + 1 ) ] = "No flux into node"
    end  # if isempty( fluxInNames )

    outCol = inCol + length( fluxInNames ) +
        ( isempty( fluxInNames ) ? 2 : 1 )
    foreach( ii -> fSheet[ XLSX.CellRef( 8, outCol + ii ) ] =
        fluxOutNames[ ii ], eachindex( fluxOutNames ) )

    if isempty( fluxOutNames )
        fSheet[ XLSX.CellRef( 8, outCol + 1 ) ] = "No flux out of node"
    end  # if isempty( fluxOutNames )


    for ii in eachindex( countData[ 1 ] )
        jj = 8 + ii
        tmp = [ fluxInData[ ii, 1 ], fluxInData[ ii, 2 ],
            countData[ ii, 2 ], fluxInData[ ii, end ],
            fluxOutData[ ii, end ],
            fluxInData[ ii, end ] - fluxOutData[ ii, end ] ]

        if hasVacancies
            append!( tmp, [ countData[ ii, 3 ], countData[ ii, 4 ] ] )
        end  # if hasVacancies

        foreach( kk -> fSheet[ XLSX.CellRef( jj, kk ) ] = tmp[ kk ],
            eachindex( tmp ) )
    end  # for ii in eachindex( countData[ 1 ] )

    if !isempty( fluxInNames )
        for ii in eachindex( fluxInData[ 1 ] )
            jj = 8 + ii
            tmp = Array( fluxInData[ ii, 3:(end-1) ] )
            foreach( kk -> fSheet[ XLSX.CellRef( jj, kk + inCol ) ] =
                tmp[ kk ], eachindex( tmp ) )
        end  # for ii in eachindex( fluxInData[ 1 ] )
    end  # if !isempty( fluxInData )

    if !isempty( fluxOutNames )
        for ii in eachindex( fluxOutData[ 1 ] )
            jj = 8 + ii
            tmp = Array( fluxOutData[ ii, 3:(end-1) ] )
            foreach( kk -> fSheet[ XLSX.CellRef( jj, kk + outCol ) ] =
                tmp[ kk ], eachindex( tmp ) )
        end  # for ii in eachindex( fluxOutData[ 1 ] )
    end  # if !isempty( fluxOutData )

    tElapsed = ( now() - tStart ).value / 1000.0
    fSheet[ "B6" ] = tElapsed

    return tElapsed

end  # dumpCountData( mpSim, node, countData, fluxInData, fluxOutData,
     #   timeRes, xf, overWrite, timeFactor, reportGenerationTime )


include( "popPlots.jl" )
include( "fluxReports.jl" )
include( "fluxPlots.jl" )
include( "systemPlots.jl" )
