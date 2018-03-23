# The prerequisite group that allows counting of personnel members.
countPersonnelPrereqGroup = PrerequisiteGroup()
addPrereq!( countPersonnelPrereqGroup, Prerequisite( :status, :active,
    relation = ==, valType = Symbol ) )


"""
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
        [ "timeEntered", "ageAtRecruitment" ] )

    # Compute the current age of all active personnel members.
    personnelAge = activePersonnel[ :ageAtRecruitment ]
    personnelAge += timePoint - activePersonnel[ :timeEntered ]
    return personnelAge

end  # getActiveAgesAtTime( mpSim, timePoint )


"""
This function returns the age distribution of all the personnel in the
simulation `mpSim` who were active at time `timePoint`, with ages rounded down
to the nearest multiple of `ageRes`.

If the given time is < 0 or larger than the currect simulation time or the
length of the simulation (whichever is smaller), or if the age resolution is
⩽ 0, this function returns `nothing`. Otherwise, it returns a
`Tuple{Vector{Float64}, Vector{Int}}` object, where the first vector holds the
ages, rounded down, ranging from the minimum age to the maximum age of the
personnel active at the requested time, and the second vector holds the number
of personnel members with that age.
"""
function getActiveAgeDistAtTime( mpSim::ManpowerSimulation, timePoint::T1,
    ageRes::T2 ) where T1 <: Real where T2 <: Real

    if ageRes <= 0
        warn( "Age resolution must be > 0.0, nothing returned." )
        return
    end  # if ageRes <= 0

    if ( timePoint < 0 ) || ( timePoint > min( now( mpSim ), mpSim.simLength ) )
        return
    end  # if ( timePoint < 0 ) || ...

    # Compute the current age of all active personnel members.
    personnelAge = floor.( Int, getActiveAgesAtTime( mpSim, timePoint ) /
        ageRes )
    ageCounts = counts( personnelAge )
    minAge = minimum( personnelAge )
    maxAge = minAge + length( ageCounts ) - 1

    # Sanity checks.
    if any( ageCounts .< 0 )
        println( "Age distribution: ", [ collect( linspace( minAge, maxAge, length( ageCounts ) ) ) *
            ageRes, ageCounts ] )
        error( "Negative number of personnel of certain age detected, this should NEVER happen." )
    elseif any( ageCounts .> mpSim.personnelCap )
        println( "Age distribution: ", [ collect( linspace( minAge, maxAge, length( ageCounts ) ) ) *
            ageRes, ageCounts ] )
        error( "Impossible number of personnel of certain age detected, this should NEVER happen." )
    end  # if any( ageCounts .< 0 )

    return ( collect( linspace( minAge, maxAge, length( ageCounts ) ) ) *
        ageRes, ageCounts )

end  # getActiveAgeDistAtTime( mpSim, timePoint, ageRes )


"""
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


"""
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
This function retrieves a view of all the personnel members in the simulation
`mpSim` who left the organisation between `tBegin` (inclusive) and `tEnd`
(exclusive). The attributes in `fields` will also be snown in the retrieved
view. People who entered and left the organisation in this interval are not
counted.

If the end time is <= 0, or the start time is larger than the current simulation
time or the length of the simulation (whichever is smaller), or if the end time
is smaller than the start time, this function returns `nothing`.
"""
function getOutFlux( mpSim::ManpowerSimulation, tBegin::T1, tEnd::T2 ) where T1 <: Real where T2 <: Real

    if ( tEnd <= 0 ) || ( tBegin > min( now( mpSim ), mpSim.simLength ) ) ||
        ( tEnd <= tBegin )
        return
    end  # if ( tEnd <= 0 ) || ...

    queryCmd = "SELECT $(mpSim.idKey)
        FROM $(mpSim.personnelDBname)
        WHERE ( $tBegin < timeExited ) AND ( timeExited <= $tEnd ) AND
            ( timeEntered <= $tBegin )"
    SQLite.query( mpSim.simDB, queryCmd )

