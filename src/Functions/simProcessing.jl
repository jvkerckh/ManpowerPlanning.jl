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
`mpSim` who entered the organisation between `tBegin` (inclusive) and `tEnd`
(exclusive). People who entered and left the organisation in this interval are
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
    queryCmd = "SELECT $persName.$idKey, attribute, timeIndex, numValue,
        strValue FROM $histName
        INNER JOIN $persName ON $persName.$idKey == $histName.$idKey
        WHERE ( timeIndex <= $timePoint ) AND ( timeEntered <= $timePoint ) AND
            ( ( timeExited > $timePoint ) OR ( timeExited IS NULL ) )
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
    changeList = getLastChanges( mpSim, timePoint, fields )
    nAttrs = floor( Int, size( changeList )[ 1 ] / nPers )
    attrsToChange = changeList[ 1:nAttrs, :attribute ].values

    # XXX Thorough test needed to see if this works as advertised. If it does
    #   though... fantastic bit of coding.
    for ii in eachindex( attrsToChange )
        # The attribute to update.
        changedAttr = Symbol( attrsToChange[ ii ] )
        # Is it a numerical attribute?
        isNum = changeList[ ii, :numValue ].hasvalue
        # Perform the update.
        activeDB[ changedAttr ] =
            changeList[ ii + (0:(nPers - 1)) * nAttrs,
            isNum ? :numValue : :strValue ].values
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
