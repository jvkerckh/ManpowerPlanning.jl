# This file defines the functions pertaining to the ManpowerSimulation type.

# The functions of the ManpowerSimulation type require SimJulia,
#   ResumableFunctions, and Distributions.

# The functions of the ManpowerSimulation type require all types.
requiredTypes = [ "recruitment",
    "state",
    "transition",
    "retirement",
    "attrition",
    "simulationReport",
    "manpowerSimulation" ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( dirname( Base.source_path() ), "..", "Types",
            reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end  # for reqType in requiredTypes


# This function tests if the simulation has been properly initialised.
export isInitialised
function isInitialised( mpSim::ManpowerSimulation )

    return mpSim.isInitialised

end  # isInitialised( mpSim )


# This function sets the ID key in the simulation to the given attribute. This
#   does NOT update the databases.
function setKey( mpSim::ManpowerSimulation, id::Union{Symbol, String} = "id" )

    mpSim.idKey = String( id )

end  # setKey!( mpSim, id )


include( joinpath( dirname( Base.source_path() ), "parFileProcessing.jl" ) )
include( joinpath( dirname( Base.source_path() ), "parFileToSQLite.jl" ) )
include( joinpath( dirname( Base.source_path() ), "sqLiteToSim.jl" ) )
include( joinpath( dirname( Base.source_path() ), "simToSQLite.jl" ) )


# This function sets the cap on the number of personnel in the simulation. Note
#   that this cap can be (temporarily) violated if the initial manpower force is
#   larger than the personnel cap. If this function receives a value ⩽ 0, there
#   will not be a personnel cap.
export setPersonnelCap
function setPersonnelCap( mpSim::ManpowerSimulation, cap::T ) where T <: Integer

    mpSim.personnelTarget = cap > 0 ? cap : 0

end  # setPersonnelCap( mpSim, cap )


# This function sets the time between two database commits.
export setDatabaseCommitTime
function setDatabaseCommitTime( mpSim::ManpowerSimulation, commitFreq::T ) where T <: Real

    if commitFreq <= 0.0
        warn( "Time between two database commits must be > 0.0." )
        return
    end  # if commitFreq <= 0.0

    mpSim.commitFrequency = commitFreq

end  # setDatabaseCommitTime( mpSim, commitFreq )


# This function adds a personnel attribute to the manpower simulation. Note that
#   it does not check whether the attribute has been defined already or not.
# This function only works if the simulation hasn't started yet.
export addAttribute!
function addAttribute!( mpSim::ManpowerSimulation, attr::PersonnelAttribute )

    if now( mpSim ) == 0
        push!( isempty( attr.values ) ? mpSim.otherAttrList :
            mpSim.initAttrList, attr )
    end  # if now( mpSim ) == 0

    return

end  # addAttribute!( mpSim, attr )


# This function clears the list of personnel attributes.
# This function only works if the simulation is in a virgin state.
export clearAttributes!
function clearAttributes!( mpSim::ManpowerSimulation )

    if now( mpSim ) == 0
        empty!( mpSim.initAttrList )
        empty!( mpSim.otherAttrList )
    end  # if now( mpSim ) == 0

    return

end  # clearAttributes!( mpSim )


# This function adds a possible personnel state.
# This function does nothing if the simulation is already running.
export addState!
function addState!( mpSim::ManpowerSimulation, state::State,
    isInitial::Bool = false )

    if now( mpSim ) == 0
        if isInitial
            mpSim.initStateList[ state ] = Vector{Transition}()
        else
            mpSim.otherStateList[ state ] = Vector{Transition}()
        end  # if isinitial
    end  # if now( mpSim ) == 0

    return

end  # addState!( mpSim )


# This function clears the list of possible personnel states.
# This function does nothing if the simulation is already running.
export clearStates!
function clearStates!( mpSim::ManpowerSimulation )

    if now( mpSim ) == 0
        empty!( mpSim.initStateList )
        empty!( mpSim.otherStateList )
    end  # if now( mpSim ) == 0

    return

end  # clearStates!( mpSim, state, isInitial )


# This function adds a personnel state transition.
# This function does nothing if the simulation is already running.
export addTransition!
function addTransition!( mpSim::ManpowerSimulation, trans::Transition )

    if now( mpSim ) == 0
        if trans.startState.isInitial
            push!( mpSim.initStateList[ trans.startState ], trans )
        else
            push!( mpSim.otherStateList[ trans.startState ], trans )
        end  # if isStartInit
    end  # if now( mpSim ) == 0

    return

end  # addTransition!( mpSim, state )


# This function clears the the personnel state transitions.
# This function does nothing if the simulation is already running.
export clearTransitions!
function clearTransitions!( mpSim::ManpowerSimulation )

    if now( mpSim ) == 0
        foreach( state -> empty!( mpSim.initStateList[ state ] ),
            keys( mpSim.initStateList ) )
        foreach( state -> empty!( mpSim.otherStateList[ state ] ),
            keys( mpSim.otherStateList ) )
    end  # if now( mpSim ) == 0

    return

end  # clearTransitions!( mpSim )


# This function adds a recruitment scheme to the simulation.
# This function does nothing if the simulation is already running. XXX (desirable??)
export addRecruitmentScheme!
function addRecruitmentScheme!( mpSim::ManpowerSimulation,
    recScheme::Recruitment )

    if now( mpSim ) == 0
        push!( mpSim.recruitmentSchemes, recScheme )
    end  # if now( mpSim ) == 0

    return

end  # addRecruitmentScheme!( mpSim, recScheme )


# This function clears the recruitment schemes from the simulation.
# This function should NOT be called while running a simulation!
export clearRecruitmentSchemes!
function clearRecruitmentSchemes!( mpSim::ManpowerSimulation )

    if now( mpSim ) == 0
        empty!( mpSim.recruitmentSchemes )
    end  # if now( mpSim ) == 0

    return

end  # clearRecruitmentSchemes!( mpSim )


# This function sets the retirement scheme of the simulation.
export setRetirement
function setRetirement( mpSim::ManpowerSimulation,
    retScheme::Union{Void, Retirement} = nothing )

    mpSim.retirementScheme = retScheme

end  # setRetirement( mpSim, retScheme )


# This function sets the attrition scheme.
export setAttrition
function setAttrition( mpSim::ManpowerSimulation,
    attrScheme::Union{Void, Attrition} = nothing )

    mpSim.defaultAttritionScheme = attrScheme

end  # setAttrition( mpSim, attrScheme )


# This function sets the length of the simulation.
export setSimulationLength
function setSimulationLength( mpSim::ManpowerSimulation, simLength::T ) where T <: Real

    if simLength <= 0.0
        warn( "Simulation length must be > 0.0" )
        return
    end  # if simLength <= 0

    mpSim.simLength = simLength

end  # setSimulationLength( mpSim, simLength )


export setPhasePriority
function setPhasePriority( mpSim::ManpowerSimulation, phase::Symbol,
    priority::T ) where T <: Integer

    if ( phase ∉ [ :recruitment, :retirement, :attrition, :transition ] ) &&
        ( phase ∉ mpSim.workingDbase.attrs )
        warn( "Unknown simulation phase, not setting priority." )
        return
    end

    mpSim.phasePriorities[ phase ] = priority

end  # setPhasePriority( mpSim, phase, priority )


export resetSimulation
function resetSimulation( mpSim::ManpowerSimulation )

    mpSim.sim = Simulation()
    mpSim.simTimeElapsed = Dates.Millisecond( 0 )

    # First, drop the tables with the same name if they exist.
    # XXX The personnel table must be dropped last due to the FOREIGN KEY
    #   constraints in the other tables.
    SQLite.drop!( mpSim.simDB, mpSim.historyDBname, ifexists = true )
    SQLite.drop!( mpSim.simDB, mpSim.transitionDBname, ifexists = true )
    SQLite.drop!( mpSim.simDB, mpSim.personnelDBname, ifexists = true )

    # Then, create the personnel and history databases.
    # XXX Other defined attributes need to be introduced here as well.
    command = "CREATE TABLE $(mpSim.personnelDBname)(
        $(mpSim.idKey) varchar(16) NOT NULL PRIMARY KEY,
        timeEntered float,
        timeExited float,
        ageAtRecruitment float,
        expectedRetirementTime float,
        expectedAttritionTime float,
        attritionScheme varchar(64)"

    if !( isempty( mpSim.initAttrList ) && isempty( mpSim.otherAttrList ) )
        command *= ',' * join( map( attr -> attr.name * " varcar(64)",
            vcat( mpSim.initAttrList, mpSim.otherAttrList ) ), ", " )
    end  # if !( isempty( mpSim.initAttrList ) &&

    command *= ", status varchar(16) )"
    SQLite.execute!( mpSim.simDB, command )

    command = "CREATE TABLE $(mpSim.historyDBname)(
        $(mpSim.idKey) varchar(16),
        attribute varchar(255),
        timeIndex float,
        numValue float,
        strValue varchar(255),
        FOREIGN KEY ($(mpSim.idKey)) REFERENCES $(mpSim.personnelDBname)($(mpSim.idKey))
    )"
    SQLite.execute!( mpSim.simDB, command )

    command = "CREATE TABLE $(mpSim.transitionDBname)(
        $(mpSim.idKey) varchar(16),
        timeIndex float,
        transition varchar(255),
        startState varchar(255),
        endState varchar(255),
        FOREIGN KEY ($(mpSim.idKey)) REFERENCES $(mpSim.personnelDBname)($(mpSim.idKey))
    )"
    SQLite.execute!( mpSim.simDB, command )

    mpSim.personnelSize = 0
    mpSim.resultSize = 0

    foreach( state -> state.inStateSince = Dict{String, Float64}(),
        keys( merge( mpSim.initStateList, mpSim.otherStateList ) ) )

    # And wipe all existing simulation reports.
    empty!( mpSim.simReports )

    mpSim.isVirgin = true

