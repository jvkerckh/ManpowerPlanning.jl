# This file holds all the functions that are needed to distill population flux
#   reports from the simulation results database.

export  generateExcelFluxReport,
        generateNodeFluxReport,
        generateFluxReport


"""
```
generateExcelFluxReport( mpSim::ManpowerSimulation,
                         timeRes::Real,
                         transList::Union{String, Tuple{String, String}}...;
                         fileName::String = "testFluxReport",
                         overWrite::Bool = true,
                         timeFactor::Real = 12.0 )
```
This function creates a report on fluxes in the manpower simulation `mpSim` on a
grid with time resolution `timeRes`, showing all the transitions
(transition types) listed in `transList`. These transitions can be entered by
transition name (as `String`) or as source/target state pairs (as
`Union{String, Tuple{String, String}}`). Non existing transitions are ignored,
names of recruitment schemes are accepted, the outflows `retirement`,
`attrition`, and `fired` are accepted, and the empty state or state `external`
is accepted to describe in and out transitions. The report is then saved in the
Excel file `fileName`, with the extension `".xlsx"` added if necessary. If the
flag `overWrite` is `true`, a new Excel file is created. Otherwise, the report
is added to the Excel file. Times are compressed by a factor `timeFactor`.

This function returns `nothing`.
"""
function generateExcelFluxReport( mpSim::ManpowerSimulation, timeRes::Real,
    transList::Union{String, Tuple{String, String},
        Tuple{String, String, String}}...;
    fileName::String = "testFluxReport", overWrite::Bool = true,
    timeFactor::Real = 12.0 )::Void

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
    tElapsed = [ 0.0, 0.0 ]
    tmpFileName = endswith( fileName, ".xlsx" ) ? fileName : fileName * ".xlsx"

    # Generate the data.
    fluxData = generateFluxReport( mpSim, timeRes, transList... )
    fluxData[ 1 ] /= timeFactor
    fluxData[ 2 ] /= timeFactor
    tElapsed[ 1 ] = ( now() - tStart ).value / 1000.0

    # Write the report.
    tElapsed[ 2 ] = dumpFluxData( mpSim, fluxData, timeRes, tmpFileName,
        overWrite, timeFactor, tElapsed[ 1 ] )
    println( "Excel flux report generated. Elapsed time: ", sum( tElapsed ),
        " seconds." )
    return

end  # generateExcelFluxReport( mpSim, timeRes, transList, fileName, overWrite,
     #   timeFactor )


"""
```
generateNodeFluxReport( mpSim::ManpowerSimulation
                        timeRes::Real,
                        isIn::Bool,
                        nodeList::String... )
```
This function creates a report on fluxes in the manpower simulation `mpSim` on a
grid with time resolution `timeRes` from/to all the states listed in
`nodeList`. If the flag `isIn` is set to `true`, these are the in fluxes,
otherwise these are the out fluxes. The total in/out flux is broken down by
transition and by source/target state.

This function returns a `Dataframe`, where the columns `:timeStart` and
`:timeEnd` hold the start and end times of each interval, and the other columns
the fluxes for each time interval `timeStart < t <= timeEnd`
except for the first row; that one counts the flux occurring at time `t = 0.0`.
"""
function generateNodeFluxReport( mpSim::ManpowerSimulation, timeRes::Real,
    isIn::Bool, nodeList::String... )::DataFrame

    resultReport = DataFrames.DataFrame( Array{Float64}( 0, 2 ),
        [ :timeStart, :timeEnd ] )

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

    # Add catalogue states to the compound state list if possible.
    generateRequiredCompounds( mpSim, nodeList... )

    # Build list of real states.
    tmpNodeList = Vector{String}()

    for stateName in nodeList
        if haskey( mpSim.stateList, stateName ) ||
            haskey( mpSim.compoundStateList, stateName )
            push!( tmpNodeList, stateName )
        elseif lowercase( stateName ) == "active"
            push!( tmpNodeList, "active" )
        end  # if haskey( mpSim.stateList, state ) || ...
    end  # for state in nodeList

    tmpNodeList = unique( tmpNodeList )

    # Generate the time grid.
    timeGrid = generateTimeGrid( mpSim, timeRes )
    nTimes = length( timeGrid )

    # Generate the results.
    resultData = hcat( vcat( 0.0, timeGrid[ 1:(end-1) ] ), timeGrid )
    nameList = Vector{String}()

    # Add the the flux counts for every state.
    for ii in eachindex( tmpNodeList )
        tmpNameList, tmpResult = countNodeFlux( mpSim, tmpNodeList[ ii ],
            timeGrid, isIn )
        nameList = vcat( nameList, tmpNameList )
        resultData = hcat( resultData, tmpResult )
    end  # for ii in eachindex( tmpNodeList )

    resultReport = DataFrame( resultData, vcat( :timeStart, :timeEnd,
        Symbol.( nameList ) ) )

    return resultReport