end  # getOutFlux( mpSim, tBegin, tEnd )


export countRecords
"""
This function counts the number of active personnel members in the simulation
`mpSim` at each time in the vector `times`. Any times < 0 and larger than the
current simulation time or the length of the simulation (whichever is smaller),
are ignored.

The function returns a `Tuple{Vector{Float64}, Vector{Float64}}` where the first
element is the vector of valid, sorted, unique time points, and the second
element is the number of active personnel at those times.
"""
function countRecords( mpSim::ManpowerSimulation, times::Vector{Float64} )

    tMax = min( mpSim.simLength, now( mpSim ) )
    tmpTimes = unique( sort( times[ 0 .<= times .<= tMax ] ) )
    tmpCounts = similar( tmpTimes, Int )
    map( ii -> tmpCounts[ ii ] =
        size( getActiveAtTime( mpSim, tmpTimes[ ii ] ) )[ 1 ],
        eachindex( tmpTimes ) )

    return ( tmpTimes, tmpCounts )

end  # countRecords( mpSim::ManpowerSimulation, times::Vector{Float64} )

"""
```
countRecords(
    mpSim::ManpowerSimulation,
    timeDelta::T,
    includeFinalTime::Bool = true ) where T <: Real
```
This version of the `countRecords` method counts the number of active people on
a time grid with resolution `timeDelta`, starting from time 0. The current
simulation time or the length of the simulation (whichever is smaller) is added
at the end.

If the argument `timeDelta` is not > 0, this function will return `nothing`.
"""
function countRecords( mpSim::ManpowerSimulation, timeDelta::T,
    includeFinalTime::Bool = true ) where T <: Real

    # Check validity of timeDelta.
    if timeDelta <= 0
        warn( "Cannot have a time grid with step size ⩽ 0.0, nothing returned." )
        return nothing
    end  # if timeDelta <= 0.0

    tMax = min( mpSim.simLength, now( mpSim ) )
    tmpTimes = collect( 0:timeDelta:tMax )

    # Add final time point if necessary.
    if tmpTimes[ end ] < tMax
        push!( tmpTimes, tMax )
    end  # if tmpTimes[ end ] < tMax

    # Check if the counts have been cached already and return it in that case.
    tmpCounts = mpSim.simCache[ timeDelta, :count ]

    if tmpCounts !== nothing
        return ( tmpTimes, tmpCounts )
    end  # if tmpCounts !== nothing

    tmpCounts = similar( tmpTimes, Int )
    map( ii -> tmpCounts[ ii ] =
        size( getActiveAtTime( mpSim, tmpTimes[ ii ] ) )[ 1 ],
        eachindex( tmpTimes ) )
    addToCache( mpSim.simCache, timeDelta, :count, tmpCounts )

    return ( tmpTimes, tmpCounts )

end  # countRecords( mpSim, timeDelta )


export countFluxIn
"""
This function counts the number of people who entered the system between each
pair of consecutive times in the vector `times`, after sorting and taking the
unique entries. People who entered and left the organisation within the same
time interval are not counted.

If there is only one unique time entry in the vector, this function will return
`nothing`. Otherwise, it will return a `Tuple{Vector{Float64}, Vector{Int}}`
where the first entry is the vector of end times of each interval and the second
is the number of people who entered the organisation during each interval.
"""
function countFluxIn( mpSim::ManpowerSimulation, times::Vector{Float64} )

    tMax = min( now( mpSim ), mpSim.simLength )
    tmpTimes = unique( sort( times ) )

    # Trim time intervals with negative endpoints and start points later than
    #   tMax.
    firstOverTime = findfirst( tmpTimes .> tMax )
    lastNegTime = findlast( tmpTimes .<= 0 )

    if firstOverTime > 0
        tmpTimes = tmpTimes[ 1:firstOverTime ]
    end  # if firstOverTime > 0

    if lastNegTime > 1
        tmpTimes = tmpTimes[ lastNegTime:end ]
    end  # if lastNegTime > 1

    if length( tmpTimes ) < 2
        warn( "Need at least 2 valid timepoints to compute flux." )
        return
    end

    tmpFlux = similar( tmpTimes[ 2:end ], Int )
    tmpFlux = map( ii -> tmpFlux[ ii ] =
        size( getInFlux( mpSim, tmpTimes[ ii ], tmpTimes[ ii + 1 ] ) )[ 1 ],
        eachindex( tmpFlux ) )
    return ( tmpTimes[ 2:end ], tmpFlux )