end  # resetSimulation( mpSim )


# This function generates a random initial population for the simulation. If the
#   cap is < 0, the initial population satisfies the cap in the simulation.
# If the simulation has already started, this will reset the simulation!
export populate
function populate( mpSim::ManpowerSimulation, cap::T = 0 ) where T <: Integer
    # Throw an error if a populate to cap is requested for a simulation without
    #   personnel cap.
    if ( cap < 0 ) && ( mpSim.personnelTarget == 0 )
        error( "Simulation has no cap, cannot populate to cap." )
    end  # if ( cap < 0 ) ...

    # (Re)initialise the simulation and the population.
    resetSimulation( mpSim )

    # If the initial population is zero, stop.
    if cap == 0
        return
    end  # if cap == 0

    # Set the actual number of personnel to seed.
    tmpCap = cap < 0 ? mpSim.personnelTarget : cap
    isRetirement = mpSim.retirementScheme !== nothing
    timeDist = isRetirement ?
        Uniform( 0.0, mpSim.retirementScheme.maxCareerLength ) : nothing

    # Create the required number of persons.
    addPersonnel!( mpSim.workingDbase,
        map( ii -> "Init" * string( ii ), 1:tmpCap ) )
    addPersonnel!( mpSim.simResult,
        map( ii -> "Init" * string( ii ), 1:tmpCap ) )

    # Fill in the necessary attributes.
    for ii in 1:tmpCap
        person = mpSim.workingDbase[ ii ]
        result = mpSim.simResult[ ii ]
        person[ :status ] = :active
        result[ :history ] = Dict{Symbol, History}()
        result[ :history ][ :status ] = History( :status )

        # Generate time in system.
        timeInSystem = isRetirement ? rand( timeDist ) : 1.0

        # Compute moment of entry in system and create retirement process if
        #   necessary.
        person[ :timeEntered ] = -timeInSystem
        result[ :history ][ :status ][ person[ :timeEntered ] ] = :active

        if isRetirement
            person[ :processRetirement ] = @process retireProcess( mpSim.sim,
                person, result, mpSim )
        end  # if isRetirement
    end  # for ii in 1:tmpCap

    # Database has entries.
    mpSim.isVirgin = false
