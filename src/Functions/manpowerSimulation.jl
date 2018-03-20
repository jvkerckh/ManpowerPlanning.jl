# This file defines the functions pertaining to the ManpowerSimulation type.

# The functions of the ManpowerSimulation type require SimJulia,
#   ResumableFunctions, and Distributions.

# The functions of the ManpowerSimulation type require all types.
requiredTypes = [ "personnel", "personnelDatabase", "prerequisite",
    "prerequisiteGroup", "historyEntry", "history", "retirement", "attrition",
    "cacheEntry", "simulationCache", "manpowerSimulation" ]

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


# This function sets the cap on the number of personnel in the simulation. Note
#   that this cap can be (temporarily) violated if the initial manpower force is
#   larger than the personnel cap. If this function receives a value ⩽ 0, there
#   will not be a personnel cap.
export setPersonnelCap
function setPersonnelCap( mpSim::ManpowerSimulation, cap::T ) where T <: Integer

    mpSim.personnelCap = cap > 0 ? cap : 0

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


# This function adds a recruitment scheme to the simulation.
# This function does nothing if the simulation is already running. XXX (desirable??)
export addRecruitmentScheme!
function addRecruitmentScheme!( mpSim::ManpowerSimulation,
    recScheme::Recruitment )

    if now( mpSim ) != 0.0
        return
    end  # if now( mpSim ) != 0.0

    push!( mpSim.recruitmentSchemes, recScheme )

end  # addRecruitmentScheme!( mpSim, recScheme )


function addRecruitmentScheme!( mpSim::ManpowerSimulation, s::Taro.Sheet,
    ii::T ) where T <: Integer

    dataColNr = ii * 4 + 2
    recScheme = Recruitment( s[ dataColNr, 6 ], s[ dataColNr, 7 ] )
    setRecruitmentCap( recScheme, Int( s[ dataColNr, 8 ] ) )
    isFixedAge = s[ dataColNr, 9 ] ≈ 1.0

    # Add the age distribution.
    if isFixedAge
        setRecruitmentAge( recScheme, s[ dataColNr, 10 ] * 12 )
    else
        rowNrOfDist = numRows( s, dataColNr - 1, dataColNr - 1 )
        distType = s[ dataColNr, rowNrOfDist ] == "Pointwise" ? :disc : :pUnif
        rowNrOfDistEnd = numRows( s, dataColNr, dataColNr )

        if rowNrOfDist + 2 > rowNrOfDistEnd
            warn( "Improper recruitment age distribution. Ignoring recruitment scheme." )
            return
        end

        ageDist = Dict{Float64, Float64}()

        for jj in (rowNrOfDist + 2):rowNrOfDistEnd
            age = s[ dataColNr, jj ] * 12
            pMass = s[ dataColNr + 1, jj ]

            # Only add the entry if it makes sense.
            if isa( age, Real ) && isa( pMass, Real ) && !haskey( ageDist, age )
                ageDist[ age ] = pMass
            end  # if isa( age, Real ) && ...
        end  # for jj in (rowNrOfDist + 2):rowNrOfDistEnd

        setAgeDistribution( recScheme, ageDist, distType )
    end  # if isFixedAge

    addRecruitmentScheme!( mpSim, recScheme )

end  # function addRecruitmentScheme!( mpSim, s, ii )


# This function clears the recruitment schemes from the simulation.
# This function should NOT be called while running a simulation!
export clearRecruitmentSchemes!
function clearRecruitmentSchemes!( mpSim::ManpowerSimulation )

    empty!( mpSim.recruitmentSchemes )

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

    mpSim.attritionScheme = attrScheme

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

    if ( phase ∉ [ :recruitment, :retirement, :attrition ] ) &&
        ( phase ∉ mpSim.workingDbase.attrs )
        warn( "Unknown simulation phase, not setting priority." )
        return
    end

    mpSim.phasePriorities[ phase ] = priority

end  # setPhasePriority( mpSim, phase, priority )


export resetSimulation
function resetSimulation( mpSim::ManpowerSimulation )

    mpSim.sim = Simulation()

    # First, drop the tables with the same name if they exist.
    SQLite.drop!( mpSim.simDB, mpSim.historyDBname, ifexists = true )
    SQLite.drop!( mpSim.simDB, mpSim.personnelDBname, ifexists = true )

    # Then, create the personnel and history databases.
    # XXX Other defined attributes need to be introduced here as well.
    command = "CREATE TABLE $(mpSim.personnelDBname)(
        $(mpSim.idKey) varchar(16) NOT NULL PRIMARY KEY,
        timeEntered float,
        timeExited float,
        ageAtRecruitment float,
        expectedRetirementTime float,
        status varchar(16)
    )"
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

    mpSim.personnelSize = 0
    mpSim.resultSize = 0

    # And the cache.
    setCacheMaxTime( mpSim.simCache, 0 )

    mpSim.isVirgin = true

