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
       setMinTime,
       setTransProbabilities,
       setMaxAttempts,
       setTimeBetweenAttempts,
       setFireAfterFail


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


"""
```
setTransProbabilities( trans::Transition,
                       probs::Vector{Float64} )
```
This function sets the execution probabilities of the state transition `trans`
to the valid entries in `probs`. Valid entries are between 0.0 and 1.0
inclusive, and invalid entries are removed. Additionally, all leading 0.0
entries will be removed as well.

This function returns `nothing`. If there are no valid probabilities, the
function will issue a warning to that effect, and won't make any changes.
"""
function setTransProbabilities( trans::Transition,
    probs::Vector{Float64} )::Void

    # Filter out all invalid probabilities.
    tmpProbs = filter( prob -> 0.0 <= prob <= 1.0, probs )
    firstNonzero = findfirst( prob -> 0.0 < prob, tmpProbs )

    # If there are no nonzero entries in the list of valid probabilities, issue
    #   a warning and don't make changes.
    if firstNonzero == 0
        warn( "No valid probabilities entered. Not making any changes to transition." )
    else
        tmpProbs = tmpProbs[ firstNonzero:end ]
        trans.probabilityList = tmpProbs
    end  # if firstNonzero == 0

    return

end  # setTransProbabilities( trans, probs )


"""
```
setMaxAttempts( trans::Transition,
                maxAttempts::T )
    where T <: Integer
```
This function sets the maximum number of times a personnel member may attempt
the transition `trans` to `maxAttempts`. Values below -1 are invalid. A value of
-1 means that there are an infinite number of attempts, and 0 means there are as
many attempts as entries in the vector of probabilities.

This function returns `nothing`. If an invalid maximum number of attempts is
entered, the function issues a warning to that effect and makes no changes to
the transition.
"""
function setMaxAttempts( trans::Transition, maxAttempts::T )::Void where T <: Integer

    if maxAttempts < -1
        warn( "Max number of attempts must be >= -1. Not making any changes." )
        return
    end  # if maxAttempts < -1

    trans.maxAttempts = maxAttempts
    return

end  # setMaxAttempts( trans, maxAttempts )


"""
```
function setTimeBetweenAttempts( trans::Transition,
                                 timeBetweenAttempts::T )
    where T <: Real
```
This function sets the time between two successive attempts at the transition
`trans` to `timeBetweenAttempts`. Values < 0.0 are invalid, and 0.0 means that
the time is the same as the schedule time of the transition.

This function returns `nothing`. If an invalid time is entered, the function
will issue a warning to that effect and makes no changes to the transition.
"""
function setTimeBetweenAttempts( trans::Transition,
    timeBetweenAttempts::T )::Void where T <: Real

    if timeBetweenAttempts < 0.0
        warn( "Time between attempts must be >= 0.0. Not making any changes." )
        return
    end  # if timeBetweenAttempts < 0.0

    trans.timeBetweenAttempts = timeBetweenAttempts
    return

end  # setTimeBetweenAttempts( trans, timeBetweenAttempts )


"""
```
setFireAfterFail( trans::Transition,
                  isFiredOnFail::Bool )
```
This function changes the isFiredOnFail flag of the transition `trans` to
`isFiredOnFail`.

This function returns `nothing`.
"""
function setFireAfterFail( trans::Transition, isFiredOnFail::Bool )::Void

    trans.isFiredOnFail = isFiredOnFail
    return

end  # setFireAfterFail( trans, isFiredOnFail )


"""
```
setMaxFlux( trans::Transition,
            maxFlux::T )
    where T <: Integer
```
This function sets the maximum flux of the transition `trans` to `maxFlux`.
Values below -1 are invalid. A value of -1 means that there is no limit on the
flux.

This function returns `nothing`. If an invalid maximum flux is entered,
the function issues a warning to that effect and makes no changes to the
transition.
"""
function setMaxFlux( trans::Transition, maxFlux::T )::Void where T <: Integer

    if maxFlux < -1
        warn( "Max flux must be >= -1. Not making any changes." )
        return
    end  # if maxFlux < -1

    trans.maxFlux = maxFlux
    return