end


# This function (re)initialises the simulation.
export initialise
function initialise( mpSim::ManpowerSimulation,
    id::Union{Symbol, String} = "id" )

    setKey( mpSim, id )
    # setPhasePriority( mpSim, :recruitment, 1 )
    # setPhasePriority( mpSim, :retirement, 2 )
    # setPhasePriority( mpSim, :attrition, 3 )
    resetSimulation( mpSim )

    # The simulation is correctly initialised.
    mpSim.isInitialised = true

end  # initialise( mpSim, id, cap, recSchemes, retScheme, initPop )


# This function returns the current time of the manpower simulation.
function Dates.now( mpSim::ManpowerSimulation )

    return now( mpSim.sim )

end


# This file holds the database commit process.
include( joinpath( dirname( Base.source_path() ), "dbManagement.jl" ) )


# This function runs the manpower simulation if it has been properly
#   initialised.
# function SimJulia.run( mpSim::ManpowerSimulation, toTime::T = 0.0 ) where T <: Real
function SimJulia.run( mpSim::ManpowerSimulation )

    if !mpSim.isInitialised
        error( "Simulation not properly initialised. Cannot run." )
    end  # if !mpSim.isInitialised

    # Set up the recruitment processes.  XXX Best way?
    if mpSim.isVirgin
        # We cannot write this with a map statement. The @process macro messes
        #   that up.
        for ii in eachindex( mpSim.recruitmentSchemes )
            @process recruitProcess( mpSim.sim, ii, mpSim )
        end  # for ii in eachindex( mpSim.recruitmentSchemes )

        mpSim.isVirgin = false
    end  # if mpSim.isVirgin

    toTime = 0.0
    oldSimTime = now( mpSim )
    mpSim.attrExecTimeElapsed = Dates.Millisecond( 0 )

    # Start the database commits.
    SQLite.execute!( mpSim.simDB, "BEGIN TRANSACTION" )
    @process dbCommitProcess( mpSim.sim,
        toTime == 0.0 ? mpSim.simLength : toTime, mpSim )
    initiateTransitionProcesses( mpSim )
    @process retireProcess( mpSim.sim, mpSim )
    @process checkAttritionProcess( mpSim.sim, mpSim )
    startTime = now()

    if toTime > 0.0
        run( mpSim.sim, toTime )
    else
        run( mpSim.sim )
    end  # if toTime > 0.0

    mpSim.simTimeElapsed += now() - startTime
    println( "Attrition execution process took $(mpSim.attrExecTimeElapsed.value / 1000) seconds." )

    # Final commit.
    SQLite.execute!( mpSim.simDB, "COMMIT" )

    # Wipe the simulation reports if the simulation time has advanced.
    if oldSimTime < now( mpSim )
        empty!( mpSim.simReports )
    end  # if oldSimTime < now( mpSim )

