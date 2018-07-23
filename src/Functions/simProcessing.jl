# This file holds all the functions related to processing simulation results.

# The prerequisite group that allows counting of personnel members.
# countPersonnelPrereqGroup = PrerequisiteGroup()
# addPrereq!( countPersonnelPrereqGroup, Prerequisite( :status, :active,
#     relation = ==, valType = Symbol ) )


export getActiveAtTime,
       getActiveAgesAtTime,
       getInFlux,
       getOutFlux,
       getLastChanges,
       getDatabaseAtTime


"""
```
getActiveAtTime( mpSim::ManpowerSimulation,
                 timePoint::T,
                 fields::Vector{String} = Vector{String}() )
    where T <: Real
```
This function retrieves a view of all the personnel in the simulation `mpSim`
who were active at time `timePoint`, and displays the ID key and all the columns
listed in `fields`.

If the given time is < 0 or larger than the current simulation time or the
length of the simulation (whichever is smaller), this function returns
`nothing`. Otherwise, it returns a `DataFrames.DataFrame` object.
"""
function getActiveAtTime( mpSim::ManpowerSimulation, timePoint::T,
    fields::Vector{String} = Vector{String}() ) where T <: Real

    if ( timePoint < 0 ) || ( timePoint > min( now( mpSim ), mpSim.simLength ) )
        return
    end  # if ( timePoint < 0 ) || ...

    tmpFields = unique( vcat( mpSim.idKey, fields ) )
    queryCmd = "SELECT $(join( tmpFields, ", " ))
        FROM $(mpSim.personnelDBname)
        WHERE ( timeEntered <= $timePoint ) AND
            ( ( timeExited > $timePoint ) OR ( timeExited IS NULL ) )
        ORDER BY $(mpSim.idKey)"
    return SQLite.query( mpSim.simDB, queryCmd )

end  # getActiveAtTime( mpSim, timePoint, fields )

"""
```
getActiveAtTime( mpSim::ManpowerSimulation,
                 stateName::String,
                 timePoint::T,
                 fields::Vector{String} = Vector{String}() )
    where T <: Real
```
This function retrieves a view of all the personnel in the simulation `mpSim`
who had the state with name `stateName` at time `timePoint`, and displays the ID
key and all the columns listed in `fields`.

If the given time is < 0 or larger than the current simulation time or the
length of the simulation (whichever is smaller), this function returns
`nothing`. Otherwise, it returns a `DataFrames.DataFrame` object.
"""
function getActiveAtTime( mpSim::ManpowerSimulation, stateName::String,
    timePoint::T, fields::Vector{String} = Vector{String}() ) where T <: Real

    if ( timePoint < 0 ) || ( timePoint > min( now( mpSim ), mpSim.simLength ) )
        return
    end  # if ( timePoint < 0 ) || ...

    tmpFields = unique( vcat( mpSim.idKey, fields ) )
    queryCmd = "SELECT $(join( tmpFields, ", " ))
        FROM $(mpSim.personnelDBname)
        WHERE timeEntered < 0"
    dummyResult = SQLite.query( mpSim.simDB, queryCmd )

    # Get the IDs of all active personnel members at that time.
    activeIDs = getActiveAtTime( mpSim, timePoint )[ 1 ]

    # Don't continue if there are no active personnel at that time.
    if isempty( activeIDs )
        return dummyResult
    end  # if isempty( activeIDs )

    # In that list, find all IDs of personnel that are in the required state at
    #   the given time.
    queryCmd = "SELECT $(mpSim.idKey), count( $(mpSim.idKey) ) appearances
	    FROM $(mpSim.transitionDBname)
	    WHERE ( $(mpSim.idKey) IN ('$(join( activeIDs, "', '" ))') ) AND
            ( timeIndex <= $timePoint ) AND
            ( ( endState IS '$stateName' ) OR ( startState IS '$stateName' ) )
	    GROUP BY $(mpSim.idKey)"
    activeIDs = SQLite.query( mpSim.simDB, queryCmd )
    activeIDs = activeIDs[ Symbol( mpSim.idKey ) ][
        activeIDs[ :appearances ] .== 1 ]

    # Don't continue if there are no active personnel with the given state at
    #   that time.
    if isempty( activeIDs )
        return dummyResult
    end  # if isempty( activeIDs )

    # Get the requested fields of the active IDs.
    queryCmd = "SELECT $(join( tmpFields, ", " ))
        FROM $(mpSim.personnelDBname)
        WHERE $(mpSim.idKey) IN ('$(join( activeIDs, "', '" ))')"
    return SQLite.query( mpSim.simDB, queryCmd )

