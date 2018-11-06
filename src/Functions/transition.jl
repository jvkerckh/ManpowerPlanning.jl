# This file holds the definition of the functions pertaining to the
#   Transition type.

# The functions of the Transition type require the State type.
requiredTypes = [ "state", "transition" ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( typePath, reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end  # for reqType in requiredTypes


export setName,
       setState,
       setSchedule,
       addCondition!,
       clearConditions!,
       addAttributeChange!,
       clearAttributeChanges!,
       setTransProbabilities,
       setMaxAttempts,
       setTimeBetweenAttempts,
       setFireAfterFail,
       setMaxFlux,
       setHasPriority


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


"""
```
setHasPriority( trans::Transition,
                hasPrio::Bool )
```
This function sets the `hasPriority` flag of the transition `trans` to
`hasPrio`, where `true` means the transition can overrule the target state's
population target.

This function returns `nothing`.
"""
function setHasPriority( trans::Transition, hasPrio::Bool )::Void

    trans.hasPriority = hasPrio
    trans.transPriority = hasPrio ? 0 : 1
    return

end  # setHasPriority( trans, hasPrio )


function Base.show( io::IO, trans::Transition )

    print( io, "    Transition $(trans.name): '$(trans.startState.name)' to '$(trans.endState.name)'" )
    print( io, "\n      Occurs with period $(trans.freq) (offset $(trans.offset))" )

    if !isempty( trans.extraConditions )
        print( io, "\n      Extra conditions: $(trans.extraConditions)" )
    end  # if !isempty( trans.extraConditions )

    if !isempty( trans.extraChanges )
        print( io, "\n      Extra changes: $(trans.extraChanges)" )
    end

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

        if trans.hasPriority
            print( io, " (overrides state pop. constraint)" )
        end  # if trans.hasPriority
    end  # if trans.maxFlux >= 0

    print( io, "\n      Transition execution probabilities: " )
    print( io, join( trans.probabilityList .* 100, "%, " ) * '%' )
    print( io, "\n      Transition at priority ", - trans.transPriority )

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
    setHasPriority( newTrans, XLSX.CellRef( sLine, sCol + 1 ) == "NO" )
    maxAttempts = sheet[ XLSX.CellRef( sLine, sCol + 2 ) ]
    setMaxAttempts( newTrans, isa( maxAttempts, Missings.Missing ) ? -1 :
        Int( maxAttempts ) )

    if isa( maxAttempts, Missings.Missing )
        setFireAfterFail( newTrans, false )
    else
        setFireAfterFail( newTrans,
            sheet[ XLSX.CellRef( sLine, sCol + 3 ) ] == "YES" )
    end  # if !isa( maxAttempts, Missings.Missing )

    # Read probability vector.
    sCol += 4
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

    processTransPriorities( mpSim )
    assignTransPriorities( mpSim )

    for state in keys( mpSim.initStateList ),
        trans in mpSim.initStateList[ state ]
        @process transitionProcess( mpSim.sim, trans, mpSim )
    end  # for state in keys( mpSim.initStateList ), ...

    for state in keys( mpSim.otherStateList ),
        trans in mpSim.otherStateList[ state ]
        @process transitionProcess( mpSim.sim, trans, mpSim )
    end  # for state in keys( mpSim.otherStateList ), ...

    return

end  # initiateTransitionProcesses( mpSim )


@resumable function transitionProcess( sim::Simulation, trans::Transition,
    mpSim::ManpowerSimulation )

    processTime = Dates.Millisecond( 0 )
    tStart = now()

    # Initialize the schedule.
    timeOfCheck = now( sim ) - trans.offset
    timeOfCheck = floor( timeOfCheck / trans.freq + 1.0 ) * trans.freq +
        trans.offset
    priority = - trans.transPriority
    maxAttempts = trans.maxAttempts == 0 ? length( trans.probabilityList ) :
        trans.maxAttempts
    nAttempts = Dict{String, Int}()

    while timeOfCheck <= mpSim.simLength
        processTime += now() - tStart
        @yield( timeout( sim, timeOfCheck - now( sim ), priority = priority ) )
        tStart = now()
        timeOfCheck += trans.freq

        # Identify all persons who're in the start state long enough and are not
        #   already going to transition to another state.
        eligibleIDs = getEligibleIDs( trans, nAttempts, maxAttempts, mpSim )
        checkedIDs = checkExtraConditions( trans, eligibleIDs, mpSim )
        updateAttemptsAndIDs!( nAttempts, maxAttempts, checkedIDs )
        transIDs = determineTransitionIDs( trans, checkedIDs, nAttempts )

        # Halt execution until the transition candidates for all transitions at
        #   the current time are determined.
        processTime += now() - tStart
        # @yield( timeout( sim, 0, priority = priority - 1 ) )
        tStart = now()
        executeTransitions( trans, transIDs, mpSim )
        newStateList = updateStates( trans, transIDs, nAttempts, mpSim )
        updateTimeToAttrition( newStateList, mpSim )
        firePersonnel( trans, checkedIDs, transIDs, nAttempts, maxAttempts,
            mpSim )
    end  # while timeOfCheck <= mpSim.simLength

    processTime += now() - tStart
    println( "Transition process for '$(trans.name)' took $(processTime.value / 1000) seconds." )

end  # transitionProcess( sim, trans, mpSim )


function getEligibleIDs( trans::Transition, nAttempts::Dict{String, Int},
    maxAttempts::Int, mpSim::ManpowerSimulation )::Vector{String}

    eligibleIDs = collect( keys( trans.startState.inStateSince ) )
    filter!( id -> !trans.startState.isLockedForTransition[ id ], eligibleIDs )

    # Check if attempts have been exhausted (imprtant if transition doesn't fire
    #   after exhaustion of attempts).
    if maxAttempts > 0
        # The first condition means 0 attempts so far.
        filter!( id -> !haskey( nAttempts, id ) ||
            ( nAttempts[ id ] < maxAttempts ), eligibleIDs )
    end  # if maxAttempts > 0

    for cond in filter( cond -> cond.attr == "time in state",
        trans.extraConditions )
        filter!( id -> cond.rel( now( mpSim ) -
            trans.startState.inStateSince[ id ], cond.val ), eligibleIDs )
    end  # for cond in filter( ...

    return eligibleIDs

end  # getEligibleIDs( trans, mpSim )


function updateAttemptsAndIDs!( nAttempts::Dict{String, Int}, maxAttempts::Int,
    eligibleIDs::Vector{String} )::Void

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

    return

end  # updateAttemptsAndIDs!( nAttempts, eligibleIDs )


function checkExtraConditions( trans::Transition, eligibleIDs::Vector{String},
    mpSim::ManpowerSimulation )::Vector{String}

    checkedIDs = eligibleIDs

    # Check extra conditions.
    if !isempty( eligibleIDs ) && !isempty( trans.extraConditions )
        queryCmd = "SELECT *, ageAtRecruitment + $(now( mpSim )) - timeEntered age, $(now( mpSim )) - timeEntered tenure
            FROM $(mpSim.personnelDBname)
            WHERE $(mpSim.idKey) IN ('$(join( eligibleIDs, "', '" ))')"
        eligibleIDsState = SQLite.query( mpSim.simDB, queryCmd )
        isIDokay = isa.( eligibleIDs, String )

        for cond in filter( cond -> cond.attr != "time in state",
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

        # Check how many spots are available in the end state, ONLY if the end
        #   state differs from the start state.
        available = -1

        if ( trans.startState != trans.endState ) &&
            ( trans.endState.stateTarget >= 0 )
            available = max( trans.endState.stateTarget -
                length( trans.endState.inStateSince ), 0 )
        end  # if ( trans.startState != trans.endState ) && ...

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
            push!( persChangesCmd, "'$attr' = '$(newAttrValues[ end ])'" )
        end  # for attr in keys( trans.endState.requirements )

        # Extra attribute changes.
        for attr in trans.extraChanges
            push!( changedAttrs, attr.name )
            push!( newAttrValues, collect( keys( attr.values ) )[ 1 ] )
            push!( persChangesCmd, "'$(attr.name)' = '$(newAttrValues[ end ])'" )
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

    stateUpdates = Vector{String}( length( transIDs ) )
    queryCmd = "SELECT $(mpSim.idKey), ageAtRecruitment, timeEntered
        FROM $(mpSim.personnelDBname)
        WHERE $(mpSim.idKey) in ('$(join( transIDs, "', '" ))')"
    importantTimes = SQLite.query( mpSim.simDB, queryCmd )

    for ii in eachindex( transIDs )
        pid = importantTimes[ ii, 1 ]
        newStateList[ pid ] = [ trans.endState ]
        delete!( trans.startState.inStateSince, pid )
        delete!( trans.startState.isLockedForTransition, pid )
        delete!( nAttempts, pid )
        trans.endState.inStateSince[ pid ] = now( mpSim )
        trans.endState.isLockedForTransition[ pid ] = false
        stateUpdates[ ii ] = "('$pid', $(now( mpSim )), '$(trans.name)', '$(trans.startState.name)', '$(trans.endState.name)')"
        newRetirementTime = computeExpectedRetirementTime( mpSim,
            mpSim.retirementScheme, importantTimes[ ii, 2 ],
            trans.endState.stateRetAge, importantTimes[ ii, 3 ] )
        retireUpdate = "UPDATE $(mpSim.personnelDBname)
            SET expectedRetirementTime = $newRetirementTime
            WHERE $(mpSim.idKey) IS '$pid'"
        SQLite.execute!( mpSim.simDB, retireUpdate )
    end  # for id in transIDs

    transChangesCmd = "INSERT INTO $(mpSim.transitionDBname)
        ($(mpSim.idKey), timeIndex, transition, startState, endState) VALUES
        $(join( stateUpdates, ", " ))"
    SQLite.execute!( mpSim.simDB, transChangesCmd )
    return newStateList

end  # function updateStates( trans, transIDs, nAttempts, mpSim )


function firePersonnel( trans::Transition, checkedIDs::Vector{String},
    transIDs::Vector{String}, nAttempts::Dict{String, Int}, maxAttempts::Int,
    mpSim::ManpowerSimulation )::Void

    # Fire the personnel members who haven't succesfully made the transition
    #   after the maximum number of attempts.
    if trans.isFiredOnFail && ( maxAttempts >= 0 ) && !isempty( checkedIDs )
        fireIDs = filter( id -> ( id ∉ transIDs ) &&
            ( nAttempts[ id ] == maxAttempts ), checkedIDs )

        if !isempty( fireIDs )
            foreach( id -> delete!( nAttempts, id ), fireIDs )
            retirePersons( mpSim, fireIDs, "fired" )
        end  # if !isempty( fireIDs )
    end  # if maxAttempts >= 0

    return

end  # firePersonnel( trans, checkedIDs, transIDs, nAttempts, maxAttempts,
     #   mpSim )


function buildTransitionNetwork( mpSim::ManpowerSimulation,
    states::String... )

    # Filter out non-existing nodes.
    stateList = merge( mpSim.initStateList, mpSim.otherStateList )
    tmpStates = collect( Iterators.filter(
        stateName -> any( state -> state.name == stateName, keys( stateList ) ),
        states ) )
    graphStates = tmpStates
    graphTrans = Vector{String}()

    # Initialise directed graph.
    nStates = length( graphStates )
    graph = MetaDiGraph( DiGraph( nStates + 2 ) )
    inNodeIndex = nStates + 1
    outNodeIndex = nStates + 2
    set_prop!( graph, nStates + 1, :state, "In" )
    set_prop!( graph, nStates + 2, :state, "Out" )

    # Add node labels and transitions for initial states.
    for ii in eachindex( tmpStates )
        set_prop!( graph, ii, :state, tmpStates[ ii ] )
        state = mpSim.stateList[ tmpStates[ ii ] ]

        # Add recruitment edge for initial state.
        if haskey( mpSim.initStateList, state )
            add_edge!( graph, inNodeIndex, ii )
            set_prop!( graph, inNodeIndex, ii, :trans, "recruitment" )
        end  # if any( state -> state.name == tmpStates[ ii ], ...

        # Add retirement edge for states with defined retirement scheme.
        retScheme = mpSim.retirementScheme

        if ( isa( retScheme, Retirement ) &&
            ( ( retScheme.maxCareerLength != 0.0 ) ||
                ( retScheme.retireAge != 0.0 ) ) ) ||
            ( state.stateRetAge != 0.0 )
            add_edge!( graph, ii, outNodeIndex )
            set_prop!( graph, ii, outNodeIndex, :trans, "retirement" )
        end  # if ( isa( retScheme, Retirement ) && ...
    end  # for ii in eachindex( tmpStates )

    push!( graphStates, "In", "Out" )
    nStates += 2

    # Add all other transitions.
    for state in keys( stateList )
        # Is the state in the original list?
        if state.name ∈ tmpStates
            # Find its index.
            startStateIndex = findfirst( tmpState -> tmpState == state.name,
                tmpStates )

            # Add all transitions starting from there.
            for trans in stateList[ state ]
                endStateIndex = findfirst(
                    tmpState -> tmpState == trans.endState.name, graphStates )

                # If end state hasn't been put in the list, add it.
                if endStateIndex == 0
                    add_vertex!( graph )
                    push!( graphStates, trans.endState.name )
                    nStates += 1
                    set_prop!( graph, nStates, :state, trans.endState.name )
                    endStateIndex = nStates
                end  # if endStateIndex == 0

                add_edge!( graph, startStateIndex, endStateIndex )
                set_prop!( graph, startStateIndex, endStateIndex, :trans,
                    trans.name )

                if trans.isFiredOnFail
                    add_edge!( graph, startStateIndex, outNodeIndex )
                    set_prop!( graph, startStateIndex, outNodeIndex, :trans,
                        "fired\n(failed $(trans.name))" )
                end  # if trans.isFiredOnFail
            end  # for trans in stateList[ state ]
        else
            startStateIndex = findfirst( tmpState -> tmpState == state.name,
                graphStates )
            isStateCreated = startStateIndex > 0

            for trans in stateList[ state ]
                endStateIndex = findfirst(
                    tmpState -> tmpState == trans.endState.name, tmpStates )
                # Add the transition if the end state is in the list of original
                #   states.
                if endStateIndex > 0
                    # Create the state if it isn't in the list.
                    if !isStateCreated
                        add_vertex!( graph )
                        push!( graphStates, trans.startState.name )
                        nStates += 1
                        set_prop!( graph, nStates, :state,
                            trans.startState.name )
                        startStateIndex = nStates
                        isstateCreated = true
                    end  # if !isStateCreated

                    add_edge!( graph, startStateIndex, endStateIndex )
                    set_prop!( graph, startStateIndex, endStateIndex, :trans,
                        trans.name )
                end  # if trans.endState.name ∈ tmpStates
            end  # for trans in stateList[ state ]
        end  # if state.name ∈ graphStates
    end  # for state in keys( stateList )

    return graph, inNodeIndex, outNodeIndex

end  # buildTransitionNetwork( mpSim, states )