end  # run( mpSim, toTime )


# This function runs the simulation from file.
export runSimFromFile
function runSimFromFile( fName::String )

    if !ispath( fName )
        warn( "File does not exist." )
        return
    elseif !endswith( fName, ".xlsx" )
        warn( "File is not a .xlsx file" )
        return
    end  # if !ispath( fName )

    # Initialise simulation.
    mpSim = ManpowerSimulation( fName )
    println( "Simulation initialised." )

    wb = Taro.Workbook( fName )
    s = getSheet( wb, "State Map" )

    # Make network plot if requested.
    if ( s.ptr !== Ptr{Void}( 0 ) ) && ( s[ "B", 3 ] == 1 )
        println( "Creating network plot." )
        tStart = now()
        plotTransitionMap( mpSim, s )
        tEnd = now()
        timeElapsed = (tEnd - tStart).value / 1000
        println( "Network plot time: $timeElapsed seconds." )
    end  # if ( s.ptr !=== Ptr{Void}( 0 ) ) && ...

    # Run only if flag is okay.  XXX to implement
    s = getSheet( wb, "General" )

    if s[ "B", 10 ] != 1
        println( "No simulation run requested." )
        return
    end  # if s[ "B", 10 ] != 1

    println( "Running simulation." )
    tStart = now()
    run( mpSim )
    tEnd = now()
    timeElapsed = (tEnd - tStart).value / 1000
    println( "Simulation time: $timeElapsed seconds." )

    # Generate plots.
    println( "Generating plots. This can take a while..." )
    tStart = now()
    showPlotsFromFile( mpSim, fName )
    tEnd = now()
    timeElapsed = (tEnd - tStart).value / 1000
    println( "Plot generation time: $timeElapsed seconds." )

end  # runSimFromFile( fName )


# These are the functions that process simulation results.
include( joinpath( dirname( Base.source_path() ), "simProcessing.jl" ) )