end  # getActiveAtTime( mpSim, stateName, timePoint, fields )


"""
```
getActiveAgesAtTime( mpSim::ManpowerSimulation,
                     timePoint::T )
    where T <: Real
```
This function returns the ages of all personnel members in the manpower
simulation `mpSim` who were active at time `timePoint`.

If the given time is < 0 or larger than the current simulation time or the
length of the simulation (whichever is smaller), the function returns `nothing`.
Otherwise, it returns a `Vector{float64}` with the ages.
"""
function getActiveAgesAtTime( mpSim::ManpowerSimulation, timePoint::T ) where T <: Real

    if ( timePoint < 0 ) || ( timePoint > min( now( mpSim ), mpSim.simLength ) )
        return
    end  # if ( timePoint < 0 ) || ...

    # Get all necessary information from the database.
    activePersonnel = getActiveAtTime( mpSim, timePoint,
        [ "ageAtRecruitment + $timePoint - timeEntered age" ] )

    # Compute the current age of all active personnel members.
    return activePersonnel[ :age ]

end  # getActiveAgesAtTime( mpSim, timePoint )


"""
```
getInFlux( mpSim::ManpowerSimulation,
           tBegin::T1,
           tEnd::T2 )
    where T1 <: Real
    where T2 <: Real
```
This function retrieves a view of all the personnel members in the simulation
`mpSim` who entered the organisation between `tBegin` (exclusive) and `tEnd`
(inclusive). People who entered and left the organisation in this interval are
not counted.

If the end time is <= 0, or the start time is larger than the current simulation
time or the length of the simulation (whichever is smaller), or if the end time
is smaller than the start time, this function returns `nothing`.
"""
function getInFlux( mpSim::ManpowerSimulation, tBegin::T1, tEnd::T2 ) where T1 <: Real where T2 <: Real

    if ( tEnd <= 0 ) || ( tBegin > min( now( mpSim ), mpSim.simLength ) ) ||
        ( tEnd <= tBegin )
        return
    end  # if ( tEnd <= 0 ) || ...

    queryCmd = "SELECT $(mpSim.idKey)
        FROM $(mpSim.personnelDBname)
        WHERE ( $tBegin < timeEntered ) AND ( timeEntered <= $tEnd ) AND
            ( ( timeExited > $tEnd ) OR ( timeExited IS NULL ) )"
    SQLite.query( mpSim.simDB, queryCmd )

end  # getInFlux( mpSim, tBegin, tEnd, fields )