end  # setMaxFlux( trans, maxFlux )


function Base.show( io::IO, trans::Transition )

    print( io, "    Transition $(trans.name): '$(trans.startState.name)' to '$(trans.endState.name)'" )
    print( io, "\n      Occurs with period $(trans.freq) (offset $(trans.offset))" )
    print( io, "\n      Minimum time in start state: $(trans.minTime)" )

    if !isempty( trans.extraConditions )
        print( io, "\n      Extra conditions: $(trans.extraConditions)" )
    end  # if !isempty( trans.extraConditions )

    if !isempty( trans.extraChanges )
        print( io, "\n      Extra changes: $(trans.extraChanges)" )
    end

    # XXX add extra conditions & changes

    if trans.maxAttempts == -1
        print( io, "\n      Infinite number of" )
    else
        nAttempts = trans.maxAttempts == 0 ? length( trans.probabilityList ) :
            trans.maxAttempts
        print( io, "\n      Max $nAttempts" )
    end  # if trans.maxAttempts == -1

    print( io, " attempts" )

    if trans.isFiredOnFail && ( trans.maxAttempts != -1 )
        print( io, "\n      Personnel members are fired if transition isn't succesful." )
    end  # if trans.isFiredOnFail

    if trans.maxFlux >= 0
        print( io, "\n      Max flux: $(trans.maxFlux)" )
    end  # if trans.maxFlux >= 0

    print( io, "\n      Transition execution probabilities: " )
    print( io, join( trans.probabilityList .* 100, "%, " ) * '%' )

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
        ( s[ "C", sLine + 5 ] == "years" ? 12.0 : 1.0 ) )
    numConds = Int( s[ "B", sLine + 6 ] )

    for ii in 1:numConds
        newCond, isCondOkay = processCondition( s[ "B", sLine + 6 + ii ],
            s[ "C", sLine + 6 + ii ], s[ "D", sLine + 6 + ii ] )

        if isCondOkay
            push!( newTrans.extraConditions, newCond )
        end  # if isCondOkay
    end  # for ii in 1:numConds

    sLine += numConds
    numExtra = Int( s[ "B", sLine + 7 ] )

    for ii in 1:numExtra
        newAttr = PersonnelAttribute( s[ "B", sLine + 7 + ii ],
            Dict( s[ "C", sLine + 7 + ii ] => 1.0 ), false )
        push!( newTrans.extraChanges, newAttr )
    end  # for ii in 1:numExtra

    sLine += numExtra
    setMaxAttempts( newTrans, Int( s[ "B", sLine + 8 ] ) )
    setFireAfterFail( newTrans, s[ "B", sLine + 9 ] == 1 )
    setMaxFlux( newTrans, Int( s[ "B", sLine + 10 ] ) )
    numProbs = Int( s[ "B", sLine + 11 ] )
    probs = Vector{Float64}( numProbs )

    for ii in 1:numProbs
        tmpProb = s[ "B", sLine + 11 + ii ]
        probs[ ii ] = isa( tmpProb, Real ) ? tmpProb : -1.0
    end  # for ii in 1:numProbs

    setTransProbabilities( newTrans, probs )
    return newTrans, startState, endState, sLine + 13 + numProbs

end  # readTransition( s, sLine )

#=
"""
```
initiateTransitionResets( mpSim::ManpowerSimulation )
```
This function initiates the processes that reset the flux counters for each
transition to zero at the start of each transition's cycle.

This function returns `nothing`.
"""
function initiateTransitionResets( mpSim::ManpowerSimulation )::Void

    for state in keys( mpSim.initStateList ),
        trans in mpSim.initStateList[ state ]
        @process transitionResetProcess( mpSim.sim, trans, mpSim )
    end  # for state in keys( mpSim.initStateList ), ...

    for state in keys( mpSim.otherStateList ),
        trans in mpSim.otherStateList[ state ]
        @process transitionResetProcess( mpSim.sim, trans, mpSim )
    end  # for state in keys( mpSim.otherStateList ), ...

    return

end  # initiateTransitionResets( mpSim )
=#

