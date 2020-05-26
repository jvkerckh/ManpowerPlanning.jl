function orderTransitions!( mpSim::MPsim )

    transitions = vcat( getindex.( Ref( mpSim.transitionsByName ),
        collect( keys( mpSim.transitionsByName ) ) )... )
    recruitment = vcat( getindex.( Ref( mpSim.recruitmentByName ),
        collect( keys( mpSim.recruitmentByName ) ) )... )
    
    transGraph = MetaDiGraph( length( transitions ) + length( recruitment ) )

    # Don't take any action if there are no transitions.
    if nv( transGraph ) == 0
        return
    end  # if nv( transGraph ) == 0

    jj = 1

    for trans in transitions
        set_prop!( transGraph, jj, :name, trans.name )
        set_prop!( transGraph, jj, :source, trans.sourceNode )
        set_prop!( transGraph, jj, :target,
            trans.isOutTransition ? "OUT" : trans.targetNode )
        set_prop!( transGraph, jj, :trans, trans )
        jj += 1
    end  # for trans in transitions

    for rec in recruitment
        set_prop!( transGraph, jj, :name, rec.name )
        set_prop!( transGraph, jj, :source, "IN" )
        set_prop!( transGraph, jj, :target, rec.targetNode )
        set_prop!( transGraph, jj, :trans, rec )
        jj += 1
    end  # for rec in recruitment

    transitions = vcat( transitions, recruitment )
    
    # Out transitions have priority over in transitions.
    for node in keys( mpSim.baseNodeList )
        outTransitions = findall( trans -> ( trans isa Transition ) &&
            ( trans.sourceNode == node ), transitions )
        inTransitions = findall( trans -> trans.targetNode == node,
            transitions )
        
        for inTrans in inTransitions, outTrans in outTransitions
            add_edge!( transGraph, outTrans, inTrans )
        end  # for inTrans in inTransitions
    end  # for node in mpSim.baseNodeList

    # Prioritise transitions by transition type.
    names = get_prop.( Ref( transGraph ), vertices( transGraph ), :name )
    uniqueNames = unique( names )
    sources = get_prop.( Ref( transGraph ), vertices( transGraph ), :source )
    uniqueSources = unique( sources )
    targets = get_prop.( Ref( transGraph ), vertices( transGraph ), :target )
    uniqueTargets = unique( targets )
    transOrder = mpSim.transitionTypeOrder
    nodeOrder = mpSim.baseNodeOrder

    for source in uniqueSources
        transFromSource = findall( sources .== source )

        if length( transFromSource ) < 2
            continue
        end  # if length( transFromSource ) < 2

        for trans1 in transFromSource, trans2 in transFromSource
            if haskey( transOrder, names[trans1] ) &&
                haskey( transOrder, names[trans2] ) &&
                ( transOrder[names[trans1]] <
                    transOrder[names[trans2]] )
                add_edge!( transGraph, trans1, trans2 )
            end  # if haskey( transOrder, names[trans1] ) && ...
        end  # for trans1 in transFromSource, trans2 in transFromSource

        transNames = names[transFromSource]

        for name in uniqueNames
            transNameSource = transFromSource[transNames .== name]

            if length( transNameSource ) < 2
                continue
            end  # if length( transNameSource ) < 2

            for trans1 in transNameSource, trans2 in transNameSource
                if haskey( nodeOrder, targets[trans1] ) &&
                    haskey( nodeOrder, targets[trans2] ) &&
                    ( nodeOrder[targets[trans1]] <
                        nodeOrder[targets[trans2]] )
                    add_edge!( transGraph, trans1, trans2 )
                end  # if haskey( nodeOrder, targets[trans1] ) && ...
            end  # for trans1 in transNameSource, trans2 in transNameSource
        end  # for name in uniqueNames
    end  # for source in uniqueSources

    for target in uniqueTargets
        transToTarget = findall( targets .== target )

        if length( transToTarget ) < 2
            continue
        end  # if length( transToTarget ) < 2

        for trans1 in transToTarget, trans2 in transToTarget
            if haskey( transOrder, names[trans1] ) &&
                haskey( transOrder, names[trans2] ) &&
                ( transOrder[names[trans1]] <
                    transOrder[names[trans2]] )
                add_edge!( transGraph, trans1, trans2 )
            end  # if haskey( transOrder, names[trans1] ) && ...
        end  # for trans1 in transToTarget, trans2 in transToTarget

        transNames = names[transToTarget]

        for name in uniqueNames
            transNameTarget = transToTarget[transNames .== name]

            if length( transNameTarget ) < 2
                continue
            end  # if length( transNameTarget ) < 2

            for trans1 in transNameTarget, trans2 in transNameTarget
                if haskey( nodeOrder, sources[trans1] ) &&
                    haskey( nodeOrder, sources[trans2] ) &&
                    ( nodeOrder[sources[trans1]] <
                        nodeOrder[sources[trans2]] )
                    add_edge!( transGraph, trans1, trans2 )
                end  # if haskey( nodeOrder, sources[trans1] ) && ...
            end  # for trans1 in transNameTarget, trans2 in transNameTarget
        end  # for name in uniqueNames
    end  # for target in uniqueTargets

    # println( "Is the graph connected? ", is_connected( transGraph ) )
    # println( "Is the graph cyclic? ", is_cyclic( transGraph ) )

    subgraphNodes = connected_components( transGraph )
    graphRanks = zeros( vertices( transGraph ) )

    for nodeList in subgraphNodes
        subgraph = induced_subgraph( transGraph, nodeList )[1]
        generateGraphNodeRanks!( subgraph )
        graphRanks[nodeList] = get_prop.( Ref( subgraph ),
            vertices( subgraph ), :rank )
    end  # for nodeList in subgraphNodes

    setfield!.( transitions, :priority, -Int.( graphRanks ) )
    mpSim.nPriorities = maximum( graphRanks )