"""
```
getInFlux( mpSim::ManpowerSimulation,
           stateName::String,
           tBegin::T1,
           tEnd::T2 )
    where T1 <: Real
    where T2 <: Real
```
This function retrieves a view of all the personnel members in the simulation
`mpSim` who entered the state with name `stateName` between `tBegin` (exclusive)
and `tEnd` (inclusive). People who entered and left the state (or the
organisation) in this interval are not counted. The view also includes the
source (start state) and the reason (transition) of the flux for each personnel
member.

If the end time is <= 0, or the start time is larger than the current simulation
time or the length of the simulation (whichever is smaller), or if the end time
is smaller than the start time, this function returns `nothing`.
"""
function getInFlux( mpSim::ManpowerSimulation, stateName::String, tBegin::T1,
    tEnd::T2 ) where T1 <: Real where T2 <: Real

    if ( tEnd <= 0 ) || ( tBegin > min( now( mpSim ), mpSim.simLength ) ) ||
        ( tEnd <= tBegin )
        return
    end  # if ( tEnd <= 0 ) || ...

    queryCmd = "SELECT $(mpSim.idKey)
        FROM $(mpSim.personnelDBname)
        WHERE timeEntered < 0"
    dummyResult = SQLite.query( mpSim.simDB, queryCmd )

    # Retrieve IDs of people leaving the organisation in time interval.
    queryCmd = "SELECT $(mpSim.idKey) FROM $(mpSim.personnelDBname)
        WHERE ( $tBegin < timeExited ) AND ( timeExited <= $tEnd )"
    fluxOutIDs = SQLite.query( mpSim.simDB, queryCmd )[ 1 ]

    # Retrieve IDs and amount of transitions starting or ending in the state.
    queryCmd = "SELECT $(mpSim.idKey), count($(mpSim.idKey)) numEntries
        FROM $(mpSim.transitionDBname)
        WHERE ( $tBegin < timeIndex ) AND ( timeIndex <= $tEnd ) AND
            ( $(mpSim.idKey) NOT IN ('$(join( fluxOutIDs, "', '" ))') ) AND
            ( ( startState IS '$stateName' ) OR ( endState IS '$stateName' ) )
        GROUP BY $(mpSim.idKey)"
    queryRes = SQLite.query( mpSim.simDB, queryCmd )
    nEntries, nCold = size( queryRes )
    numEntries = Dict{String, Vector{Int}}()

    for ii in 1:nEntries
        numEntries[ queryRes[ 1 ][ ii ] ] = [ queryRes[ 2 ][ ii ], 0 ]
    end  # for ii in 1:nEntries

    # Retrieve IDs and amount of transitions ending in the state.
    queryCmd = "SELECT $(mpSim.idKey), count($(mpSim.idKey)) numEntries
        FROM $(mpSim.transitionDBname)
        WHERE ( $tBegin < timeIndex ) AND ( timeIndex <= $tEnd ) AND
            ( $(mpSim.idKey) NOT IN ('$(join( fluxOutIDs, "', '" ))') ) AND
            ( endState IS '$stateName' )
        GROUP BY $(mpSim.idKey)"
    queryRes = SQLite.query( mpSim.simDB, queryCmd )
    nEntries, nCold = size( queryRes )

    for ii in 1:nEntries
        numEntries[ queryRes[ 1 ][ ii ] ][ 2 ] = queryRes[ 2 ][ ii ]
    end  # for ii in 1:nEntries

    # If most transitions are into the state, personnel member is in the state
    #   at the end of the time interval.
    fluxInIDs = collect( keys( numEntries ) )
    filter!( id -> ( numEntries[ id ][ 2 ] * 2 > numEntries[ id ][ 1 ] ),
        fluxInIDs )

    if isempty( fluxInIDs )
        return dummyResult
    end  # if isempty( fluxInIDs )

    # Get start state and transition name for previously identified people.
    queryCmd = "SELECT $(mpSim.idKey), startState, transition
        FROM $(mpSim.transitionDBname)
        WHERE ( $tBegin < timeIndex ) AND ( timeIndex <= $tEnd ) AND
            ( endState IS '$stateName' ) AND
            ( $(mpSim.idKey) IN ('$(join( fluxInIDs, "', '" ))') )
        GROUP BY $(mpSim.idKey)"
    result = SQLite.query( mpSim.simDB, queryCmd )

    # If person has multiple transitions in/out of the state, set start state
    #   and transition to unknown.
    for ii in 1:length( fluxInIDs )
        id = result[ Symbol( mpSim.idKey ) ][ ii ]

        if numEntries[ id ][ 1 ] > 1
            result[ :startState ][ ii ] = "unknown"
            result[ :transition ][ ii ] = "unknown"
        end  # if numEntries[ id ][ 1 ] > 1
    end  # for ii in 1:length( fluxInIDs )

    return result

#=
    # Retrieve the list of people achieving the state in the time interval.
    queryCmd = "SELECT $(mpSim.idKey)
        FROM $(mpSim.transitionDBname)
        WHERE ( $tBegin < timeIndex ) AND ( timeIndex <= $tEnd ) AND
            ( endState IS '$stateName' )"
    fluxInIDs = SQLite.query( mpSim.simDB, queryCmd )[ 1 ]

    # If no personnel members entered the state, no need to continue.
    if isempty( fluxInIDs )
        return dummyResult
    end  # if isempty( fluxInIDs )

    # Retrieve the list of those personnel members leaving the state or the
    #   organisation in the time interval.
    queryCmd = "SELECT $(mpSim.idKey)
        FROM $(mpSim.transitionDBname)
        WHERE ( $tBegin < timeIndex ) AND ( timeIndex <= $tEnd ) AND
            ( $(mpSim.idKey) IN ('$(join( fluxInIDs, "', '" ))') ) AND
            ( ( startState IS '$stateName' ) OR ( endState IS NULL ) )"
    fluxOutIDs = SQLite.query( mpSim.simDB, queryCmd )[ 1 ]
    filter!( id -> id ∉ fluxOutIDs, fluxInIDs )

    queryCmd = "SELECT $(mpSim.idKey), startState, transition
        FROM $(mpSim.transitionDBname)
        WHERE ( $tBegin < timeIndex ) AND ( timeIndex <= $tEnd ) AND
            ( $(mpSim.idKey) IN ('$(join( fluxInIDs, "', '" ))') ) AND
            ( endState IS '$stateName' )"

    return SQLite.query( mpSim.simDB, queryCmd )
