# This file holds the definition of the report retrieval functions pertaining to
#   the SimulationReport type.

export getCountReport,
       getFluxInReport,
       getFluxOutReport,
       getFluxOutBreakdown,
       getAgeDistributionReport,
       getAgeStatsReport


"""
```
getCountReport( mpSim::ManpowerSimulation,
                timeRes::T )
    where T <: Real
```
This function retrieves a report of the number of active persons in the manpower
simulation `mpSim` for a time grid with time resolution `timeRes`. If the
current simulation time is zero, or the time resolution is negative, no report
is retrieved.

This function returns a `Tuple{Vector{Float64}, Vector{Int}}` where the first
element is the time grid of the report, and the second element is the number of
active personnel at each time step. If no report is available for whatever
reason, the function returns `nothing`.
"""
# Functions used
# --------------
# From same file:
# - safeInitialiseReport
# - isReportGenerated
# From simulationReport.jl:
# - generateCountReport
function getCountReport( mpSim::ManpowerSimulation, timeRes::T ) where T <: Real

    # Try to initialise a report if needed. If it didn't work, don't continue.
    if !safeInitialiseReport( mpSim, timeRes )
        return
    end  # if !isReportInitialised( mpSim, timeRes )

    # Create the report if it doesn't exist yet.
    if !isReportGenerated( mpSim, timeRes, :count )
        generateCountReport( mpSim, timeRes )
    end  # if !isReportGenerated( mpSim, timeRes, :count )

    simReport = mpSim.simReports[ timeRes ]
    return ( simReport.timeGrid, simReport.activeCount )

end  # getCountReport( mpSim, timeRes )


"""
```
getFluxInReport( mpSim::ManpowerSimulation,
                 timeRes::T )
    where T <: Real
```
This function retrieves a report of the number of persons in the manpower
simulation `mpSim` who became active in each time interval of a time grid with
time resolution `timeRes`. If the current simulation time is zero, or the time
resolution is negative, no report is retrieved.

This function returns a `Tuple{Vector{Float64}, Vector{Int}}` where the first
element is the time grid of the report, and the second element is the number of
personnel who became active in each time interval. If no report is available for
whatever reason, the function returns `nothing`.
"""
# Functions used
# --------------
# From same file:
# - safeInitialiseReport
# - isReportGenerated
# From simulationReport.jl:
# - generateFluxInReport
function getFluxInReport( mpSim::ManpowerSimulation, timeRes::T ) where T <: Real

    # Try to initialise a report if needed. If it didn't work, don't continue.
    if !safeInitialiseReport( mpSim, timeRes )
        return
    end  # if !isReportInitialised( mpSim, timeRes )

    # Create the report if it doesn't exist yet.
    if !isReportGenerated( mpSim, timeRes, :fluxIn )
        generateFluxInReport( mpSim, timeRes )
    end  # if !isReportGenerated( mpSim, timeRes, :fluxIn )

    simReport = mpSim.simReports[ timeRes ]
    return ( simReport.timeGrid[ 2:end ], simReport.fluxIn )

end  # getFluxInReport( mpSim, timeRes )


"""
```
getFluxOutReport( mpSim::ManpowerSimulation,
                  timeRes::T )
    where T <: Real
```
This function retrieves a report of the number of persons in the manpower
simulation `mpSim` who became inactive in each time interval of a time grid with
time resolution `timeRes`. If the current simulation time is zero, or the time
resolution is negative, no report is retrieved.

This function returns a `Tuple{Vector{Float64}, Vector{Int}}` where the first
element is the time grid of the report, and the second element is the number of
personnel who became inactive in each time interval. If no report is available
for whatever reason, the function returns `nothing`.
"""
# Functions used
# --------------
# From same file:
# - safeInitialiseReport
# - isReportGenerated
# From simulationReport.jl:
# - generateFluxOutReport
function getFluxOutReport( mpSim::ManpowerSimulation, timeRes::T ) where T <: Real

    # Try to initialise a report if needed. If it didn't work, don't continue.
    if !safeInitialiseReport( mpSim, timeRes )
        return
    end  # if !isReportInitialised( mpSim, timeRes )

    # Create the report if it doesn't exist yet.
    if !isReportGenerated( mpSim, timeRes, :fluxOut )
        generateFluxOutReport( mpSim, timeRes )
    end  # if !isReportGenerated( mpSim, timeRes, :fluxOut )

    simReport = mpSim.simReports[ timeRes ]
    return ( simReport.timeGrid[ 2:end ], simReport.fluxOut )