end  # orderTransitions!( mpSim )


@resumable function transitionProcess( sim::Simulation, transition::Transition,
    mpSim::MPsim )

    processTime = Dates.Millisecond( 0 )
    tStart = now()

    # Initialize the schedule.
    priority = transition.priority
    priorityShift = ( transition.hasPriority ? 0 : 1 ) * mpSim.nPriorities
    maxAttempts = transition.maxAttempts == 0 ?
        length( transition.probabilityList ) : transition.maxAttempts
    nAttempts = Dict{String,Int}()

    timeToWait = transition.offset

    # If an initial population snapshot is uploaded, and it contains zero-time
    #   events, don't execute zero-time transition.
    if ( timeToWait == 0 ) && !mpSim.isVirgin
        timeToWait += transition.freq
    end  # if ( timeToWait == 0 ) && ...

    while now( sim ) + timeToWait <= mpSim.simLength
        processTime += now() - tStart
        @yield( timeout( sim, timeToWait, priority = priority -
            ( transition.minFlux == 0 ? priorityShift : 0 ) ) )
        tStart = now()
        timeToWait = transition.freq

        # Identify all persons who're in the start state long enough and are not
        #   already going to transition to another state.
        eligibleIDs = getEligibleIDs( transition, nAttempts, maxAttempts,
            mpSim )
        checkedIDs = checkExtraConditions( transition, eligibleIDs, mpSim )
        updateAttemptsAndIDs!( nAttempts, maxAttempts, checkedIDs )

        # Assign a modified probability to each person.
        transitionLevels = determineTransitionLevels( transition, checkedIDs,
            nAttempts )

        # If the transition has a minimum flux, transition those IDs first, and
        #   set the priority of the rest of the transition to the proper level.
        if transition.minFlux > 0
            mandatoryIDs = determineMandatoryIDs( transition, checkedIDs,
                transitionLevels )
            performTransitions( mpSim, transition, mandatoryIDs )
            @yield( timeout( sim, 0, priority = priority - priorityShift ) )
            sourceNode = mpSim.baseNodeList[transition.sourceNode]
            filter!( id -> haskey( sourceNode.inNodeSince, id ), checkedIDs )
        end  # if transition.minFlux > 0

        transitionIDs = determineAdditionalIDs( transition, checkedIDs,
            transitionLevels, mpSim )
        performTransitions( mpSim, transition, transitionIDs )
    end  # while now( sim ) + timeToWait <= mpSim.simLength

    processTime += now() - tStart

    if mpSim.showInfo
        println( "Transition process for '", transition.name, "' took ",
            processTime.value / 1000, " seconds." )
    end  # if mpSim.showOutput