end  # countFluxIn( mpSim, times )

"""
```
countFluxIn(
    mpSim::ManpowerSimulation,
    timeDelta::T ) where T <: Real
```
This version of the `countFluxIn` method counts the influx of people on a
time grid with resolution `timeDelta`, starting from time 0.

If the argument `timeDelta` is not > 0, this function will return `nothing`.
"""
function countFluxIn( mpSim::ManpowerSimulation, timeDelta::T ) where T <: Real

    if timeDelta <= 0.0
        warn( "Cannot have a time grid with step size ⩽ 0.0, nothing returned." )
        return nothing
    end  # if timeDelta <= 0.0

    tMax = min( now( mpSim ), mpSim.simLength )
    tmpTimes = collect( 0:timeDelta:tMax )

    # To ensure the final flux period is handled properly, add tMax to the list.
    if tmpTimes[ end ] < tMax
        push!( tmpTimes, tMax )
    end  # if tmpTimes[ end ] < tMax

    # Check if the counts have been cached already and return it in that case.
    tmpFlux = mpSim.simCache[ timeDelta, :fluxIn ]

    if tmpFlux !== nothing
        return ( tmpTimes[ 2:end ], tmpFlux )
    end  # if tmpCounts !== nothing

    tmpFlux = similar( tmpTimes[ 2:end ], Int )
    tmpFlux = map( ii -> tmpFlux[ ii ] =
        size( getInFlux( mpSim, tmpTimes[ ii ], tmpTimes[ ii + 1 ] ) )[ 1 ],
        eachindex( tmpFlux ) )
    addToCache( mpSim.simCache, timeDelta, :fluxIn, tmpFlux )

    return ( tmpTimes[ 2:end ], tmpFlux )

end  # countfluxIn( mpSim, timeDelta )


export countFluxOut
"""
This function counts the number of people who left the system between each
pair of consecutive times in the vector `times`, after sorting and taking the
unique entries. People who entered and left the organisation within the same
time interval are not counted. If the flag `includeByType` is set to `true`, the
function will also count by the reasons for leaving.

If there is only one unique time entry in the vector, this function will return
`nothing`. Otherwise, it will return a `Tuple{Vector{Float64}, Vector{Int}}`
where the first entry is the vector of start times of each interval nad the
second is the number of people who left the organisation during each interval.

If `includeByType` is `true`, the output will be a
`Tuple{Vector{Float64}, Vector{Int}, Dict{String, Vector{Int}}}`, where
the last entry is a count of the flux out broken down by reason for leaving.
"""
function countFluxOut( mpSim::ManpowerSimulation, times::Vector{Float64},
    includeByType::Bool = false )

    tMax = min( now( mpSim ), mpSim.simLength )
    tmpTimes = unique( sort( times ) )

    # Trim time intervals with negative endpoints and start points later than
    #   tMax.
    firstOverTime = findfirst( tmpTimes .> tMax )
    lastNegTime = findlast( tmpTimes .<= 0 )

    if firstOverTime > 0
        tmpTimes = tmpTimes[ 1:firstOverTime ]
    end  # if firstOverTime > 0

    if lastNegTime > 1
        tmpTimes = tmpTimes[ lastNegTime:end ]
    end  # if lastNegTime > 1

    if length( tmpTimes ) < 2
        warn( "Need at least 2 valid timepoints to compute flux." )
        return
    end

    # If we need to break down the fluxes by reason for leaving, we need to
    #   initalise the dictionary.
    if includeByType
        tmpBreakdown = Dict{String, Vector{Int}}()
        queryCmd = "SELECT strValue
            FROM $(mpSim.historyDBname)
            WHERE attribute = 'status'"
        listOfReasons = SQLite.query( mpSim.simDB, queryCmd )
        listOfReasons = unique( listOfReasons[ :status ].values )
    end  # if includeByType

    tmpFlux = similar( tmpTimes[ 2:end ], Int )
    tmpFlux = map( ii -> tmpFlux[ ii ] =
        size( getOutFlux( mpSim, tmpTimes[ ii ], tmpTimes[ ii + 1 ] ) )[ 1 ],
        eachindex( tmpFlux ) )
    return ( tmpTimes[ 2:end ], tmpFlux )