end  # getFluxOutReport( mpSim, timeRes )


"""
```
getFluxOutBreakdown( mpSim::ManpowerSimulation,
                     timeRes::T )
    where T <: Real
```
This function retrieves a report of the number of persons in the manpower
simulation `mpSim` who became inactive in each time interval of a time grid with
time resolution `timeRes`, broken down by cause of inactivity. If the current
simulation time is zero, or the time resolution is negative, no report is
retrieved.

This function returns a `Tuple{Vector{Float64}, Dict{String, Vector{Int}}}`
where the first element is the time grid of the report, and the second element
is the number of personnel who became inactive in each time interval per cause
(= keys of the dictionary). If no report is available for whatever reason, the
function returns `nothing`.
"""
# Functions used
# --------------
# From same file:
# - safeInitialiseReport
# - isReportGenerated
# From simulationReport.jl:
# - generateFluxOutReport
function getFluxOutBreakdown( mpSim::ManpowerSimulation, timeRes::T ) where T <: Real

    # Try to initialise a report if needed. If it didn't work, don't continue.
    if !safeInitialiseReport( mpSim, timeRes )
        return
    end  # if !isReportInitialised( mpSim, timeRes )

    # Create the report if it doesn't exist yet.
    if !isReportGenerated( mpSim, timeRes, :fluxOut )
        generateFluxOutReport( mpSim, timeRes )
    end  # if !isReportGenerated( mpSim, timeRes, :fluxOut )

    simReport = mpSim.simReports[ timeRes ]
    return ( simReport.timeGrid[ 2:end ], simReport.fluxOutBreakdown )

end  # getFluxOutBreakdown( mpSim, timeRes )


"""
```
getAgeDistributionReport( mpSim::ManpowerSimulation,
                          timeRes::T1,
                          ageRes::T2 )
    where T1 <: Real where T2 <: Real
```
This function retrieves a report on the distribution of the ages of the active
persons for the manpower simulation `mpSim` for a time grid with time resolution
`timeRes`. The age points for the age distribution form a grid with resolution
`ageRes`.

This function returns a `Tuple{Vector{Float64}, Vector{Float64}, Array{Int, 2}}`
where the first element is the time grid of the report, the second element is
the age grid, and the last element is the matrix of the age distribution at
every point in the time grid, corresponding to the rows of the matrix. If no
report is available for whatever reason, the function returns `nothing`.
"""
# Functions used
# --------------
# From same file:
# - safeInitialiseReport
# - isReportGenerated
# - getAgeResolution
# From simulationReport.jl:
# - generateAgeReports
function getAgeDistributionReport( mpSim::ManpowerSimulation, timeRes::T1,
    ageRes::T2 ) where T1 <: Real where T2 <: Real

    # Try to initialise a report if needed. If it didn't work, don't continue.
    if !safeInitialiseReport( mpSim, timeRes )
        return
    end  # if !isReportInitialised( mpSim, timeRes )

    # Do nothing if the age resolution isn't positive.
    if ageRes <= 0
        warn( "Negative age resolution entered. No report generated." )
        return
    end  # if ageRes <= 0

    # Create the report if it doesn't exist yet, and if the age resolution is
    #   correct.
    if !isReportGenerated( mpSim, timeRes, :age ) ||
        ( getAgeResolution( mpSim, timeRes ) != ageRes )
        generateAgeReports( mpSim, timeRes, ageRes )
    end  # if !isReportGenerated( mpSim, timeRes, :age ) || ...

    simReport = mpSim.simReports[ timeRes ]
    return ( simReport.timeGrid, simReport.ageGrid, simReport.ageDist )

end  # getAgeDistributionReport( mpSim, timeRes, ageRes )


"""
```
getAgeStatsReport( mpSim::ManpowerSimulation,
                   timeRes::T )
    where T <: Real
```
This function retrieves a report on the statistics of the distribution of the
ages of the active persons for the manpower simulation `mpSim` for a time grid
with time resolution `timeRes`.

This function returns a `Tuple{Vector{Float64}, Array{Int, 2}}` where the first
element is the time grid of the report, and the second element is the matrix
with the statistics with each column corresponding to one of these statistics,
in that order: mean, standard deviation, median, minimum, maximum. If no report
is available for whatever reason, the function returns `nothing`.
"""
# Functions used
# --------------
# From same file:
# - safeInitialiseReport
# - isReportGenerated
# From simulationReport.jl:
# - generateAgeReports
function getAgeStatsReport( mpSim::ManpowerSimulation, timeRes::T ) where T <: Real

    # Try to initialise a report if needed. If it didn't work, don't continue.
    if !safeInitialiseReport( mpSim, timeRes )
        return
    end  # if !isReportInitialised( mpSim, timeRes )

    # Create the report if it doesn't exist yet.
    if !isReportGenerated( mpSim, timeRes, :age )
        generateAgeReports( mpSim, timeRes )
    end  # if !isReportGenerated( mpSim, timeRes, :age )

    simReport = mpSim.simReports[ timeRes ]
    return ( simReport.timeGrid, simReport.ageStats )