=#
end  # getInFlux( mpSim, tBegin, tEnd, fields )


"""
```
getOutFlux( mpSim::ManpowerSimulation,
            tBegin::T1,
            tEnd::T2,
            fields::Vector{String} = Vector{String}() )
    where T1 <: Real
    where T2 <: Real
```
This function retrieves a view of all the personnel members in the simulation
`mpSim` who left the organisation between `tBegin` (inclusive) and `tEnd`
(exclusive). The attributes in `fields` will also be snown in the retrieved
view. People who entered and left the organisation in this interval are not
counted.

If the end time is <= 0, or the start time is larger than the current simulation
time or the length of the simulation (whichever is smaller), or if the end time
is smaller than the start time, this function returns `nothing`.
"""
function getOutFlux( mpSim::ManpowerSimulation, tBegin::T1, tEnd::T2,
    fields::Vector{String} = Vector{String}() ) where T1 <: Real where T2 <: Real

    if ( tEnd <= 0 ) || ( tBegin > min( now( mpSim ), mpSim.simLength ) ) ||
        ( tEnd <= tBegin )
        return
    end  # if ( tEnd <= 0 ) || ...

    tmpFields = unique( vcat( mpSim.idKey, fields ) )
    queryCmd = "SELECT $(join( tmpFields, ", " ))
        FROM $(mpSim.personnelDBname)
        WHERE ( $tBegin < timeExited ) AND ( timeExited <= $tEnd ) AND
            ( timeEntered <= $tBegin )"
    SQLite.query( mpSim.simDB, queryCmd )

end  # getOutFlux( mpSim, tBegin, tEnd, fields )

