# This file defines the ManpowerSimulation type. This type bundles all the
#   information of the simulation.

# The ManpowerSimulation type requires SimJulia, ResumableFunctions, and
#   Distributions.

# The ManpowerSimulation type requires all the other types.
requiredTypes = [ "prerequisite",
    "prerequisiteGroup", "recruitment", "retirement", "simulationReport" ]

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

    # this is the name of the simulation database file.
    dbName::String

    # This is the name of this simulation instance.
    simName::String

    # This is a link to the database file holding the relevant tables for this
    #   simulation.
    simDB::SQLite.DB

    # These are the names of the personnel, history, and transition databases.
    personnelDBname::String
    historyDBname::String
    transitionDBname::String

    # This flag marks if the simulation has been properly initialised with the
    #   init function.
    isInitialised::Bool

    # This flag marks if the simulation has been properly initialised and has
    #   an empty results database.
    isVirgin::Bool

    # The ID key of the database.
    idKey::String

    # Target number of people in the simulation. If this is set to 0, there is
    #   no cap.
    personnelTarget::Int

    # The current number of active personnel members in the simulation.
    personnelSize::Int

    # The total number of personnel members in the simulation.
    resultSize::Int

    # The time between successive SQLite commits.
    commitFrequency::Float64

    # The additional attributes.
    initAttrList::Vector{PersonnelAttribute}
    otherAttrList::Vector{PersonnelAttribute}

    # The states.
    initStateList::Dict{State, Vector{Transition}}
    otherStateList::Dict{State, Vector{Transition}}

    # The recruitment schemes.
    recruitmentSchemes::Vector{Recruitment}

    # The attrition scheme.
    attritionScheme::Attrition

    # The retirement scheme.
    retirementScheme::Union{Void, Retirement}

    # SimJulia simulation.
    sim::Simulation

    # Processor time of the simulation.
    simTimeElapsed::Dates.Millisecond

    # Time of attrition execution processes.
    attrExecTimeElapsed::Dates.Millisecond

    # The priorities of the various simulation phases.
    phasePriorities::Dict{Symbol, Int8}

    # The length of the simulation.
    simLength::Float64

    # The generated reports of the simulation.
    simReports::Dict{Float64, SimulationReport}


    function ManpowerSimulation( ; dbName::String = "simDB",
        simName::String = "testSim" )

        newMPsim = new()
        newMPsim.simName = simName

        # This block creates the database file if necessary and opens a link to
        #   it.  XXX Persistent??
        tmpDBname = ( dbName == "" ) || endswith( dbName, ".sqlite" ) ?
            dbName : dbName * ".sqlite"

        if tmpDBname == ""
            println( "Results database kept in memory." )
        else
            println( "Database file \"$tmpDBname\" ",
                isfile( tmpDBname ) ? "exists" : "does not exist", "." )
        end  # if tmpDBname == ""

        newMPsim.dbName = tmpDBname
        newMPsim.simDB = SQLite.DB( tmpDBname )

        # This line ensures that foreign key logic works.
        SQLite.execute!( newMPsim.simDB, "PRAGMA foreign_keys = ON" )

        newMPsim.personnelDBname = "Personnel_$simName"
        newMPsim.historyDBname = "History_$simName"
        newMPsim.transitionDBname = "Transitions_$simName"

        # Check if databases are present and issue a warning if so.
        tmpTableList = SQLite.tables( newMPsim.simDB )[ :name ]

        if ( newMPsim.personnelDBname ∈ tmpTableList ) ||
                ( newMPsim.historyDBname ∈ tmpTableList )
            warn( "Results for a simulation called \"$(newMPsim.simName)\" already in database. These will be overwritten." )
        end  # if newMPsim.personnelDBname ∈ tmpTableList

        newMPsim.isInitialised = false
        newMPsim.isVirgin = false
        newMPsim.idKey = "id"
        newMPsim.personnelTarget = 0
        newMPsim.personnelSize = 0
        newMPsim.resultSize = 0
        newMPsim.commitFrequency = 1.0
        newMPsim.initAttrList = Vector{PersonnelAttribute}()
        newMPsim.otherAttrList = Vector{PersonnelAttribute}()
        newMPsim.initStateList = Dict{State, Vector{Transition}}()
        newMPsim.otherStateList = Dict{State, Vector{Transition}}()
        newMPsim.recruitmentSchemes = Vector{Recruitment}()
        newMPsim.attritionScheme = Attrition( "default" )
        newMPsim.retirementScheme = nothing
        newMPsim.sim = Simulation()
        newMPsim.simTimeElapsed = Dates.Millisecond( 0 )
        newMPsim.attrExecTimeElapsed = Dates.Millisecond( 0 )
        newMPsim.phasePriorities = Dict( :attrCheck => 10,
            :recruitment => 20,
            :transition => 30,
            :retirement => 40,
            :attrition => 50 )
        newMPsim.simLength = 1.0
        newMPsim.simReports = Dict{Float64, SimulationReport}()
        return newMPsim

    end  # ManpowerSimulation( ; dbName, simName )

    function ManpowerSimulation( configFileName::String )

        newMPsim = ManpowerSimulation()
        initialiseFromExcel( newMPsim, configFileName )
        initialise( newMPsim )
        return newMPsim

    end  # ManpowerSimulation( configFileName )

end  # type ManpowerSimulation
