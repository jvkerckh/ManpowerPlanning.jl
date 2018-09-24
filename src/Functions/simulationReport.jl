# This file holds the definition of the functions pertaining to the
#   SimulationReport type.

# The functions of the SimulationReport type require no additional types.
requiredTypes = [ "simulationReport" ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( dirname( Base.source_path() ), "..", "Types",
            reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end  # for reqType in requiredTypes

export setTimeGrid,
       setAgeGrid,
       initialiseReport,
       clearReports,
       generateReports,
       generateCountReport,
       generateFluxInReport,
       generateFluxOutReport,
       generateFluxReport,
       generateAgeReports,
       generateExcelReport,
       generateExcelFluxReport


"""
```
setTimeGrid( simRep::SimulationReport,
             grid::Vector{Float64} )
```
This function sets the time grid of the simulation report `simRep` to `grid`.
The entries in the grid will be sorted, and only the unique entries which are
>= 0 are retained. Additionally, any stored report will be deleted as it doesn't
match the time grid anymore.

This function returns `nothing`. If the resulting time grid is empty or has only
one entry, a warning is issued that some reporting functions will not generate
results.
"""
# Functions used
# --------------
# From same file
# - clearReports
function setTimeGrid( simRep::SimulationReport, grid::Vector{Float64} )

    tmpGrid = sort( unique( grid[ 0 .<= grid ] ) )
    simRep.timeGrid = tmpGrid
    clearReports( simRep )

    if isempty( tmpGrid )
        warn( "No valid points in time grid. Cannot generate reports." )
    elseif length( tmpGrid ) == 1
        warn( "Only one valid point in time grid. Cannot generate flux reports." )
    end  # if isempty( timeGrid )

end  # setTimeGrid( simRep, grid )


"""
```
setAgeGrid( simRep::SimulationReport,
            grid::Vector{Float64} )
```
This function sets the age grid for the age distribution report of the
simulation report `simRep` to `grid`. The entries in the grid will be sorted,
and only the unique entries which are >= 0 are retained. Additionally, the
stored age distribution report will be deleted as it doesn't match the age grid
anymore.

This function returns `nothing`. If the resulting age grid is empty, a warning
is issued that the age distribution reporting function will not generate
results.
"""
# Function used: none
function setAgeGrid( simRep::SimulationReport, grid::Vector{Float64} )

    tmpAgeGrid = sort( unique( grid[ 0 .<= grid ] ) )
    simRep.ageGrid = tmpAgeGrid
    simRep.ageDist = Array{Int}( 0, 0 )
        # empty! does not exist for Array{T,N} with N > 1.

    if isempty( tmpAgeGrid )
        warn( "No valid points in age grid. Cannot generate age distribution report." )
    end  # if isempty( tmpAgeGrid )

end  # setAgeGrid( simRep, grid )


"""
```
initialiseReport( mpSim::ManpowerSimulation,
                  timeRes::T )
    where T <: Real
```
This function initialises a report for the manpower simulation `mpSim`, with a
time resolution of `timeRes`. If the simulation already has a report for that
time resolution, it will be overwritten.

The function returns `nothing`. If the time resolution is negative, no report
will be initialised.
"""
# Functions used
# --------------
# From same file
# - constructor function
# - generateTimeGrid
function initialiseReport( mpSim::ManpowerSimulation, timeRes::T ) where T <: Real

    tmpGrid = generateTimeGrid( mpSim, timeRes )

    if tmpGrid === nothing
        return
    end  # if tmpGrid === nothing

    mpSim.simReports[ timeRes ] = SimulationReport( tmpGrid )
    return

end  # initialiseReport( mpSim, timeRes, ageRes )


"""
```
clearReports( simRep::SimulationReport )
```
This function clears all the reports from the simulation report `simRep`. It
will also remove the age grid for the age distribution report.

This function returns `nothing`.
"""
# Functions used: none
function clearReports( simRep::SimulationReport )

    empty!( simRep.activeCount )
    empty!( simRep.fluxIn )
    empty!( simRep.fluxOut )
    empty!( simRep.fluxOutBreakdown )
    simRep.ageDist = Array{Int}( 0, 0 )
    simRep.ageStats = Array{Float64}( 0, 0 )
        # empty! does not exist for Array{T,N} with N > 1.

end  # clearReports( simRep )


"""
```
generateReports( mpSim::ManpowerSimulation,
                 simRep::SimulationReport )
```
This function generates the simulation reports of the manpower simulation
`mpSim` and stores them in `simRep`. The reports use the time and age grids
defined in the `SimulationReport` object.

This function returns `nothing`. If specific reports couldn't be generated due
to the sizes of the grids, the function will issue warnings to that effect.
"""
# Functions used
# --------------
# From same file
# - generateCountReport
# - generateFluxInReport
# - generateFluxOutReport
# - generateAgeReports
function generateReports( mpSim::ManpowerSimulation, simRep::SimulationReport )

    generateCountReport( mpSim, simRep )
    generateFluxInReport( mpSim, simRep )
    generateFluxOutReport( mpSim, simRep )
    generateAgeReports( mpSim, simRep )

end  # generateReports( mpSim, simRep )

"""
```
generateReports( mpSim::ManpowerSimulation,
                 timeRes::T1,
                 ageRes::T2 )
```
This function generates the simulation reports of the manpower simulation
`mpSim` for a time grid with time resolution `timeRes`. The report for the age
distribution uses an age grid with resolution `ageRes`.

This function returns `nothing`. If specific reports couldn't be generated, the
function will issue warnings to that effect.
"""
# Functions used
# --------------
# From same file
# - generateCountReport
# - generateFluxInReport
# - generateFluxOutReport
# - generateAgeReports
function generateReports( mpSim::ManpowerSimulation, timeRes::T1, ageRes::T2 ) where T1 <: Real where T2 <: Real

    generateCountReport( mpSim, timeRes )
    generateFluxInReport( mpSim, timeRes )
    generateFluxOutReport( mpSim, timeRes )
    generateAgeReports( mpSim, timeRes, ageRes )

end  # generateReports( mpSim, timeRes, ageRes )


"""
```
generateCountReport( mpSim::ManpowerSimulation,
                     simRep::SimulationReport )
```
This function generates a report of the number of active persons in the manpower
simulation `mpSim` and stores this in `simRep`. The report uses the time grid
defined in the `SimulationReport` object, and shrinks it to the lower of the
current simulation time and the length of the simulation. If the current
simulation time is zero, no report is generated.

This function returns `nothing`. If the report couldn't be generated due to the
size of the time grid (meaning it's empty), the function will issue warnings to
that effect.
"""
# Functions used
# --------------
# From same file:
# - setTimeGrid
# From simProcessing.jl
# - getActiveAtTime
function generateCountReport( mpSim::ManpowerSimulation,
    simRep::SimulationReport )

    # Issue warning when trying to generate report of a simultation that hasn't
    #   started.
    if now( mpSim ) == 0
        warn( "Simulation hasn't started yet. Cannot generate report." )
        return
    end  # if now( mpSim ) == 0

    # Truncate time grid if last entry is past current simulation time.
    maxTime = min( now( mpSim ), mpSim.simLength )

    if simRep.timeGrid[ end ] > maxTime
        warn( "Last entry of time grid past current simulation time. Truncating grid." )
        maxIndex = findlast( simRep.timeGrid .<= maxTime )
        setTimeGrid( simRep, simRep.timeGrid[ 1:maxIndex ] )
    end  # if simRep.timeGrid[ end ] > maxTime

    # Issue warning on an empty time grid and don't do anything.
    if isempty( simRep.timeGrid )
        warn( "Time grid empty. Cannot generate active count report." )
        return
    end  # if isempty( simRep.timeGrid )

    simRep.activeCount = map( timePoint -> size(
        getActiveAtTime( mpSim, timePoint ) )[ 1 ], simRep.timeGrid )
    return

end  # generateCountReport( mpSim, simRep )


"""
```
generateCountReport( mpSim::ManpowerSimulation,
                     timeRes::T,
                     stateName::String = "" )
    where T <: Real
```
This function generates a report of the number of persons in the manpower
simulation `mpSim` who are in the state with name `stateName`, for a time grid
with time resolution `timeRes`.

This function returns a `DataFrame`. If the report couldn't be generated, the
function will issue warnings to that effect.
"""
function generateCountReport( mpSim::ManpowerSimulation, timeRes::T,
    stateName::String = "" )::DataFrame where T <: Real

    resultReport = DataFrame( Array{Float64}( 0, 1 ), [ :timePoint ] )

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

    tmpStateName = stateName == "" ? "active" : stateName

    # Generate the flux counts.
    fluxInCount = generateFluxReport( mpSim, timeRes, true, true,
        tmpStateName )
    fluxOutCount = generateFluxReport( mpSim, timeRes, false, true,
        tmpStateName )

    return generateCountReport( mpSim, tmpStateName, fluxInCount, fluxOutCount )

end  # generateCountReport( mpSim, timeRes, stateName )



"""
```
generateCountReport( mpSim::ManpowerSimulation,
                     stateName::String,
                     fluxInCount::DataFrame,
                     fluxOutCount::DataFrame )
```
This function generates a report of the number of persons in the manpower
simulation `mpSim` who are in the state with name `stateName`, using the flux
information contained in the reports `fluxInCount` and `fluxOutCount`.
Attention: this function should not be called directly as it does not perform
any sanity checks on the flux reports.

This function returns a `DataFrame`.
"""
function generateCountReport( mpSim::ManpowerSimulation, stateName::String,
    fluxInCount::DataFrame, fluxOutCount::DataFrame )::DataFrame

    queryCmd = "SELECT count($(mpSim.idKey)) initialPopulation FROM $(mpSim.transitionDBname)
        WHERE timeIndex < 0 AND endState IS '$stateName'"
    initPop = SQLite.query( mpSim.simDB, queryCmd )[  1, 1 ]
    timeGrid = fluxInCount[ :timeEnd ]
    counts = cumsum( fluxInCount[ end ] - fluxOutCount[ end ] ) + initPop

    return DataFrame( hcat( timeGrid, counts ),
        [ :timePoint, Symbol( stateName ) ] )

end  # generateCountReport( mpSim, stateName, fluxInCounts, fluxOutCounts )

#=
"""
```
generateCountReport( mpSim::ManpowerSimulation,
                     stateName::String,
                     timeRes::T,
                     breakdownBy::String = "" )
    where T <: Real
```
This function generates a report of the number of active persons in the manpower
simulation `mpSim` with the state with name `stateName` for a time grid with
time resolution `timeRes`. If the `breakdownBy` argument is provided, the
function also breaks the personnel counts down by the values of that attribute
if it exists. If the current simulation time is zero, or the time resolution is
negative, no report is generated.

This function returns a `Tuple{Vector{Float64}, Vector{Int}}` if no breakdown is
requested, where the first element is the time grid, and the second element are
the personnel counts. If a breakdown is requested, it returns a
`Tuple{Vector{Float64}, Vector{Int}, Vector{String}, Array{Int,2}}`, where the
two first elements are as above, the third is the list of different values the
breakdown attribute can take, and the last element is the matrix of counts,
where every column is the number of people having the attribute at a specific
value. If the report couldn't be generated, the function will issue warnings to
that effect and return `nothing`.
"""
# Functions used
# --------------
# From simProcessing.jl
# - getActiveAtTime
function generateCountReport( mpSim::ManpowerSimulation, stateName::String,
    timeRes::T, breakdownBy::String = "" ) where T <: Real

    # Issue warning if time resolution is negative.
    if timeRes <= 0
        warn( "Negative time resolution for grid. Resolution must be > 0.0" )
        return
    end

    # Issue warning when trying to generate report of a simultation that hasn't
    #   started.
    if now( mpSim ) == 0
        warn( "Simulation hasn't started yet. Cannot generate report." )
        return
    end  # if now( mpSim ) == 0

    tmpBreakdownBy = replace( breakdownBy, " ", "_" )

    # Test if the breakdown attribute exist.
    if ( breakdownBy != "" ) && !any( attr -> attr.name == tmpBreakdownBy,
        vcat( mpSim.initAttrList, mpSim.otherAttrList ) )
        tmpBreakdownBy = ""
        warn( "Attribute '$breakdownBy' doesn't exist. Can only generate overall count report." )
    end  # if ( breakdownBy != "" ) && ...

    # Generate the time grid.
    timeGrid = generateTimeGrid( mpSim, timeRes )

    if tmpBreakdownBy == ""
        counts = map( tPoint -> length( getActiveAtTime(
            mpSim, stateName, tPoint )[ 1 ] ), timeGrid )
        return ( timeGrid, counts )
    end  # if tmpBreakdownBy == ""

    nTimes = length( timeGrid )
    countBreakdown = Dict{String, Vector{Int}}()
    totals = similar( timeGrid, Int )

    # Perform the counts.
    for ii in 1:nTimes
        dbState = getDatabaseAtTime( mpSim, timeGrid[ ii ],
            [ tmpBreakdownBy ] )[ Symbol( tmpBreakdownBy ) ]
        counts = countmap( dbState )

        for attrVal in keys( counts )
            if attrVal ∉ keys( countBreakdown )
                countBreakdown[ attrVal ] = zeros( Int, nTimes )
            end  # if attrVal ∉ keys( countBreakdown )

            countBreakdown[ attrVal ][ ii ] = counts[ attrVal ]
        end  # for attrVal in keys( counts )
    end  # for ii in eachindex( timeGrid )

    attrVals = collect( keys( countBreakdown ) )
    counts = zeros( Int, nTimes, length( attrVals ) )
    foreach( ii -> counts[ :, ii ] = countBreakdown[ attrVals[ ii ] ],
        eachindex( attrVals ) )
    totals = map( ii -> sum( counts[ ii, : ] ), 1:nTimes )

    return ( timeGrid, totals, attrVals, counts )

end  # generateCountReport( mpSim, stateName, timeRes, breakdownBy )
=#

"""
```
generateFluxInReport( mpSim::ManpowerSimulation,
                      simRep::SimulationReport )
```
This function generates a report of the number of persons in the manpower
simulation `mpSim` who became active in each time interval and stores this in
`simRep`. The report uses the time grid defined in the `SimulationReport`
object, and shrinks it to the lower of the current simulation time and the
length of the simulation. If the current simulation time is zero, no report is
generated.

This function returns `nothing`. If the report couldn't be generated due to the
size of the time grid (empty or only 1 time point), the function will issue
warnings to that effect.
"""
# Functions used
# --------------
# From same file:
# - setTimeGrid
# From simProcessing.jl
# - getInFlux
function generateFluxInReport( mpSim::ManpowerSimulation,
    simRep::SimulationReport )

    # Issue warning when trying to generate report of a simultation that hasn't
    #   started.
    if now( mpSim ) == 0
        warn( "Simulation hasn't started yet. Cannot generate report." )
        return
    end  # if now( mpSim ) == 0

    # Truncate time grid if last entry is past current simulation time.
    maxTime = min( now( mpSim ), mpSim.simLength )

    if simRep.timeGrid[ end ] > maxTime
        warn( "Last entry of time grid past current simulation time. Truncating grid." )
        maxIndex = findlast( simRep.timeGrid .<= maxTime )
        setTimeGrid( simRep, simRep.timeGrid[ 1:maxIndex ] )
    end  # if simRep.timeGrid[ end ] > maxTime

    # Issue warning on an empty time grid or a time grid with one entry and
    #   don't do anything.
    if length( simRep.timeGrid ) < 2
        warn( "Not enough entries in time grid. Cannot generate flux in report." )
        return
    end  # length( simRep.timeGrid ) < 2

    simRep.fluxIn = map( ii -> size( getInFlux( mpSim, simRep.timeGrid[ ii ],
        simRep.timeGrid[ ii + 1 ] ) )[ 1 ],
        eachindex( simRep.timeGrid[ 2:end ] ) )
    return

end  # generateFluxInReport( mpSim, simRep )

"""
```
generateFluxInReport( mpSim::ManpowerSimulation,
                      timeRes::T )
    where T <: Real
```
This function generates a report of the number of persons in the manpower
simulation `mpSim` who became active in each time interval on a time grid with
resolution `timeRes`. If the current simulation time is zero, or the time
resolution is negative, no report is generated.

This function returns `nothing`. If the report couldn't be generated, the
function will issue warnings to that effect.
"""
# Functions used
# --------------
# From same file:
# - initialiseReport
# - generateFluxInReport
function generateFluxInReport( mpSim::ManpowerSimulation, timeRes::T ) where T <: Real

    # Initialise a report if there is no key.
    if !haskey( mpSim.simReports, timeRes )
        initialiseReport( mpSim, timeRes )
    end  # if !hasKey( mpSim.simReports, timeRes )

    # If there is still no key, it means the time resolution was negative, and
    #   nothing more can be done.
    if !haskey( mpSim.simReports, timeRes )
        return
    end  # if !haskey( mpSim.simReports, timeRes )

    generateFluxInReport( mpSim, mpSim.simReports[ timeRes ] )

end  # generateFluxInReport( mpSim, timeRes )

"""
```
generateFluxInReport( mpSim::ManpowerSimulation,
                      stateName::String,
                      timeRes::T,
                      isBreakdownBySource::Bool = true )
    where T <: Real
```
This function generates a report of the number of persons in the manpower
simulation `mpSim` who reached the state with name `stateName` in each time
interval on a time grid with resolution `timeRes`. The flag
`isBreakdownBySource` determines if the breakdown of the in flux happens by
source state, or by transition type. If the current simulation time is zero, or
the time resolution is negative, no report is generated.

This function returns a
`Tuple{Vector{Float64}, Vector{Int}, Vector{String}, Array{Int,2}}`. The first
element of the `Tuple` is the time grid, the second element is the total in flux
for each time interval, the third is the list of in flux types, and the last is
the number of people in each time interval by in flux type. If the report
couldn't be generated, the function will issue warnings to that effect and
return `nothing`.
"""
# Functions used
# --------------
# From simProcessing.jl
# - getInFlux
function generateFluxInReport( mpSim::ManpowerSimulation, stateName::String,
    timeRes::T, isBreakdownBySource::Bool = true ) where T <: Real

    # Issue warning if time resolution is negative.
    if timeRes <= 0
        warn( "Negative time resolution for grid. Resolution must be > 0.0" )
        return
    end

    # Issue warning when trying to generate report of a simultation that hasn't
    #   started.
    if now( mpSim ) == 0
        warn( "Simulation hasn't started yet. Cannot generate report." )
        return
    end  # if now( mpSim ) == 0

    # Generate the time grid.
    timeGrid = generateTimeGrid( mpSim, timeRes )
    nTimes = length( timeGrid ) - 1
    fluxInCounts = Dict{String, Vector{Int}}()
    colToRead = isBreakdownBySource ? :startState : :transition

    for ii in 1:nTimes
        inFluxList = getInFlux( mpSim, stateName, timeGrid[ ii ],
            timeGrid[ ii + 1 ] )

        # If there is no in flux information, don't do any operations.
        if length( inFluxList ) == 3
            counts = countmap( inFluxList[ colToRead ] )

            for tmpEntry in keys( counts )
                entry = isa( tmpEntry, String ) ? tmpEntry : "External"

                # Ensure the results can be processed.
                if !haskey( fluxInCounts, entry )
                    fluxInCounts[ entry ] = zeros( Int, nTimes )
                end  # if !haskey( colToRead, entry )

                fluxInCounts[ entry ][ ii ] = counts[ tmpEntry ]
            end  # for entry in keys( counts )
        end
    end  # for ii in eachindex( timeGrid[ 1:(end - 1) ] )

    # Copy entries to matrix and make totals.
    entries = collect( keys( fluxInCounts ) )
    counts = Array{ Int }( nTimes, length( entries ) )
    foreach( ii -> counts[ :, ii ] = fluxInCounts[ entries[ ii ] ],
        eachindex( entries ) )
    totals = map( ii -> sum( counts[ ii, : ] ), 1:nTimes )

    return ( timeGrid[ 2:end ], totals, entries, counts )

end  # generateFluxInReport( mpSim, stateName, timeRes, isBreakdownBySource )


"""
```
generateFluxOutReport( mpSim::ManpowerSimulation,
                       simRep::SimulationReport )
```
This function generates a report of the number of persons in the manpower
simulation `mpSim` who became inactive in each time interval and stores this in
`simRep`. The report uses the time grid defined in the `SimulationReport`
object, and shrinks it to the lower of the current simulation time and the
length of the simulation. If the current simulation time is zero, no report is
generated.

In addition to the flux out, this function also breaks this flux down by the
reason for inactivity.

This function returns `nothing`. If the report couldn't be generated due to the
size of the time grid (empty or only 1 time point), the function will issue
warnings to that effect.
"""
# Functions used
# --------------
# From same file:
# - setTimeGrid
# From simProcessing.jl
# - getOutFlux
function generateFluxOutReport( mpSim::ManpowerSimulation,
    simRep::SimulationReport )

    # Issue warning when trying to generate report of a simultation that hasn't
    #   started.
    if now( mpSim ) == 0
        warn( "Simulation hasn't started yet. Cannot generate report." )
        return
    end  # if now( mpSim ) == 0

    # Truncate time grid if last entry is past current simulation time.
    maxTime = min( now( mpSim ), mpSim.simLength )

    if simRep.timeGrid[ end ] > maxTime
        warn( "Last entry of time grid past current simulation time. Truncating grid." )
        maxIndex = findlast( simRep.timeGrid .<= maxTime )
        setTimeGrid( simRep, simRep.timeGrid[ 1:maxIndex ] )
    end  # if simRep.timeGrid[ end ] > maxTime

    # Issue warning on an empty time grid or a time grid with one entry and
    #   don't do anything.
    if length( simRep.timeGrid ) < 2
        warn( "Not enough entries in time grid. Cannot generate flux out reports." )
        return
    end  # length( simRep.timeGrid ) < 2

    # Get list of retirement reasons.
    queryCmd = "SELECT status
        FROM $(mpSim.personnelDBname)
        WHERE timeExited IS NOT NULL
        GROUP BY status"
    fluxOutReasons = SQLite.query( mpSim.simDB, queryCmd )[ :status ]

    # We perform multiple tests on the flux out queries, so vectors need to be
    #   initialised in advance.
    simRep.fluxOut = zeros( simRep.timeGrid[ 2:end ], Int )
    foreach( reason -> simRep.fluxOutBreakdown[ reason ] =
        zeros( simRep.fluxOut ), fluxOutReasons )

    for ii in eachindex( simRep.fluxOut )
        outFlux = getOutFlux( mpSim, simRep.timeGrid[ ii ],
            simRep.timeGrid[ ii + 1 ], [ "status" ] )
        simRep.fluxOut[ ii ] = size( outFlux )[ 1 ]
        reasonCount = countmap( outFlux[ :status ] )
        foreach( reason -> simRep.fluxOutBreakdown[ reason ][ ii ] =
            reasonCount[ reason ], keys( reasonCount ) )
    end  # for ii in eachindex( simRep.fluxOut )

    return

end  # generateFluxOutReport( mpSim, simRep )

"""
```
generateFluxOutReport( mpSim::ManpowerSimulation,
                       timeRes::T )
    where T <: Real
```
This function generates a report of the number of persons in the manpower
simulation `mpSim` who became inactive in each time interval on a time grid with
resolution `timeRes`. If the current simulation time is zero, or the time
resolution is negative, no report is generated.

This function returns `nothing`. If the report couldn't be generated, the
function will issue warnings to that effect.
"""
# Functions used
# --------------
# From same file:
# - initialiseReport
# - generateFluxOutReport
function generateFluxOutReport( mpSim::ManpowerSimulation, timeRes::T ) where T <: Real

    # Initialise a report if there is no key.
    if !haskey( mpSim.simReports, timeRes )
        initialiseReport( mpSim, timeRes )
    end  # if !hasKey( mpSim.simReports, timeRes )

    # If there is still no key, it means the time resolution was negative, and
    #   nothing more can be done.
    if !haskey( mpSim.simReports, timeRes )
        return
    end  # if !haskey( mpSim.simReports, timeRes )

    generateFluxOutReport( mpSim, mpSim.simReports[ timeRes ] )

end  # generateFluxOutReport( mpSim, timeRes )

"""
```
generateFluxOutReport( mpSim::ManpowerSimulation,
                       stateName::String,
                       timeRes::T,
                       isBreakdownByTarget::Bool = true )
    where T <: Real
```
This function generates a report of the number of persons in the manpower
simulation `mpSim` who left the state with name `stateName` in each time
interval on a time grid with resolution `timeRes`. The flag
`isBreakdownByTarget` determines if the breakdown of the in flux happens by
target state, or by transition type. If the current simulation time is zero, or
the time resolution is negative, no report is generated.

This function returns a `Tuple{Vector{Float64}, Vector{String}, Array{Int,2}}`.
The first element of the `Tuple` is the time grid, the second is the list of in
flux types with the total as first type, and the third is the number of people
in each time interval by in flux type. If the report couldn't be generated, the
function will issue warnings to that effect and return `nothing`.
"""
# Functions used
# --------------
# From simProcessing.jl
# - getOutFlux
function generateFluxOutReport( mpSim::ManpowerSimulation, stateName::String,
    timeRes::T, isBreakdownByTarget::Bool = true ) where T <: Real

    # Issue warning if time resolution is negative.
    if timeRes <= 0
        warn( "Negative time resolution for grid. Resolution must be > 0.0" )
        return
    end

    # Issue warning when trying to generate report of a simultation that hasn't
    #   started.
    if now( mpSim ) == 0
        warn( "Simulation hasn't started yet. Cannot generate report." )
        return
    end  # if now( mpSim ) == 0

    # Generate the time grid.
    timeGrid = generateTimeGrid( mpSim, timeRes )
    nTimes = length( timeGrid ) - 1
    fluxOutCounts = Dict{String, Vector{Int}}()
    colToRead = isBreakdownByTarget ? :endState : :transition

    for ii in 1:nTimes
        outFluxList = getOutFlux( mpSim, stateName, timeGrid[ ii ],
            timeGrid[ ii + 1 ] )

        # If there is no in flux information, don't do any operations.
        if length( outFluxList ) == 3
            counts = countmap( outFluxList[ colToRead ] )

            for tmpEntry in keys( counts )
                entry = isa( tmpEntry, String ) ? tmpEntry : "External"

                # Ensure the results can be processed.
                if !haskey( fluxOutCounts, entry )
                    fluxOutCounts[ entry ] = zeros( Int, nTimes )
                end  # if !haskey( colToRead, entry )

                fluxOutCounts[ entry ][ ii ] = counts[ tmpEntry ]
            end  # for entry in keys( counts )
        end
    end  # for ii in eachindex( timeGrid[ 1:(end - 1) ] )

    # Copy entries to matrix and make totals.
    entries = collect( keys( fluxOutCounts ) )
    counts = Array{ Int }( nTimes, length( entries ) )
    foreach( ii -> counts[ :, ii ] = fluxOutCounts[ entries[ ii ] ],
        eachindex( entries ) )
    totals = map( ii -> sum( counts[ ii, : ] ), 1:nTimes )

    return ( timeGrid[ 2:end ], totals, entries, counts )

end  # generateFluxOutReport( mpSim, stateName, timeRes, isBreakdownByTarget )


"""
```
generateFluxReport( mpSim::ManpowerSimulation,
                    timeRes::T,
                    transList::Union{String, Tuple{String, String}}... )
    where T <: Real
```
This function creates a report on fluxes in the manpower simulation `mpSim` on a
grid with time resolution `timeRes`, showing all the transitions
(transition types) listed in `transList`. These transitions can be entered by
transition name (as `String`) or as source/target state pairs (as
`Union{String, Tuple{String, String}}`). Non existing transitions are ignored,
names of recruitment schemes are accepted, the outflows `retired`,
`resigned`, and `fired` are accepted, and the empty state or state `external` is
accepted to describe in and out transitions.

This function returns a `Dataframe`, where the columns `:timeStart` and
`:timeEnd` hold the start and end times of each interval, and the other columns
the flux, per transition, for each time interval `timeStart < t <= timeEnd`
except for the first row; that one counts the flux occurring at time `t = 0.0`.
"""
function generateFluxReport( mpSim::ManpowerSimulation, timeRes::T,
    transList::Union{String, Tuple{String, String}}... )::DataFrame where T <: Real

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

    # Build list of real transitions.
    tmpTransList = Vector{String}()
    tmpPairList = Vector{Tuple{String, String}}()

    for transName in transList
        if isa( transName, String ) &&
            validateTransition( mpSim, transName )
            push!( tmpTransList, transName )
        elseif !isa( transName, String )
            startState, endState = transName
            startState = lowercase( startState ) == "external" ? "" : (
                lowercase( startState ) == "active" ? "active" : startState )
            endState = lowercase( endState ) == "external" ? "" : (
                lowercase( endState ) == "active" ? "active" : endState )

            if validateTransition( mpSim, startState, endState )
                push!( tmpPairList, ( startState, endState ) )
            end  # if validateTransition( mpSim, startState, endState )
        end  # if isa( transName, String ) && ...
    end  # for transName in transList

    tmpTransList = unique( tmpTransList )
    tmpPairList = unique( tmpPairList )

    # Generate the time grid.
    timeGrid = generateTimeGrid( mpSim, timeRes )
    nTimes = length( timeGrid )
    nTrans = length( tmpTransList )
    nPairs = length( tmpPairList )

    # Generate the results.
    resultData = zeros( nTimes, nTrans + nPairs + 2 )
    resultData[ :, 1 ] = vcat( 0.0, timeGrid[ 1:(end-1) ] )
    resultData[ :, 2 ] = timeGrid
    nameList = Vector{String}( nPairs )

    # Add the transitions by name.
    for ii in eachindex( tmpTransList )
        resultData[ :, ii + 2 ] = countTransitionFlux( mpSim,
            tmpTransList[ ii ], timeGrid )
    end  # for jj in eachindex( tmpTransList )

    # Add the transitions by source/target state pair.
    for ii in eachindex( tmpPairList )
        startState, endState = tmpPairList[ ii ]

        if startState == ""
            nameList[ ii ] = "External to " *
                ( endState == "active" ? "System" : endState )
        elseif endState == ""
            nameList[ ii ] = ( startState == "active" ? "System" : startState ) *
                " to External"
        else
            nameList[ ii ] = startState * " to " * endState
        end  # if startState == ""

        resultData[ :, ii + nTrans + 2 ] =
            countTransitionFlux( mpSim, startState, endState,
            timeGrid )
    end  # for jj in eachindex( tmpTransList )

    resultReport = DataFrame( resultData, vcat( :timeStart, :timeEnd,
        Symbol.( tmpTransList ), Symbol.( nameList ) ) )

    return resultReport

end  # generateFluxReport( mpSim, timeRes, transList... )


"""
```
generateFluxReport( mpSim::ManpowerSimulation,
                    timeRes::T,
                    isInFlux::Bool,
                    isByTransition::Bool,
                    stateList::String... )
    where T <: Real
```
This function creates a report on fluxes in the manpower simulation `mpSim` on a
grid with time resolution `timeRes` from/to all the states listed in
`stateList`. If the flag `isInFlux` is set to `true`, these are the in fluxes,
otherwise these are the out fluxes. The total in/out flux is broken down by
transition (type) if `isByTransition` is `true`, and by source/target state
otherwise.

This function returns a `Dataframe`, where the columns `:timeStart` and
`:timeEnd` hold the start and end times of each interval, and the other columns
the fluxes for each time interval `timeStart < t <= timeEnd`
except for the first row; that one counts the flux occurring at time `t = 0.0`.
"""
function generateFluxReport( mpSim::ManpowerSimulation, timeRes::T,
    isInFlux::Bool, isByTransition::Bool, stateList::String... )::DataFrame where T <: Real

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

    # Build list of real states.
    tmpStateList = Vector{String}()

    for stateName in stateList
        if haskey( mpSim.stateList, stateName )
            push!( tmpStateList, stateName )
        elseif lowercase( stateName ) == "active"
            push!( tmpStateList, "active" )
        end  # if haskey( mpSim.stateList, state )
    end  # for state in stateList

    tmpStateList = unique( tmpStateList )

    # Generate the time grid.
    timeGrid = generateTimeGrid( mpSim, timeRes )
    nTimes = length( timeGrid )
    nStates = length( tmpStateList )

    # Generate the results.
    resultData = hcat( vcat( 0.0, timeGrid[ 1:(end-1) ] ), timeGrid )
    nameList = Vector{String}()

    # Add the the flux counts for every state.
    for ii in eachindex( tmpStateList )
        tmpNameList, tmpResult = countTransitionFlux( mpSim, tmpStateList[ ii ],
            timeGrid, isInFlux, isByTransition )
        nameList = vcat( nameList, tmpNameList )
        resultData = hcat( resultData, tmpResult )
    end  # for ii in eachindex( tmpStateList )

    resultReport = DataFrame( resultData, vcat( :timeStart, :timeEnd,
        Symbol.( nameList ) ) )

    return resultReport

end  # generateFluxReport( mpSim, timeRes, isInFlux, isByTransition,
     #   stateList... )


"""
```
generateAgeReports( mpSim::ManpowerSimulation,
                    simRep::SimulationReport )
```
This function generates a report on the distribution of the ages of the active
persons, as well as some basic statistics of this age distribution, in the
manpower simulation `mpSim` and stores this in `simRep`. The report uses the
time grid defined in the `SimulationReport` object, and shrinks it to the lower
of the current simulation time and the length of the simulation. The age
distribution report also uses the age grid defined in the report object, and
adds the minumum age if the lowest age in the age grid is higher than that. If
the current simulation time is zero, no report is generated. If the age grid is
empty, no age distribution report is generated.

The frequencies in the distribution output are the number of people with age
between two consecutive ages in the grid, including the first of the two. For
the last frequency, it is the number of people having at least the last age.

The age statistics report determines the following statistics for the age
distribution at every time point of the time grid: mean, standard deviation,
median, minimum, and maximum.

This function returns `nothing`. If the report couldn't be generated due to the
size of the time grid, the function will issue warnings to that effect.
"""
# Functions used
# --------------
# From same file:
# - setTimeGrid
# - setAgeGrid
# From simProcessing.jl
# - getActiveAgesAtTime
function generateAgeReports( mpSim::ManpowerSimulation,
    simRep::SimulationReport )

    # Issue warning when trying to generate report of a simultation that hasn't
    #   started.
    if now( mpSim ) == 0
        warn( "Simulation hasn't started yet. Cannot generate report." )
        return
    end  # if now( mpSim ) == 0

    # Truncate time grid if last entry is past current simulation time.
    maxTime = min( now( mpSim ), mpSim.simLength )

    if simRep.timeGrid[ end ] > maxTime
        warn( "Last entry of time grid past current simulation time. Truncating grid." )
        maxIndex = findlast( simRep.timeGrid .<= maxTime )
        setTimeGrid( simRep, simRep.timeGrid[ 1:maxIndex ] )
    end  # if simRep.timeGrid[ end ] > maxTime

    # Issue warning on an empty time grid and don't do anything.
    if isempty( simRep.timeGrid )
        warn( "Time grid empty. Cannot generate age reports." )
        return
    end  # if isempty( simRep.timeGrid )

    # Find minimum age and add to grid if necessary. This will ensure that an
    #   age distribution report can always be generated, even on an empty age
    #   grid.
    queryCmd = "SELECT min( ageAtRecruitment ) minAge
        FROM $(mpSim.personnelDBname)"
    minAge = SQLite.query( mpSim.simDB, queryCmd )[ :minAge ][ 1 ]

    if !isempty( simRep.ageGrid )
        if minAge < simRep.ageGrid[ 1 ]
            setAgeGrid( simRep, vcat( minAge, simRep.ageGrid ) )
        end  # # if minAge > simRep.ageGrid[ 1 ]

        simRep.ageDist = zeros( Int, length( simRep.timeGrid ),
            length( simRep.ageGrid ) )
    else
        simRep.ageDist = Array{Int}( 0, 0 )
    end  # if !isempty( simRep.ageGrid )

    simRep.ageStats = zeros( Float64, length( simRep.timeGrid ), 5 )

    for ii in eachindex( simRep.timeGrid )
        ages = getActiveAgesAtTime( mpSim, simRep.timeGrid[ ii ] )

        if !isempty( simRep.ageDist )
            invCumFreq = map( age -> count( ages .>= age ), simRep.ageGrid )
            push!( invCumFreq, 0 )
            simRep.ageDist[ ii, : ] = invCumFreq[ 1:(end - 1) ] -
                invCumFreq[ 2:end ]
        end  # if !isempty( simRep.ageDist )

        if isempty( ages )
            simRep.ageStats[ ii, : ] = NaN
        else
            simRep.ageStats[ ii, : ] = [ mean( ages ), std( ages ),
                median( ages ), minimum( ages ), maximum( ages ) ]
        end
    end  # for ii in eachindex( simRep.timeGrid )

    return

end  # generateAgeReports( mpSim, simRep )

"""
```
generateAgeReports( mpSim::ManpowerSimulation,
                    timeRes::T1,
                    ageRes::T2 = NaN )
    where T1 <: Real where T2 <: Real
```
This function generates a report on the distribution of the ages of the active
persons, as well as some basic statistics of this age distribution, in the
manpower simulation `mpSim` for a time grid with time resolution `timeRes`. The
age points for the age distribution form a grid with resolution `ageRes`. If
the age resolution is `NaN`, no changes to the age grid are made.

This function returns `nothing`. If any of report couldn't be generated, the
function will issue warnings to that effect.
"""
# Functions used
# --------------
# From same file:
# - initialiseReport
# - generateAgeGrid
# - setAgeGrid
# - generateAgeReports
function generateAgeReports( mpSim::ManpowerSimulation, timeRes::T1,
    ageRes::T2 = NaN ) where T1 <: Real where T2 <: Real

    # Initialise a report if there is no key.
    if !haskey( mpSim.simReports, timeRes )
        initialiseReport( mpSim, timeRes )
    end  # if !hasKey( mpSim.simReports, timeRes )

    # If there is still no key, it means the time resolution was negative, and
    #   nothing more can be done.
    if !haskey( mpSim.simReports, timeRes )
        return
    end  # if !haskey( mpSim.simReports, timeRes )

    if !isnan( ageRes )
        tmpAgeGrid = generateAgeGrid( mpSim, ageRes )
        setAgeGrid( mpSim.simReports[ timeRes ],
            tmpAgeGrid === nothing ? Vector{Float64}() : tmpAgeGrid )
        # setAgeGrid takes only a Vector{Float64} as second argument, so if
        #   generating an age grid failed and returns nothing, a safety net is
        #   needed.
    end  # if !isnan( ageRes )

    generateAgeReports( mpSim, mpSim.simReports[ timeRes ] )

end  # generateAgeReports( mpSim, timeRes, ageRes )


"""
```
generateExcelReport( mpSim::ManpowerSimulation,
                     timeRes::T1,
                     ageRes::T2,
                     fileName::String )
    where T1 <: Real
    where T2 <: Real
```
This function generates an Excel report of the manpower simulation `mpSim` for a
time resolution `timeRes`, and an age resolution `ageRes` for the age
distribution report. The report is exported to the file with name `fileName`. If
the proposed filename does not have the file extension `.xlsx`, it will be
added.

The function returns `nothing`. If the report cannot be generated for whatever
reason, the function will give warnings to that effect.
"""
function generateExcelReport( mpSim::ManpowerSimulation, timeRes::T1,
    ageRes::T2, fileName::String = "testReport" )::Void where T1 <: Real where T2 <: Real

    tStart = now()

    # Don't generate the Excel report if there's no count report available. This
    #   means that either the time resolution ⩽ 0 or that the simulation hasn't
    #   started yet.
    nRec = getCountReport( mpSim, timeRes )

    if nRec === nothing
        return
    end  # if nRec === nothing

    # Retrieve other reports.
    timeSteps = nRec[ 1 ]
    nRec = nRec[ 2 ]
    nFluxIn = getFluxInReport( mpSim, timeRes )[ 2 ]
    nFluxOut = getFluxOutReport( mpSim, timeRes )[ 2 ]
    nFluxOutBreakdown = getFluxOutBreakdown( mpSim, timeRes )[ 2 ]
    fluxOutReasons = collect( keys( nFluxOutBreakdown ) )
    ageDist = getAgeDistributionReport( mpSim, timeRes, ageRes )
    ageStats = getAgeStatsReport( mpSim, timeRes )[ 2 ]

    # Generate file.
    tmpFileName = endswith( fileName, ".xlsx" ) ? fileName : fileName * ".xlsx"

    XLSX.openxlsx( tmpFileName, mode = "w" ) do xf
        persSheet = xf[ 1 ]
        XLSX.rename!( persSheet, "Personnel" )
        ageSheet = XLSX.addsheet!( xf, "Personnel age" )

        # General info
        tmp = [ "Simulation length", "Time resolution",
            "Age dist. age resolution", "Personnel cap",
            "Report generation time" ]
        foreach( ii -> persSheet[ "A$ii" ] = tmp[ ii ], eachindex( tmp ) )
        tmp = [ min( now( mpSim ), mpSim.simLength ), timeRes,
            ageRes > 0 ? ageRes : "Invalid", mpSim.personnelTarget ]
        foreach( ii -> persSheet[ "B$ii" ] = tmp[ ii ], eachindex( tmp ) )
        persSheet[ "C5" ] = "seconds"

        # Table headers.
        headers = [ "sim time", "personnel", "flux in", "flux out", "net flux" ]
        headers = vcat( headers, fluxOutReasons )
        nReasons = length( fluxOutReasons )
        foreach( ii -> persSheet[ XLSX.CellRef( 7, ii ) ] = headers[ ii ],
            eachindex( headers ) )

        # Headers of age sheet.
        headers = [ "sim time", "mean", "st. dev.", "median", "min", "max" ]

        # Add extra headers if an age distribution report is available.
        if ageDist !== nothing
            headers = vcat( headers, "ages", ageDist[ 2 ] )
        end  # if ageDist !== nothing

        foreach( ii -> ageSheet[ XLSX.CellRef( 1, ii ) ] = headers[ ii ],
            eachindex( headers ) )

        # Tables.
        for ii in eachindex( timeSteps )
            # General sheet.
            tmpIndex = ii + 7
            persSheet[ "A$tmpIndex" ] = timeSteps[ ii ]
            persSheet[ "B$tmpIndex" ] = nRec[ ii ]

            if ii > 1
                persSheet[ "C$tmpIndex" ] = nFluxIn[ ii - 1 ]
                persSheet[ "D$tmpIndex" ] = nFluxOut[ ii - 1 ]
                persSheet[ "E$tmpIndex" ] = "=C$(tmpIndex)-D$(tmpIndex)"
                testCell = XLSX.getcell( persSheet, "E$tmpIndex" )
                testCell.formula = persSheet[ "E$tmpIndex" ]
                foreach( jj -> persSheet[ XLSX.CellRef( tmpIndex, jj + 5 ) ] =
                    nFluxOutBreakdown[ fluxOutReasons[ jj ] ][ ii - 1 ],
                    eachindex( fluxOutReasons ) )
            end  # if ii > 1

            # Age sheet.
            tmpIndex = ii + 1
            ageSheet[ "A$tmpIndex" ] = timeSteps[ ii ]
            foreach( jj -> ageSheet[ XLSX.CellRef( tmpIndex, jj + 1 ) ] =
                ageStats[ ii, jj ], 1:5 )

            # Add the age distribution if it exists.
            if ageDist !== nothing
                foreach( jj -> ageSheet[ XLSX.CellRef( tmpIndex, jj + 7 ) ] =
                    ageDist[ 3 ][ ii, jj ], eachindex( ageDist[ 2 ] ) )
            end  # if ageDist !== nothing
        end  # for ii in eachindex( timeSteps )

        persSheet[ "B5" ] = ( now() - tStart ).value / 1000
    end  # XLSX.openxlsx( tmpFileName ) do xf

    println( "Report created and saved to $tmpFileName." )
    return

end  # generateExcelReport( mpSim, timeRes, ageRes )


"""
```
generateExcelFluxReport( mpSim::ManpowerSimulation,
                         timeRes::T,
                         transList::Union{String, Tuple{String, String}}...;
                         fileName::String = "testFluxReport",
                         overWrite::Bool = true,
                         timeFactor::Float64 = 12.0 )
    where T <: Real
```
This function creates a report on fluxes in the manpower simulation `mpSim` on a
grid with time resolution `timeRes`, showing all the transitions
(transition types) listed in `transList`. These transitions can be entered by
transition name (as `String`) or as source/target state pairs (as
`Union{String, Tuple{String, String}}`). Non existing transitions are ignored,
names of recruitment schemes are accepted, the outflows `retired`,
`resigned`, and `fired` are accepted, and the empty state or state `external` is
accepted to describe in and out transitions. The report is then saved in the
Excel file `fileName`, with the extension `".xlsx"` added if necessary. If the
flag `overWrite` is `true`, a new Excel file is created. Otherwise, the report
is added to the Excel file. Times are compressed by a factor `timeFactor`.

This function returns `nothing`.
"""
function generateExcelFluxReport( mpSim::ManpowerSimulation, timeRes::T1,
    transList::Union{String, Tuple{String, String}}...;
    fileName::String = "testFluxReport", overWrite::Bool = true,
    timeFactor::T2 = 12.0 )::Void where T1 <: Real where T2 <: Real

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


# ==============================================================================
# Non-exported methods.
# ==============================================================================

"""
```
generateTimeGrid( mpSim::ManpowerSimulation,
                  timeRes::T,
                  addCurrentTime::Bool = true )
    where T <: Real
```
This function generates a time grid for the manpower simulation `mpSim` with
time resolution `timeRes`. The resulting grid will span from 0 to the current
simulation time or the length of the simulation, whichever is smaller. If the
flag `addCurrentTime` is set to `true`, the current simulation time will be
added at the end.

This function returns a `Vector{float64}`. If the time resolution is negative,
or if the current simulation time is zero, the function gives a warning and
returns `nothing` instead.
"""
# Functions used: none
function generateTimeGrid( mpSim::ManpowerSimulation, timeRes::T,
    addCurrentTime::Bool = true ) where T <: Real

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
generateAgeGrid( mpSim::ManpowerSimulation,
                 ageRes::T )
    where T <: Real
```
This function generates an age grid for the manpower simulation `mpSim` with
age resolution `ageRes`. The resulting grid will span from the largest multiple
of the resolution which is smaller than or equal to the minimum age in the
simulation, to the largest multiple of the resolution which is smaller than or
equal to the maximum age in the simulation.

This function returns a `Vector{Float64}`. If the age resolution is negative, or
if there are no people in the simulation, the function gives a warning and
returns `nothing` instead.
"""
# Functions used: none
function generateAgeGrid( mpSim::ManpowerSimulation, ageRes::T ) where T <: Real

    if ageRes <= 0
        warn( "Negative age resolution entered. No age grid generated." )
        return
    end  # if ageRes <= 0

    if mpSim.resultSize == 0
        warn( "Simulation hasn't started yet. No age grid generated." )
        return
    end  # if mpSim.resultSize == 0

    queryCmd = "SELECT min( ageAtRecruitment ) minAge,
            max( ageAtRecruitment + timeExited - timeEntered ) maxAge
        FROM $(mpSim.personnelDBname)
        WHERE timeExited IS NOT NULL"
    ageBoundsLeft = SQLite.query( mpSim.simDB, queryCmd )

    # This ensures that the results are sensible... I hope.
    if !isa( ageBoundsLeft[ :minAge ][ 1 ], Float64 )
        ageBoundsLeft[ :minAge ][ 1 ] = +Inf
        ageBoundsLeft[ :maxAge ][ 1 ] = 0
    end  # if !isa( ageBoundsLeft[ :minAge ][ 1 ], Float64 )

    queryCmd = "SELECT min( ageAtRecruitment ) minAge,
            max( ageAtRecruitment + $(mpSim.simLength) - timeEntered ) maxAge
        FROM $(mpSim.personnelDBname)
        WHERE timeExited IS NULL"
    ageBoundsIn = SQLite.query( mpSim.simDB, queryCmd )

    # This ensures that the results are sensible... I hope.
    if !isa( ageBoundsIn[ :minAge ][ 1 ], Float64 )
        ageBoundsIn[ :minAge ][ 1 ] = +Inf
        ageBoundsIn[ :maxAge ][ 1 ] = 0
    end  # if !isa( ageBoundsLeft[ :minAge ][ 1 ], Float64 )

    minAge = floor( min( ageBoundsLeft[ :minAge ][ 1 ],
        ageBoundsIn[ :minAge ][ 1 ] ) / ageRes ) * ageRes
    maxAge = floor( max( ageBoundsLeft[ :maxAge ][ 1 ],
        ageBoundsIn[ :maxAge ][ 1 ] ) / ageRes ) * ageRes

    return collect( minAge:ageRes:maxAge )

end  # generateAgeGrid( mpSim, ageRes )


"""
```
validateTransition( mpSim::ManpowerSimulation,
                    transName::String )
```
This function tests if the manpower simulation `mpSim` has a transition named
`transName`, either as an in-transition (recruitment line), a through-
transition, or an out-transition (`retired`, `resigned`, `fired`).

This function returns a `Bool`, the result of the test.
"""
function validateTransition( mpSim::ManpowerSimulation,
    transName::String )::Bool

    isOut = lowercase( transName ) ∈ [ "snapshot", "retired", "resigned", "fired" ]
    isIn = transName ∈ map( recScheme -> recScheme.name,
        mpSim.recruitmentSchemes )
    isThrough = haskey( mpSim.transList, transName )

    return isIn || isOut || isThrough

end  # validateTransition( mpSim, transName )


"""
```
validateTransition( mpSim::ManpowerSimulation,
                    startState::String,
                    endState::String )
```
This function tests if the manpower simulation `mpSim` can have a transition
between `startState` and `endState`, where an empty string or `external` is used
to denote in and out-transitions. Note that it doens't check whether a
transition between these states actually exists.

This function returns a `Bool`, the result of the test.
"""
function validateTransition( mpSim::ManpowerSimulation, startState::String,
    endState::String )::Bool

    isStartExt = startState == ""
    isEndExt = endState == ""
    isStartState = haskey( mpSim.stateList, startState )
    isEndState = haskey( mpSim.stateList, endState )

    isIn = isStartExt && isEndState
    isOut = isStartState & isEndExt
    isThrough = isStartState && isEndState

    return isIn || isOut || isThrough

end  # validateTransition( mpSim, startState, endState )


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

    queryCmd = "SELECT DISTINCT $(mpSim.idKey), timeIndex FROM $(mpSim.transitionDBname)
        WHERE transition IS '$transName'"
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

end  # countTransitionFlux( mpSim, timeGrid )


"""
```
countTransitionFlux( mpSim::ManpowerSimulation,
                     startState::String,
                     endState::String,
                     timeGrid::Vector{Float64} )
```
This function counts the fluxes in the manpower simulation `mpSim` of the
transition from `startState` to `endState` over the time grid `timeGrid`.

The function returns a `Vector{Int}` with the flux counts for each time
interval. The first entry of the vector is the flux that occurs at time 0.
"""
function countTransitionFlux( mpSim::ManpowerSimulation, startState::String,
    endState::String, timeGrid::Vector{Float64} )::Vector{Int}

    startState = startState == "" ? "NULL" : "'$startState'"
    endState = endState == "" ? "NULL" : "'$endState'"

    queryCmd = "SELECT DISTINCT $(mpSim.idKey), timeIndex FROM $(mpSim.transitionDBname)
        WHERE startState IS $startState AND endState IS $endState"
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

end  # countTransitionFlux( mpSim, startState, endState, timeGrid )


"""
```
countTransitionFlux( mpSim::ManpowerSimulation,
                     stateName::String,
                     timeGrid::Vector{Float64},
                     isInFlux::Bool,
                     isByTransition::Bool )
```
This function counts the fluxes in the manpower simulation `mpSim` of the
transition from/to the state with name `stateName` over the time grid
`timeGrid`. If `isInFlux` is true, the in fluxes are counted, otherwise the out
fluxes are counted. If `isByTransition` is `true`, the total flux is broken down
by transition, otherwise by source/target state.

The function returns a `Tuple{Vector{String}}, Array{Int}` where the first
element is the name of each transition, given in such a way it carries all
needed information, and the second element is the matrix of the fluxes for each
time interval. The first row of the matrix are the fluxes that occur at time 0.
"""
function countTransitionFlux( mpSim::ManpowerSimulation, stateName::String,
    timeGrid::Vector{Float64}, isInFlux::Bool, isByTransition::Bool )

    tmpFluxResult = Dict{String, Vector{Int}}()

    # First, the flux in counts.
    countCol = isByTransition ? "transition" :
        ( isInFlux ? "startState" : "endState" )

    queryCmd = "SELECT timeIndex, $countCol FROM $(mpSim.transitionDBname)
        WHERE "

    if isInFlux
        queryCmd *= "startState IS NOT '$stateName' AND endState IS '$stateName'"
    else
        queryCmd *= "startState IS '$stateName' AND endState IS NOT '$stateName'"
    end  # if isInFlux

    transRecord = SQLite.query( mpSim.simDB, queryCmd )
    nFlux = size( transRecord )[ 1 ]
    map!( entry -> isa( entry, Missings.Missing ) ? "external" : entry,
        transRecord[ Symbol( countCol ) ], transRecord[ Symbol( countCol ) ] )
    nameList = unique( transRecord[ Symbol( countCol ) ] )
    nNames = length( nameList )
    fluxResult = zeros( Int, length( timeGrid ), nNames + 1 )
    foreach( name -> tmpFluxResult[ name ] = zeros( timeGrid ), nameList )

    for ii in eachindex( timeGrid )
        startTime = ii == 1 ? 0.0 : timeGrid[ ii - 1 ]
        endTime = timeGrid[ ii ]
        isInTimeSpan = ii == 1 ? transRecord[ :timeIndex ] .== 0 :
            startTime .< transRecord[ :timeIndex ] .<= endTime
        tmpCount = StatsBase.countmap(
            transRecord[ isInTimeSpan, Symbol( countCol ) ] )
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

    nameList = nameList .* ( isInFlux ? " to " : " from " ) .* stateName

    return vcat( nameList,
        "flux " * ( isInFlux ? "into" : "out of" ) * " $stateName" ),
        fluxResult

end  # countTransitionFlux( mpSim, stateName, timeGrid, byTransition )


"""
```
dumpFluxData( mpSim::ManpowerSimulation,
              fluxData::DataFrame,
              timeRes::T1,
              fileName::String,
              overWrite::Bool,
              timeFactor::T2,
              reportGenerationTime::Float64 )
    where T1 <: Real where T2 <: Real
```
This function writes the flux data in `fluxData` to the Excel file `fileName`,
using the other parameters as guidance. If the flag `overWrite` is `true`, a new
file is created, otherwise a new sheet is added to the file.

This function returns a `Float6'`, the time (in seconds) it took to write the
Excel report.
"""
function dumpFluxData( mpSim::ManpowerSimulation, fluxData::DataFrame,
    timeRes::T1, fileName::String, overWrite::Bool, timeFactor::T2,
    reportGenerationTime::Float64 )::Float64 where T1 <: Real where T2 <: Real

    tStart = now()
    tElapsed = 0.0

    XLSX.openxlsx( fileName, mode = overWrite ? "w" : "rw" ) do xf
        fSheet = xf[ 1 ]

        if overWrite
            XLSX.rename!( fSheet, "Flux Report" )
        else
            nSheets = XLSX.sheetcount( xf )
            fSheet = XLSX.addsheet!( xf, "Flux Report $(nSheets + 1)" )
        end  # if overWrite

        # Sheet header
        fSheet[ "A1" ] = "Simulation length"
        fSheet[ "B1" ] = mpSim.simLength / timeFactor
        fSheet[ "A2" ] = "Time resolution of report"
        fSheet[ "B2" ] = timeRes / timeFactor
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
        fSheet[ "B$(nPoints + 8)" ] = "Average flux"
        fSheet[ "B$(nPoints + 9)" ] = "St.dev. of flux"

        for jj in eachindex( tNames )
            rangeRef = XLSX.CellRange( 7, jj + 2, nPoints + 6, jj + 2 )

            avRef = XLSX.CellRef( nPoints + 8, jj + 2 )
            fSheet[ avRef ] = "=average($rangeRef)"
            testCell = XLSX.getcell( fSheet, avRef )
            testCell.formula = fSheet[ avRef ]

            sdRef = XLSX.CellRef( nPoints + 9, jj + 2 )
            fSheet[ sdRef ] = "=stdev($rangeRef)"
            testCell = XLSX.getcell( fSheet, sdRef )
            testCell.formula = fSheet[ sdRef ]
        end  # for jj in eachindex( tNames )

        tElapsed = ( now() - tStart ).value / 1000.0
        fSheet[ "B4" ] = tElapsed
    end  # XLSX.openxlsx( tmpFileName, "w" ) do xf

    return tElapsed

end  # dumpFluxData( mpSim, fluxData, timeRes, fileName, overWrite, timeFactor )


# Include the retrieval functions.
include( joinpath( dirname( Base.source_path() ), "simulationReportRetrieval.jl" ) )

# Include the plotting functions.
include( joinpath( dirname( Base.source_path() ), "simulationPlots.jl" ) )