"""
```
getOutFlux( mpSim::ManpowerSimulation,
            stateName::String,
            tBegin::T1,
            tEnd::T2 )
    where T1 <: Real
    where T2 <: Real
```
This function retrieves a view of all the personnel members in the simulation
`mpSim` who left the state with name `stateName` between `tBegin` (exclusive)
and `tEnd` (inclusive). People who entered and left the state (or the
organisation) in this interval are not counted. The view also includes the
target (end state) and the reason (transition) of the flux for each personnel
member.

If the end time is <= 0, or the start time is larger than the current simulation
time or the length of the simulation (whichever is smaller), or if the end time
is smaller than the start time, this function returns `nothing`.
"""
function getOutFlux( mpSim::ManpowerSimulation, stateName::String, tBegin::T1,
    tEnd::T2 ) where T1 <: Real where T2 <: Real

    if ( tEnd <= 0 ) || ( tBegin > min( now( mpSim ), mpSim.simLength ) ) ||
        ( tEnd <= tBegin )
        return
    end  # if ( tEnd <= 0 ) || ...

    queryCmd = "SELECT $(mpSim.idKey)
        FROM $(mpSim.personnelDBname)
        WHERE timeEntered < 0"
    dummyResult = SQLite.query( mpSim.simDB, queryCmd )

    # Get people who were in the state at the start of the time interval.
    inStateIDs = getActiveAtTime( mpSim, stateName, tBegin )[ 1 ]

    if isempty( inStateIDs )
        return dummyResult
    end  # if isempty( inStateIDs )

    # Get people who left the organisation in time interval.
    queryCmd = "SELECT $(mpSim.idKey)
        FROM $(mpSim.personnelDBname)
        WHERE ( $(mpSim.idKey) IN ('$(join( inStateIDs, "', '" ))') ) AND
            ( $tBegin < timeExited ) AND ( timeExited <= $tEnd )"
    fluxOutOfSystemIDs = SQLite.query( mpSim.simDB, queryCmd )[ 1 ]

    # Retrieve IDs and amount of transitions starting or ending in the state.
    queryCmd = "SELECT $(mpSim.idKey), count($(mpSim.idKey)) numEntries
        FROM $(mpSim.transitionDBname)
        WHERE ( $tBegin < timeIndex ) AND ( timeIndex <= $tEnd ) AND
            ( $(mpSim.idKey) IN ('$(join( inStateIDs, "', '" ))') ) AND
            ( ( startState IS '$stateName' ) OR ( endState IS '$stateName' ) )
        GROUP BY $(mpSim.idKey)"
    queryRes = SQLite.query( mpSim.simDB, queryCmd )
    nEntries, nCold = size( queryRes )
    numEntries = Dict{String, Vector{Int}}()

    for ii in 1:nEntries
        numEntries[ queryRes[ 1 ][ ii ] ] = [ queryRes[ 2 ][ ii ], 0 ]
    end  # for ii in 1:nEntries

    # Retrieve IDs and amount of transitions starting in the state.
    queryCmd = "SELECT $(mpSim.idKey), count($(mpSim.idKey)) numEntries
        FROM $(mpSim.transitionDBname)
        WHERE ( $tBegin < timeIndex ) AND ( timeIndex <= $tEnd ) AND
            ( $(mpSim.idKey) IN ('$(join( inStateIDs, "', '" ))') ) AND
            ( startState IS '$stateName' )
        GROUP BY $(mpSim.idKey)"
    queryRes = SQLite.query( mpSim.simDB, queryCmd )
    nEntries, nCold = size( queryRes )

    for ii in 1:nEntries
        numEntries[ queryRes[ 1 ][ ii ] ][ 2 ] = queryRes[ 2 ][ ii ]
    end  # for ii in 1:nEntries

    fluxOutIDs = collect( keys( numEntries ) )
    filter!( id -> numEntries[ id ][ 2 ] * 2 > numEntries[ id ][ 1 ],
        fluxOutIDs )
    fluxOutIDs = merge( fluxOutIDs, fluxOutOfSystemIDs )

    if isempty( fluxOutIDs )
        return dummyResult
    end  # if isempty( fluxInIDs )

    queryCmd = "SELECT $(mpSim.idKey), endState, transition
        FROM $(mpSim.transitionDBname)
        WHERE ( $tBegin < timeIndex ) AND ( timeIndex <= $tEnd ) AND
            ( $(mpSim.idKey) IN ('$(join( fluxOutIDs, "', '" ))') ) AND
            ( startState IN ('$stateName', 'active') )
        GROUP BY $(mpSim.idKey)"
    result = SQLite.query( mpSim.simDB, queryCmd )

    # If the person has multiple transition into/out of the state during time
    #   interval and hasn't left the system, set end state and transition to
    #   unknown.
    for ii in eachindex( fluxOutIDs )
        id = result[ Symbol( mpSim.idKey ) ][ ii ]

        if ( id ∉ fluxOutOfSystemIDs ) && ( numEntries[ id ][ 1 ] > 1 )
            result[ :endState ][ ii ] = "unknown"
            result[ :transition ][ ii ] = "unknown"
        end  # if id ∈ fluxOutOfSystemIDs
    end  # for ii in eachindex( fluxOutIDs )

    return result


    # Retrieve the list of those personnel members entering the state or the
    #   organisation in the time interval.
    if !isempty( fluxOutIDs )
        queryCmd = "SELECT $(mpSim.idKey)
            FROM $(mpSim.transitionDBname)
            WHERE ( $tBegin < timeIndex ) AND ( timeIndex <= $tEnd ) AND
                ( $(mpSim.idKey) IN ('$(join( fluxOutIDs, "', '" ))') ) AND
                ( ( endState IS '$stateName' ) OR ( startState IS NULL ) )"
        fluxInIDs = SQLite.query( mpSim.simDB, queryCmd )[ 1 ]
        filter!( id -> id ∉ fluxInIDs, fluxOutIDs )
    end  # if !isempty( fluxOutIDs )

    # Get all personnel members who were in the state at the start of the time
    #   interval.
    inStateIDs = getActiveAtTime( mpSim, stateName, tBegin )[ 1 ]
    queryCmd = "SELECT $(mpSim.idKey)
        FROM $(mpSim.personnelDBname)
        WHERE ( $(mpSim.idKey) IN ('$(join( inStateIDs, "', '" ))') ) AND
            ( $tBegin < timeExited ) AND ( timeExited <= $tEnd )"
    fluxOutOfSystemIDs = SQLite.query( mpSim.simDB, queryCmd )[ 1 ]
    fluxOutIDs = merge( fluxOutIDs, fluxOutOfSystemIDs )

    if isempty( fluxOutIDs )
        return dummyResult
    end  # if isempty( fluxInIDs )

    queryCmd = "SELECT $(mpSim.idKey), endState, transition
        FROM $(mpSim.transitionDBname)
        WHERE ( $tBegin < timeIndex ) AND ( timeIndex <= $tEnd ) AND
            ( $(mpSim.idKey) IN ('$(join( fluxOutIDs, "', '" ))') ) AND
            ( startState IN ('$stateName', 'active') )"
    result2 = SQLite.query( mpSim.simDB, queryCmd )

    resMiss = filter( id -> id ∉ result[ 1 ], result2[ 1 ] )
    res2Miss = filter( id -> id ∉ result2[ 1 ], result[ 1 ] )

    print( "Time: $tBegin" )
    if isempty( resMiss ) && isempty( res2Miss )
        println( "\t\tNothing missing -- ", size( result ), " vs ", size( result2 ) )

        if length( result2[ 1 ] ) > length( unique( result2[ 1 ] ) )
            println( "Old way has duplicates." )
        end
    else
        if !isempty( resMiss )
            print( "\t\tMissing from new: ", resMiss )
        end

        if !isempty( res2Miss )
            print( "\t\tMissing from old: ", res2Miss )
        end

        println()
    end

    return SQLite.query( mpSim.simDB, queryCmd )

