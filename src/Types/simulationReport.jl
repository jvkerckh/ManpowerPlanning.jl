# This file defines the SimulationReport type. This type holds the reports for
#   a particular time resolution of a particular simulation.

# The SimulationReport type does not require any other times.
requiredTypes = []

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( dirname( Base.source_path() ), reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end  # for reqType in requiredTypes


export SimulationReport
"""
This type defines a set of reports of a `ManpowerSimulation` for a specific time
grid.

The type contains the following fields:
* `timeGrid::Vector{Float64}`: the time grid of the report. The entries in this
vector are sorted from smallest to largest, and there are no duplicate entries.
* `activeCount::Vector{Int}`: the number of active personnel in the simulation
at each time point of the time grid.
* `fluxIn::Vector{Int}`: the number of personnel that became active between
every pair of consecutive time steps, with the final time point included.
* `fluxOut::Vector{Int}`: the number of personnel that became inactive between
every pair of consecutive time steps, with the final time point included.
* `fluxOutBreakdown::Dict{String, Vector{Int}}`: the number of personnel that
became inactive between every pair of consecutive time steps, with the final
time point included, broken down by reason for becoming inactive.
* `ageGrid::Vector{Float64}`: the grid of ages for the age distribution report.
* `ageDistribution::Array{Int, 2}`: the distribution of the age of active
personnel at every time point of the time grid, where each row corresponds to
one time point.
* `ageStats::Array{Float64, 5}`: basic statistics about the age distribution of
the active personnel at every time point of the time grid. The five columns hold
the following information, in this order: mean age, standard deviation, median
age, minimum age, maximum age.
"""
type SimulationReport

    timeGrid::Vector{Float64}
    activeCount::Vector{Int}
    fluxIn::Vector{Int}
    fluxOut::Vector{Int}
    fluxOutBreakdown::Dict{String, Vector{Int}}
    ageGrid::Vector{Float64}
    ageDist::Array{Int, 2}
    ageStats::Array{Float64, 2}


    # Default constructor
    function SimulationReport()

        newSimRep = new()
        newSimRep.timeGrid = Vector{Float64}()
        newSimRep.activeCount = Vector{Int}()
        newSimRep.fluxIn = Vector{Int}()
        newSimRep.fluxOut = Vector{Int}()
        newSimRep.fluxOutBreakdown = Dict{String, Vector{Int}}()
        newSimRep.ageGrid = Vector{Float64}()
        newSimRep.ageDist = Array{Int}( 0, 0 )
        newSimRep.ageStats = Array{Float64}( 0, 0 )
        return newSimRep

    end  # SimulationReport()


    # Constructor on grid
    function SimulationReport( timeGrid::Vector{Float64} )

        newSimRep = SimulationReport()
        setTimeGrid( newSimRep, timeGrid )
        return newSimRep

    end  # SimulationReport( timeGrid )

end  # type SimulationReport