function initiateTransitionProcesses( mpSim::ManpowerSimulation )::Void

    for state in keys( mpSim.initStateList ),
        trans in mpSim.initStateList[ state ]
        @process transitionNewProcess( mpSim.sim, trans, mpSim )
    end  # for state in keys( mpSim.initStateList ), ...

    for state in keys( mpSim.otherStateList ),
        trans in mpSim.otherStateList[ state ]
        @process transitionNewProcess( mpSim.sim, trans, mpSim )
    end  # for state in keys( mpSim.otherStateList ), ...

    return

end  # initiateTransitionProcesses( mpSim )


@resumable function transitionNewProcess( sim::Simulation, trans::Transition,
    mpSim::ManpowerSimulation )

    # Initialize the schedule.
    timeOfCheck = now( sim ) - trans.offset
    timeOfCheck = ceil( timeOfCheck / trans.freq ) * trans.freq + trans.offset
    priority = mpSim.phasePriorities[ :transition ]
    maxAttempts = trans.maxAttempts == 0 ? length( trans.probabilityList ) :
        trans.maxAttempts
    nAttempts = Dict{String, Int}()

    while timeOfCheck <= mpSim.simLength
        @yield( timeout( sim, timeOfCheck - now( sim ), priority = priority ) )

        if trans.name == "Experienced Promotion"
            println( "Testing '$(trans.name)' at $(now( sim ))" )
        end

        timeOfCheck += trans.freq

        # Identify all persons who're in the start state long enough.
        eligibleIDs = filter( id -> trans.minTime <=
            now( sim ) - trans.startState.inStateSince[ id ],
            collect( keys( trans.startState.inStateSince ) ) )

        if ( trans.name == "Experienced Promotion" ) && !isempty( eligibleIDs )
            println( "Eligible IDs: $eligibleIDs" )
        end

        updateAttemptsAndIDs!( nAttempts, maxAttempts, eligibleIDs )
        checkedIDs = checkExtraConditions( trans, eligibleIDs, mpSim )

        if ( trans.name == "Experienced Promotion" ) && !isempty( checkedIDs )
            println( "Checked IDs: $checkedIDs" )
        end

        transIDs = determineTransitionIDs( trans, checkedIDs, nAttempts )
        executeTransitions( trans, transIDs, mpSim )
        updateStates( trans, transIDs, nAttempts, mpSim )
        firePersonnel( trans, eligibleIDs, transIDs, nAttempts, maxAttempts,
            mpSim )
    end  # while timeOfCheck <= mpSim.simLength

end  # transitionNewProcess( sim, trans, mpSim )


function updateAttemptsAndIDs!( nAttempts::Dict{String, Int}, maxAttempts::Int,
    eligibleIDs::Vector{String} )::Void

    # Clear entries of non-eligible IDs.
    for id in keys( nAttempts )
        if id ∉ eligibleIDs
            delete!( nAttempts, id )
        end  # if id ∉ eligibleIDs
    end  # for id in keys( nAttempts )

    # Update number of attempts.
    if !isempty( eligibleIDs )
        # Increase number of attempts for all eligible IDs. 0 attempts means
        #   the personnel member has already executed the transition
        #   succesfully while stil being eligible for it.
        for id in eligibleIDs
            if haskey( nAttempts, id ) && ( ( maxAttempts == -1 ) ||
                ( nAttempts[ id ] <= maxAttempts ) ) && ( nAttempts[ id ] > 0 )
                nAttempts[ id ] += 1
            else
                nAttempts[ id ] = 1
            end  # if haskey( nAttempts, id ) && ...
        end  # for id in eligibleIDs

        # Remove the ones who have more attempts than the maximum (if there
        #   is a maximum).
        filter!( id -> ( maxAttempts == -1 ) || ( ( nAttempts[ id ] > 0 ) &&
            ( nAttempts[ id ] <= maxAttempts ) ), eligibleIDs )
    end  # if !isempty( eligibleIDs )

    return

end  # updateAttemptsAndIDs!( nAttempts, eligibleIDs )