end  # getAgeStatsReport( mpSim, timeRes )


# ==============================================================================
# Non-exported methods.
# ==============================================================================


"""
```
isReportInitialised( mpSim::ManpowerSimulation,
                     timeRes::T )
    where T <: Real
```
This function checks whether the manpower simulation `mpSim` has a report
initialised for time resolution `timeRes`.

This function returns a `Bool`.
"""
# Functions used: none
function isReportInitialised( mpSim::ManpowerSimulation, timeRes::T ) where T <: Real

    return haskey( mpSim.simReports, timeRes )

end  # isReportInitialised( mpSim, timeRes )


"""
```
safeInitialiseReport( mpSim::ManpowerSimulation,
                      timeRes::T )
    where T <: Real
```
This function initialises a report for the manpower simulation `mpSim` for time
resolution `timeRes` if necessary, and checks if such a report has actually been
initialised.

This function returns a `Bool`.
"""
# Functions used
# --------------
# From same file:
# - isReportInitialised
# From simulationReport.jl:
# - initialiseReport
function safeInitialiseReport( mpSim::ManpowerSimulation, timeRes::T ) where T <: Real

    # Check if a report has been initialised for this time resolution. If not,
    #   initialise one.
    if !isReportInitialised( mpSim, timeRes )
        initialiseReport( mpSim, timeRes )
    end  # if !isReportInitialised( mpSim, timeRes )

    return isReportInitialised( mpSim, timeRes )

end  # safeInitialiseReport( mpSim, timeRes )


"""
```
isReportGenerated( mpSim::ManpowerSimulation,
                   timeRes::T,
                   report::Symbol )
    where T <: Real
```
This function checks whether the manpower simulation `mpSim` has a report for
time resolution `timeRes` of the type `report`. Allowed types are:
* `:count`
* `:fluxIn`
* `:fluxOut`
* `:age`

This function returns a `Bool`.
"""
# Functions used
# --------------
# From same file:
# - isReportInitialised
function isReportGenerated( mpSim::ManpowerSimulation, timeRes::T,
    report::Symbol ) where T <: Real

    if report ∉ [ :count, :fluxIn, :fluxOut, :age ]
        warn( "Unknown report type. This warning should not appear." )
        return false
    end  # if report ∉ [ :count, :fluxIn, :fluxOut, :age ]

    if !isReportInitialised( mpSim, timeRes )
        return false
    end  # if !isReportInitialised( mpSim, timeRes )

    simReport = mpSim.simReports[ timeRes ]

    if ( report === :count ) && !isempty( simReport.activeCount )
        return true
    elseif ( report === :fluxIn ) && !isempty( simReport.fluxIn )
        return true
    elseif ( report === :fluxOut ) && !isempty( simReport.fluxOut )
        return true
    elseif ( report === :age ) && !isempty( simReport.ageDist ) &&
        !isempty( simReport.ageStats )
        return true
    end  # if ( report === :count ) && ...

    return false

end  # isReportGenerated( mpSim, timeRes, report )


"""
```
getAgeResolution( mpSim,
                  timeRes )
    where T <: Real
```
This function retrieves the age resolution of the simulation reports for the
manpower simulation `mpSim`, with time resolution `timeRes`.

This function returns a `Float64`. If there is no age distribution report
initialised for the given time grid, or if the age grid has only one entry, the
function returns `NaN`.
"""
# Functions used
# --------------
# From same file:
# - isReportInitialised
function getAgeResolution( mpSim::ManpowerSimulation, timeRes::T ) where T <: Real

    if !isReportInitialised( mpSim, timeRes )
        return NaN
    end  # if !isReportInitialised( mpSim, timeRes )

    simReport = mpSim.simReports[ timeRes ]

    return length( simReport.ageGrid ) < 2 ? NaN :
        simReport.ageGrid[ 2 ] - simReport.ageGrid[ 1 ]

end  # getAgeResolution( mpSim, timeRes )
