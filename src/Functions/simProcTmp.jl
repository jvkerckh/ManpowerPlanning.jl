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
end


"""
This function returns the age distribution of all the personnel in the
simulation `mpSim` who were active at time `timePoint`, with ages rounded down
to the nearest multiple of `ageRes`.

If the given time is < 0 or larger than the currect simulation time or the
length of the simulation (whichever is smaller), this function returns
`nothing`. Otherwise, it returns a `Tuple{Vector{Float64}, Vector{Int}}` object,
where the first vector holds the ages, rounded down, ranging from the minimum
age to the maximum age of the personnel active at the requested time, and the
second vector holds the number of personnel members with that age.
"""
function getActiveAgeDistAtTime( mpSim::ManpowerSimulation, timePoint::T1,
    ageRes::T2 ) where T1 <: Real  where T2 <: Real

    activePersonnel = getActiveAtTime( mpSim, timePoint,
        [ "timeEntered", "ageAtRecruitment" ] )
    personnelAge = activePersonnel[ :ageAtRecruitment ].values
    personnelAge -= activePersonnel[ :timeEntered ].values
    personnelAge += timePoint
    personnelAge = floor.( Int, personnelAge / ageRes )
    ageCounts = counts( personnelAge )
    minAge = minimum( personnelAge )
    maxAge = minAge + length( ageCounts ) - 1
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
        # This works (or should work) because the view from the personnel
        #   database is sorted by personnel ID, and the view from the historic
        #   database is sorted by personnel ID, then by attribute.
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
    includeFinalTime::Bool = false ) where T <: Real