end  # getOutFlux( mpSim, tBegin, tEnd, fields )


"""
```
getLastChanges( mpSim::ManpowerSimulation,
                timePoint::T,
                fields::Vector{String} )
    where T <: Real
```
This function retrieves a view of the last changes in the simulation `mpSim` up
to time `timePoint` for all personnel members active at that time, and for the
fields in `fields`.

If the given time is < 0 or if the fields attribute is an empty vector, this
function returns `nothing`. Otherwise, it returns a `DataFrames.DataFrame`
object.
"""
function getLastChanges( mpSim::ManpowerSimulation, timePoint::T,
    fields::Vector{String} ) where T <: Real

    if ( timePoint < 0 ) || isempty( fields )
        return
    end  # if ( timePoint < 0 ) || ...

    persName = mpSim.personnelDBname
    histName = mpSim.historyDBname
    idKey = mpSim.idKey

    tmpFields = unique( fields )
    queryCmd = "SELECT $histName.$idKey, attribute, timeIndex, numValue,
        strValue FROM $histName
        INNER JOIN $persName ON $persName.$idKey == $histName.$idKey
        WHERE ( timeIndex <= $timePoint ) AND
            ( ( timeExited > $timePoint ) OR ( timeExited IS NULL ) ) AND
            ( attribute IN ('$(join( fields, "', '"))') )
        GROUP BY $histName.$idKey, attribute
        ORDER BY $histName.$idKey, attribute"
    return SQLite.query( mpSim.simDB, queryCmd )

end  # getLastChanges( mpSim, timePoint, fields )


"""
```
getDatabaseAtTime( mpSim::ManpowerSimulation,
                   timePoint::T,
                   fields::Vector{String} = Vector{String}() )
    where T <: Real
```
This function retrieves a view of all the personnel in the simulation `mpSim`
who were active at time `timePoint`, and displays the ID key and all the columns
listed in `fields`. The values in the database are those that the records had at
the given time of the simulation.

If the given time is < 0 or larger than the current simulation time or the
length of the simulation (whichever is smaller), or if the list of fields is
empty, this function returns `nothing`. Otherwise, it returns a
`DataFrames.DataFrame` object.
"""
function getDatabaseAtTime( mpSim::ManpowerSimulation, timePoint::T,
    fields::Vector{String} = Vector{String}() ) where T <: Real

    activeDB = getActiveAtTime( mpSim, timePoint, fields )

    # If no additional fields are requested, it's just the list of personnel
    #   members, and it can be returned.
    if isempty( fields )
        return activeDB
    end  # if isempty( fields )

    if activeDB === nothing
        return
    end  # if activeDB === nothing

    nPers = size( activeDB )[ 1 ]

    # If there aren't any active personnel members at that time, that's the
    #   database.
    if nPers == 0
        return activeDB
    end  # if nPers == 0

    changeList = getLastChanges( mpSim, timePoint, fields )
    nAttrs = floor( Int, size( changeList )[ 1 ] / nPers )
    attrsToChange = changeList[ 1:nAttrs, :attribute ]

    # XXX Thorough test needed to see if this works as advertised. If it does
    #   though... fantastic bit of coding.
    for ii in eachindex( attrsToChange )
        # The attribute to update.
        changedAttr = Symbol( attrsToChange[ ii ] )
        # Is it a numerical attribute?
        isNum = isa( changeList[ ii, :numValue ], Real )
        # Perform the update.
        activeDB[ changedAttr ] =
            changeList[ ii + (0:(nPers - 1)) * nAttrs,
            isNum ? :numValue : :strValue ]
        # This works because the view from the personnel database is sorted by
        #   personnel ID, and the view from the historic database is sorted by
        #   personnel ID, then by attribute.
        # In addition, any attribute that shows up in the historic database
        #   must show up for ALL personnel records as the starting value of the
        #   attribute must be stored for later recall.
    end  # for ii in eachindex( fields )

    return activeDB

