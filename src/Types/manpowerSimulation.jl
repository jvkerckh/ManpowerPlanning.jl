# This file defines the ManpowerSimulation type. This type bundles all the
#   information of the simulation.

# The ManpowerSimulation type requires SimJulia, ResumableFunctions, and
#   Distributions.

# The ManpowerSimulation type requires all the other types.
requiredTypes = [ "personnel", "personnelDatabase", "prerequisite",
    "prerequisiteGroup", "recruitment", "retirement", "simulationCache" ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( dirname( Base.source_path() ), reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end  # for reqType in requiredTypes


export ManpowerSimulation
type ManpowerSimulation
    # This flag marks if the simulation has been properly initialised with the
    #   init function.
    isInitialised::Bool

    # This flag marks if the simulation has been properly initialised and has
    #   an empty results database.
    isVirgin::Bool

    # The ID key of the database.
    idKey::Symbol

    # The active, working personnel database.
    workingDbase::PersonnelDatabase

    # The simulation result.
    simResult::PersonnelDatabase

    # Maximum number of people in the simulation. If this is set to 0, there is
    #   no cap.
    personnelCap::Int

    # The recruitment schemes.
    recruitmentSchemes::Vector{Recruitment}

    # The attrition scheme.
    attritionScheme::Union{Void, Attrition}

    # The retirement scheme.
    retirementScheme::Union{Void, Retirement}

    # SimJulia simulation.
    sim::Simulation

    # The priorities of the various simulation phases.
    phasePriorities::Dict{Symbol, Int8}

    # The length of the simulation.
    simLength::Float64

    # The report cache of the simulation.
    simCache::SimulationCache


    function ManpowerSimulation()
        newMPsim = new()
        newMPsim.isInitialised = false
        newMPsim.isVirgin = false
        newMPsim.idKey = :id
        newMPsim.workingDbase = PersonnelDatabase( :id )
        newMPsim.simResult = PersonnelDatabase( :id )
        newMPsim.personnelCap = 0
        newMPsim.recruitmentSchemes = Vector{Recruitment}()
        newMPsim.attritionScheme = nothing
        newMPsim.retirementScheme = nothing
        newMPsim.sim = Simulation()
        newMPsim.phasePriorities = Dict( :recruitment => 1, :retirement => 2, :attrition => 3 )
        newMPsim.simLength = 1.0
        newMPsim.simCache = SimulationCache()
        return newMPsim
    end  # ManpowerSimulation()
end  # type ManpowerSimulation
