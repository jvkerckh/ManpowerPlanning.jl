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
       setIsOutTrans!,
       setSchedule,
       addCondition!,
       clearConditions!,
       addAttributeChange!,
       clearAttributeChanges!,
       setTransProbabilities,
       setMaxAttempts,
       setTimeBetweenAttempts,
       setFluxBounds,
       setMinFlux,
       setMaxFlux,
       setHasPriority


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
start state will be set. Note that the end state will be ignored if the
transition's `isOutTrans` flag is set to `true`.

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
setIsOutTrans!( trans::Transition,
                isOutTrans::Bool )
```
This function sets the `isOutTrans` flag of the transition `trans` to
`isOutTrans`.

This function returns `nothing`.
"""
function setIsOutTrans!( trans::Transition, isOutTrans::Bool )::Void

    trans.isOutTrans = isOutTrans
    return

end  # setIsOutTrans!( trans, isOutTrans )


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
setFluxBounds( trans::Transition,
               minFlux::Integer,
               maxFlux::Integer )
```
This function sets the flux of the transition `trans` to the range `minFlux` to
`maxFlux`. Values below 0 for the minimum flux are invalid. Values below -1 for
the maximum flux are invalid. A value of -1 for the maximum flux means that
there is no upper limit on the flux. A minimum flux which is higher than the
maximum flux is invalid.

This function returns `nothing`. If an invalid flux range is entered, the
function issues a warning to that effect and makes no changes to the
transition.
"""
function setFluxBounds( trans::Transition, minFlux::Integer,
    maxFlux::Integer )

    if minFlux < 0
        warn( "Min flux must be >= 0. Not making any changes." )
        return
    end  # if minFlux < 0

    if maxFlux < -1
        warn( "Max flux must be >= -1. Not making any changes." )
        return
    end  # if maxFlux < -1

    if ( maxFlux > -1 ) && ( minFlux > maxFlux )
        warn( "Min flux cannot be higher than max flux.",
            " Not making any changes." )
        return
    end  # if ( maxFlux > -1 ) && ...

    trans.minFlux = minFlux
    trans.maxFlux = maxFlux
    return

end  # setMaxFlux( trans, maxFlux )


"""
```
setMinFlux( trans::Transition,
            minFlux::Integer )
```
This function sets the minimum flux of the transition `trans` to `minFlux`.
Values below 0 are invalid. Values higher than the transition's current max flux
are invalid.

This function returns `nothing`. If an invalid minimum flux is entered, the
function issues a warning to that effect and makes no changes to the
transition.
"""
function setMinFlux( trans::Transition, minFlux::Integer )::Void

    if minFlux < 0
        warn( "Min flux must be >= 0. Not making any changes." )
        return
    end  # if minFlux < 0

    if ( trans.maxFlux > -1 ) && ( minFlux > trans.maxFlux )
        warn( "Min flux must be <= current max flux ", trans.maxFlux,
            ". Not making any changes." )
    end  # if ( trans.maxFlux > -1 ) && ...

    trans.minFlux = minFlux
    return

end  # setMaxFlux( trans, maxFlux )


"""
```
setMaxFlux( trans::Transition,
            maxFlux::Integer )
```
This function sets the maximum flux of the transition `trans` to `maxFlux`.
Values below -1 are invalid. A value of -1 means that there is no limit on the
flux. Values smaller than the transition's current min flux are invalid.

