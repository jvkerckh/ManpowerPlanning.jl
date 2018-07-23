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
       generateAgeReports,
       generateExcelReport


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
                     timeRes::T )
    where T <: Real
```
This function generates a report of the number of active persons in the manpower
simulation `mpSim` for a time grid with time resolution `timeRes`. If the
current simulation time is zero, or the time resolution is negative, no report
is generated.

This function returns `nothing`. If the report couldn't be generated, the
function will issue warnings to that effect.
"""
# Functions used
# --------------
# From same file:
# - initialiseReport
# - generateCountReport
function generateCountReport( mpSim::ManpowerSimulation, timeRes::T ) where T <: Real

    # Initialise a report if there is no key.
    if !haskey( mpSim.simReports, timeRes )
        initialiseReport( mpSim, timeRes )
    end  # if !hasKey( mpSim.simReports, timeRes )

    # If there is still no key, it means the time resolution was negative, and
    #   nothing more can be done.
    if !haskey( mpSim.simReports, timeRes )
        return
    end  # if !haskey( mpSim.simReports, timeRes )

    generateCountReport( mpSim, mpSim.simReports[ timeRes ] )

end  # generateCountReport( mpSim, timeRes )

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
    ageRes::T2, fileName::String = "testReport" ) where T1 <: Real where T2 <: Real

    tStart = now()

    # Don't generate the Excel report if there's no count report available. This
    #   means that either the time resolution ⩽ 0 or that the simulation hasn't
    #   started yet.
    nRec = getCountReport( mpSim, timeRes )

    if nRec === nothing
        return
    end  # if nRec === nothing

    wb = Workbook()
    genSheet = createSheet( wb, "Personnel" )
    ageSheet = createSheet( wb, "Personnel age" )

    # General info
    genSheet[ "A", 1 ] = "Simulation length"
    genSheet[ "A", 2 ] = "Time resolution"
    genSheet[ "A", 3 ] = "Age dist. age resolution"
    genSheet[ "A", 4 ] = "Personnel cap"
    genSheet[ "A", 5 ] = "Report generation time"
    genSheet[ "B", 1 ] = min( now( mpSim ), mpSim.simLength )
    genSheet[ "B", 2 ] = timeRes
    genSheet[ "B", 3 ] = ageRes > 0 ? ageRes : "Invalid"
    genSheet[ "B", 4 ] = mpSim.personnelTarget
    genSheet[ "C", 5 ] = "s"

    # Retrieve other reports.
    timeSteps = nRec[ 1 ]
    nRec = nRec[ 2 ]
    nFluxIn = getFluxInReport( mpSim, timeRes )[ 2 ]
    nFluxOut = getFluxOutReport( mpSim, timeRes )[ 2 ]
    nFluxOutBreakdown = getFluxOutBreakdown( mpSim, timeRes )[ 2 ]
    fluxOutReasons = collect( keys( nFluxOutBreakdown ) )
    ageDist = getAgeDistributionReport( mpSim, timeRes, ageRes )
    ageStats = getAgeStatsReport( mpSim, timeRes )[ 2 ]

    # Table headers.
    headers = [ "sim time", "personnel", "flux in", "flux out", "net flux" ]
    headers = vcat( headers, fluxOutReasons )
    nReasons = length( fluxOutReasons )
    foreach( ii -> genSheet[ ii, 7 ] = headers[ ii ], eachindex( headers ) )

    # Headers of age sheet.
    headers = [ "sim time", "mean", "st. dev.", "median", "min", "max" ]

    # Add extra headers if an age distribution report is available.
    if ageDist !== nothing
        headers = vcat( headers, "ages", ageDist[ 2 ] )
    end  # if ageDist !== nothing

    foreach( ii -> ageSheet[ ii, 1 ] = headers[ ii ], eachindex( headers ) )

    # Tables.
    for ii in eachindex( timeSteps )
        # General sheet.
        tmpIndex = ii + 7
        genSheet[ "A", tmpIndex ] = timeSteps[ ii ]
        genSheet[ "B", tmpIndex ] = nRec[ ii ]

        if ii > 1
            genSheet[ "C", tmpIndex ] = nFluxIn[ ii - 1 ]
            genSheet[ "D", tmpIndex ] = nFluxOut[ ii - 1 ]
            genSheet[ "E", tmpIndex ] = "=C$(tmpIndex)-D$(tmpIndex)"
            foreach( jj -> genSheet[ jj + 5, tmpIndex ] =
                nFluxOutBreakdown[ fluxOutReasons[ jj ] ][ ii - 1 ],
                eachindex( fluxOutReasons ) )
        end  # if ii > 1

        # Age sheet.
        tmpIndex = ii + 1
        ageSheet[ "A", tmpIndex ] = timeSteps[ ii ]
        foreach( jj -> ageSheet[ jj + 1, tmpIndex ] = ageStats[ ii, jj ], 1:5 )

        if ageDist !== nothing
            foreach( jj -> ageSheet[ jj + 7, tmpIndex ] = ageDist[ 3 ][ ii, jj ],
                eachindex( ageDist[ 2 ] ) )
        end  # if ageDist !== nothing
    end  # for ii in eachindex( nRec )

    tEnd = now()
    genSheet[ "B", 5 ] = ( tEnd - tStart ).value / 1000
    tmpFilename = endswith( fileName, ".xlsx" ) ? fileName : fileName * ".xlsx"
    write( tmpFilename, wb )
    println( "Report created and saved to $tmpFilename." )

end  # generateExcelReport( mpSim, timeRes, ageRes )


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


# Include the retrieval functions.
include( joinpath( dirname( Base.source_path() ), "simulationReportRetrieval.jl" ) )

# Include the plotting functions.
include( joinpath( dirname( Base.source_path() ), "simulationPlots.jl" ) )