function checkExtraConditions( trans::Transition, eligibleIDs::Vector{String},
    mpSim::ManpowerSimulation )::Vector{String}

    checkedIDs = eligibleIDs

    if !isempty( eligibleIDs ) && !isempty( trans.extraConditions )
        queryCmd = "SELECT *, ageAtRecruitment + $(now( mpSim )) - timeEntered age
            FROM $(mpSim.personnelDBname)
            WHERE $(mpSim.idKey) IN ('$(join( eligibleIDs, "', '" ))')"
        eligibleIDsState = SQLite.query( mpSim.simDB, queryCmd )
        isIDokay = isa.( eligibleIDs, String )

        for cond in trans.extraConditions
            attr = Symbol( lowercase( cond.attr ) == "age" ? "age" : cond.attr )
            isIDokay = isIDokay .& map( ii -> cond.rel(
                eligibleIDsState[ attr ][ ii ], cond.val ), eachindex( isIDokay ) )
        end  # for cond in trans.extraConditions

        checkedIDs = eligibleIDsState[ Symbol( mpSim.idKey ) ][ isIDokay ]
    end  # if !isempty( eligibleIDs )

    return checkedIDs
end  # checkExtraConditions( trans, eligibleIDs, mpSim )


function determineTransitionIDs( trans::Transition, eligibleIDs::Vector{String},
    nAttempts::Dict{String, Int} )::Vector{String}

    transIDs = eligibleIDs

    if !isempty( eligibleIDs )
        # Determine who undergoes transition.
        nEligible = length( eligibleIDs )
        transRolls = rand( nEligible )
        transIDs = eligibleIDs[ map( ii -> transRolls[ ii ] <
            trans.probabilityList[ min( length( trans.probabilityList ),
            nAttempts[ eligibleIDs[ ii ] ] ) ], 1:nEligible ) ]
            # The n-th probability in the list where n is the lesser of the
            #   size of the probability list and the number of attempts by
            #   the ii-th eligible person.

        # Take only trans.maxFlux random IDs if the number of eligible IDs
        #   exceeds this.
        if ( trans.maxFlux != -1 ) && ( length( transIDs ) > trans.maxFlux )
            transIDs = transIDs[ sortperm( rand( length( transIDs ) ) )[
                1:(trans.maxFlux) ] ]
                # Get the first trans.maxFlux entries of the permutation
                #   vector that puts the vector of random numbers in sorted
                #   order.
        end  # if ( trans.maxFlux != -1 ) && ...
    end  # if !isempty( eligibleIDs )

    return transIDs

end  # determineTransitionIDs( trans, eligibleIDs, nAttempts )


function executeTransitions( trans::Transition, transIDs::Vector{String},
    mpSim::ManpowerSimulation )

    if !isempty( transIDs )
        # Get current state of the personnel members undergoing the
        #   transition.
        queryCmd = "SELECT * FROM $(mpSim.personnelDBname)
            WHERE $(mpSim.idKey) IN ('$(join( transIDs, "', '" ))')"
        transIDsState = SQLite.query( mpSim.simDB, queryCmd )
        tmpIDs = transIDsState[ Symbol( mpSim.idKey ) ]

        # Make changes in personnel database.
        persChangesCmd = Vector{String}()
        changedAttrs = Vector{String}()
        newAttrValues = Vector{String}()

        # End state attributes.
        for attr in keys( trans.endState.requirements )
            if length( trans.endState.requirements[ attr ] ) == 1
                push!( changedAttrs, attr )
                push!( newAttrValues,
                    trans.endState.requirements[ attr ][ 1 ] )
                push!( persChangesCmd, "$attr = '$(newAttrValues[ end ])'" )
            end  # if length( trans.endState.requirements ) == 1
        end  # for attr in keys( trans.endState.requirements )

        # Extra attribute changes.
        for attr in trans.extraChanges
            push!( changedAttrs, attr.name )
            push!( newAttrValues, collect( keys( attr.values ) )[ 1 ] )
            push!( persChangesCmd, "$(attr.name) = '$(newAttrValues[ end ])'" )
        end  # for attr in trans.extraChanges

        persChangesCmd = "UPDATE $(mpSim.personnelDBname)
            SET $(join( persChangesCmd, ", " ))
            WHERE $(mpSim.idKey) IN ('$(join( tmpIDs, "', '" ))')"
        SQLite.execute!( mpSim.simDB, persChangesCmd )
        # XXX include extra attribute changes.

        # Record attribute changes in history database.
        histChangesCmd = Vector{String}()

        for ii in eachindex( changedAttrs )
            oldAttrValues = transIDsState[ Symbol( changedAttrs[ ii ] ) ]
            changedIDs = tmpIDs[ oldAttrValues .!= newAttrValues[ ii ] ]

            if !isempty( changedIDs )
                suffix = "', '$(changedAttrs[ ii ])', $(now( mpSim )), '$(newAttrValues[ ii ])')"
                push!( histChangesCmd,
                    join( "('" .* changedIDs .* suffix, ", " ) )
            end  # if !isempty( changedIDs )
        end  # for attr in changedAttrs

        if !isempty( histChangesCmd )
            histChangesCmd = "INSERT INTO $(mpSim.historyDBname)
                ($(mpSim.idKey), attribute, timeIndex, strValue) VALUES
                $(join( histChangesCmd, ", "))"
            SQLite.execute!( mpSim.simDB, histChangesCmd )
        end  # if !isempty( histChangesCmd )
    end  # if !isempty( transIDs )