end  # generateNodeFluxReport( mpSim, timeRes, isIn, nodeList... )


"""
```
generateFluxReport( mpSim::ManpowerSimulation,
                    timeRes::Real,
                    transList::Union{String, Tuple{String, String},
                        Tuple{String, String, String}}... )
```
This function creates a report on fluxes in the manpower simulation `mpSim` on a
grid with time resolution `timeRes`, showing all the transitions
(transition types) listed in `transList`. These transitions can be entered by
transition name (as `String`) or as source/target state pairs (as
`Union{String, Tuple{String, String}}`). Non existing transitions are ignored,
names of recruitment schemes are accepted, the outflows `retirement`,
`attrition`, and `fired` are accepted, and the empty state or state `external`
is accepted to describe in and out transitions.

This function returns a `Dataframe`, where the columns `:timeStart` and
`:timeEnd` hold the start and end times of each interval, and the other columns
the flux, per transition, for each time interval `timeStart < t <= timeEnd`
except for the first row; that one counts the flux occurring at time `t = 0.0`.
"""
function generateFluxReport( mpSim::ManpowerSimulation, timeRes::Real,
    transList::Union{String, Tuple{String, String},
        Tuple{String, String, String}}... )::DataFrame

    resultReport = DataFrame( Array{Float64}( 0, 2 ),
        [ :timeStart, :timeEnd ] )

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

    tmpTransList, tmpPairList, tmpTripleList = generateValidTransitionLists(
        mpSim, collect( transList ) )

    resultData, nameList, nameList2 = generateFluxData( mpSim, timeRes,
        tmpTransList, tmpPairList, tmpTripleList )

    resultReport = DataFrame( resultData, vcat( :timeStart, :timeEnd,
        Symbol.( tmpTransList ), Symbol.( nameList ), Symbol.( nameList2 ) ) )

    return resultReport

end  # generateFluxReport( mpSim, timeRes, transList... )


# ==============================================================================
# Non-exported methods.
# ==============================================================================

"""
```
generateValidTransitionLists( mpSim::ManpowerSimulation,
                              transList::Vector )
```
This function filters all transitions in the list `transList` on plausability
using the information of the manpower simulation `mpSim`. The vector `transList`
contains elements of three different types: `String`, `Tuple{String, String}`,
and `Tuple{String, String, String}`.

This function returns a `Tuple` consisting of a `Vector{String}`, a
`Vector{Tuple{String, String}}`, and a `Vector{Tuple{String, String, String}}`
object, which are the filtered lists for each type of transition.
"""
function generateValidTransitionLists( mpSim::ManpowerSimulation,
    transList::Vector )

    # Split the transitions by type.
    tmpTransList = Vector{String}(
        filter( trans -> trans isa String, transList ) )
    tmpPairList = Vector{Tuple{String, String}}(
        filter( trans -> trans isa Tuple{String, String}, transList ) )
    tmpTripleList = Vector{Tuple{String, String, String}}(
        filter( trans -> trans isa Tuple{String, String, String}, transList ) )

    # Get all nodes in the list of transitions.
    nodeList = vcat( map( trans -> trans[ 1 ], tmpPairList ),
        map( trans -> trans[ 2 ], tmpPairList ),
        map( trans -> trans[ 2 ], tmpTripleList ),
        map( trans -> trans[ 3 ], tmpTripleList ) )
    nodeList = unique( nodeList )

    # Generate compound nodes if necessary.
    XLSX.openxlsx( mpSim.catFileName ) do catXF
        if XLSX.hassheet( catXF, "General" ) && XLSX.hassheet( catXF, "States" )
            nCatStates = catXF[ "General" ][ "B6" ]
            stateCat = catXF[ "States" ]
            catStateList = string.(
                stateCat[ XLSX.CellRange( 2, 1, nCatStates + 1, 1 ) ][ : ] )

            processCompoundStates( mpSim )
            includeCatNodes( mpSim, nodeList, stateCat, catStateList )
        end  # if XLSX.hassheet( catXF, "General" ) && ...
    end  # XLSX.openxlsx( mpSim.catFileName ) do catXF

    # Filter out invalid transitions.
    filter!( trans -> validateTransition( mpSim, trans ), tmpTransList )
    filter!( trans -> validateTransition( mpSim, trans[ 1 ], trans[ 2 ] ),
        tmpPairList )
    filter!( trans -> validateTransition( mpSim, trans[ 1 ] ) &&
        validateTransition( mpSim, trans[ 2 ], trans[ 3 ] ), tmpTripleList )

    return unique( tmpTransList ), unique( tmpPairList ),
        unique( tmpTripleList )