end  # getDatabaseAtTime( mpSim, timePoint, fields )


export generateReport
"""
This function generates a basic simulation report of the simulation `mpSim` on
a timegrid with resolution `timeDelta`, and exports it to the Excel file
`fileName`. The `.xlsx` extension is added if necessary.
"""
function generateReport( mpSim::ManpowerSimulation, timeDelta::T,
    fileName::String ) where T <: Real

    tic()
    nRecords = countRecords( mpSim, timeDelta )
    nFluxIn = countFluxIn( mpSim, timeDelta )
    nFluxOut = countFluxOut( mpSim, timeDelta, true )

    workbook = Workbook()
    sheet = createSheet( workbook, "Personnel" )

    # General info
    sheet[ "A", 1 ] = "Simulation length"
    sheet[ "B", 1 ] = min( now( mpSim ), mpSim.simLength )
    sheet[ "A", 2 ] = "Report time resolution"
    sheet[ "B", 2 ] = timeDelta
    sheet[ "A", 3 ] = "Personnel cap"
    sheet[ "B", 3 ] = mpSim.personnelTarget
    sheet[ "A", 4 ] = "Report generated in"
    sheet[ "C", 4 ] = "s"

    # Data headers
    sheet[ "A", 6 ] = "Time"
    sheet[ "B", 6 ] = "Personnel"
    sheet[ "C", 6 ] = "Flux In"
    sheet[ "D", 6 ] = "Flux Out"
    sheet[ "E", 6 ] = "Net Flux"
    sheet[ "F", 6 ] = "Retired"
    sheet[ "G", 6 ] = "Resigned"

    # Put data in Excel file
    n = length( nRecords[ 1 ] )
    sheet[ "A", 7 ] = nRecords[ 1 ][ 1 ]
    sheet[ "B", 7 ] = nRecords[ 2 ][ 1 ]

    for ii in 2:n
        sheet[ "A", 6 + ii ] = nRecords[ 1 ][ ii ]
        sheet[ "B", 6 + ii ] = nRecords[ 2 ][ ii ]
        sheet[ "C", 6 + ii ] = nFluxIn[ 2 ][ ii - 1 ]
        sheet[ "D", 6 + ii ] = nFluxOut[ 2 ][ ii - 1 ]
        sheet[ "E", 6 + ii ] = sheet[ "C", 6 + ii ] - sheet[ "D", 6 + ii ]
        sheet[ "F", 6 + ii ] = haskey( nFluxOut[ 3 ], "retired" ) ? nFluxOut[ 3 ][ "retired" ][ ii - 1 ] : 0
        sheet[ "G", 6 + ii ] = haskey( nFluxOut[ 3 ], "resigned" ) ? nFluxOut[ 3 ][ "resigned" ][ ii - 1 ] : 0
    end  # for ii in 2:n

    # if n == length( nFluxIn[ 1 ] )
    #     sheet[ "A", 7 + n ] == nFluxIn[ 1 ][ n ]
    #     sheet[ "C", 7 + n ] == nFluxIn[ 2 ][ n ]
    #     sheet[ "D", 7 + n ] == nFluxOut[ 2 ][ n ]
    # end  # if n == length( nFluxIn[ 1 ] )

    # Wrap up.
    sheet[ "B", 4 ] = toq()  # Time it took to create the report.
    tmpFileName = endswith( fileName, ".xlsx" ) ? fileName : fileName * ".xlsx"
    write( tmpFileName, workbook )
    println( "Report created and saved to $tmpFileName." )

end  # generateReport( mpSim, timeDelta )