end  # executeTransitions( trans, transIDs, mpSim )


function updateStates( trans::Transition, transIDs::Vector{String},
    nAttempts::Dict{String, Int}, mpSim::ManpowerSimulation )::Void

    # Check which states have been added or removed as side effect from
    #   the transition.
    if !isempty( transIDs )
        # Get current state of the personnel members undergoing the
        #   transition.
        queryCmd = "SELECT * FROM $(mpSim.personnelDBname)
            WHERE $(mpSim.idKey) IN ('$(join( transIDs, "', '" ))')"
        transIDsState = SQLite.query( mpSim.simDB, queryCmd )

        isStartRetained = Vector{Bool}()
        isEndReached = Vector{Bool}()
        stateUpdates = Vector{String}()

        for state in keys( merge( mpSim.initStateList,
            mpSim.otherStateList ) )
            personsInState = transIDsState[ Symbol( mpSim.idKey ) ]

            # Check which IDs are in the state.
            if !isempty( state.requirements )
                personsInState = personsInState[ map( ii -> all( attr ->
                    transIDsState[ Symbol( attr ) ][ ii ] ∈
                        state.requirements[ attr ],
                    keys( state.requirements ) ),
                    eachindex( personsInState ) ) ]
            end  # if !isempty( state.requirements )

            # If the personnel member is in the start or the end state of
            #   the transition, make a note.
            if state === trans.startState
                isStartRetained = map( id -> id ∈ personsInState, transIDs )
            elseif state === trans.endState
                isEndReached = map( id -> id ∈ personsInState, transIDs )
            # For the other states, note the changes.
            else
                newIDsInState = filter( id -> ( id ∈ personsInState ) &&
                    !haskey( state.inStateSince, id ), transIDs )
                droppedIDs = filter( id -> ( id ∉ personsInState ) &&
                    haskey( state.inStateSince, id ), transIDs )

                # For newly achieved states, add an entry that the state is
                #   reached form an unknown state.
                if !isempty( newIDsInState )
                    suffix = "', $(now( mpSim )), '$(trans.name)', 'unknown', '$(state.name)')"
                    push!( stateUpdates, join( "('" .* newIDsInState .*
                        suffix, ", " ) )

                    for id in newIDsInState
                        state.inStateSince[ id ] = now( mpSim )
                    end  # for id in newIDsInState
                end  # if !isempty( newIDsInState )

                # For dropped states, add an entry that the state
                #   transitions to an known state.
                if !isempty( droppedIDs )
                    suffix = "', $(now( mpSim )), '$(trans.name)', '$(state.name)', 'unknown')"
                    push!( stateUpdates, join( "('" .* droppedIDs .* suffix,
                        ", " ) )

                    for id in droppedIDs
                        delete!( state.inStateSince, id )
                    end  # for id in droppedIDs
                end  # if !isempty( droppedIDs )
            end  # if state === trans.startState
        end  # for state in keys( merge( ...

        # Add transition entries for start and end states.
        for jj in eachindex( transIDs )
            pid = transIDs[ jj ]

            if isEndReached[ jj ]
                push!( stateUpdates, "('$pid', $(now( mpSim )), '$(trans.name)', '$(trans.startState.name)', '$(trans.endState.name)')" )
                trans.endState.inStateSince[ pid ] = now( mpSim )

                if isStartRetained[ jj ]
                    push!( stateUpdates, "('$pid', $(now( mpSim )), '$(trans.name)', 'nuknown', '$(trans.endState.name)')" )
                end
            elseif !isStartRetained[ jj ]
                push!( stateUpdates, "('$pid', $(now( mpSim )), '$(trans.name)', '$(trans.startState.name)', 'unknown')" )
            end  # if isEndReached[ jj ]

            if !isStartRetained[ jj ]
                delete!( trans.startState.inStateSince, pid )
            end  # if !isStartRetained[ jj ]

            # Retain success of transition and note ineligibility of
            #   personnel member to undergo it again even if they stay in
            #   the required start state.
            nAttempts[ pid ] = 0
        end  # for jj in eachindex( transIDs )

        transChangesCmd = "INSERT INTO $(mpSim.transitionDBname)
            ($(mpSim.idKey), timeIndex, transition, startState, endState) VALUES
            $(join( stateUpdates, ", " ))"
        SQLite.execute!( mpSim.simDB, transChangesCmd )
    end  # if !isempty( transIDs )

    return

