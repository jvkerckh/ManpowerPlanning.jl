# This file covers everything related to retirement.

# The functions of the Retirement type require SimJulia and ResumableFunctions.

# The functions of the Retirement type require the Personnel, PersonnelDatabase,
#   and ManpowerSimulation types.
requiredTypes = [ "manpowerSimulation",
    "retirement" ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( dirname( Base.source_path() ), "..", "Types",
            reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end  # for reqType in requiredTypes


if !isdefined( :retirementReasons )
    const retirementReasons = [ "retired", "resigned", "fired" ]
end # if !isdefined( :retirementReasons )


#=
# This function retires the personnel member for the given reason (:retired,
#   :resigned, :fired).
export retire
function retire( person::Personnel, reason::Symbol )
    if in( reason, retirementReasons )
        person[ :status ] = reason
        return true
    end  # if in( reason, retirementReasons )

    return false
end  # retire( person, reason )

function retire( person::Personnel, reason::Symbol, sim::Simulation )
    if retire( person, reason )
        person[ :retireTime ] = now( sim )  # XXX to check if this is correct.
        # XXX Also, make sure to include Ben's routines
    end
end


# This function retires the person with the given id in the database.
function retire( dbase::PersonnelDatabase, index::DbIndexType, reason::Symbol )
    retire( dbase[ index ], reason )
end  # retire( dbase, index, reason )

function retire( dbase::PersonnelDatabase, index::DbIndexType, reason::Symbol,
    sim::Simulation )
    retire( dbase[ index ], reason, sim )
end  # retire( dbase, index, reason, sim )
=#


# This function sets the period length and the offset of the retirement
#   schedule.
export setRetirementSchedule
function setRetirementSchedule( retScheme::Retirement, freq::T1, offset::T2 ) where T1 <: Real where T2 <: Real

    if freq < 0.0
        warn( "Retirement cycle length must be ⩾ 0.0. Not making changes to the retirement scheme." )
        return
    end  # if freq < 0.0

    retScheme.retireFreq = freq
    retScheme.retireOffset = freq > 0.0 ?
        ( offset % freq + ( offset < 0.0 ? freq : 0.0 ) ) : 0.0

end  # setRetirementSchedule( retScheme, freq, offset )


# XXX the functions below need updating to properly handle changes in retirement
#   parameters.

# This function sets the maximal career length of the retirement scheme.
export setCareerLength
function setCareerLength( retScheme::Retirement, maxCareer::T ) where T <: Real

    if maxCareer < 0.0
        error( "Maximal career length must be => 0.0." )
    end  # if maxCareer < 0.0

    retScheme.maxCareerLength = maxCareer

end  # setCareerLength( retScheme, cLength )


# This function sets the maximal careeer length in the manpower simulation.
# If the max career length is entered as 0, no returement based on tenure
#   occurs.
# If the update flag is set, the retirement processes of all personnel records
#   need to be updated to reflect the change.
function setCareerLength( mpSim::ManpowerSimulation, maxCareer::T,
    updateRetirement::Bool = false ) where T <: Real

    if maxCareer < 0.0
        error( "Maximal career length must be ⩾ 0.0." )
    end  # if maxCareer < 0.0

    oldMaxCareer = mpSim.retirementScheme === nothing ? 0.0 :
        mpSim.retirementScheme.maxCareerLength   # To change for age.

    # Don't make unnecessary changes.
    if oldMaxCareer == maxCareer
        return
    end  # if oldMaxCareer == maxCareer

    # If there is no retirement scheme, create one.
    if mpSim.retirementScheme === nothing
        mpSim.retirementScheme = Retirement( maxCareer = maxCareer )
    else
        setCareerLength( mpSim.retirementScheme, maxCareer )
    end   # if maxCareer == 0.0

    # Update personnel records if necessary.
    if updateRetirement
        # XXX
    end
    # if updateRetirement

end # setCareerLength( mpSim, maxCareer, updateRetirement )


# This function sets the mandatory retirment of the retirement scheme.
export setRetirementAge
function setRetirementAge( retScheme::Retirement, retireAge::T ) where T <: Real

    if retireAge < 0.0
        error( "Mandatory retirement age must be => 0.0." )
    end  # if retireAge < 0.0

    retScheme.retireAge = retireAge

end  # setRetirementAge( retScheme, retireAge )


function setRetirementAge( mpSim::ManpowerSimulation, retireAge::T,
    updateRetirement::Bool = false ) where T <: Real

    oldRetireAge = mpSim.retirementScheme === nothing ? 0.0 :
        mpSim.retirementScheme.retireAge   # To change for age.

    # Don't make unnecessary changes.
    if oldRetireAge == retireAge
        return
    end  # if oldRetAge == retireAge

    # If there is no retirement scheme, create one.
    if mpSim.retirementScheme === nothing
        mpSim.retirementScheme = Retirement( retireAge = retireAge )
    else
        setRetirementAge( mpSim.retirementScheme, retireAge )
    end   # if maxCareer == 0.0

    # Update personnel records if necessary.
    if updateRetirement
        # XXX
    end  # if updateRetirement

end # setRetirementAge( mpSim, retireAge, updateRetirement )


#=
function retirePerson( mpSim::ManpowerSimulation, person::Personnel,
    result::Personnel, reason::Symbol )

    if !in( reason, retirementReasons )
        error( "$reason -- unknown retirement reason." )
    end  # if !in( reason, retirementReasons )

    result[ :status, now( mpSim ) ] = reason
    id = person[ mpSim.idKey ]
    removePersonnel!( mpSim.workingDbase, id )
    # println( "Person $id has retired at $(now( mpSim ))." )

end  # retirePerson( mpSim, person, result, reason )
=#

function retirePerson( mpSim::ManpowerSimulation, id::String, reason::String )

    if !in( reason, retirementReasons )
        error( "$reason -- unknown retirement reason." )
    end  # if !in( reason, retirementReasons )

    mpSim.personnelSize -= 1
    foreach( state -> delete!( state.inStateSince, id ),
        keys( merge( mpSim.initStateList, mpSim.otherStateList ) ) )

    # Change the person's status in the personnel database.
    command = "UPDATE $(mpSim.personnelDBname)
        SET status = '$reason', timeExited = $(now( mpSim ))
        WHERE $(mpSim.idKey) = '$id'"
    SQLite.execute!( mpSim.simDB, command )

    # Add the person's status change to the history database.
    command = "INSERT INTO $(mpSim.historyDBname)
        ($(mpSim.idKey), attribute, timeIndex, strValue) VALUES
        ('$id', 'status', $(now( mpSim )), '$reason')"
    SQLite.execute!( mpSim.simDB, command )

    # Add the person's retirement event to the transition database.
    command = "INSERT INTO $(mpSim.transitionDBname)
        ($(mpSim.idKey), timeIndex, transition, startState) VALUES
        ('$id', $(now( mpSim )), '$reason', 'active')"
    SQLite.execute!( mpSim.simDB, command )

end  # retirePerson( mpSim, id, reason )


function retirePersons( mpSim::ManpowerSimulation, ids::Vector{String},
    reason::String )

    if !in( reason, retirementReasons )
        error( "$reason -- unknown retirement reason." )
    end  # if !in( reason, retirementReasons )

    mpSim.personnelSize -= length( ids )

    for state in keys( merge( mpSim.initStateList, mpSim.otherStateList ) )
        foreach( id -> delete!( state.inStateSince, id ), ids )
    end  # for state in keys( merge( ...

    # Change the person's status in the personnel database.
    command = "UPDATE $(mpSim.personnelDBname)
        SET status = '$reason', timeExited = $(now( mpSim ))
        WHERE $(mpSim.idKey) IN ('$(join( ids, "', '" ))')"
    SQLite.execute!( mpSim.simDB, command )

    # Add the person's status change to the history database.
    command = "('" .* ids .* "', 'status', $(now( mpSim )), '$reason')"
    command = "INSERT INTO $(mpSim.historyDBname)
        ($(mpSim.idKey), attribute, timeIndex, strValue) VALUES
        $(join( command, ", "))"
    SQLite.execute!( mpSim.simDB, command )

    # Add the person's retirement event to the transition database.
    command = "('" .* ids .* "', $(now( mpSim )), '$reason', 'active')"
    command = "INSERT INTO $(mpSim.transitionDBname)
        ($(mpSim.idKey), timeIndex, transition, startState) VALUES
        $(join( command, ", "))"
    SQLite.execute!( mpSim.simDB, command )

end  # function retirePersons( mpSim, ids, reason )


# This function computes the person's expected retirement time and returns it.
export computeExpectedRetirementTime
function computeExpectedRetirementTime( mpSim::ManpowerSimulation, id::String,
    ageAtRecruitment::T1, timeEntered::T2 ) where T1 <: Real where T2 <: Real

    retScheme = mpSim.retirementScheme

    # No need to continue processing if there's no retirement scheme.
    if retScheme === nothing
        return
    end  # if retScheme === nothing

    # Get the person from the database.
    # command = "SELECT timeEntered, ageAtRecruitment
    #     FROM $(mpSim.personnelDBname)
    #     WHERE $(mpSim.idKey) = '$id'"
    # person = SQLite.query( mpSim.simDB, command )

    # Compute how long the person is in the system already. Usually 0.0.
    timeInSystem = now( mpSim ) - timeEntered

    # Compute the time left until retirement.
    timeToRetireAge = retScheme.retireAge > 0.0 ? retScheme.retireAge -
        ageAtRecruitment - timeInSystem : +Inf
    timeToCareerEnd = retScheme.maxCareerLength > 0.0 ?
        retScheme.maxCareerLength - timeInSystem : +Inf
    timeToRetire = min( timeToRetireAge, timeToCareerEnd )
    timeOfRetirement = now( mpSim ) + timeToRetire

    # Adjustment to observe the retirement schedule.  XXX to remove.
    # if ( retScheme.retireFreq > 0.0 ) && ( timeToRetire < +Inf )
    #     extraTime = timeOfRetirement % retScheme.retireFreq
    #     extraTime = retScheme.retireOffset - extraTime
    #     extraTime += extraTime < 0.0 ? retScheme.retireFreq : 0.0
    #     timeToRetire += extraTime
    #     timeOfRetirement += extraTime
    # end  # if ( retScheme.retireFreq > 0.0 ) && ...
#=
    # Enter the time in the database if needed.
    if timeToRetire < +Inf
        command = "UPDATE $(mpSim.personnelDBname)
            SET expectedRetirementTime = $timeOfRetirement
            WHERE $(mpSim.idKey) = '$id'"
        SQLite.execute!( mpSim.simDB, command )
    end
=#
    return timeOfRetirement

end  # computeExpectedRetirementTime( mpSim )


# This function is the retirement process.
@resumable function retireProcess( sim::Simulation, id::String,
    timeOfRetirement::T, mpSim::ManpowerSimulation ) where T <: Real

    # Don't do anything if the retirement time occurs after the simulation's
    #   end. This will ensure that the simulation will not take any steps beyond
    #   those that are necessary.
    if timeOfRetirement > mpSim.simLength
        return
    end  # if timeOfRetirement > mpSim.simLength

    try
        @yield timeout( sim, timeOfRetirement - now( sim ),
            priority = mpSim.phasePriorities[ :retirement ] )

        # Check if the person is still in the system.
        queryCmd = "SELECT $(mpSim.idKey) FROM $(mpSim.personnelDBname)
            WHERE ( $(mpSim.idKey) IS '$id' ) AND
                status NOT IN ('resigned', 'fired')"
        result = SQLite.query( mpSim.simDB, queryCmd )

        # Retire the person only if necessary.
        if size( result ) == ( 1, 1 )
            retirePerson( mpSim, id, "retired" )
        end  # if size( result ) == ( 1, 1 )
    catch err
        if !isa( err, SimJulia.InterruptException )
            error( "Something went badly wrong: $(typeof( err )) -- $err" )
        end  # if !isa( err, InterruptException )
    end

end  # retireProcess( sim, id, timeOfRetirement, mpSim )


@resumable function retireProcess( sim::Simulation, mpSim::ManpowerSimulation )

    # Immediately terminate process if there's no retirement scheme.
    # XXX Will this be needed?
    if isa( mpSim.retirementScheme, Void )
        return
    end  # if isa( mpSim.retirementScheme, Void )

    processTime = Dates.Millisecond( 0 )
    tStart = now()

    retScheme = mpSim.retirementScheme
    timeOfNextRetirement = now( sim ) - retScheme.retireOffset
    timeOfNextRetirement = ceil( timeOfNextRetirement /
        retScheme.retireFreq ) * retScheme.retireFreq
    timeOfNextRetirement += retScheme.retireOffset
    priority = mpSim.phasePriorities[ :retirement ]
    queryCmd = "SELECT $(mpSim.idKey) FROM $(mpSim.personnelDBname)
        WHERE status NOT IN ('fired', 'resigned', 'retired')
            AND expectedRetirementTime <= "

    while timeOfNextRetirement <= mpSim.simLength
        processTime += now() - tStart
        @yield( timeout( sim, timeOfNextRetirement - now( sim ),
            priority = priority ) )
        tStart = now()

        # Find list of people who should retire now.
        idsToRetire = SQLite.query( mpSim.simDB,
            queryCmd * string( now( sim ) ) )[ Symbol( mpSim.idKey ) ]
        idsToRetire = Vector{String}( idsToRetire )

        if !isempty( idsToRetire )
            retirePersons( mpSim, idsToRetire, "retired" )
        end  # if !isempty( idsToRetire )

        timeOfNextRetirement += retScheme.retireFreq
    end  # while timeOfNextRetirement <= mpSim.simLength

    processTime += now() - tStart
    println( "Retirement process took $(processTime.value / 1000) seconds." )

end  # retireProcess( sim, mpSim )


# This function retrieves the expected retirement time from the database, and
#   starts the actual retirement process.
function retireFunction( mpsim::ManpowerSimulation, id::String )

    # Get expected time of retirement from the database.
    command = "SELECT expectedRetirementTime
        FROM $(mpSim.personnelDBname)
        WHERE $(mpSim.idKey) = '$id'"
    person = SQLite.query( mpSim.simDB, command )
    timeOfRetirement = person[ 1, :expectedRetirementTime ]
    timeOfRetirement = timeOfRetirement.hasvalue ? timeOfRetirement.value : +Inf

    return @process retireProcess( mpSim.sim, id, timeOfRetirement, mpSim )

end  # retireFunction( mpSim, id )

#=
@resumable function retireProcess( sim::Simulation, person::Personnel,
    result::Personnel, mpSim::ManpowerSimulation )

    # Don't do anything if the retirement time occurs after the simulation's
    #   end. This will ensure that the simulation will not take any steps beyond
    #   those that are necessary.
    if timeOfRetirement > mpSim.simLength
        return
    end  # if timeOfRetirement > mpSim.simLength

    try
        @yield timeout( sim, timeToRetire,
            priority = mpSim.phasePriorities[ :retirement ] )
        retirePerson( mpSim, person, result, :retired )
    catch err
        if !isa( err, SimJulia.InterruptException )
            error( "Something went badly wrong: $(typeof( err )) -- $err" )
        end  # if !isa( err, InterruptException )
    end
end  # retireProcess( sim, person, result, mpSim )
=#

function Base.show( io::IO, retScheme::Retirement )

    if ( retScheme.maxCareerLength == 0.0 ) && ( retScheme.retireAge == 0.0 )
        print( io, "No retirement scheme." )
        return
    end   # if ( retScheme.maxCareerLength == 0.0 ) && ...

    out = ""

    if retScheme.retireFreq > 0.0
        out *= "Retirement schedule period: $(retScheme.retireFreq)"
        out *= " (+ $(retScheme.retireOffset))"
    end  # if retScheme.retireFreq > 0.0

    if retScheme.maxCareerLength > 0.0
        out *= out == "" ? "" : "\n"
        out *= "Max career length: $(retScheme.maxCareerLength)"
    end  # if retScheme.maxCareerLength > 0

    if retScheme.retireAge > 0.0
        out *= out == "" ? "" : "\n"
        out *= "Retirement age: $(retScheme.retireAge)"
    end  # if retScheme.maxCareerLength > 0

    print( io, out )

end  # Base.show( io, retScheme )
