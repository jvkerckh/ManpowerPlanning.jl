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
       addCondition!,
       clearConditions!,
       addAttributeChange!,
       clearAttributeChanges!,
       setMinTime,
       setTransProbabilities,
       setMaxAttempts,
       setTimeBetweenAttempts,
       setFireAfterFail


dummyState = State( "Dummy" )

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
addCondition!( trans::Transition,
               cond::Condition )
```
This function adds the consition `cond` as extra condition to the transition
`trans`. This function does NOT check if conditions are contradictory with each
other or with the start state.

This function returns `nothing`.
"""
function addCondition!( trans::Transition, cond::Condition )::Void

    push!( trans.extraConditions, cond )
    return

end  # addCondition!( trans, cond )


"""
```
clearConditions!( trans::Transition )
```
This function clear all extra conditions from the transition `trans`.

This function returns `nothing`.
"""
function clearConditions!( trans::Transition )::Void

    empty!( trans.extraConditions )
    return

end  # clearConditions!( trans )


"""
```
addAttributeChange!( trans::Transition,
                     attr::String,
                     newVal::String )
```
This function adds an extra attribute change to the transition `trans`, ensuring
that the attribute `attr` is changed to the value `newVal`. If the transition
already changes the attribute, the change gets overwritten and the function
issues a warning.

This function returns `nothing`.
"""
function addAttributeChange!( trans::Transition, attr::String,
    newVal::String )::Void

    # XXX Logic overhaul needed?
    changeIndex = findfirst( tmpAttr -> tmpAttr.name == attr,
        trans.extraChanges )

    if changeIndex == 0
        newAttr = PersonnelAttribute( attr, Dict( newVal => 1.0 ), false )
        push!( trans.extraChanges, newAttr )
    else
        warn( "Attribute change for attribute '$attr' already recorded. Overwriting the change." )
        setAttrValues!( trans.extraChanges, Dict( newVal => 1.0 ) )
    end  # if changeIndex == 0

    return

end  # addAttributeChange!( trans, attr, newVal )


"""
```
clearAttributeChanges!( trans::Transition )
```
This function clears all attribute changes from the transition `trans`.

This function returns `nothing`.
"""
function clearAttributeChanges!( trans::Transition )::Void

    empty!( trans.extraChanges)
    return

end  # clearAttributeChanges!( trans )


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

function readTransition( sheet::XLSX.Worksheet, sLine::T ) where T <: Integer

    newTrans = Transition( sheet[ "A$sLine" ], dummyState, dummyState )
    startState, endState = sheet[ "B$sLine" ], sheet[ "C$sLine" ]
    setSchedule( newTrans, sheet[ "D$sLine" ], sheet[ "E$sLine" ] )

    # Read time related conditions.
    sCol = 7
    nTimeConds = Int( sheet[ XLSX.CellRef( sLine, sCol ) ] )

    for ii in 1:nTimeConds
        newCond, isCondOkay = processCondition(
            sheet[ XLSX.CellRef( sLine, sCol + ii ) ],
            sheet[ XLSX.CellRef( sLine + 1, sCol + ii ) ],
            sheet[ XLSX.CellRef( sLine + 2, sCol + ii ) ] )

        if isCondOkay
            addCondition!( newTrans, newCond )
        end  # if isCondOkay
    end  # for ii in 1:nTimeConds


    # Read other/attribute conditions.
    sCol += nTimeConds + 2
    nOtherConds = Int( sheet[ XLSX.CellRef( sLine, sCol ) ] )

    for ii in 1:nOtherConds
        newCond, isCondOkay = processCondition(
            sheet[ XLSX.CellRef( sLine, sCol + ii ) ],
            sheet[ XLSX.CellRef( sLine + 1, sCol + ii ) ],
            sheet[ XLSX.CellRef( sLine + 2, sCol + ii ) ] )

        if isCondOkay
            addCondition!( newTrans, newCond )
        end  # if isCondOkay
    end  # for ii in 1:nOtherConds

    # Read dynamics.
    sCol += nOtherConds + 2
    maxFlux = sheet[ XLSX.CellRef( sLine, sCol ) ]
    setMaxFlux( newTrans, isa( maxFlux, Missings.Missing ) ? -1 :
        Int( maxFlux ) )
    maxAttempts = sheet[ XLSX.CellRef( sLine, sCol + 1 ) ]
    setMaxAttempts( newTrans, isa( maxAttempts, Missings.Missing ) ? -1 :
        Int( maxAttempts ) )

    if isa( maxAttempts, Missings.Missing )
        setFireAfterFail( newTrans, false )
    else
        setFireAfterFail( newTrans,
            sheet[ XLSX.CellRef( sLine, sCol + 2 ) ] == "YES" )
    end  # if !isa( maxAttempts, Missings.Missing )

    # Read probability vector.
    sCol += 3
    nProbs = Int( sheet[ XLSX.CellRef( sLine, sCol ) ] )
    probs = Vector{Float64}( nProbs )

    for ii in 1:nProbs
        probs[ ii ] = sheet[ XLSX.CellRef( sLine, sCol + ii ) ]
    end  # for ii in 1:nProbs

    setTransProbabilities( newTrans, probs )

    # Read extra attribute changes.
    sCol += nProbs + 2
    nExtraChanges = Int( sheet[ XLSX.CellRef( sLine, sCol ) ] )

    for ii in 1:nExtraChanges
        addAttributeChange!( newTrans,
            sheet[ XLSX.CellRef( sLine, sCol + ii ) ],
            sheet[ XLSX.CellRef( sLine + 1, sCol + ii ) ] )
    end  # for ii in 1:nExtraChanges

    return newTrans, startState, endState

end  # readTransition( sheet, sLine )


function purgeRedundantExtraChanges( trans::Transition )::Void

    endStateReqs = collect( keys( trans.endState.requirements ) )
    indsToRemove = find( attr -> attr.name ∈ endStateReqs, trans.extraChanges )
    deleteat!( trans.extraChanges, indsToRemove )
    return

end  # purgeRedundantExtraChanges( trans )


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

    processTime = Dates.Millisecond( 0 )
    tStart = now()

    # Initialize the schedule.
    timeOfCheck = now( sim ) - trans.offset
    timeOfCheck = ceil( timeOfCheck / trans.freq ) * trans.freq + trans.offset
    priority = mpSim.phasePriorities[ :transition ]
    maxAttempts = trans.maxAttempts == 0 ? length( trans.probabilityList ) :
        trans.maxAttempts
    nAttempts = Dict{String, Int}()

    while timeOfCheck <= mpSim.simLength
        processTime += now() - tStart
        @yield( timeout( sim, timeOfCheck - now( sim ), priority = priority ) )
        tStart = now()
        timeOfCheck += trans.freq

        if any( id -> !haskey( trans.startState.inStateSince, id ),
            keys( trans.startState.isLockedForTransition ) ) ||
            any( id -> !haskey( trans.startState.isLockedForTransition, id ),
                keys( trans.startState.inStateSince ) )
            println( "Transition '$(trans.name)' at $(now( sim ))" )
            println( "Start state '$(trans.startState.name)'" )
            println( trans.startState.inStateSince )
            println( trans.startState.isLockedForTransition )
            error( "PROBLEM!" )
        end
        # Identify all persons who're in the start state long enough and are not
        #   already going to transition to another state.
        eligibleIDs = getEligibleIDs( trans, mpSim )
        updateAttemptsAndIDs!( nAttempts, maxAttempts, eligibleIDs )
        checkedIDs = checkExtraConditions( trans, eligibleIDs, mpSim )
        transIDs = determineTransitionIDs( trans, checkedIDs, nAttempts )

        # Halt execution until the transition candidates for all transitions at
        #   the current time are determined.
        processTime += now() - tStart
        @yield( timeout( sim, 0, priority = priority - Int8( 1 ) ) )
        tStart = now()
        executeTransitions( trans, transIDs, mpSim )
        newStateList = updateStates( trans, transIDs, nAttempts, mpSim )
        updateTimeToAttrition( newStateList, mpSim )
        firePersonnel( trans, eligibleIDs, transIDs, nAttempts, maxAttempts,
            mpSim )
    end  # while timeOfCheck <= mpSim.simLength

    processTime += now() - tStart
    println( "Transition process for '$(trans.name)' took $(processTime.value / 1000) seconds." )

end  # transitionNewProcess( sim, trans, mpSim )


function getEligibleIDs( trans::Transition,
    mpSim::ManpowerSimulation )::Vector{String}

    eligibleIDs = collect( keys( trans.startState.inStateSince ) )
    filter!( id -> !trans.startState.isLockedForTransition[ id ], eligibleIDs )

    for cond in filter( cond -> cond.attr == "time_in_state",
        trans.extraConditions )
        filter!( id -> cond.rel( now( mpSim ) -
            trans.startState.inStateSince[ id ], cond.val ), eligibleIDs )
    end  # for cond in filter( ...

    return eligibleIDs

end  # getEligibleIDs( trans, mpSim )


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
        queryCmd = "SELECT *, ageAtRecruitment + $(now( mpSim )) - timeEntered age, $(now( mpSim )) - timeEntered tenure
            FROM $(mpSim.personnelDBname)
            WHERE $(mpSim.idKey) IN ('$(join( eligibleIDs, "', '" ))')"
        eligibleIDsState = SQLite.query( mpSim.simDB, queryCmd )
        isIDokay = isa.( eligibleIDs, String )

        for cond in filter( cond -> cond.attr != "time_in_state",
            trans.extraConditions )
            isIDokay = isIDokay .& map( ii -> cond.rel(
                eligibleIDsState[ Symbol( cond.attr ) ][ ii ], cond.val ),
                eachindex( isIDokay ) )
        end  # for cond in filter( ...

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

        # Check how many spots are available in the end state.
        available = -1

        if trans.endState.stateTarget >= 0
            available = max( trans.endState.stateTarget -
                length( trans.endState.inStateSince ), 0 )
        end  # if trans.endState.stateTarget >= 0

        # Determine the number of personnel members to undergo the transition.
        #   This is the minimum of the number of the max flux and the number of
        #   vacancies in the end state.
        toChoose = trans.maxFlux

        if trans.maxFlux == -1
            toChoose = available
        elseif available != -1
            toChoose = min( available, toChoose )
        end  # if trans.maxFlux == -1

        # Take only toChoose random IDs if the number of eligible IDs exceeds
        #   this.
        if ( toChoose != -1 ) && ( length( transIDs ) > toChoose )
            transIDs = transIDs[ sortperm( rand( length( transIDs ) ) )[
                1:toChoose ] ]
                # Get the first toChoose entries of the permutation
                #   vector that puts the vector of random numbers in sorted
                #   order.
        end  # if ( toChoose != -1 ) && ...

        # Lock the chosen IDs for transition.
        foreach( id -> trans.startState.isLockedForTransition[ id ] = true,
            transIDs )
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
            push!( changedAttrs, attr )
            push!( newAttrValues,
                trans.endState.requirements[ attr ][ 1 ] )
            push!( persChangesCmd, "$attr = '$(newAttrValues[ end ])'" )
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
    nAttempts::Dict{String, Int},
    mpSim::ManpowerSimulation )::Dict{String, Vector{State}}

    newStateList = Dict{String, Vector{State}}()

    if isempty( transIDs )
        return newStateList
    end  # if isempty( transIDs )

    # Get current state of the personnel members undergoing the
    #   transition.
    queryCmd = "SELECT * FROM $(mpSim.personnelDBname)
        WHERE $(mpSim.idKey) IN ('$(join( transIDs, "', '" ))')"
    transIDsState = SQLite.query( mpSim.simDB, queryCmd )

    isStartRetained = Vector{Bool}()
    isEndReached = Vector{Bool}()
    stateUpdates = Vector{String}()
    newStateList = Dict{String, Vector{State}}()
    foreach( id -> newStateList[ id ] = Vector{State}(), transIDs )

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
                    state.isLockedForTransition[ id ] = false
                end  # for id in newIDsInState
            end  # if !isempty( newIDsInState )

            # For dropped states, add an entry that the state
            #   transitions to an unknown state.
            if !isempty( droppedIDs )
                suffix = "', $(now( mpSim )), '$(trans.name)', '$(state.name)', 'unknown')"
                push!( stateUpdates, join( "('" .* droppedIDs .* suffix,
                    ", " ) )

                for id in droppedIDs
                    delete!( state.inStateSince, id )
                    delete!( state.isLockedForTransition, id )
                end  # for id in droppedIDs
            end  # if !isempty( droppedIDs )
        end  # if state === trans.startState

        # Add this state to the list for all persons in it.
        foreach( id -> push!( newStateList[ id ], state ), personsInState )
    end  # for state in keys( merge( ...

    # Add transition entries for start and end states.
    for jj in eachindex( transIDs )
        pid = transIDs[ jj ]

        if isEndReached[ jj ]
            push!( stateUpdates, "('$pid', $(now( mpSim )), '$(trans.name)', '$(trans.startState.name)', '$(trans.endState.name)')" )
            trans.endState.inStateSince[ pid ] = now( mpSim )
            trans.endState.isLockedForTransition[ pid ] = false

            if isStartRetained[ jj ]
                push!( stateUpdates, "('$pid', $(now( mpSim )), '$(trans.name)', 'nuknown', '$(trans.endState.name)')" )
            end
        elseif !isStartRetained[ jj ]
            push!( stateUpdates, "('$pid', $(now( mpSim )), '$(trans.name)', '$(trans.startState.name)', 'unknown')" )
        end  # if isEndReached[ jj ]

        if !isStartRetained[ jj ]
            delete!( trans.startState.inStateSince, pid )
            delete!( trans.startState.isLockedForTransition, pid )
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
    return newStateList

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