end  # generateValidTransitionLists( mpSim, transList )


"""
```
generateFluxData( mpSim::ManpowerSimulation,
                  timeRes::Real,
                  tmpTransList::Vector{String},
                  tmpPairList::Vector{Tuple{String, String}},
                  tmpTripleList::Vector{Tuple{String, String, String}} )
```
This function generates flux data for the manpower simulation `mpSim` for each
of the requested transitions for a grid with time resolution `timeRes`. The
transitions are requested in 3 ways:
* Vector `tmpTransList`: transitions requested by type. This gives the
  cumulative flux for all transitions of this type.
* vector `tmpPairList`: transitions requested by source/target node pair. This
  gives the cumulative flux for all transitions from the source to the target
  node.
* Vector `tmpTripleList`: transitions requested by type + source/target pair.

The function returns a `Tuple` consisting of 3 elements: an `Array{Int}` with
the fluxes, where each column is the evolutino of the flux, and the columns are
ordered by `tmpTransList`, `tmpPairList`, and then `tmpTripleList`; a
`Vector{String}` with the labels for all transitions in `tmpPairList`; a
`Vector{String}` with the labels for all transitions in `tmpTripleList`.
"""
function generateFluxData( mpSim::ManpowerSimulation, timeRes::Real,
    tmpTransList::Vector{String}, tmpPairList::Vector{Tuple{String, String}},
    tmpTripleList::Vector{Tuple{String, String, String}} )

    # Generate the time grid.
    timeGrid = generateTimeGrid( mpSim, timeRes )
    nTimes = length( timeGrid )
    nTrans = length( tmpTransList )
    nPairs = length( tmpPairList )
    nTriples = length( tmpTripleList )

    # Generate the results matrix.
    resultData = zeros( nTimes, nTrans + nPairs + nTriples + 2 )
    resultData[ :, 1 ] = vcat( 0.0, timeGrid[ 1:(end-1) ] )
    resultData[ :, 2 ] = timeGrid
    nameList = Vector{String}( nPairs )
    nameList2 = Vector{String}( nTriples )

    # Add the transitions by name.
    for ii in eachindex( tmpTransList )
        resultData[ :, ii + 2 ] = countTransitionFlux( mpSim,
            tmpTransList[ ii ], timeGrid )
    end  # for jj in eachindex( tmpTransList )

    # Add the transitions by source/target state pair.
    for ii in eachindex( tmpPairList )
        startNode, endNode = tmpPairList[ ii ]

        if startNode == ""
            nameList[ ii ] = string( "External to ", endNode == "active" ?
                "System" : endNode )
        elseif endNode == ""
            nameList[ ii ] = string( startNode == "active" ? "System" :
                startNode, " to External" )
        else
            nameList[ ii ] = string( startNode, " to ", endNode )
        end  # if startNode == ""

        resultData[ :, ii + nTrans + 2 ] =
            countTransitionFlux( mpSim, startNode, endNode,
            timeGrid )
    end  # for jj in eachindex( tmpTransList )

    for ii in eachindex( tmpTripleList )
        transName, startNode, endNode = tmpTripleList[ ii ]

        if startNode == ""
            nameList2[ ii ] = string( transName, ": External to ",
                endNode == "active" ? "System" : endNode )
        elseif endNode == ""
            nameList2[ ii ] = string( transName, ": ", startNode == "active" ?
                "System" : startNode, " to External" )
        else
            nameList2[ ii ] = string( transName, ": ", startNode, " to ",
                endNode )
        end  # if startNode == ""

        resultData[ :, ii + nTrans + nPairs + 2 ] =
            countTransitionFlux( mpSim, transName, startNode, endNode,
            timeGrid )
    end  # for ii in eachIndex( tmpTripleList )

    return resultData, nameList, nameList2

