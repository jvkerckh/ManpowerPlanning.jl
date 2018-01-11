# The prerequisite group that allows counting of personnel members.
countPersonnelPrereqGroup = PrerequisiteGroup()
addPrereq!( countPersonnelPrereqGroup, Prerequisite( :status, :active,
    relation = ==, valType = Symbol ) )


# This function performs a snapshot at each moment in the times vector, after
#   sorting, and counts the number of personnel members satisfying the
#   prerequisites. It returns a pair of time and amount vectors.
export countRecords
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

function countRecords( mpSim::ManpowerSimulation, times::Vector{Float64} )
    return countRecords( mpSim, times, countPersonnelPrereqGroup )
end  # countRecords( mpSim, times )

function countRecords( mpSim::ManpowerSimulation, timeDelta::T ) where T <: Real
    # If the report is already cached, return the cached report.
    if isCached( mpSim.simCache, timeDelta, :count )
        return ( collect( 0.0:timeDelta:min( now( mpSim ), mpSim.simLength ) ),
            mpSim.simCache[ timeDelta, :count ] )
    end  # if isCached( mpSim.simCache, timeDelta, :count )

    # Check if the currect resolution can be divided by any of the cached
    #   resolutions.
    res = getCachedResolutions( mpSim.simCache )
    res = res[ map( t -> 0 == ( timeDelta % t ) &&
        ( isCached( mpSim.simCache, t, :count ) ), res ) ]

    # If so, aggregate from the cached report with the coarsest resolution.
    if !isempty( res )
        fromRes = maximum( res )
        aggregateCountReport( mpSim.simCache, fromRes, timeDelta )
        return countRecords( mpSim, timeDelta )
    end  # if !isempty( res )

    # Otherwise, generate a new report and cache it. If the simulation is
    #   continued, the cache gets wiped.
    report = countRecords( mpSim, timeDelta, countPersonnelPrereqGroup )
    mpSim.simCache[ timeDelta, :count ] = report[ 2 ]
    return report
end  # countRecords( mpSim, timeDelta )


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
    nWholePeriods = Int( floor( ( length( snapReport[ 1 ] ) - 1 ) / aggrRatio ) )
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


# This function counts the number of people that started to satisfy the given
#   set of prerequisites during each period. It returns a pair of time and
#   amount vectors.
export countFluxIn
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

function countFluxIn( mpSim::ManpowerSimulation, times::Vector{Float64} )
    return countFluxIn( mpSim, times, countPersonnelPrereqGroup )
end  # countFluxIn( mpSim, times )

function countFluxIn( mpSim::ManpowerSimulation, timeDelta::T ) where T <: Real
    # If the report is already cached, return the cached report.
    if isCached( mpSim.simCache, timeDelta, :fluxIn )
        tMax = min( now( mpSim ), mpSim.simLength )
        timeGrid = collect( timeDelta:timeDelta:tMax )

        if timeGrid[ end ] < tMax
            push!( timeGrid, tMax )
        end  # if timeGrid[ end ] < tMax

        return ( timeGrid, mpSim.simCache[ timeDelta, :fluxIn ] )
    end  # if isCached( mpSim.simCache, timeDelta, :count )

    # Check if the currect resolution can be divided by any of the cached
    #   resolutions.
    res = getCachedResolutions( mpSim.simCache )
    res = res[ map( t -> 0 == ( timeDelta % t ) &&
        ( isCached( mpSim.simCache, t, :fluxIn ) ), res ) ]

    # If so, aggregate from the cached report with the coarsest resolution.
    if !isempty( res )
        fromRes = maximum( res )
        aggregateFluxReport( mpSim.simCache, fromRes, timeDelta )
        return countFluxIn( mpSim, timeDelta )
    end  # if !isempty( res )

    # Otherwise, generate a new report and cache it. If the simulation is
    #   continued, the cache gets wiped.
    report = countFluxIn( mpSim, timeDelta, countPersonnelPrereqGroup )
    mpSim.simCache[ timeDelta, :fluxIn ] = report[ 2 ]
    return report
end  # countFluxIn( mpSim, timeDelta )


# This function counts the number of people that stopped to satisfy the given
#   set of prerequisites during each period. It returns a pair of time and
#   amount vectors.
export countFluxOut
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

function countFluxOut( mpSim::ManpowerSimulation, times::Vector{Float64} )
    return countFluxOut( mpSim, times, countPersonnelPrereqGroup )
end  # countFluxOut( mpSim, times )

function countFluxOut( mpSim::ManpowerSimulation, timeDelta::T ) where T <: Real
    # If the report is already cached, return the cached report.
    if isCached( mpSim.simCache, timeDelta, :fluxOut )
        tMax = min( now( mpSim ), mpSim.simLength )
        timeGrid = collect( timeDelta:timeDelta:tMax )

        if timeGrid[ end ] < tMax
            push!( timeGrid, tMax )
        end  # if timeGrid[ end ] < tMax

        return ( timeGrid, mpSim.simCache[ timeDelta, :fluxOut ] )
    end  # if isCached( mpSim.simCache, timeDelta, :count )

    # Check if the currect resolution can be divided by any of the cached
    #   resolutions.
    res = getCachedResolutions( mpSim.simCache )
    res = res[ map( t -> 0 == ( timeDelta % t ) &&
        ( isCached( mpSim.simCache, t, :fluxOut ) ), res ) ]

    # If so, aggregate from the cached report with the coarsest resolution.
    if !isempty( res )
        fromRes = maximum( res )
        aggregateFluxReport( mpSim.simCache, fromRes, timeDelta, false )
        return countFluxOut( mpSim, timeDelta )
    end  # if !isempty( res )

    # Otherwise, generate a new report and cache it. If the simulation is
    #   continued, the cache gets wiped.
    report = countFluxOut( mpSim, timeDelta, countPersonnelPrereqGroup )
    mpSim.simCache[ timeDelta, :fluxOut ] = report[ 2 ]
    return report
end  # countFluxOut( mpSim, timeDelta )

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