end  # transitionProcess( sim, transition, mpSim )


function getEligibleIDs( transition::Transition, nAttempts::Dict{String,Int},
    maxAttempts::Int, mpSim::MPsim )::Vector{String}

    sourceNode = mpSim.baseNodeList[transition.sourceNode]
    eligibleIDs = collect( keys( sourceNode.inNodeSince ) )

    # Check if attempts have been exhausted (important if transition doesn't
    #   fire after exhaustion of attempts).
    if maxAttempts > 0
        # The first condition means 0 attempts so far.
        filter!( id -> !haskey( nAttempts, id ) ||
            ( nAttempts[id] < maxAttempts ), eligibleIDs )
    end  # if maxAttempts > 0

    filter!( id -> now( mpSim ) > sourceNode.inNodeSince[id], eligibleIDs )

    for cond in filter( cond -> cond.attribute == "time in node",
        transition.extraConditions )
        filter!( id -> cond.operator( now( mpSim ) -
            sourceNode.inNodeSince[id], cond.value ), eligibleIDs )
    end  # for cond in filter( ...

    return eligibleIDs

end  # getEligibleIDs( transition, mpSim )


function checkExtraConditions( transition::Transition,
    eligibleIDs::Vector{String}, mpSim::MPsim )

    if isempty( eligibleIDs ) || isempty( transition.extraConditions )
        return eligibleIDs
    end  # if isempty( eligibleIDs ) || ...

    # Check extra conditions.
    queryCmd = string( "SELECT *, ageAtRecruitment + ", now( mpSim ),
        " - timeEntered age, ", now( mpSim ), " - timeEntered tenure FROM `",
        mpSim.persDBname, "` WHERE ",
        "\n    `", mpSim.idKey, "` IN ('", join( eligibleIDs, "', '" ), "')" )
    eligibleIDsState = DataFrame( DBInterface.execute( mpSim.simDB, queryCmd ) )
    checkedIDs = Vector{String}( eligibleIDsState[:, Symbol( mpSim.idKey )] )
    isIDokay = trues( length( checkedIDs ) )

    for cond in filter( cond -> cond.attribute != "time in node",
        transition.extraConditions )
        isIDokay = isIDokay .& map( ii -> cond.operator(
            eligibleIDsState[:, Symbol( cond.attribute )][ii], cond.value ),
            eachindex( isIDokay ) )
    end  # for cond in filter( ...

    return checkedIDs[isIDokay]

end  # checkExtraConditions( transition, eligibleIDs, mpSim )


function updateAttemptsAndIDs!( nAttempts::Dict{String,Int}, maxAttempts::Int,
    eligibleIDs::Vector{String} )

    # Increase number of attempts for all eligible IDs. 0 attempts means
    #   the personnel member has already executed the transition
    #   succesfully while stil being eligible for it.
    for id in eligibleIDs
        if haskey( nAttempts, id ) && ( ( maxAttempts == -1 ) ||
            ( nAttempts[id] <= maxAttempts ) ) && ( nAttempts[id] > 0 )
            nAttempts[id] += 1
        else
            nAttempts[id] = 1
        end  # if haskey( nAttempts, id ) && ...
    end  # for id in eligibleIDs

end  # updateAttemptsAndIDs!( nAttempts, eligibleIDs )


function determineTransitionLevels( transition::Transition,
    eligibleIDs::Vector{String}, nAttempts::Dict{String,Int} )

    probDict = Dict{String,Float64}()

    if isempty( eligibleIDs )
        return probDict
    end  # if isempty( eligibleIDs )

    # The probabilities of undergoing the transition for each person.
    tresholds =  transition.probabilityList[
        min.( length( transition.probabilityList ),
        getindex.( Ref( nAttempts ), eligibleIDs ) )]
    modProbs = rand( length( eligibleIDs ) ) ./ tresholds
    setindex!.( Ref( probDict ), modProbs, eligibleIDs )
    return probDict

end  # determineTransitionLevels( trans, eligibleIDs, nAttempts )


