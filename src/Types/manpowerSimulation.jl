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
    # This is the name of the parameter configuration file. If this is an empty
    #   string, the simulation must be configured manually.
    parFileName::String

    # This is the name of this simulation instance.
    simName::String

    # This is a link to the database file holding the relevant tables for this
    #   simulation.
    simDB::SQLite.DB

    # These are the names of the personnel and history databases.
    personnelDBname::String
    historyDBname::String

    # This flag marks if the simulation has been properly initialised with the
    #   init function.
    isInitialised::Bool

    # This flag marks if the simulation has been properly initialised and has
    #   an empty results database.
    isVirgin::Bool

    # The ID key of the database.
    idKey::String

    # The active, working personnel database.
    workingDbase::PersonnelDatabase

    # The simulation result.
    simResult::PersonnelDatabase

    # Maximum number of people in the simulation. If this is set to 0, there is
    #   no cap.
    personnelCap::Int

    # The current number of active personnel members in the simulation.
    personnelSize::Int

    # The total number of personnel members in the simulation.
    resultSize::Int

    # The time between successive SQLite commits.
    commitFrequency::Float64

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


    function ManpowerSimulation( ; dbName::String = "simDB",
        simName::String = "testSim" )

        newMPsim = new()
        newMPsim.simName = simName

        # This block creates the database file if necessary and opens a link to
        #   it.  XXX Persistent??
        tmpDBname = dbName * ".sqlite"
        println( "Database file \"$tmpDBname\" ",
            isfile( tmpDBname ) ? "exists" : "does not exist", "." )
        newMPsim.simDB = SQLite.DB( tmpDBname )

        # This line ensures that foreign key logic works.
        SQLite.execute!( newMPsim.simDB, "PRAGMA foreign_keys = ON" )

        newMPsim.personnelDBname = "Personnel_" * simName
        newMPsim.historyDBname = "History_" * simName

        # Check if databases are present and issue a warning if so.
        tmpTableList = SQLite.tables( newMPsim.simDB )[ :name ]

        if ( newMPsim.personnelDBname ∈ tmpTableList ) ||
                ( newMPsim.historyDBname ∈ tmpTableList )
            warn( "Results for a simulation called \"$(newMPsim.simName)\" already in database. These will be overwritten." )
        end  # if newMPsim.personnelDBname ∈ tmpTableList

        newMPsim.isInitialised = false
        newMPsim.isVirgin = false
        newMPsim.idKey = "id"
        newMPsim.personnelCap = 0
        newMPsim.personnelSize = 0
        newMPsim.resultSize = 0
        newMPsim.commitFrequency = 1.0
        newMPsim.recruitmentSchemes = Vector{Recruitment}()
        newMPsim.attritionScheme = nothing
        newMPsim.retirementScheme = nothing
        newMPsim.sim = Simulation()
        newMPsim.phasePriorities = Dict( :recruitment => 1, :retirement => 2, :attrition => 3 )
        newMPsim.simLength = 1.0
        newMPsim.simCache = SimulationCache()
        return newMPsim

    end  # ManpowerSimulation( ; dbName, simName )

    function ManpowerSimulation( configFileName::String )

        newMPsim = ManpowerSimulation()
        initialiseFromExcel( newMPsim, configFileName )
        initialise( newMPsim )
        return newMPsim

    end  # ManpowerSimulation( configFileName )

end  # type ManpowerSimulation