function Base.show( io::IO, mpSim::ManpowerSimulation )

    if mpSim.dbName == ""
        print( io, "Simulation database kept in memory." )
    else
        print( io, "Simulation database file: \"$(mpSim.dbName)\"" )
    end  # if mpSim.dbName == ""

    print( io, "\nSimulation name: \"$(mpSim.simName)\"" )
    print( io, "\nInitialization state: " )
    print( io, isInitialised( mpSim ) ? "OK" : "not properly initialised" )

    if mpSim.personnelTarget > 0
        print( io, "\nPersonnel cap: $(mpSim.personnelTarget)" )
    end  # if mpSim.personnelTarget > 0

    if isempty( mpSim.initAttrList )
        print( io, "\nNo initialised attributes" )
    else
        print( io, "\nInitialised attributes" )
        foreach( attr -> print( io, "\n$attr" ), mpSim.initAttrList )
    end  # if isempty( mpSim.initAttrList )

    if isempty( mpSim.otherAttrList )
        print( io, "\nNo other attributes" )
    else
        print( io, "\nOther attributes" )
        foreach( attr -> print( io, "\n$attr" ), mpSim.otherAttrList )
    end  # if isempty( mpSim.otherAttrList )

    if isempty( mpSim.initStateList )
        print( io, "\nNo initial personnel states" )
    else
        print( io, "\nInitial personnel states & transitions" )

        for state in keys( mpSim.initStateList )
            print( io, "\n$state" )

            if isempty( mpSim.initStateList[ state ] )
                print( io, "\n    No transitions from this state" )
            else
                foreach( trans -> print( io, "\n$trans" ),
                    mpSim.initStateList[ state ] )
            end  # if isempty( mpSim.initStateList[ state ] )
        end  # for state in  keys( mpSim.initStateList )
    end  # if isempty( mpSim.initStateList )

    if isempty( mpSim.otherStateList )
        print( io, "\nNo other personnel states" )
    else
        print( io, "\nOther personnel states & transitions" )

        for state in keys( mpSim.otherStateList )
            print( io, "\n$state" )

            if isempty( mpSim.otherStateList[ state ] )
                print( io, "\n    No transitions from this state" )
            else
                foreach( trans -> print( io, "\n$trans" ),
                    mpSim.otherStateList[ state ] )
            end  # if isempty( mpSim.otherStateList[ state ] )
        end  # for state in  keys( mpSim.otherStateList )
    end  # if isempty( mpSim.otherStateList )

    if !isempty( mpSim.recruitmentSchemes )
        print( io, "\nRecruitment schemes" )
        foreach( recScheme -> print( io, "\n$recScheme" ),
            mpSim.recruitmentSchemes )
    end  # if !isempty( mpSim.recruitmentSchemes )

    if isa( mpSim.defaultAttritionScheme, Attrition )
        print( io, "\nDefault attrition scheme: $(mpSim.defaultAttritionScheme)" )
    end  #if isa( mpSim.defaultAttritionScheme, Attrition )

    if isa( mpSim.retirementScheme, Retirement )
        print( io, "\nRetirement scheme: $(mpSim.retirementScheme)" )
    end  # if isa( mpSim.retirementScheme, Retirement )

    print( io, "\nSimulation length: $(mpSim.simLength)" )

    if isInitialised( mpSim )
        print( io, "\nCurrent simulation time: $(now( mpSim ))" )

        if now( mpSim ) > 0.0
            print( io, "\nSimulation run time: $(mpSim.simTimeElapsed.value / 1000) seconds" )
        end  # if now( mpSim ) > 0.0
    end  # if isInitialised( mpSim )

    print( io, "\nID key: $(string( mpSim.idKey ))" )

    print( io, "\nSimulation phase priorities: " )
    print( io, join( map( phase -> "$phase: $(mpSim.phasePriorities[ phase ])",
        keys( mpSim.phasePriorities ) ), "; " ) )

    if !isInitialised( mpSim )
        return
    end  # if !isInitialised( mpSim )

    print( io, "\nCurrent number of active personnel in database: ",
        "$(mpSim.personnelSize)" )
    print( io, "\nTotal number of personnel in simulation: ",
        "$(mpSim.resultSize)" )

end  # show( io, mpSim )