end  # countFluxOut( mpSim, times )

"""
```
countFluxOut(
    mpSim::ManpowerSimulation,
    timeDelta::T ) where T <: Real
```
This version of the `countFluxOut` method counts the outflux of people on a
time grid with resolution `timeDelta`, starting from time 0.

If the argument `timeDelta` is not > 0, this function will return `nothing`.
"""
function countFluxOut( mpSim::ManpowerSimulation, timeDelta::T,
    includeByType::Bool = false ) where T <: Real

    if timeDelta <= 0.0
        warn( "Cannot have a time grid with step size ⩽ 0.0, nothing returned." )
        return nothing
    end  # if timeDelta <= 0.0

    tMax = min( now( mpSim ), mpSim.simLength )
    tmpTimes = collect( 0:timeDelta:tMax )

    # To ensure the final flux period is handled properly, add tMax to the list.
    if tmpTimes[ end ] < tMax
        push!( tmpTimes, tMax )
    end  # if tmpTimes[ end ] < tMax

    # Check if the reports have been cached already.
    tmpFlux = mpSim.simCache[ timeDelta, :fluxIn ]

    if includeByType
        tmpFluxRes = mpSim.simCache[ timeDelta, :resigned ]
        tmpFluxRet = mpSim.simCache[ timeDelta, :retired ]

        # If all caches are present, return all flux out caches in the proper
        #   format.
        if ( tmpFlux !== nothing ) && ( tmpFluxRes !== nothing ) &&
            ( tmpFluxRet !== nothing )
            breakdownDict = Dict{String, Vector{Int}}( "resigned" => tmpFluxRes,
                "retired" => tmpFluxRet )
            return ( tmpTimes[ 2:end ], tmpFlux, breakdownDict )
        end  # if ( tmpFlux !== nothing ) && ...
    elseif tmpFlux !== nothing
        return ( tmpTimes[ 2:end ], tmpFlux )
    end  # if includeByType

    tmpFlux = similar( tmpTimes[ 2:end ], Int )

    # If we need to break down the fluxes by reason for leaving, we need to
    #   initalise a matrix to store the information.
    if includeByType
        queryCmd = "SELECT strValue
            FROM $(mpSim.historyDBname)
            WHERE attribute = 'status'"
        listOfReasons = SQLite.query( mpSim.simDB, queryCmd )
        listOfReasons = unique( listOfReasons[ 1 ] )
        tmpBreakdown = zeros( Int, length( tmpFlux ), length( listOfReasons ) )
    end  # if includeByType

    for ii in eachindex( tmpFlux )
        # This query retrieves the list of personnel IDs that left the
        #   organisation in the time period.
        queryCmd = "SELECT $(mpSim.idKey)
            FROM $(mpSim.personnelDBname)
            WHERE $(tmpTimes[ ii ]) < timeExited AND
                timeExited <= $(tmpTimes[ ii + 1 ])"

        # If we need a breakdown, get the last entry per ID for changes in the
        #   status attribute. The number of rows in this query is the same as
        #   the number of rows in the above query.
        if includeByType
            queryCmd = "SELECT strValue, max( timeIndex ) timeIndex
                FROM $(mpSim.historyDBname)
                WHERE attribute = 'status' AND
                    $(mpSim.idKey) IN ($queryCmd)
                GROUP BY $(mpSim.idKey)"
        end

        outFlux = SQLite.query( mpSim.simDB, queryCmd )[ 1 ]
        tmpFlux[ ii ] = length( outFlux )

        # If a breakdown by reason is needed, and people left the organisation,
        #   count them by reason.
        if includeByType && ( tmpFlux[ ii ] > 0 )
            reasonCounts = countmap( outFlux )

            map( jj -> tmpBreakdown[ ii, jj ] =
                get( reasonCounts, listOfReasons[ jj ], 0 ),
                eachindex( listOfReasons ) )
        end  # if includeByType && ...
    end  # for ii in eachindex( tmpFlux )

    if includeByType
        breakdownDict = Dict{String, Vector{Int}}()
        map( jj -> if sum( tmpBreakdown[ :, jj ] ) != 0
            breakdownDict[ listOfReasons[ jj ] ] = tmpBreakdown[ :, jj ]
        end, eachindex( listOfReasons ) )
        return ( tmpTimes[ 2:end ], tmpFlux, breakdownDict )
    end

    return ( tmpTimes[ 2:end ], tmpFlux )