This function returns `nothing`. If an invalid maximum flux is entered, the
function issues a warning to that effect and makes no changes to the
transition.
"""
function setMaxFlux( trans::Transition, maxFlux::Integer )::Void

    if maxFlux < -1
        warn( "Max flux must be >= -1. Not making any changes." )
        return
    end  # if maxFlux < -1

    if ( maxFlux > -1 ) && ( maxFlux > maxFlux )
        warn( "Max flux must be >= current min flux ", trans.minFlux,
            ". Not making any changes." )
    end  # if ( maxFlux > -1 ) && ...

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

    print( io, "    Transition '", trans.name, "': '", trans.startState.name,
        "' to '", trans.isOutTrans ? "external" : trans.endState.name, "'" )
    print( io, "\n      Occurs with period ", trans.freq, " (offset ",
        trans.offset, ")" )

    if !isempty( trans.extraConditions )
        print( io, "\n      Extra conditions: ", trans.extraConditions )
    end  # if !isempty( trans.extraConditions )

    if !isempty( trans.extraChanges )
        print( io, "\n      Extra changes: ", trans.extraChanges )
    end

    if trans.maxAttempts == -1
        print( io, "\n      Infinite number of" )
    else
        nAttempts = trans.maxAttempts == 0 ? length( trans.probabilityList ) :
            trans.maxAttempts
        print( io, "\n      Max ", nAttempts )
    end  # if trans.maxAttempts == -1

    print( io, " attempts" )

    if trans.minFlux > 0
        print( io, "\n      Min flux: ", trans.minFlux )
    end

    if trans.maxFlux >= 0
        print( io, "\n      Max flux: ", trans.maxFlux )

        if trans.hasPriority
            print( io, " (overrides state pop. constraint)" )
        end  # if trans.hasPriority
    end  # if trans.maxFlux >= 0

    print( io, "\n      Transition execution probabilities: ",
        join( trans.probabilityList .* 100, "%, " ), '%' )
    print( io, "\n      Transition at priority ", - trans.transPriority )

end  # Base.show( io, trans )


# ==============================================================================
# Non-exported methods.
# ==============================================================================

function readTransition( sheet::XLSX.Worksheet, sLine::Integer )

    newTrans = Transition( sheet[ "A$sLine" ], dummyNode, dummyNode )
    startState, endState = string( sheet[ "B$sLine" ] ),
        string( sheet[ "C$sLine" ] )
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
    minFlux = sheet[ XLSX.CellRef( sLine, sCol ) ]
    maxFlux = sheet[ XLSX.CellRef( sLine, sCol + 1 ) ]
    setFluxBounds( newTrans, isa( minFlux, Missing ) ? 0 : Int( minFlux ),
        isa( maxFlux, Missing ) ? -1 : Int( maxFlux ) )
    setHasPriority( newTrans,
        sheet[ XLSX.CellRef( sLine, sCol + 2 ) ] == "NO" )
    maxAttempts = sheet[ XLSX.CellRef( sLine, sCol + 3 ) ]
    setMaxAttempts( newTrans, isa( maxAttempts, Missing ) ? -1 :
        Int( maxAttempts ) )

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


function readOutTransition( sheet::XLSX.Worksheet, sLine::Integer )

    newTrans = Transition( sheet[ "A$sLine" ], dummyNode )
    sourceNode = string( sheet[ "B$sLine" ] )
    setSchedule( newTrans, sheet[ "C$sLine" ], sheet[ "D$sLine" ] )

    # Read time related conditions.
    sCol = 6
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
    minFlux = sheet[ XLSX.CellRef( sLine, sCol ) ]
    maxFlux = sheet[ XLSX.CellRef( sLine, sCol + 1 ) ]
    setFluxBounds( newTrans, isa( minFlux, Missing ) ? 0 : Int( minFlux ),
        isa( maxFlux, Missing ) ? -1 : Int( maxFlux ) )
    maxAttempts = sheet[ XLSX.CellRef( sLine, sCol + 2 ) ]
    setMaxAttempts( newTrans, isa( maxAttempts, Missing ) ? -1 :
        Int( maxAttempts ) )

    # Read probability vector.
    sCol += 2
    nProbs = Int( sheet[ XLSX.CellRef( sLine, sCol ) ] )
    probs = Vector{Float64}( nProbs )

    for ii in 1:nProbs
        probs[ ii ] = sheet[ XLSX.CellRef( sLine, sCol + ii ) ]
    end  # for ii in 1:nProbs

    setTransProbabilities( newTrans, probs )

    return newTrans, sourceNode

end  # readOutTransition( sheet, sLine )


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
    priorityShift = ( trans.hasPriority ? 1 : 2 ) * mpSim.nTrans
    maxAttempts = trans.maxAttempts == 0 ? length( trans.probabilityList ) :
        trans.maxAttempts
    nAttempts = Dict{String, Int}()
    toShow = true

    while timeOfCheck <= mpSim.simLength
        processTime += now() - tStart
        filter!( ( id, nAtt ) -> haskey( trans.startState.inStateSince, id ),
            nAttempts )
        @yield( timeout( sim, timeOfCheck - now( sim ), priority = priority -
            ( trans.minFlux == 0 ? priorityShift : 0 ) ) )
        tStart = now()
        timeOfCheck += trans.freq

        # Identify all persons who're in the start state long enough and are not
        #   already going to transition to another state.
        eligibleIDs = getEligibleIDs( trans, nAttempts, maxAttempts, mpSim )
        checkedIDs = checkExtraConditions( trans, eligibleIDs, mpSim )
        updateAttemptsAndIDs!( nAttempts, maxAttempts, checkedIDs )

        # Assign a modified probability to each person.
        transLevels = determineTransitionLevels( trans, checkedIDs, nAttempts )

        # If the transition has a minimum flux, transition those IDs first, and
        #   set the priority of the rest of the transition to the proper level.
        if trans.minFlux > 0
            mandIDs = determineMandatoryIDs( trans, checkedIDs, transLevels )
            performTransitions( mpSim, trans, mandIDs )
            @yield( timeout( sim, 0, priority = priority - priorityShift ) )
            filter!( id -> haskey( trans.startState.inStateSince, id ),
                checkedIDs )
        end  # if trans.minFlux > 0

        transIDs = determineAdditionalIDs( trans, checkedIDs, transLevels )
        performTransitions( mpSim, trans, transIDs )
    end  # while timeOfCheck <= mpSim.simLength

    processTime += now() - tStart
    println( "Transition process for '$(trans.name)' took $(processTime.value / 1000) seconds." )

end  # transitionProcess( sim, trans, mpSim )


function getEligibleIDs( trans::Transition, nAttempts::Dict{String, Int},
    maxAttempts::Int, mpSim::ManpowerSimulation )::Vector{String}

    eligibleIDs = collect( keys( trans.startState.inStateSince ) )

    # Check if attempts have been exhausted (imprtant if transition doesn't fire
    #   after exhaustion of attempts).
    if maxAttempts > 0
        # The first condition means 0 attempts so far.
        filter!( id -> !haskey( nAttempts, id ) ||
            ( nAttempts[ id ] < maxAttempts ), eligibleIDs )
    end  # if maxAttempts > 0

    for cond in filter( cond -> cond.attr == "time in node",
        trans.extraConditions )
        filter!( id -> cond.rel( now( mpSim ) -
            trans.startState.inStateSince[ id ], cond.val ), eligibleIDs )
    end  # for cond in filter( ...

    return eligibleIDs

end  # getEligibleIDs( trans, mpSim )


function checkExtraConditions( trans::Transition, eligibleIDs::Vector{String},
    mpSim::ManpowerSimulation )::Vector{String}

    if isempty( eligibleIDs ) || isempty( trans.extraConditions )
        return eligibleIDs
    end  # if isempty( eligibleIDs ) || ...

    checkedIDs = eligibleIDs

    # Check extra conditions.
    queryCmd = string( "SELECT *, ageAtRecruitment + ", now( mpSim ),
        " - timeEntered age, ", now( mpSim ), " - timeEntered tenure
        FROM `", mpSim.personnelDBname, "`
        WHERE `", mpSim.idKey, "` IN ('", join( eligibleIDs, "', '" ), "')" )
    eligibleIDsState = SQLite.query( mpSim.simDB, queryCmd )
    isIDokay = isa.( eligibleIDs, String )

    for cond in filter( cond -> cond.attr != "time in node",
        trans.extraConditions )
        isIDokay = isIDokay .& map( ii -> cond.rel(
            eligibleIDsState[ Symbol( cond.attr ) ][ ii ], cond.val ),
            eachindex( isIDokay ) )
    end  # for cond in filter( ...

    checkedIDs = eligibleIDsState[ Symbol( mpSim.idKey ) ][ isIDokay ]

    return checkedIDs

end  # checkExtraConditions( trans, eligibleIDs, mpSim )


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


function determineTransitionLevels( trans::Transition,
    eligibleIDs::Vector{String},
    nAttempts::Dict{String, Int} )::Dict{String, Float64}

    if isempty( eligibleIDs )
        return Dict{String, Float64}()
    end  # if isempty( eligibleIDs )

    # The probabilities of undergoing the transition for each person.
    tresholds = trans.probabilityList[ map( ii -> min(
        length( trans.probabilityList ), nAttempts[ eligibleIDs[ ii ] ] ),
        eachindex( eligibleIDs ) ) ]
    modProbs = rand( length( eligibleIDs ) ) ./ tresholds

    return Dict{String, Float64}( eligibleIDs[ ii ] => modProbs[ ii ] for ii =
        eachindex( eligibleIDs ) )

end  # determineTransitionLevels( trans, eligibleIDs, nAttempts )


function determineMandatoryIDs( trans::Transition, eligibleIDs::Vector{String},
    transLevels::Dict{String, Float64} )::Vector{String}

    if length( eligibleIDs ) <= trans.minFlux
        return eligibleIDs
    end  # if length( eligibleIDs ) <= trans.minFlux

    # Get the min flux IDs which have the smallest value for their transLevel.
    modProbs = map( id -> transLevels[ id ], eligibleIDs )

    return eligibleIDs[ sortperm( modProbs )[ 1:(trans.minFlux) ] ]

end  # determineMandatoryIDs( trans, eligibleIDs, transLevels )


function performTransitions( mpSim::ManpowerSimulation, trans::Transition,
    idList::Vector{String} )::Void

    if trans.isOutTrans
        retirePersons( mpSim, idList, trans.name )
    else
        # Execute the transition for the selected personnel members and
        #   perform necessary updates.
        executeTransitions( trans, idList, mpSim )

        if trans.startState !== trans.endState
            newStateList = updateStates( trans, idList, mpSim )
            updateTimeToAttrition( newStateList, mpSim )
        end  # if trans.startState !== trans.endState
    end  # if trans.isOutTrans

    return

end  # performTransitions( mpSim, trans, idList )


function executeTransitions( trans::Transition, transIDs::Vector{String},
    mpSim::ManpowerSimulation )

    if isempty( transIDs )
        return
    end  # if isempty( transIDs )

    # Get current state of the personnel members undergoing the
    #   transition.
    queryCmd = "SELECT * FROM `$(mpSim.personnelDBname)`
        WHERE `$(mpSim.idKey)` IN ('$(join( transIDs, "', '" ))')"
    transIDsState = SQLite.query( mpSim.simDB, queryCmd )
    tmpIDs = transIDsState[ Symbol( mpSim.idKey ) ]

    # Make changes in personnel database.
    persChangesCmd = Vector{String}()
    changedAttrs = Vector{String}()
    newAttrValues = Vector{String}()

    # End state attributes.
    if trans.startState !== trans.endState
        for attr in keys( trans.endState.requirements )
            push!( changedAttrs, attr )
            push!( newAttrValues,
                trans.endState.requirements[ attr ][ 1 ] )
            push!( persChangesCmd, "`$attr` = '$(newAttrValues[ end ])'" )
        end  # for attr in keys( trans.endState.requirements )
    end  # if trans.startState !== trans.endState

    # Extra attribute changes.
    for attr in trans.extraChanges
        push!( changedAttrs, attr.name )
        push!( newAttrValues, collect( keys( attr.values ) )[ 1 ] )
        push!( persChangesCmd, "`$(attr.name)` = '$(newAttrValues[ end ])'" )
    end  # for attr in trans.extraChanges

    if !isempty( persChangesCmd )
        persChangesCmd = "UPDATE `$(mpSim.personnelDBname)`
            SET $(join( persChangesCmd, ", " ))
            WHERE `$(mpSim.idKey)` IN ('$(join( tmpIDs, "', '" ))')"
        SQLite.execute!( mpSim.simDB, persChangesCmd )
    end  # if !isempty( persChangesCmd )

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
        histChangesCmd = "INSERT INTO `$(mpSim.historyDBname)`
            (`$(mpSim.idKey)`, attribute, timeIndex, strValue) VALUES
            $(join( histChangesCmd, ", "))"
        SQLite.execute!( mpSim.simDB, histChangesCmd )
    end  # if !isempty( histChangesCmd )

    return

end  # executeTransitions( trans, transIDs, mpSim )


function updateStates( trans::Transition, transIDs::Vector{String},
    mpSim::ManpowerSimulation )::Dict{String, Vector{State}}

    newStateList = Dict{String, Vector{State}}()

    if isempty( transIDs )
        return newStateList
    end  # if isempty( transIDs )

    stateUpdates = Vector{String}( length( transIDs ) )
    queryCmd = "SELECT `$(mpSim.idKey)`, ageAtRecruitment, timeEntered
        FROM `$(mpSim.personnelDBname)`
        WHERE `$(mpSim.idKey)` in ('$(join( transIDs, "', '" ))')"
    importantTimes = SQLite.query( mpSim.simDB, queryCmd )

    for ii in eachindex( transIDs )
        pid = importantTimes[ ii, 1 ]
        newStateList[ pid ] = [ trans.endState ]
        delete!( trans.startState.inStateSince, pid )
        trans.endState.inStateSince[ pid ] = now( mpSim )
        stateUpdates[ ii ] = "('$pid', $(now( mpSim )), '$(trans.name)', '$(trans.startState.name)', '$(trans.endState.name)')"
    end  # for id in transIDs

    transChangesCmd = "INSERT INTO `$(mpSim.transitionDBname)`
        (`$(mpSim.idKey)`, timeIndex, transition, startState, endState) VALUES
        $(join( stateUpdates, ", " ))"
    SQLite.execute!( mpSim.simDB, transChangesCmd )
    return newStateList

end  # function updateStates( trans, transIDs, mpSim )


function determineAdditionalIDs( trans::Transition, eligibleIDs::Vector{String},
    transLevels::Dict{String, Float64} )::Vector{String}

    if trans.maxFlux == trans.minFlux
        return Vector{String}()
    end  # if trans.maxFlux == trans.minFlux

    if isempty( eligibleIDs )
        return eligibleIDs
    end  # if isempty( eligibleIDs )

    # Determine the max number of personnel members left to transfer.
    maxToTransfer = trans.maxFlux == -1 ? length( eligibleIDs ) :
        trans.maxFlux - trans.minFlux
    vacancies = -1

    if !( trans.isOutTrans ) && !( trans.hasPriority ) &&
        ( trans.startState !== trans.endState ) &&
        trans.endState.stateTarget >= 0
        vacancies = max( 0, trans.endState.stateTarget -
            length( trans.endState.inStateSince ) )
    end  # if !( trans.isOutTrans ) && ...

    if vacancies >= 0
        maxToTransfer = min( maxToTransfer, vacancies )
    end  # if vacancies >= 0

    if maxToTransfer == 0
        return Vector{String}()
    end  # if maxToTransfer == 0

    modProbs = map( id -> transLevels[ id ], eligibleIDs )
    hasPassed = modProbs .< 1

    # If the number of people who have passed the test is smaller than the
    #   number of people who can transfer, return the list of people who passed.
    if sum( hasPassed ) <= maxToTransfer
        return eligibleIDs[ hasPassed ]
    end  # if sum( hasPassed ) <= maxToTransfer

    # Otherwise, only select people with highest scores.
    return eligibleIDs[ sortperm( modProbs )[ 1:maxToTransfer ] ]

end  # determineAdditionalIDs( trans, eligibleIDs, transLevels )


function buildTransitionNetwork( mpSim::ManpowerSimulation,
    nodes::String... )

    # Filter out non-existing nodes.
    nodeList = merge( mpSim.initStateList, mpSim.otherStateList )
    tmpNodes = collect( Iterators.filter(
        nodeName -> any( node -> node.name == nodeName, keys( nodeList ) ),
        nodes ) )
    graphNodes = tmpNodes
    graphTrans = Vector{String}()

    # Initialise directed graph.
    nNodes = length( graphNodes )
    graph = MetaDiGraph( DiGraph( nNodes + 2 ) )
    inNodeIndex = nNodes + 1
    outNodeIndex = nNodes + 2
    set_prop!( graph, nNodes + 1, :node, "In" )
    set_prop!( graph, nNodes + 2, :node, "Out" )

    # Add node labels to states.
    for ii in 1:nNodes
        set_prop!( graph, ii, :node, graphNodes[ ii ] )
    end  # for ii in 1:nNodes

    # Add recruitment edges.
    for recScheme in mpSim.recruitmentSchemes
        recNodeIndex = findfirst( graphNodes .== recScheme.recState )
        add_edge!( graph, inNodeIndex, recNodeIndex )
        set_prop!( graph, inNodeIndex, recNodeIndex, :trans,
            recScheme.name )
    end  # for recScheme in mpSim.recSchemes

    push!( graphNodes, "In", "Out" )
    nNodes += 2

    # Add all other transitions.
    for state in keys( nodeList )
        # Is the state in the original list?
        if state.name ∈ tmpNodes
            # Find its index.
            startStateIndex = findfirst( tmpNodes .== state.name )

            # Add all transitions starting from there.
            for trans in nodeList[ state ]
                endStateIndex = trans.endState.name == "Dummy" ? outNodeIndex :
                    findfirst( graphNodes .== trans.endState.name )

                # If end state hasn't been put in the list, add it.
                if endStateIndex == 0
                    add_vertex!( graph )
                    push!( graphNodes, trans.endState.name )
                    nNodes += 1
                    set_prop!( graph, nNodes, :node, trans.endState.name )
                    endStateIndex = nNodes
                end  # if endStateIndex == 0

                add_edge!( graph, startStateIndex, endStateIndex )
                set_prop!( graph, startStateIndex, endStateIndex, :trans,
                    trans.name )
            end  # for trans in nodeList[ state ]
        else
            startStateIndex = findfirst( graphNodes .== state.name )
            isStateCreated = startStateIndex > 0

            for trans in nodeList[ state ]
                endStateIndex = findfirst( tmpNodes .== trans.endState.name )
                # Add the transition if the end state is in the list of original
                #   states.
                if endStateIndex > 0
                    # Create the state if it isn't in the list.
                    if !isStateCreated
                        add_vertex!( graph )
                        push!( graphNodes, trans.startState.name )
                        nNodes += 1
                        set_prop!( graph, nNodes, :node,
                            trans.startState.name )
                        startStateIndex = nNodes
                        isstateCreated = true
                    end  # if !isStateCreated

                    add_edge!( graph, startStateIndex, endStateIndex )
                    set_prop!( graph, startStateIndex, endStateIndex, :trans,
                        trans.name )
                end  # if trans.endState.name ∈ tmpNodes
            end  # for trans in nodeList[ state ]
        end  # if state.name ∈ graphNodes
    end  # for state in keys( nodeList )

    return graph, inNodeIndex, outNodeIndex

end  # buildTransitionNetwork( mpSim, nodes )