end  # generateFluxData( mpSim, timeRes, tmpTransList, tmpPairList,
     #   tmpTripleList )


"""
```
validateTransition( mpSim::ManpowerSimulation,
                    transName::String )
```
This function tests if the manpower simulation `mpSim` has a transition named
`transName`, either as an in-transition (recruitment line), a through-
transition, or an out-transition (including `attrition`).

This function returns a `Bool`, the result of the test.
"""
function validateTransition( mpSim::ManpowerSimulation,
    transName::String )::Bool

    isAttr = lowercase( transName ) == "attrition"
    isIn = transName ∈ map( recScheme -> recScheme.name,
        mpSim.recruitmentSchemes )
    isTrans = haskey( mpSim.transList, transName )

    return isIn || isAttr || isTrans

end  # validateTransition( mpSim, transName )


"""
```
validateTransition( mpSim::ManpowerSimulation,
                    startNode::String,
                    startNode::String )
```
This function tests if the manpower simulation `mpSim` can have a transition
between `startNode` and `endNode`, where an empty string is used to denote in
and out-transitions. Note that it doens't check whether a transition between
these states actually exists.

This function returns a `Bool`, the result of the test.
"""
function validateTransition( mpSim::ManpowerSimulation, startNode::String,
    endNode::String )::Bool

    # Which type of node are the start and end nodes, external, base, or
    #   compound?
    isStartExt = startNode == ""
    isStartBase = haskey( mpSim.stateList, startNode )
    isStartCompound = haskey( mpSim.compoundStateList, startNode )
    isEndExt = endNode == ""
    isEndBase = haskey( mpSim.stateList, endNode )
    isEndCompound = haskey( mpSim.compoundStateList, endNode )

    # If the start node is contained in the end node, or vice versa, the
    #   transition is invalid.
    if isStartBase && isEndCompound &&
        ( mpSim.stateList[ startNode ] ∈ mpSim.compoundStateList[ endNode ] )
        return false
    elseif isStartCompound && isEndBase &&
        ( mpSim.stateList[ endNode ] ∈ mpSim.compoundStateList[ startNode ] )
        return false
    elseif isStartCompound && isEndCompound &&
        ( ( mpSim.compoundStateList[ startNode ] ⊆
            mpSim.compoundStateList[ endNode ] ) ||
        ( mpSim.compoundStateList[ endNode ] ⊆
            mpSim.compoundStateList[ startNode ] ) )
        return false
    end  # if isStartBase &&

    isStartNode = isStartBase || isStartCompound
    isEndNode = isEndBase || isEndCompound

    isIn = isStartExt && isEndNode
    isOut = isStartNode & isEndExt
    isThrough = isStartNode && isEndNode

    return isIn || isOut || isThrough

end  # validateTransition( mpSim, startNode, endNode )