end  # countFluxOut( mpSim, timeDelta )


export getAgeStatistics
"""
```
getAgeStatistics( mpSim::ManpowerSimulation,
                  timeDelta::T,
                  includeFinalTime::Bool = true )
    where T <: Real
```
This function generates statistics for the active personnel in the manpower
simulation `mpSim` on a timegrid with resolution `timeDelta`.

If the resolution of the time grid is ⩽ 0, the function returns `nothing`.
Otherwise, it returns a `Tuple{Vector{Float64}, Array{Float64, 2}}` where the
first element is a vector holding the times of the grid, and the second element
is a matrix with 5 columns, and one row for each time in the time grid. The
columns of this matrix hold, in this order, the average age, the standard
deviation, the median age, the minimum age, and the maximum age.
"""
function getAgeStatistics( mpSim::ManpowerSimulation, timeDelta::T,
    includeFinalTime::Bool = true ) where T <: Real

    # Check validity of timeDelta.
    if timeDelta <= 0
        warn( "Cannot have a time grid with step size ⩽ 0.0, nothing returned." )
        return
    end  # if timeDelta <= 0.0

    tMax = min( mpSim.simLength, now( mpSim ) )
    tmpTimes = collect( 0:timeDelta:tMax )

    # Add final time point if necessary.
    if includeFinalTime && ( tmpTimes[ end ] < tMax )
        push!( tmpTimes, tMax )
    end  # if includeFinalTime && ...

    tmpStats = zeros( Float64, length( tmpTimes), 5 )

    for ii in eachindex( tmpTimes )
        personnelAge = getActiveAgesAtTime( mpSim, tmpTimes[ ii ] )
        sumStats = summarystats( personnelAge )
        tmpStats[ ii, : ] = [ sumStats.mean, std( personnelAge ),
            sumStats.median, sumStats.min, sumStats.max ]
    end  # for ii in eachindex( tmpTimes )

    return ( tmpTimes, tmpStats )

end  # getAgeStatistics( mpSim, timeDelta, includeFinalTime )


