# This file holds the definition of the functions pertaining to the
#   Transition type.

# The functions of the Transition type require the State type.
requiredTypes = [ "state", "transition" ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( dirname( Base.source_path() ), "..", "Types",
            reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end  # for reqType in requiredTypes


export setName,
        setState,
       setSchedule,
       setMinTime


"""
```
setName( trans::Transition,
         name::String )
```
This function sets the name of the transition `trans` to `name`.

This function returns `nothing`.
"""
function setName( trans::Transition, name::String )::Void

    trans.name = name
    return

end  # setName( trans, name )

"""
```
setState( trans::Transition,
          state::State,
          isEndState::Bool = false )
```
This function sets one of the states (start/end) of the transition `trans` to
`state`. If `isEndState` is `true`, the end state will be set, otherwise the
start state will be set.

This function returns `nothing`.
"""
function setState( trans::Transition, state::State,
    isEndState::Bool = false )::Void

    if isEndState
        trans.endState = state
    else
        trans.startState = state
    end  # if isEndState

    return

end  # setState( trans, state, isEndState )


"""
```
setSchedule( trans::Transition,
             freq::T1,
             offset::T2 = 0.0 )
```
This function sets the schedule of the transition `trans`. This transition will
be checked every `freq` time units with an offset of `offset` with respect to
the start of the simulation.

This function returns `nothing`. If the entered period is ⩽ 0.0, the function
will issue a warning and not change the schedule.
"""
function setSchedule( trans::Transition, freq::T1, offset::T2 = 0.0 )::Void where T1 <: Real where T2 <: Real

    if freq <= 0.0
        warn( "Time between two transition checks must be > 0.0" )
        return
    end  # if freq <= 0.0

    trans.freq = freq
    trans.offset = offset % freq + ( offset < 0.0 ? freq : 0.0 )
    return

end  # setSchedule( trans, freq, offset )


"""
```
setMinTime( trans::Transition,
            minTime::T )
```
This function sets the minimum time a personnel member has to be in the start
state of transition `trans` to `minTime`, before he can make that transition.

This function returns `nothing`. If the minimum time is ⩽ 0.0, the function will
issue a warning and not change the schedule.
"""
function setMinTime( trans::Transition, minTime::T )::Void where T <: Real

    if minTime <= 0.0
        warn( "Time that personnel member must have initial state must be > 0.0" )
        return
    end  # if minTime <= 0.0

    trans.minTime = minTime
    return

end  # setMinTime( trans, minTime )


function Base.show( io::IO, trans::Transition )

    print( io, "    Transition '$(trans.startState.name)' to '$(trans.endState.name)'" )
    print( io, "\n      Occurs with period $(trans.freq) (offset $(trans.offset))" )
    print( io, "\n      Minimum time in start state: $(trans.minTime)" )

end  # Base.show( io, trans )


# ==============================================================================
# Non-exported methods.
# ==============================================================================


function readTransition( s::Taro.Sheet, sLine::T ) where T <: Integer

    startState = s[ "B", sLine + 1 ]
    endState = s[ "B", sLine + 2 ]
    dummyState = State( "Dummy" )
    newTrans = Transition( s[ "B", sLine ], dummyState, dummyState )
    setSchedule( newTrans, s[ "B", sLine + 3 ], s[ "B", sLine + 4 ] )
    setMinTime( newTrans, s[ "B", sLine + 5 ] *
        ( s[ "C", sLine + 4 ] == "years" ? 1.0 : 12.0 ) )

    return newTrans, startState, endState, sLine + 7

end  # readTransition( s, sLine )


@resumable function transitionProcess( sim::Simulation,
    trans::Transition, id::String, mpSim::ManpowerSimulation )

    timeOfCheck = now( sim ) + trans.minTime

    # Adjust check time to schedule
    timeOfCheck -= trans.offset
    timeOfCheck = ceil( timeOfCheck / trans.freq ) * trans.freq + trans.offset

    priority = mpSim.phasePriorities[ :transition ]

    # No need to do anything if the transition would occur past the sim
    #   length.
    if timeOfCheck > mpSim.simLength
        return
    end  # if timeOfCheck > mpSim.simLength

    # Wait required time.
    @yield( timeout( sim,timeOfCheck - now( sim ), priority = priority ) )

    # Check if personnel member is active and still satisfies the state.
    startStateReqs = trans.startState.requirements
    queryCmd = "SELECT $(mpSim.idKey) FROM $(mpSim.personnelDBname)
        WHERE ( status NOT IN ( 'retired', 'resigned' ) )
            AND ( $(mpSim.idKey) IS '$id' )"

    for attr in keys( startStateReqs )
        queryCmd *= " AND ( $attr IN ('" *
            join( startStateReqs[ attr ], "', '" ) * "') )"
    end  # for req in keys( startStateReqs )

    ids = SQLite.query( mpSim.simDB, queryCmd )[ Symbol( mpSim.idKey ) ]

    # Perform transition only if the personnel member is still eligible.
    if length( ids ) == 1
        endStateReqs = trans.endState.requirements
        changes = Dict{String, String}()

        for attr in keys( endStateReqs )
            if length( endStateReqs[ attr ] ) == 1
                changes[ attr ] = endStateReqs[ attr ][ 1 ]
            end  # if length( endStateReqs[ attr ] ) == 1
        end  # for attr in keys( endStateReqs )

        changedAttrs = collect( keys( changes ) )
        persCommand = Vector{String}( length( changedAttrs ) )
        histCommand = Vector{String}( length( changedAttrs ) )

        for ii in eachindex( changedAttrs )
            attr = changedAttrs[ ii ]
            persCommand[ ii ] = "$attr = '$(changes[ attr ])'"
            histCommand[ ii ] = "( '$id', '$attr', $(now( sim )), '$(changes[ attr ])' )"
        end  # for ii in eachindex( changedAttrs )

        persCommand = "UPDATE $(mpSim.personnelDBname) SET " *
            join( persCommand, ", " ) * " WHERE $(mpSim.idKey) IS '$id'"
        histCommand = "INSERT INTO $(mpSim.historyDBname)
            ($(mpSim.idKey), attribute, timeIndex, strValue) VALUES " *
            join( histCommand, ", " )
        transCommand = "INSERT INTO $(mpSim.transitionDBname)
            ($(mpSim.idKey), timeIndex, transition, startState, endState) VALUES
            ('$id', $(now( sim )), '$(trans.name)', '$(trans.startState.name)', '$(trans.endState.name)')"
        SQLite.execute!( mpSim.simDB, persCommand )
        SQLite.execute!( mpSim.simDB, histCommand )
        SQLite.execute!( mpSim.simDB, transCommand )
    end  # if length( ids ) == 1

    # Set up the new transitions from the end state.
    newTransList = nothing

    if trans.endState.isInitial
        newTransList = mpSim.initStateList[ trans.endState ]
    else
        newTransList = mpSim.otherStateList[ trans.endState ]
    end  # if trans.endState.isInitial

    for newTrans in newTransList
        @process transitionProcess( sim, newTrans, id, mpSim )
    end  # for newTrans in newTransList

end