end  # function updateStates( trans, transIDs, nAttempts, mpSim )


function firePersonnel( trans::Transition, eligibleIDs::Vector{String},
    transIDs::Vector{String}, nAttempts::Dict{String, Int}, maxAttempts::Int,
    mpSim::ManpowerSimulation )::Void

    # Fire the personnel members who haven't succesfully made the transition
    #   after the maximum number of attempts.
    if trans.isFiredOnFail && ( maxAttempts >= 0 ) && !isempty( eligibleIDs )
        fireIDs = filter( id -> ( nAttempts[ id ] == maxAttempts ) &&
            ( id ∉ transIDs ), eligibleIDs )
        if !isempty( fireIDs )
            foreach( id -> delete!( nAttempts, id ), fireIDs )
            retirePersons( mpSim, fireIDs, "fired" )
        end  # if !isempty( fireIDs )
    end  # if maxAttempts >= 0

    return

end  # firePersonnel( trans, eligibleIDs, transIDs, nAttempts, maxAttempts,
     #   mpSim )

#=
@resumable function transitionResetProcess( sim::Simulation, trans::Transition,
    mpSim::ManpowerSimulation )

    # Get the first time the reset must happen.
    timeOfCheck = now( sim ) - trans.offset
    timeOfCheck = ceil( timeOfCheck / trans.freq ) * trans.freq + trans.offset
    priority = mpSim.phasePriorities[ :transition ] + Int8( 1 )

    while timeOfCheck <= mpSim.simLength
        @yield( timeout( sim, timeOfCheck - now( sim ), priority = priority ) )
        trans.currentFlux = 0
        timeOfCheck += trans.freq
    end  # while timeOfCheck <= simLength