export getAgeDistEvolution
"""
This function determines the distribution of the age of active personnel members
in the simulation `mpSim` on a timegrid with resolution `timeDelta`. The ages
are rounded down to the nearest multiple of `ageRes`.

If the resolution of the time grid is ⩽ 0, or the age resolution is ⩽ 0, this
function returns `nothing`. Otherwise it returns a
`Tuple{Vector{Float64}, Vector{Float64}, Array{Int}}` object where the first
element is a vector holding the times of the grid, the second element is a
vector holding the ages, and the third element is the matrix of the number of
active personnel members having a certain age at a certain time, with each row
corresponding to a single time point.
"""
function getAgeDistEvolution( mpSim::ManpowerSimulation, timeDelta::T1,
    ageRes::T2, includeFinalTime::Bool = true ) where T1 <: Real where T2 <: Real

    # Check validity of ageRes
    if ageRes <= 0
        warn( "Age resolution must be > 0.0, nothing returned." )
        return
    end  # if ageRes <= 0

    # Check validity of timeDelta.
    if timeDelta <= 0
        warn( "Cannot have a time grid with step size ⩽ 0.0, nothing returned." )
        return
    end  # if timeDelta <= 0.0

    tMax = min( mpSim.simLength, now( mpSim ) )
    tmpTimes = collect( 0:timeDelta:tMax )

    # Add final time point if necessary.
    if includeFinalTime && ( tmpTimes[ end ] < tMax )
        push!( tmpTimes, tMax )
    end  # if includeFinalTime && ...

    nTimes = length( tmpTimes )
    ages = Vector{Float64}()
    minAge = 0.0
    maxAge = 0.0
    # The array must be defined first here.
    distPerTime = Array{Int}( nTimes, 0 )

    for ii in eachindex( tmpTimes )
        ageDistAtTime = getActiveAgeDistAtTime( mpSim, tmpTimes[ ii ], ageRes )
        tmpMinAge = minimum( ageDistAtTime[ 1 ] )
        tmpMaxAge = maximum( ageDistAtTime[ 1 ] )

        # Create/extend the age distribution matrix if needed.
        if isempty( ages )
            ages = ageDistAtTime[ 1 ]
            minAge = tmpMinAge
            maxAge = tmpMaxAge
            distPerTime = zeros( Int, nTimes, length( ages ) )
        else

            # If there's a new minimum age, add the required columns at the
            #   start of the age distribution matrix.
            if tmpMinAge < minAge
                colsToAdd = floor( Int, ( minAge - tmpMinAge ) / ageRes )
                ages = vcat( collect( tmpMinAge + ( 0:(colsToAdd - 1) ) * ageRes ),
                    ages )
                distPerTime = hcat( zeros( Int, nTimes, colsToAdd ),
                    distPerTime )
                minAge = tmpMinAge
            end  # if tmpMinAge < minAge

            # If there's a new maximum age, add the required columns at the end
            #   of the age distribution matrix.
            if tmpMaxAge > maxAge
                colsToAdd = floor( Int, ( tmpMaxAge - maxAge ) / ageRes )
                ages = vcat( ages, collect( maxAge + ( 1:colsToAdd ) * ageRes ) )
                distPerTime = hcat( distPerTime,
                    zeros( Int, nTimes, colsToAdd ) )
                maxAge = tmpMaxAge
            end  # if tmpMaxAge > maxAge
        end  # if isempty( ages )

        nAges = length( ageDistAtTime[ 1 ] )
        colNrs = findfirst( ages, tmpMinAge ) + ( 0:(nAges - 1) )
        distPerTime[ ii, colNrs ] = ageDistAtTime[ 2 ]
    end  # for ii in eachindex( tmpTimes )

    if any( distPerTime .< 0 ) || any( distPerTime .> mpSim.personnelCap )
        error( "A problem has occurred, DATA CORRUPTION!" )
    end

    return( tmpTimes, ages, distPerTime )

end  # getAgeDistEvolution( mpSim, timeDelta, ageRes, includeFinalTime )


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
    sheet[ "B", 3 ] = mpSim.personnelCap
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