function determineMandatoryIDs( transition::Transition,
    eligibleIDs::Vector{String}, transitionLevels::Dict{String,Float64} )

    if length( eligibleIDs ) <= transition.minFlux
        return eligibleIDs
    end  # if length( eligibleIDs ) <= transition.minFlux

    # Get the min flux IDs which have the smallest value for their transLevel.
    modProbs = getindex.( Ref( transitionLevels ), eligibleIDs )
    return eligibleIDs[sortperm( modProbs )[1:(transition.minFlux)]]

end  # determineMandatoryIDs( transition, eligibleIDs, transLevels )


function determineAdditionalIDs( transition::Transition,
    eligibleIDs::Vector{String}, transitionLevels::Dict{String,Float64},
    mpSim::MPsim )

    if transition.maxFlux == transition.minFlux
        return Vector{String}()
    end  # if transition.maxFlux == transition.minFlux

    if isempty( eligibleIDs )
        return eligibleIDs
    end  # if isempty( eligibleIDs )

    # Determine the max number of personnel members left to transfer.
    maxToTransfer = transition.maxFlux == -1 ? length( eligibleIDs ) :
        transition.maxFlux - transition.minFlux
    vacancies = -1

    targetNode = transition.isOutTransition ? nothing :
        mpSim.baseNodeList[transition.targetNode]

    if !transition.isOutTransition && !transition.hasPriority &&
        ( transition.sourceNode != transition.targetNode ) &&
        ( targetNode.target >= 0 )
        vacancies = max( 0, targetNode.target -
            length( targetNode.inNodeSince ) )
    end  # if !( transition.isOutTransition ) && ...

    if vacancies >= 0
        maxToTransfer = min( maxToTransfer, vacancies )
    end  # if vacancies >= 0

    if maxToTransfer == 0
        return Vector{String}()
    end  # if maxToTransfer == 0

    modProbs = getindex.( Ref( transitionLevels ), eligibleIDs )
    hasPassed = modProbs .< 1

    # If the number of people who have passed the test is smaller than the
    #   number of people who can transfer, return the list of people who passed.
    if count( hasPassed ) <= maxToTransfer
        return eligibleIDs[hasPassed]
    end  # if sum( hasPassed ) <= maxToTransfer

    # Otherwise, only select people with highest scores.
    return eligibleIDs[sortperm( modProbs )[1:maxToTransfer]]

end  # determineAdditionalIDs( transition, eligibleIDs, transitionLevels,
     #   mpSim )


function performTransitions( mpSim::MPsim, transition::Transition,
    idList::Vector{String} )

    if isempty( idList )
        return
    end  # if isempty( idList )

    if transition.isOutTransition
        removePersons( idList, transition.sourceNode, transition.name, mpSim )
    else
        # Execute the transition for the selected personnel members and
        #   perform necessary updates.
        executeTransitions( transition, idList, mpSim )

        if transition.sourceNode !== transition.targetNode
            updateNodes( transition, idList, mpSim )
        end  # if transition.sourceNode !== transition.targetNode
    end  # if transition.isOutTrans

end  # performTransitions( mpSim, transition, idList )


