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


export setRetirementCondFlag


# This function sets the period length and the offset of the retirement
#   schedule.
export setRetirementSchedule
function setRetirementSchedule( retScheme::Retirement, freq::T1, offset::T2 ) where T1 <: Real where T2 <: Real

    if freq <= 0.0
        warn( "Retirement cycle length must be > 0.0. Not making changes to the retirement scheme." )
        return
    end  # if freq < 0.0

    retScheme.retireFreq = freq
    retScheme.retireOffset =  offset % freq + ( offset < 0.0 ? freq : 0.0 )

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


"""
```
setRetirementCondFlag( retScheme::Retirement,
                       isEither::Bool )
```
This function sets the flag controlling whether one or both of the conditions
need to be satisfied for retirement scheme `retScheme` to `isEither`, where a
value of `true` stands for one of the conditions.

This function returns `nothing`.
"""
function setRetirementCondFlag( retScheme::Retirement, isEither::Bool )::Void

    retScheme.isEither = isEither
    return

end  # setRetirementCondFlag( retScheme, iseither )


"""
```
setRetirementCondFlag( mpSim::ManpowerSimulation,
                       isEither::Bool )
```
This function sets the flag controlling whether one or both of the conditions
need to be satisfied for the default retirement scheme in the manpower
simulation `mpSim` to `isEither`, where a value of `true` stands for one of the
conditions. If no default retirement scheme is defined, this function does
nothing.

This function returns `nothing`.
"""
function setRetirementCondFlag( mpSim::ManpowerSimulation, isEither::Bool )::Void

    if !isa( mpSim.retirementScheme, Void )
        setRetireCondFlag( mpSim.retirementScheme, isEither )
    end  # if !isa( mpSim.retirementScheme, Void )

    return

end  # setRetirementCondFlag( retScheme, iseither )


function retirePerson( mpSim::ManpowerSimulation, id::String, reason::String )

    if !in( reason, retirementReasons )
        error( "$reason -- unknown retirement reason." )
    end  # if !in( reason, retirementReasons )

    mpSim.personnelSize -= 1
    personInStates = [ "active" ]

    for state in keys( merge( mpSim.initStateList, mpSim.otherStateList ) )
        if haskey( state.inStateSince, id )
            push!( personInStates, state.name )
        end  # if haskey( state.inStateSince, id )

        delete!( state.inStateSince, id )
        delete!( state.isLockedForTransition, id )
    end  # for id in keys( merge( ...

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
    retEvents = "('$id', $(now( mpSim )), '$reason', '" .*
        personInStates .* "')"
    command = "INSERT INTO $(mpSim.transitionDBname)
        ($(mpSim.idKey), timeIndex, transition, startState) VALUES
        $(join( retEvents, ", " ))"
    SQLite.execute!( mpSim.simDB, command )

end  # retirePerson( mpSim, id, reason )


function retirePersons( mpSim::ManpowerSimulation, ids::Vector{String},
    reason::String )

    if !in( reason, retirementReasons )
        error( "$reason -- unknown retirement reason." )
    end  # if !in( reason, retirementReasons )

    mpSim.personnelSize -= length( ids )
    idsInStates = ids
    personInStates = fill( "active", length( ids ) )

    for state in keys( merge( mpSim.initStateList, mpSim.otherStateList ) ),
        id in ids
        if haskey( state.inStateSince, id )
            push!( idsInStates, id )
            push!( personInStates, state.name )
        end  # if haskey( state.inStateSince, id )

        delete!( state.inStateSince, id )
        delete!( state.isLockedForTransition, id )
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
        $(join( command, ", " ))"
    SQLite.execute!( mpSim.simDB, command )

    # Add the person's retirement event to the transition database.
    command = "('" .* idsInStates .* "', $(now( mpSim )), '$reason', '" .*
        personInStates .* "')"
    command = "INSERT INTO $(mpSim.transitionDBname)
        ($(mpSim.idKey), timeIndex, transition, startState) VALUES
        $(join( command, ", " ))"
    SQLite.execute!( mpSim.simDB, command )

end  # function retirePersons( mpSim, ids, reason )


# This function computes the person's expected retirement time and returns it.
export computeExpectedRetirementTime
function computeExpectedRetirementTime( mpSim::ManpowerSimulation,
    retScheme::Retirement, ageAtRecruitment::T1, timeEntered::T2 ) where T1 <: Real where T2 <: Real

    # No need to continue processing if there's no retirement scheme.
    if retScheme === nothing
        return +Inf
    end  # if retScheme === nothing

    # Compute how long the person is in the system already. Usually 0.0.
    timeInSystem = now( mpSim ) - timeEntered

    # Compute the time left until retirement.
    timeToRetireAge = retScheme.retireAge > 0.0 ? retScheme.retireAge -
        ageAtRecruitment - timeInSystem : +Inf
    timeToCareerEnd = retScheme.maxCareerLength > 0.0 ?
        retScheme.maxCareerLength - timeInSystem : +Inf
    timeToRetire = min( timeToRetireAge, timeToCareerEnd )

    if !retScheme.isEither && ( timeToRetireAge < +Inf ) &&
        ( timeToCareerEnd < +Inf )
        timeToRetire = max( timeToRetireAge, timeToCareerEnd )
    end  # if !retScheme.isEither && ...

    timeOfRetirement = now( mpSim ) + timeToRetire
    return timeOfRetirement == +Inf ? "NULL" : timeOfRetirement

end  # computeExpectedRetirementTime( mpSim, ageAtRecruitment, timeEntered )


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


function Base.show( io::IO, retScheme::Retirement )

    if ( retScheme.maxCareerLength == 0.0 ) && ( retScheme.retireAge == 0.0 )
        print( io, "No retirement scheme." )
        return
    end   # if ( retScheme.maxCareerLength == 0.0 ) && ...

    out = "      Retirement schedule period: $(retScheme.retireFreq)"
    out *= " (+ $(retScheme.retireOffset))"

    if retScheme.maxCareerLength > 0.0
        out *= "\n      Max career length: $(retScheme.maxCareerLength)"
    end  # if retScheme.maxCareerLength > 0

    if retScheme.retireAge > 0.0
        out *= "\n      Retirement age: $(retScheme.retireAge)"
    end  # if retScheme.maxCareerLength > 0

    if retScheme.maxCareerLength * retScheme.retireAge > 0.0
        out *= "\n      " * ( retScheme.isEither ? "Either" : "Both" )
        out *= " condition" * ( retScheme.isEither ? "" : "s" )
        out *= " must be satisfied for retirement."
    end  # if retScheme.maxCareerLength * retScheme.retireAge > 0.0

    print( io, out )

end  # Base.show( io, retScheme )