```
This version of the `countRecords` method counts the number of active people on
a time grid with resolution `timeDelta`, starting from time 0. If the flag
`includeFinalTime` is set to `true`, the current simulation time or the length
of the simulation (whichever is smaller) is added at the end.

If the argument `timeDelta` is not > 0, this function will return `nothing`.
"""
function countRecords( mpSim::ManpowerSimulation, timeDelta::T,
    includeFinalTime::Bool = false ) where T <: Real

    # Check validity of timeDelta.
    if timeDelta <= 0
        warn( "Cannot have a time grid with step size ⩽ 0.0, nothing returned." )
        return nothing
    end  # if timeDelta <= 0.0

    tMax = min( mpSim.simLength, now( mpSim ) )
    tmpTimes = collect( 0:timeDelta:tMax )

    # Add final time point if necessary.
    if includeFinalTime && ( tmpTimes[ end ] < tMax )
        push!( tmpTimes, tMax )
    end  # if includeFinalTime && ...

    tmpCounts = similar( tmpTimes, Int )
    map( ii -> tmpCounts[ ii ] =
        size( getActiveAtTime( mpSim, tmpTimes[ ii ] ) )[ 1 ],
        eachindex( tmpTimes ) )

    return ( tmpTimes, tmpCounts )

end  # countRecords( mpSim, timeDelta, includeFinalTime )



# This function performs a snapshot at each moment in the times vector, after
#   sorting, and counts the number of personnel members satisfying the
#   prerequisites. It returns a pair of time and amount vectors.
function countRecords( dbase::PersonnelDatabase, times::Vector{Float64},
    prereqGroup::PrerequisiteGroup )
    if !hasAttribute( dbase, :history )
        warn( "The database has no history field." )
    end  # if !hasAttribute( dbase, :history )

    tmpTimes = sort( times )
    result = map( timestamp -> countRecords( dbase, prereqGroup,
        timestamp ), tmpTimes )
    return ( tmpTimes, result )
end  # countRecords( dbase, times, prereqGroup )

function countRecords( mpSim::ManpowerSimulation, times::Vector{Float64},
    prereqGroup::PrerequisiteGroup )
    return countRecords( mpSim.simResult, times, prereqGroup )
end  # countRecords( mpSim, times, prereqGroup )

function countRecords( mpSim::ManpowerSimulation, timeDelta::T,
    prereqGroup::PrerequisiteGroup ) where T <: Real
    if timeDelta <= 0.0
        warn( "Cannot have a time grid with step size ⩽ 0.0, nothing returned." )
        return nothing
    end  # if timeDelta <= 0.0

    return countRecords( mpSim.simResult,
        collect( 0.0:timeDelta:min( now( mpSim ), mpSim.simLength ) ),
        prereqGroup )
end  # countRecords( mpSim, timeDelta, prereqGroup )

# function countRecords( mpSim::ManpowerSimulation, times::Vector{Float64} )
#     return countRecords( mpSim, times, countPersonnelPrereqGroup )
# end  # countRecords( mpSim, times )

# function countRecords( mpSim::ManpowerSimulation, timeDelta::T ) where T <: Real
#     # If the report is already cached, return the cached report.
#     if isCached( mpSim.simCache, timeDelta, :count )
#         return ( collect( 0.0:timeDelta:min( now( mpSim ), mpSim.simLength ) ),
#             mpSim.simCache[ timeDelta, :count ] )
#     end  # if isCached( mpSim.simCache, timeDelta, :count )
#
#     # Check if the currect resolution can be divided by any of the cached
#     #   resolutions.
#     res = getCachedResolutions( mpSim.simCache )
#     res = res[ map( t -> 0 == ( timeDelta % t ) &&
#         ( isCached( mpSim.simCache, t, :count ) ), res ) ]
#
#     # If so, aggregate from the cached report with the coarsest resolution.
#     if !isempty( res )
#         fromRes = maximum( res )
#         aggregateCountReport( mpSim.simCache, fromRes, timeDelta )
#         return countRecords( mpSim, timeDelta )
#     end  # if !isempty( res )
#
#     # Otherwise, generate a new report and cache it. If the simulation is
#     #   continued, the cache gets wiped.
#     report = countRecords( mpSim, timeDelta, countPersonnelPrereqGroup )
#     mpSim.simCache[ timeDelta, :count ] = report[ 2 ]
#     return report
# end  # countRecords( mpSim, timeDelta )


# This function counts the average number of people that satisfy the given set
#   of prerequisites during each period. The average is taken over a number of
#   snapshots during each period. The entry at time 0.0 is the snapshot at this
#   time.
export countAverage
function countAverage( mpSim::ManpowerSimulation, reportTimeDelta::T1,
    snapTimeDelta::T2, prereqGroup::Union{Void, PrerequisiteGroup} = nothing ) where T1 <: Real where T2 <: Real
    if ( reportTimeDelta <= 0.0 ) || ( snapTimeDelta <= 0.0 )
        warn( "Cannot have a time grid with step size ⩽ 0.0, nothing returned." )
        return nothing
    end  # if ( reportTimeDelta <= 0.0 ) || ...

    if reportTimeDelta % snapTimeDelta != 0.0
        warn( "Time grid of report must be a multiple of the snap time grid, nothing returned." )
        return nothing
    end  # if reportTimeDelta % snapTimeDelta != 0.0

    if prereqGroup === nothing
        snapReport = countRecords( mpSim, snapTimeDelta )
    else
        snapReport = countRecords( mpSim, snapTimeDelta, prereqGroup )
    end  # if prereqGroup === nothing

    aggrRatio = Int( reportTimeDelta / snapTimeDelta )

    if aggrRatio == 1
        return snapReport
    end  # if aggrRatio == 1

    # Create the reporting times.
    tMax = snapReport[ 1 ][ end ]
    tmpTimes = collect( 0.0:reportTimeDelta:tMax )

    if tmpTimes[ end ] < tMax
        push!( tmpTimes, tMax )
    end  # if tmpTimes < snapReport[ 1 ][ end ]

    tmpCounts = similar( tmpTimes, Float64 )

    # The snapshot at time 0.0.
    tmpCounts[ 1 ] = snapReport[ 2 ][ 1 ]
    nWholePeriods = floor( Int, ( length( snapReport[ 1 ] ) - 1 ) / aggrRatio )
    map( ii -> tmpCounts[ ii + 1 ] =
        mean( snapReport[ 2 ][ 1 + ( ii - 1 ) * aggrRatio + (1:aggrRatio) ] ),
        1:nWholePeriods )

    # Average over last shortened period if necessary.
    if length( snapReport[ 1 ] ) > 1 + nWholePeriods * aggrRatio
        tmpCounts[ end ] =
            mean( snapReport[ 2 ][ ( nWholePeriods * aggrRatio + 2 ):end ] )
    end  # if length( snapReport[ 1 ] ) > 1 + nWholePeriods * aggrRatio

    return ( tmpTimes, tmpCounts )
end  # countAverage( mpSim, reportTimeDelta, snapTimeDelta, prereqGroup )


# This function counts a moving average of the number of people
#   that satisfy the given set of prerequisites during each period. The average
#   is taken over a number of snapshots during each period.
export countMovingAverage
function countMovingAverage( mpSim::ManpowerSimulation, timeDelta::T1,
    windowSize::T2, prereqGroup::Union{Void, PrerequisiteGroup} = nothing ) where T1 <: Real where T2 <: Integer
    if timeDelta <= 0.0
        warn( "Cannot have a time grid with step size ⩽ 0.0, nothing returned." )
        return nothing
    end  # if if timeDelta <= 0.0

    if windowSize <= 0
        warn( "Moving average window size must be > 0, nothing returned." )
        return nothing
    end  # if reportTimeDelta % snapTimeDelta != 0.0

    if prereqGroup === nothing
        snapReport = countRecords( mpSim, timeDelta )
    else
        snapReport = countRecords( mpSim, timeDelta, prereqGroup )
    end  # if prereqGroup === nothing

    if windowSize == 1
        return snapReport
    end  # if windowSize == 1

    tmpTimes = snapReport[ 1 ]
    tmpCount = similar( tmpTimes, Float64 )
    nTimes = length( tmpTimes )
    map( ii -> tmpCount[ ii ] = sum( snapReport[ 2 ][ 1:ii ] ) / windowSize,
        1:(windowSize - 1) )  # The first entries.
    map( ii -> tmpCount[ ii ] =
        mean( snapReport[ 2 ][ (1:windowSize) + ii - windowSize ] ),
        windowSize:nTimes )  # The other entries.

    return ( tmpTimes, tmpCount )
end  # countMovingAverage( mpSim, timeDelta, windowSize, prereqGroup )


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

    tmpFlux = similar( tmpTimes[ 2:end ], Int )
    tmpFlux = map( ii -> tmpFlux[ ii ] =
        size( getInFlux( mpSim, tmpTimes[ ii ], tmpTimes[ ii + 1 ] ) )[ 1 ],
        eachindex( tmpFlux ) )
    return ( tmpTimes[ 2:end ], tmpFlux )

end  # countfluxIn( mpSim, timeDelta )


# This function counts the number of people that started to satisfy the given
#   set of prerequisites during each period. It returns a pair of time and
#   amount vectors.
function countFluxIn( dbase::PersonnelDatabase, times::Vector{Float64},
    prereqGroup::PrerequisiteGroup )
    tmpTimes = unique( times )

    if length( tmpTimes ) < 2
        warn( "A minimum of 2 unique entries needed in the time grid." )
    end  # if length( times ) < 2

    tmpTimes = sort( tmpTimes )
    result = similar( tmpTimes[ 2:end ], Int )

    for ii in eachindex( result )
        result[ ii ] = countFluxIn( dbase, prereqGroup, tmpTimes[ ii ],
            tmpTimes[ ii + 1 ] )
    end  # for ii in eachindex( result )

    return ( tmpTimes[ 2:end ], result )
end  # countFluxIn( dbase, times, prereqGroup )

function countFluxIn( mpSim::ManpowerSimulation, times::Vector{Float64},
    prereqGroup::PrerequisiteGroup )
    return countFluxIn( mpSim.simResult, times, prereqGroup )
end  # countFluxIn( mpSim, times, prereqGroup )

function countFluxIn( mpSim::ManpowerSimulation, timeDelta::T,
    prereqGroup::PrerequisiteGroup ) where T <: Real
    if timeDelta <= 0.0
        warn( "Cannot have a time grid with step size ⩽ 0.0, nothing returned." )
        return nothing
    end  # if timeDelta <= 0.0

    tMax = min( now( mpSim ), mpSim.simLength )
    tmpTimes = collect( 0.0:timeDelta:tMax )
    push!( tmpTimes, tMax )  # This is safe because the countFluxIn
                             #   function takes unique times.
    return countFluxIn( mpSim.simResult, tmpTimes, prereqGroup )
end  # countFluxIn( mpSim, timeDelta, prereqGroup )

# function countFluxIn( mpSim::ManpowerSimulation, times::Vector{Float64} )
#     return countFluxIn( mpSim, times, countPersonnelPrereqGroup )
# end  # countFluxIn( mpSim, times )

# function countFluxIn( mpSim::ManpowerSimulation, timeDelta::T ) where T <: Real
#     # If the report is already cached, return the cached report.
#     if isCached( mpSim.simCache, timeDelta, :fluxIn )
#         tMax = min( now( mpSim ), mpSim.simLength )
#         timeGrid = collect( timeDelta:timeDelta:tMax )
#
#         if timeGrid[ end ] < tMax
#             push!( timeGrid, tMax )
#         end  # if timeGrid[ end ] < tMax
#
#         return ( timeGrid, mpSim.simCache[ timeDelta, :fluxIn ] )
#     end  # if isCached( mpSim.simCache, timeDelta, :count )
#
#     # Check if the currect resolution can be divided by any of the cached
#     #   resolutions.
#     res = getCachedResolutions( mpSim.simCache )
#     res = res[ map( t -> 0 == ( timeDelta % t ) &&
#         ( isCached( mpSim.simCache, t, :fluxIn ) ), res ) ]
#
#     # If so, aggregate from the cached report with the coarsest resolution.
#     if !isempty( res )
#         fromRes = maximum( res )
#         aggregateFluxReport( mpSim.simCache, fromRes, timeDelta )
#         return countFluxIn( mpSim, timeDelta )
#     end  # if !isempty( res )
#
#     # Otherwise, generate a new report and cache it. If the simulation is
#     #   continued, the cache gets wiped.
#     report = countFluxIn( mpSim, timeDelta, countPersonnelPrereqGroup )
#     mpSim.simCache[ timeDelta, :fluxIn ] = report[ 2 ]
#     return report
# end  # countFluxIn( mpSim, timeDelta )


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

    # If we need to break down the fluxes by reason for leaving, we need to
    #   initalise a matrix to store the information.
    if includeByType
        queryCmd = "SELECT strValue
            FROM $(mpSim.historyDBname)
            WHERE attribute = 'status'"
        listOfReasons = SQLite.query( mpSim.simDB, queryCmd )
        listOfReasons = unique( listOfReasons[ 1 ].values )
        tmpBreakdown = zeros( Int, length( tmpTimes - 1 ),
            length( listOfReasons ) )
    end  # if includeByType

    tmpFlux = similar( tmpTimes[ 2:end ], Int )

    for ii in eachindex( tmpFlux )
        outFlux = getOutFlux( mpSim, tmpTimes[ ii ], tmpTimes[ ii + 1 ] )[ 1 ]
        tmpFlux[ ii ] = length( outFlux )

        if includeByType
            if tmpFlux[ ii ] > 0
                queryCmd = "SELECT strValue
                    FROM $(mpSim.historyDBname)
                    WHERE $(mpSim.idKey) IN ('$(join( outFlux.values, "', '" ))') AND
                    attribute = 'status' AND
                    $(tmpTimes[ ii ]) < timeIndex AND timeIndex <= $(tmpTimes[ ii + 1 ])"
                outReasons = SQLite.query( mpSim.simDB, queryCmd )[ 1 ].values
            else
                outReasons = Vector{String}()
            end  # if tmpFlux[ ii ] > 0

            reasonCounts = countmap( outReasons )

            map( jj -> tmpBreakdown[ ii, jj ] =
                get( reasonCounts, listOfReasons[ jj ], 0 ),
                eachindex( listOfReasons ) )
        end  # if includeByType
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


# This function counts the number of people that stopped to satisfy the given
#   set of prerequisites during each period. It returns a pair of time and
#   amount vectors.
function countFluxOut( dbase::PersonnelDatabase, times::Vector{Float64},
    prereqGroup::PrerequisiteGroup )
    tmpTimes = unique( times )

    if length( tmpTimes ) < 2
        warn( "A minimum of 2 unique entries needed in the time grid." )
    end  # if length( times ) < 2

    tmpTimes = sort( tmpTimes )
    result = similar( tmpTimes[ 2:end ], Int )

    for ii in eachindex( result )
        result[ ii ] = countFluxOut( dbase, prereqGroup, tmpTimes[ ii ],
            tmpTimes[ ii + 1 ] )
    end  # for ii in eachindex( result )

    return ( tmpTimes[ 2:end ], result )
end  # countFluxOut( dbase, times, prereqGroup )

function countFluxOut( mpSim::ManpowerSimulation, times::Vector{Float64},
    prereqGroup::PrerequisiteGroup )
    return countFluxOut( mpSim.simResult, times, prereqGroup )
end  # countFluxOut( mpSim, times, prereqGroup )

function countFluxOut( mpSim::ManpowerSimulation, timeDelta::T,
    prereqGroup::PrerequisiteGroup ) where T <: Real
    if timeDelta <= 0.0
        warn( "Cannot have a time grid with step size ⩽ 0.0, nothing returned." )
        return nothing
    end  # if timeDelta <= 0.0

    tMax = min( now( mpSim ), mpSim.simLength )
    tmpTimes = collect( 0.0:timeDelta:tMax )
    push!( tmpTimes, tMax )  # This is safe because the countFluxOut
                             #   function takes unique times.
    return countFluxOut( mpSim, tmpTimes, prereqGroup )
end  # countFluxOut( mpSim, timeDelta, prereqGroup )

# function countFluxOut( mpSim::ManpowerSimulation, times::Vector{Float64} )
#     return countFluxOut( mpSim, times, countPersonnelPrereqGroup )
# end  # countFluxOut( mpSim, times )

# function countFluxOut( mpSim::ManpowerSimulation, timeDelta::T ) where T <: Real
#     # If the report is already cached, return the cached report.
#     if isCached( mpSim.simCache, timeDelta, :fluxOut )
#         tMax = min( now( mpSim ), mpSim.simLength )
#         timeGrid = collect( timeDelta:timeDelta:tMax )
#
#         if timeGrid[ end ] < tMax
#             push!( timeGrid, tMax )
#         end  # if timeGrid[ end ] < tMax
#
#         return ( timeGrid, mpSim.simCache[ timeDelta, :fluxOut ] )
#     end  # if isCached( mpSim.simCache, timeDelta, :count )
#
#     # Check if the currect resolution can be divided by any of the cached
#     #   resolutions.
#     res = getCachedResolutions( mpSim.simCache )
#     res = res[ map( t -> 0 == ( timeDelta % t ) &&
#         ( isCached( mpSim.simCache, t, :fluxOut ) ), res ) ]
#
#     # If so, aggregate from the cached report with the coarsest resolution.
#     if !isempty( res )
#         fromRes = maximum( res )
#         aggregateFluxReport( mpSim.simCache, fromRes, timeDelta, false )
#         return countFluxOut( mpSim, timeDelta )
#     end  # if !isempty( res )
#
#     # Otherwise, generate a new report and cache it. If the simulation is
#     #   continued, the cache gets wiped.
#     report = countFluxOut( mpSim, timeDelta, countPersonnelPrereqGroup )
#     mpSim.simCache[ timeDelta, :fluxOut ] = report[ 2 ]
#     return report
# end  # countFluxOut( mpSim, timeDelta )

# This function creates a basic simulation report using the Functions
#   countRecords( mpSim, timeDelta ), countFluxIn( mpSim, timeDelta ), and
#   countFluxOut( mpSim, timeDelta ) and exports the report to an Excel file.
export generateReport
function generateReport( mpSim::ManpowerSimulation, timeDelta::T,
    fileName::String ) where T <: Real

    tic()
    nRecords = countRecords( mpSim, timeDelta )
    nFluxIn = countFluxIn( mpSim, timeDelta )
    nFluxOut = countFluxOut( mpSim, timeDelta )

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

    # Put data in Excel file
    n = length( nRecords[ 1 ] )
    sheet[ "A", 7 ] = nRecords[ 1 ][ 1 ]
    sheet[ "B", 7 ] = nRecords[ 2 ][ 1 ]

    for ii in 2:n
        sheet[ "A", 6 + ii ] = nRecords[ 1 ][ ii ]
        sheet[ "B", 6 + ii ] = nRecords[ 2 ][ ii ]
        sheet[ "C", 6 + ii ] = nFluxIn[ 2 ][ ii - 1 ]
        sheet[ "D", 6 + ii ] = nFluxOut[ 2 ][ ii - 1 ]
    end  # for ii in 2:n

    if n == length( nFluxIn[ 1 ] )
        sheet[ "A", 7 + n ] == nFluxIn[ 1 ][ n ]
        sheet[ "C", 7 + n ] == nFluxIn[ 2 ][ n ]
        sheet[ "D", 7 + n ] == nFluxOut[ 2 ][ n ]
    end  # if n == length( nFluxIn[ 1 ] )

    # Wrap up.
    sheet[ "B", 4 ] = toq()  # Time it took to create the report.
    tmpFileName = endswith( fileName, ".xlsx" ) ? fileName : fileName * ".xlsx"
    write( tmpFileName, workbook )
    println( "Report created and saved to $tmpFileName." )
end  # generateReport( mpSim, timeDelta )