"""
```
countNodeFlux( mpSim::ManpowerSimulation,
               stateName::String,
               timeGrid::Vector{Float64},
               isIn::Bool )
```
This function counts the fluxes in the manpower simulation `mpSim` of the
transition from/to the state with name `stateName` over the time grid
`timeGrid`. If `isIn` is true, the in fluxes are counted, otherwise the out
fluxes are counted.

The function returns a `Tuple{Vector{String}}, Array{Int}` where the first
element is the name of each transition, given in such a way it carries all
needed information, and the second element is the matrix of the fluxes for each
time interval, where the total flux (the last column) is broken down by
transition and source/taget state. The first row of the matrix are the fluxes
that occur at time 0.
"""
function countNodeFlux( mpSim::ManpowerSimulation, stateName::String,
    timeGrid::Vector{Float64}, isIn::Bool )

    tmpFluxResult = Dict{String, Vector{Int}}()

    # First, get ALL fluxes to or from the state.
    countCol = isIn ? "startState" : "endState"

    queryCmd = string( "SELECT timeIndex, transition, ", countCol,
        " FROM `", mpSim.transitionDBname, "`
        WHERE 0 <= timeIndex AND " )
    stateNames = haskey( mpSim.compoundStateList, stateName ) ?
        join( mpSim.compoundStateList[ stateName ].stateList, "', '" ) :
        stateName
    stateNames = string( "( '", stateNames, "' )" )
    queryCond = ""

    if isIn
        queryCond = string( "( startState IS NULL OR startState NOT IN ",
            stateNames, " ) AND endState IN ", stateNames )
    else
        queryCond = string( "startState IN ", stateNames,
            " AND ( endState IS NULL OR endState NOT IN ", stateNames, " )" )
    end  # if isIn

    queryCmd = string( queryCmd, queryCond )
    transRecord = SQLite.query( mpSim.simDB, queryCmd )
    nFlux = size( transRecord )[ 1 ]
    map!( entry -> isa( entry, Missings.Missing ) ? "external" : entry,
        transRecord[ Symbol( countCol ) ], transRecord[ Symbol( countCol ) ] )
    transRecord[ :transType ] = string.( transRecord[ :transition ],
        ( isIn ? " from " : " to " ), transRecord[ Symbol( countCol ) ] )
    nameList = unique( transRecord[ :transType ] )

    # Ensure that "attrition" is part of the names for an out flux report, with
    #   breakdown by transition.
    if !isIn && !( "attrition to external" in nameList )
        push!( nameList, "attrition to external" )
    end  # if !isIn && ...

    nNames = length( nameList )
    fluxResult = zeros( Int, length( timeGrid ), nNames + 1 )
    foreach( name -> tmpFluxResult[ name ] = zeros( timeGrid ), nameList )

    for ii in eachindex( timeGrid )
        startTime = ii == 1 ? 0.0 : timeGrid[ ii - 1 ]
        endTime = timeGrid[ ii ]
        isInTimeSpan = ii == 1 ? transRecord[ :timeIndex ] .== 0 :
            startTime .< transRecord[ :timeIndex ] .<= endTime
        tmpCount = StatsBase.countmap( transRecord[ isInTimeSpan, :transType ] )
        foreach( name -> tmpFluxResult[ name ][ ii ] = tmpCount[ name ],
            keys( tmpCount ) )
    end  # for ii in eachindex( timeGrid )

    foreach( ii -> fluxResult[ :, ii ] = tmpFluxResult[ nameList[ ii ] ],
        1:nNames )

    if nNames == 1
        fluxResult[ :, 2 ] = fluxResult[ :, 1 ]
    else
        fluxResult[ :, nNames + 1 ] = sum( fluxResult[ :, 1:nNames ], 2 )
    end  # if nNames == 1

    nameList = string.( nameList, isIn ? " to " : " from ", stateName )

    return vcat( nameList, string( "flux ", isIn ? "into" : "out of", ' ',
        stateName ) ), fluxResult

end  # countNodeFlux( mpSim, stateName, timeGrid, isIn )


"""
```
countTransitionFlux( mpSim::ManpowerSimulation,
                     transName::String,
                     timeGrid::Vector{Float64} )
```
This function counts the fluxes in the manpower simulation `mpSim` of the
transition with name `transName` over the time grid `timeGrid`.

The function returns a `Vector{Int}` with the flux counts for each time
interval. The first entry of the vector is the flux that occurs at time 0.
"""
function countTransitionFlux( mpSim::ManpowerSimulation, transName::String,
    timeGrid::Vector{Float64} )::Vector{Int}

    # The distinct is necessary because in and out transitions are listed more
    #   than once, once as a transition from/to active, once as a transition
    #   from/to their current state(s).
    queryCmd = string( "SELECT DISTINCT `", mpSim.idKey,
        "`, timeIndex FROM `", mpSim.transitionDBname, "`
        WHERE transition IS '", transName, "'" )
    transTime = SQLite.query( mpSim.simDB, queryCmd )[ 2 ]
    counts = zeros( timeGrid, Int )

    if !isempty( transTime )
        for jj in eachindex( timeGrid )
            startTime = jj == 1 ? 0 : timeGrid[ jj - 1 ]
            endTime = timeGrid[ jj ]
            counts[ jj ] = sum( jj == 1 ? startTime .== transTime :
                startTime .< transTime .<= endTime )
        end  # for jj in eachindex( timeGrid )
    end  # if !isempty( transTime )

    return counts

end  # countTransitionFlux( mpSim, transName, timeGrid )

"""
```
countTransitionFlux( mpSim::ManpowerSimulation,
                     startNode::String,
                     endNode::String,
                     timeGrid::Vector{Float64} )
```
This function counts the fluxes in the manpower simulation `mpSim` of the
transition from `startNode` to `endNode` over the time grid `timeGrid`. If
either of these are compound nodes,

The function returns a `Vector{Int}` with the flux counts for each time
interval. The first entry of the vector is the flux that occurs at time 0.
"""
function countTransitionFlux( mpSim::ManpowerSimulation, startNode::String,
    endNode::String, timeGrid::Vector{Float64} )::Vector{Int}

    queryCmd = generateTransQuery( mpSim, startNode,  endNode )
    transTime = SQLite.query( mpSim.simDB, queryCmd )[ 2 ]
    counts = zeros( timeGrid, Int )

    if !isempty( transTime )
        for jj in eachindex( timeGrid )
            startTime = jj == 1 ? 0 : timeGrid[ jj - 1 ]
            endTime = timeGrid[ jj ]
            counts[ jj ] = sum( jj == 1 ? startTime .== transTime :
                startTime .< transTime .<= endTime )
        end  # for jj in eachindex( timeGrid )
    end  # if !isempty( transTime )

    return counts

end  # countTransitionFlux( mpSim, startNode, endNode, timeGrid )

"""
```
countTransitionFlux( mpSim::ManpowerSimulation,
                     transName::String,
                     startNode::String,
                     endNode::String,
                     timeGrid::Vector{Float64} )
```
This function counts the fluxes in the manpower simulation `mpSim` of the
transition with name `transName` and going from `startNode` to `endNode` over
the time grid `timeGrid`.

The function returns a `Vector{Int}` with the flux counts for each time
interval. The first entry of the vector is the flux that occurs at time 0.
"""
function countTransitionFlux( mpSim::ManpowerSimulation, transName::String,
    startNode::String, endNode::String,
    timeGrid::Vector{Float64} )::Vector{Int}

    queryCmd = string( generateTransQuery( mpSim, startNode, endNode ),
        " AND transition IS '", transName, "'" )
    transTime = SQLite.query( mpSim.simDB, queryCmd )[ 2 ]
    counts = zeros( timeGrid, Int )

    if !isempty( transTime )
        for jj in eachindex( timeGrid )
            startTime = jj == 1 ? 0 : timeGrid[ jj - 1 ]
            endTime = timeGrid[ jj ]
            counts[ jj ] = sum( jj == 1 ? startTime .== transTime :
                startTime .< transTime .<= endTime )
        end  # for jj in eachindex( timeGrid )
    end  # if !isempty( transTime )

    return counts

end  # countTransitionFlux( mpSim, transName, startNode, endNode, timeGrid )


"""
```
generateTransQuery( mpSim::ManpowerSimulation,
                    startNode::String,
                    endNode::String )
```
This function generates an SQL query that grabs all transitions from the results
database of the manpower simulation `mpSim`, where the transitions go from
`startNode` to `endNode`.

This function returns a `String`, the resulting SQL query.
"""
function generateTransQuery( mpSim::ManpowerSimulation, startNode::String,
    endNode::String )::String

    isStartBase = ( startNode == "" ) || haskey( mpSim.stateList, startNode )
    isEndBase = ( endNode == "" ) || haskey( mpSim.stateList, endNode )

    # Generate the SQL conditions.
    startCond = "startState "
    endCond = "endState "

    if isStartBase
        startCond = string( startCond, "IS ", startNode == "" ? "NULL" :
            string( "'", startNode, "'" ) )
    else
        compList = mpSim.compoundStateList[ startNode ].stateList

        # Take set difference if the end node of the transition is also a
        #   compound node.
        if !isEndBase
            filter!( compNode -> compNode ∉
                mpSim.compoundStateList[ endNode ].stateList, compList )
        end  # if !isEndBase

        startCond = string( startCond, "IN ('", join( compList, "', '" ), "')" )
    end  # if isStartBase

    if isEndBase
        endCond = string( endCond, "IS ", endNode == "" ? "NULL" :
            string( "'", endNode, "'" ) )
    else
        compList = mpSim.compoundStateList[ endNode ].stateList

        # Take set difference if the start node of the transition is also a
        #   compound node.
        if !isStartBase
            filter!( compNode -> compNode ∉
                mpSim.compoundStateList[ startNode ].stateList, compList )
        end  # if !isEndBase

        endCond = string( endCond, "IN ('", join( compList, "', '" ), "')" )
    end  # if isStartBase

    return string( "SELECT DISTINCT `", mpSim.idKey,
        "`, timeIndex FROM `", mpSim.transitionDBname, "`
        WHERE ", startCond, " AND ", endCond )

end  # generateTransQuery( mpSim, startNode, endNode )


"""
```
dumpFluxData( mpSim::ManpowerSimulation,
              fluxData::DataFrame,
              timeRes::Real,
              fileName::String,
              overWrite::Bool,
              timeFactor::Real,
              reportGenerationTime::Float64 )
```
This function writes the flux data in `fluxData` to the Excel file `fileName`,
using the other parameters as guidance. If the flag `overWrite` is `true`, a new
file is created, otherwise a new sheet is added to the file.

This function returns a `Float6'`, the time (in seconds) it took to write the
Excel report.
"""
function dumpFluxData( mpSim::ManpowerSimulation, fluxData::DataFrame,
    timeRes::Real, fileName::String, overWrite::Bool, timeFactor::Real,
    reportGenerationTime::Float64 )::Float64

    tStart = now()
    tElapsed = 0.0

    XLSX.openxlsx( fileName, mode = overWrite ? "w" : "rw" ) do xf
        fSheet = xf[ 1 ]

        # Prep the new sheet.
        if overWrite
            XLSX.rename!( fSheet, "Flux Report" )
        else
            nSheets = XLSX.sheetcount( xf )
            fSheet = XLSX.addsheet!( xf, string( "Flux Report ", nSheets + 1 ) )
        end  # if overWrite

        # Sheet header
        fSheet[ "A1" ] = "Simulation length"
        fSheet[ "B1" ] = mpSim.simLength / timeFactor
        fSheet[ "C1" ] = "years"
        fSheet[ "A2" ] = "Time resolution of report"
        fSheet[ "B2" ] = timeRes / timeFactor
        fSheet[ "C2" ] = "years"
        fSheet[ "A3" ] = "Data generation time"
        fSheet[ "B3" ] = reportGenerationTime
        fSheet[ "C3" ] = "seconds"
        fSheet[ "A4" ] = "Excel generation time"
        fSheet[ "C4" ] = "seconds"

        # Table header
        tNames = string.( names( fluxData )[ 3:end ] )
        fSheet[ "A6" ] = "Start time"
        fSheet[ "B6" ] = "End time"

        foreach( ii -> fSheet[ XLSX.CellRef( 6, ii + 2 ) ] = tNames[ ii ],
            eachindex( tNames ) )

        nPoints, nCols = size( fluxData )

        for ii in 1:nPoints, jj in 1:nCols
            fSheet[ XLSX.CellRef( 6 + ii, jj ) ] = fluxData[ ii, jj ]
        end  # for ii in 1:nPoints, jj in 1:nCols

        # Add averages and standard deviations of fluxes.
        fSheet[ XLSX.CellRef( nPoints + 8, 2 ) ] = "Average flux"
        fSheet[ XLSX.CellRef( nPoints + 9, 2 ) ] = "St.dev. of flux"

        for jj in eachindex( tNames )
            rangeRef = XLSX.CellRange( 7, jj + 2, nPoints + 6, jj + 2 )

            avRef = XLSX.CellRef( nPoints + 8, jj + 2 )
            fSheet[ avRef ] = string( "=average(", rangeRef, ")" )
            testCell = XLSX.getcell( fSheet, avRef )
            testCell.formula = fSheet[ avRef ]

            sdRef = XLSX.CellRef( nPoints + 9, jj + 2 )
            fSheet[ sdRef ] = string( "=stdev(", rangeRef, ")" )
            testCell = XLSX.getcell( fSheet, sdRef )
            testCell.formula = fSheet[ sdRef ]
        end  # for jj in eachindex( tNames )

        tElapsed = ( now() - tStart ).value / 1000.0
        fSheet[ "B4" ] = tElapsed
    end  # XLSX.openxlsx( tmpFileName, "w" ) do xf

    return tElapsed

end  # dumpFluxData( mpSim, fluxData, timeRes, fileName, overWrite, timeFactor )