end  # transitionResetProcess( sim, trans )


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
    @yield( timeout( sim, timeOfCheck - now( sim ), priority = priority ) )

    # Check if personnel member is active and still satisfies the state.
    tmpMaxAttempts = trans.maxAttempts <= 0 ? length( trans.probabilityList ) :
        trans.maxAttempts
    tmpTime = trans.timeBetweenAttempts == 0.0 ? 1.0 :
        ceil( trans.timeBetweenAttempts / trans.freq )
    tmpTime *= trans.freq
    nAttempts = 1
    startStateReqs = trans.startState.requirements
    queryCmd = "SELECT * FROM $(mpSim.personnelDBname)
        WHERE ( status NOT IN ( '$(join( retirementReasons, "', '" ))' ) )
            AND ( $(mpSim.idKey) IS '$id' )"

    for attr in keys( startStateReqs )
        queryCmd *= " AND ( $attr IN ('" *
            join( startStateReqs[ attr ], "', '" ) * "') )"
    end  # for req in keys( startStateReqs )

    isFirst = true
    isFired = false
    isTransitionOkay = false
    nIDs = 1  # nIDs indicates if person satisfies requirements or not
              #   (Yes = 1).

    while ( nIDs == 1 ) && !isTransitionOkay &&
        ( ( now( sim ) < mpSim.simLength ) || isFirst ) &&
        ( nAttempts <= tmpMaxAttempts )
        # Wait the required time until the next attempt.
        if !isFirst
            @yield( timeout( sim, tmpTime, priority = priority ) )
        end  # if nAttempts > 1

        isFirst = false

        # Retrieve the list of all personnel members with the given id
        #   satisfying the requirements. This means that if the list is empty,
        #   the personnel member no longer satisfies the state requirements.
        persons = SQLite.query( mpSim.simDB, queryCmd )
        nIDs, nAttrs = size( persons )

        # Attempt to perform transition only if the personnel member is still
        #   eligible.
        if nIDs == 1
            person = Dict{String,Any}()

            for ii in 1:nAttrs
                person[ String( names( persons )[ ii ] ) ] = persons[ ii ][ 1 ]
            end  # for ii in 1:nAttrs

            isTransitionOkay = executeTransition( trans, nAttempts, id, person,
                mpSim )
        end  # nIDs == 1

        # Go to the next attempt if no transition took place assuming the
        #   personnel member is still in the start state.
        if !isTransitionOkay && ( nIDs == 1 )
            # Only increase number of attempts if the max number of attempts is
            #   not infinitie, or the number of attempts isn't equal to the max
            #   number.
            if ( trans.maxAttempts >= 0 ) || ( nAttempts != tmpMaxAttempts )
                nAttempts += 1
            end  # if ( trans.maxAttempts >= 0 ) || ...
        end  # if !isTransitionOkay && ...
    end  # while ( nIDs == 1 ) && ...

    # If the transition is fire-on-fail, if the person has exhausted their
    #   attempts, and if they are still eligible, fire the person.
    if trans.isFiredOnFail && ( nAttempts > tmpMaxAttempts ) && ( nIDs == 1 )
        retirePerson( mpSim, id, "fired" )
    end  # if trans.isFiredOnFail && ...

end  # transitionProcess( sim, trans, id, mpSim )