end  # resetSimulation( mpSim )


# This function generates a random initial population for the simulation. If the
#   cap is < 0, the initial population satisfies the cap in the simulation.
# If the simulation has already started, this will reset the simulation!
export populate
function populate( mpSim::ManpowerSimulation, cap::T = 0 ) where T <: Integer
    # Throw an error if a populate to cap is requested for a simulation without
    #   personnel cap.
    if ( cap < 0 ) && ( mpSim.personnelCap == 0 )
        error( "Simulation has no cap, cannot populate to cap." )
    end  # if ( cap < 0 ) ...

    # (Re)initialise the simulation and the population.
    resetSimulation( mpSim )

    # If the initial population is zero, stop.
    if cap == 0
        return
    end  # if cap == 0

    # Set the actual number of personnel to seed.
    tmpCap = cap < 0 ? mpSim.personnelCap : cap
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
include( "dbManagement.jl" )


# This function runs the manpower simulation if it has been properly
#   initialised.
function SimJulia.run( mpSim::ManpowerSimulation, toTime::T = 0.0 ) where T <: Real
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
    end  # if now( mpSim ) == 0.0

    oldSimTime = now( mpSim )

    # Start the database commits.
    SQLite.execute!( mpSim.simDB, "BEGIN TRANSACTION" )
    @process dbCommitProcess( mpSim.sim,
        toTime == 0.0 ? mpSim.simLength : toTime, mpSim )

    if toTime > 0.0
        run( mpSim.sim, toTime )
    else
        run( mpSim.sim )
    end  # if toTime > 0.0

    # Final commit.
    SQLite.execute!( mpSim.simDB, "COMMIT" )

    # Empty the simulation cache if the simulation time has advanced.
    if oldSimTime < now( mpSim )
        setCacheMaxTime( mpSim.simCache, min( now( mpSim ), mpSim.simLength ) )
    end
end  # run( mpSim, toTime )


# This function extracts the result database from the simulation.
export getSimResult
function getSimResult( mpSim::ManpowerSimulation )
    return mpSim.simResult
end  # getSimResult( mpSim )


# This function saves a manpower simulation to file so it can be loaded into
#   Julia at another time in the exact state it was saved.
export saveSimulation
function saveSimulation( mpSim::ManpowerSimulation,
    fileName::String = "tmpManpower.jld2" )
    tmpFileName = fileName

    if !endswith( fileName, ".jld2" )
        tmpFileName *= ".jld2"
    end  # if !endswith( fileName, ".jld2" )

    save( tmpFileName, "mpSim", mpSim )

end  # saveSimulation( mpSim, fileName )


# This function loads a manpower simulation stored in the file.
export loadSimulation
function loadSimulation( fileName::String = "tmpManpower.jld2" )
    if !endswith( fileName, ".jld2" )
        error( "File is not a Julia data archive." )
    end  # if !endswith( fileName, ".jld2" )

    if !isfile( fileName )
        error( "File does not exist." )
    end  # if !isfile( fileName )

    fileContents = open( fileName )

    if !haskey( fileContents, "mpSim" )
        error( "File does not contain a manpower simulation." )
    end  # if !haskey( fileContents, "mpSim" )

    mpSim = fileContents[ "mpSim" ]

    if !isa( mpSim, ManpowerSimulation )
        error( "File does not contain a manpower simulation." )
    end  # if !isa( mpSim, ManpowerSimulation )

    return mpSim
end  # loadSimulation( fileName )


# These are the functions that process simulation results.
include( "simProcessing.jl" )


function Base.show( io::IO, mpSim::ManpowerSimulation )

    print( io, "Simulation name: \"$(mpSim.simName)\"" )
    print( io, "\nInitialization state: " )
    print( io, isInitialised( mpSim ) ? "OK" : "not properly initialized" )

    if mpSim.personnelCap > 0
        print( io, "\nPersonnel cap: $(mpSim.personnelCap)" )
    end  # if mpSim.personnelCap > 0

    if !isempty( mpSim.recruitmentSchemes )
        print( io, "\nRecruitment schemes: $(mpSim.recruitmentSchemes)" )
    end  # if !isempty( mpSim.recruitmentSchemes )

    if isa( mpSim.attritionScheme, Attrition )
        print( io, "\nAttrition scheme: $(mpSim.attritionScheme)" )
    end  #if isa( mpSim.attritionScheme, Attrition )

    if isa( mpSim.retirementScheme, Retirement )
        print( io, "\nRetirement scheme: $(mpSim.retirementScheme)" )
    end  # if isa( mpSim.retirementScheme, Retirement )

    print( io, "\nSimulation length: $(mpSim.simLength)" )

    if isInitialised( mpSim )
        print( io, "\nCurrent simulation time: $(now( mpSim ))" )
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