function executeTransitions( transition::Transition, idList::Vector{String},
    mpSim::MPsim )

    # Get current state of the personnel members undergoing the
    #   transition.
    queryCmd = string( "SELECT * FROM `", mpSim.persDBname, "` WHERE",
        "\n    `", mpSim.idKey, "` IN ('", join( idList, "', '" ), "')" )
    idListState = DataFrame( DBInterface.execute( mpSim.simDB, queryCmd ) )
    tmpIDs = idListState[:, Symbol( mpSim.idKey )]

    # Make changes in personnel database.
    persChangesCmd = [string( "currentNode = '", transition.targetNode, "'" )]
    changedAttrVals = Dict{String,String}()

    # Target node attributes.
    if !transition.isOutTransition &&
        ( transition.sourceNode !== transition.targetNode )
        targetNode = mpSim.baseNodeList[transition.targetNode]
        changedAttrVals = deepcopy( targetNode.requirements )
    end  # if !transition.isOutTransition && ...

    # Extra changes because of the transition.
    changedAttrs = collect( keys( transition.extraChanges ) )
    setindex!.( Ref( changedAttrVals ),
        getindex.( Ref( transition.extraChanges ), changedAttrs ),
        changedAttrs )

    # Change attributes in personnel database.
    changedAttrs = collect( keys( changedAttrVals ) )
    append!( persChangesCmd, string.( "`", changedAttrs, "` = '",
        getindex.( Ref( changedAttrVals ), changedAttrs ), "'" ) )
    persChangesCmd = string( "UPDATE `", mpSim.persDBname, "`",
        "\n    SET ", join( persChangesCmd, ", " ),
        "\n    WHERE `", mpSim.idKey, "` IN ('", join( tmpIDs, "', '" ), "')" )
    DBInterface.execute( mpSim.simDB, persChangesCmd )

    # Record attribute changes in history database.
    histChangesCmd = Vector{String}()

    for attr in changedAttrs
        oldAttrValues = idListState[:, Symbol( attr )]
        changedIDs = tmpIDs[oldAttrValues .!= changedAttrVals[attr]]

        if !isempty( changedIDs )
            push!( histChangesCmd, join( string.( "\n    ('", changedIDs,
                "', '", attr, "', ", now( mpSim ), ", '",
                changedAttrVals[attr], "')" ), ", " ) )
        end  # if !isempty( changedIDs )
    end  # for attr in changedAttrs

    if !isempty( histChangesCmd )
        histChangesCmd = string( "INSERT INTO `", mpSim.histDBname, "` (`",
            mpSim.idKey, "`, attribute, timeIndex, value) VALUES",
            join( histChangesCmd, "," ) )
        DBInterface.execute( mpSim.simDB, histChangesCmd )
    end  # if !isempty( histChangesCmd )

end  # executeTransitions( trans, idList, mpSim )


function updateNodes( transition::Transition, transIDs::Vector{String},
    mpSim::MPsim )

    # Update the inNodeSince fields of the source and target nodes.
    sourceNode = mpSim.baseNodeList[transition.sourceNode]
    tName = transition.isOutTransition ? "NULL" :
        string( "'", transition.targetNode, "'" )
    delete!.( Ref( sourceNode.inNodeSince ), transIDs )

    if !transition.isOutTransition
        targetNode = mpSim.baseNodeList[transition.targetNode]
        setindex!.( Ref( targetNode.inNodeSince ), now( mpSim ), transIDs )
    end  # if !transition.isOutTransition

    # Update the database of node transitions.
    transCmd = string.( "\n    ('", transIDs, "', ", now( mpSim ), ", '",
        transition.name, "', '", transition.sourceNode, "', ", tName, ")" )
    transCmd = string( "INSERT INTO `", mpSim.transDBname, "` (`", mpSim.idKey,
        "`, timeIndex, transition, sourceNode, targetNode) VALUES",
        join( transCmd, "," ) )
        DBInterface.execute( mpSim.simDB, transCmd )

    # Update the expected time of attrition.
    updateTimeOfAttrition( transIDs, transition.targetNode, mpSim )

end  # function updateNodes( transition, transIDs, mpSim )


function updateTimeOfAttrition( transIDs::Vector{String}, targetName::String,
    mpSim::MPsim  )

    # Update the expected times to attrition.
    targetNode = mpSim.baseNodeList[targetName]
    attrition = mpSim.attritionSchemes[targetNode.attrition]
    timeOfAttrition = now( mpSim ) .+ generateTimeToAttrition( attrition,
        length( transIDs ) )
    timeOfAttrition = map( toa -> toa == +Inf ? "NULL" : toa, timeOfAttrition )

    updateCmds = string.( "UPDATE `", mpSim.persDBname, "`",
        "\n    SET expectedAttritionTime = ", timeOfAttrition,
        "\n    WHERE `", mpSim.idKey, "` IS '", transIDs, "'" )
    SQLite.execute.( Ref( mpSim.simDB ), updateCmds )

    # Check if any of the new attrition times occur before the next attrition
    #   process check.
    # newProcessCheckTime = ceil( now( mpSim ) / mpSim.attritionTimeSkip ) *
    #     mpSim.attritionTimeSkip

    # for ii in eachindex( idList )
    #     if newAttrTimeList[ii] <= newProcessCheckTime
    #         executeAttritionProcess( mpSim.sim, idList[ii],
    #             newAttrTimeList[ii], mpSim )
    #     end  # if newAttrTimeList[ii] <= newProcessCheckTime
    # end  # for ii in eachindex( idList )

end  # updateTimeOfAttrition( transIDs, targetName, mpSim )