"""
```
executeTransition( trans::Transition,
                   nAttempts::Int,
                   id::String,
                   person::Dict{String, Any},
                   mpSim::ManpowerSimulation )
```
This function executes the transition `trans`, attempt `nAttempts`, for the
person with ID `id` and attributes contained in `person` in the manpower
simulation `mpSim`.

This function returns a `Bool`, which indicates if the transition was succesful
or not.
"""
function executeTransition( trans::Transition, nAttempts::Int, id::String,
    person::Dict{String, Any}, mpSim::ManpowerSimulation )::Bool

    # Don't perform checks if the maximum flux for this transition period is
    #   already reached.
    if trans.currentFlux == trans.maxFlux
        return false
    end

    tmpAttempt = min( nAttempts, length( trans.probabilityList ) )

    # Check if the person undergoes the transition.
    if rand() > trans.probabilityList[ tmpAttempt ]
        return false
    end

    trans.currentFlux += 1

    # Make the changes from one state to the other.
    tmpPerson = person
    endStateReqs = trans.endState.requirements
    changes = Dict{String, String}()

    for attr in keys( endStateReqs )
        if length( endStateReqs[ attr ] ) == 1
            changes[ attr ] = endStateReqs[ attr ][ 1 ]
        end  # if length( endStateReqs[ attr ] ) == 1
    end  # for attr in keys( endStateReqs )

    changedAttrs = collect( keys( changes ) )
    # We only need to perform the changes for the attributes that need changing.
    filter!( attr -> tmpPerson[ attr ] != changes[ attr ], changedAttrs )

    # Only run the code to make changes if there are actual changes in attribute
    #   values.
    if !isempty( changedAttrs )
        persCommand = Vector{String}( length( changedAttrs ) )
        histCommand = Vector{String}( length( changedAttrs ) )

        for ii in eachindex( changedAttrs )
            attr = changedAttrs[ ii ]
            tmpPerson[ attr ] = changes[ attr ]
            persCommand[ ii ] = "$attr = '$(changes[ attr ])'"
            histCommand[ ii ] = "( '$id', '$attr', $(now( mpSim )), '$(changes[ attr ])' )"
        end  # for ii in eachindex( changedAttrs )

        persCommand = "UPDATE $(mpSim.personnelDBname) SET " *
            join( persCommand, ", " ) * " WHERE $(mpSim.idKey) IS '$id'"
        histCommand = "INSERT INTO $(mpSim.historyDBname)
            ($(mpSim.idKey), attribute, timeIndex, strValue) VALUES " *
            join( histCommand, ", " )
        SQLite.execute!( mpSim.simDB, persCommand )
        SQLite.execute!( mpSim.simDB, histCommand )
    end  # if !isempty( changedattrs )

    oldStateList = split( tmpPerson[ "states" ], "," )

    # Only set up new transitions if the end state is different from the start
    #   state.
    if trans.startState.name != trans.endState.name
        transCommand = "INSERT INTO $(mpSim.transitionDBname)
            ($(mpSim.idKey), timeIndex, transition, startState, endState) VALUES
            ('$id', $(now( mpSim )), '$(trans.name)', '$(trans.startState.name)', '$(trans.endState.name)')"
        SQLite.execute!( mpSim.simDB, transCommand )
        oldStateIndex = findfirst( oldStateList .== trans.startState.name )
        oldStateList[ oldStateIndex ] = trans.endState.name

        # Add inStateSince entry to target state for this ID.
        trans.endState.inStateSince[ id ] = now( mpSim )

        # Set up the new transitions from the end state.
        newTransList = nothing

        if trans.endState.isInitial
            newTransList = mpSim.initStateList[ trans.endState ]
        else
            newTransList = mpSim.otherStateList[ trans.endState ]
        end  # if trans.endState.isInitial

        for newTrans in newTransList
            @process transitionProcess( mpSim.sim, newTrans, id, mpSim )
        end  # for newTrans in newTransList
    end  # if trans.startState.name != trans.endState.name

    # Find all the states the personnel member is in after the transition.
    newStateList = Vector{String}()

    for state in keys( merge( mpSim.initStateList, mpSim.otherStateList ) )
        if isPersonnelOfState( tmpPerson, state )
            push!( newStateList, state.name )
        end  # if isPersonnelOfState( tmpPerson, state )
    end  # for state in ...

    # Update the personnel database to all the new states of the personnel
    #   member.
    persCommand = "UPDATE $(mpSim.personnelDBname)
        SET states = '$(join( newStateList, "," ))'
        WHERE $(mpSim.idKey) IS '$id'"
    SQLite.execute!( mpSim.simDB, persCommand )

    # Detect and log side effects from this transition.
    extraTrans = Vector{String}()

    # Dropped states have to be mentioned in the transaction database as
    #   transitions to "unknown".
    for state in filter( tmpState -> tmpState ∉ newStateList, oldStateList )
        push!( extraTrans, "('$id', $(now( mpSim )), '$(trans.name)', '$state', 'unknown')" )
    end  # for state in filter( ...

    # Remove ID from inStateSince if the person has left the start state of the
    #   transition.
    if trans.startState.name ∉ newStateList
        delete!( trans.startState.inStateSince, id )
    end  # if trans.startState.name ∉ newStateList

    # New states have to be mentioned in the transaction database as
    #   transitions from "unknown".
    for state in filter( tmpState -> tmpState ∉ oldStateList, newStateList )
        push!( extraTrans, "('$id', $(now( mpSim )), '$(trans.name)', 'unknown', '$state')" )

        # Do not add inStateSince entry if the person is still in the start
        #   state of the transition.
        if state != trans.startState
        end  # if state != trans.startState
    end  # for state in filter( ...

    if !isempty( extraTrans )
        transCommand = "INSERT INTO $(mpSim.transitionDBname)
            ($(mpSim.idKey), timeIndex, transition, startState, endState) VALUES
            $(join( extraTrans, ", "))"
        SQLite.execute!( mpSim.simDB, transCommand )
    end  # if !isempty( extraTrans )

    return true

end  # executeTransition( trans, id, person, mpSim )
=#
