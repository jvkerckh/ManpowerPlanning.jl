function verifyBaseNodeAttributes!( mpSim::MPsim )

    missingAttributes = Dict{String, Vector{String}}()
    missingValues = Vector{NTuple{3, String}}()

    # Verify the consistency of the attributes in each base node.
    for nodeName in keys( mpSim.baseNodeList )
        node = mpSim.baseNodeList[ nodeName ]

        for attribute in keys( node.requirements )
            value = node.requirements[ attribute ]
            if haskey( missingAttributes, attribute )
                push!( missingAttributes[ attribute ], nodeName )
            elseif !haskey( mpSim.attributeList, attribute )
                missingAttributes[ attribute ] = [ nodeName ]
            elseif !isAttributeValuePossible( mpSim.attributeList[ attribute ],
                value )
                push!( missingValues, (nodeName, attribute, value) )
            end  # if haskey( missingAttributes, attribute )
        end  # for attribute in node.requirements
    end  # for nodeName in keys( mpSim.baseNodeList )

    # Report missing attributes in base node requirements.
    warnString = map( collect( keys( missingAttributes ) ) ) do attribute
        return string( "Unknown attribute '", attribute, "' in base node(s) '",
            join( missingAttributes[ attribute ], "', '", "', and '" ), "'" )
    end  # map( ... ) do attribute

    if !isempty( warnString )
        @warn join( warnString, "\n" )
        mpSim.isConsistent = false
    end  # if !isempty( warnString )

    # Report missing values in base node requirements.
    warnString = map( missingValues ) do missingVal
        return string( "Unknown value '", missingVal[ 3 ], "' for attribute '",
            missingVal[ 2 ], "' in base node '", missingVal[ 1 ], "'" )
    end  # map( missingValues ) do missingVal

    if !isempty( warnString )
        @warn join( warnString, "\n" )
        mpSim.isConsistent = false
    end  # if !isempty( warnString )

end  # verifyBaseNodeAttributes!( mpSim )


function verifyBaseNodeAttrition!( mpSim::MPsim )

    # Verify consistency of attrition schemes in base nodes.
    missingAttrition = Dict{String, Vector{String}}()

    for nodeName in keys( mpSim.baseNodeList )
        node = mpSim.baseNodeList[ nodeName ]
        attrition = node.attrition

        if !haskey( mpSim.attritionSchemes, attrition )
            if haskey( missingAttrition, attrition )
                push!( missingAttrition[ attrition ], node.name )
            else
                missingAttrition[ attrition ] = [ node.name ]
            end  # if haskey( missingAttrition, attrition )
        end  # if !haskey( mpSim.attritionSchemes, attrition )
    end  # for node in mpSim.baseNodeList

    # Report missing attrition schemes in base nodes.
    warnString = map( collect( keys( missingAttrition ) ) ) do attrition
        return string( "Unknown attrition scheme '", attrition,
            "' in base nodes '", join( missingAttrition[ attrition ], "', '",
            "', and '" ), "'" )
    end  # map( ... ) do attrition

    if !isempty( warnString )
        @warn join( warnString, "\n" )
        mpSim.isConsistent = false
    end  # if !isempty( warnString )    

end  # verifyBaseNodeAttrition!( mpSim )


function verifyTransitionBaseNodes!( mpSim::MPsim )

    # Verify consistency of base nodes in each transition.
    missingSourceNodes = Dict{String, Vector{String}}()
    missingTargetNodes = Dict{String, Vector{String}}()

    for node in keys( mpSim.transitionsBySource )
        if !haskey( mpSim.baseNodeList, node )
            missingSourceNodes[ node ] = map( transition -> transition.name,
                mpSim.transitionsBySource[ node ] )
        end  # if !haskey( mpSim.baseNodeList, node )
    end  # for node in keys( mpSim.transitionsBySource )

    for node in keys( mpSim.transitionsByTarget )
        if ( node != "OUT" ) && !haskey( mpSim.baseNodeList, node )
            missingTargetNodes[ node ] = map( transition -> transition.name,
                mpSim.transitionsByTarget[ node ] )
        end  # if !haskey( mpSim.baseNodeList, node )
    end  # for node in keys( mpSim.transitionsByTarget )

    # Report missing source/target nodes in compound node composition.
    warnString = map( collect( keys( missingSourceNodes ) ) ) do node
        return string( "Unknown source node '", node, "' in transition(s) '",
            join( missingSourceNodes[ node ], "', '", "', and '" ), "'" )
    end  # warnString = map( ... ) do node

    if !isempty( warnString )
        @warn join( warnString, "\n" )
        mpSim.isConsistent = false
    end  # if !isempty( warnString )

    warnString = map( collect( keys( missingTargetNodes ) ) ) do node
        return string( "Unknown target node '", node, "' in transition(s) '",
            join( missingTargetNodes[ node ], "', '", "', and '" ), "'" )
    end  # warnString = map( ... ) do node

    if !isempty( warnString )
        @warn join( warnString, "\n" )
        mpSim.isConsistent = false
    end  # if !isempty( warnString )

end  # verifyTransitionBaseNodes!( mpSim )


function verifyTransitionConditions!( mpSim::MPsim )

    # Verify consistency of attributes in each transition.
    missingAttributes = Dict{String, Vector{String}}()
    missingValues = Vector{NTuple{3, String}}()

    for transitionName in keys( mpSim.transitionsByName ),
        transition in mpSim.transitionsByName[ transitionName ],
        condition in transition.extraConditions

        attribute = condition.attribute
        isTime = lowercase( attribute ) ∈ timeAttributes

        if !isTime && !haskey( mpSim.attributeList, attribute )
            if haskey( missingAttributes, attribute )
                push!( missingAttributes[ attribute ], transitionName )
            else
                missingAttributes[ attribute ] = [ transitionName ]
            end  # if haskey( missingAttributes, attribute )
        elseif !isTime
            attribute = mpSim.attributeList[ attribute ]

            if ( condition.operator == Base.:(==) ) &&
                !isAttributeValuePossible( attribute, condition.value )
                !haskey( mpSim.attributeList, condition.value )
                push!( missingValues,
                    (transitionName, attribute.name, condition.value) )
            elseif condition.operator == Base.:∈
                for value in filter(
                    val -> !isAttributeValuePossible( attribute, val ),
                    condition.value )
                    push!( missingValues, (transitionName, attribute.name,
                        value) )
                end  # for value in filter( ... )
            end  # if ( condition.operator == Base.:(==) ) && ...
        end  # if !isTime && ...
    end  # for transitionName in mpSim.transitionsByName, ...
    
    # Report missing attributes in base node requirements.
    warnString = map( collect( keys( missingAttributes ) ) ) do attribute
        return string( "Unknown attribute '", attribute, "' in base node(s) '",
            join( missingAttributes[ attribute ], "', '", "', and '" ), "'" )
    end  # map( ... ) do attribute

    if !isempty( warnString )
        @warn join( warnString, "\n" )
        mpSim.isConsistent = false
    end  # if !isempty( warnString )

    # Report missing values in base node requirements.
    warnString = map( missingValues ) do missingVal
        return string( "Unknown value '", missingVal[ 3 ], "' for attribute '",
            missingVal[ 2 ], "' in base node '", missingVal[ 1 ], "'" )
    end  # map( missingValues ) do missingVal

    if !isempty( warnString )
        @warn join( warnString, "\n" )
        mpSim.isConsistent = false
    end  # if !isempty( warnString )    

end  # verifyTransitionConditions!( mpSim )


function verifyCompoundNodeComponents!( mpSim::MPsim )

    # Verify consistency of base nodes in each compound node.
    missingNodes = Dict{String, Vector{String}}()

    for nodeName in keys( mpSim.compoundNodeList )
        node = mpSim.compoundNodeList[ nodeName ]

        for baseNode in node.baseNodeList
            if haskey( missingNodes, baseNode )
                push!( missingNodes[ baseNode ], nodeName )
            elseif !haskey( mpSim.baseNodeList, baseNode )
                missingNodes[ baseNode ] = [ nodeName ]
            end  # if haskey( missingNodes, baseNode )
        end  # for baseNode in node.baseNodeList
    end  # for nodeName in keys( mpSim.compoundNodeList )

    # Report missing base nodes in compound node composition.
    warnString = map( collect( keys( missingNodes ) ) ) do node
        return string( "Unknown base node '", node, "' in compound node(s) '",
            join( missingNodes[ node ], "', '", "', and '" ), "'" )
    end  # warnString = map( ... ) do node

    if !isempty( warnString )
        @warn join( warnString, "\n" )
        mpSim.isConsistent = false
    end  # if !isempty( warnString )    

end  # verifyCompoundNodeComponents!( mpSim )


function verifyRecruitmentTargets!( mpSim::MPsim )

    # Verify target nodes of recruitment schemes.
    missingNodes = Dict{String, Vector{String}}()

    for nodeName in keys( mpSim.recruitmentByTarget )
        if !haskey( mpSim.baseNodeList, nodeName )
            missingNodes[ nodeName ] = map( recruitment -> recruitment.name,
                mpSim.recruitmentByTarget[ nodeName ] )
        end  # if !haskey( mpSim.baseNodeList, nodeName )
    end  # for nodeName in keys( mpSim.recruitmentByTarget )

    # Report missing target nodes of recruitment schemes.
    warnString = map( collect( keys( missingNodes ) ) ) do node
        return string( "Unknown target node '", node,
            "' in recruitment scheme(s) '",
            join( missingNodes[ node ], "', '", "', and '" ), "'" )
    end  # map( ... ) do node

    if !isempty( warnString )
        @warn join( warnString, "\n" )
        mpSim.isConsistent = false
    end  # if !isempty( warnString )

end  # verifyRecruitmentTargets!( mpSim )


function setSimAttributes!( mpSim::MPsim, attributes::Vector{Attribute},
    wipeConfig::Bool )

    attributeNames = getfield.( attributes, :name )

    if length( attributeNames ) != length( unique( attributeNames ) )
        @warn "Multiple attributes with same name in attribute list, not making any changes."
        return false
    end  # if length( attributeNames ) != length( unique( attributeNames ) )

    if wipeConfig
        clearSimulationAttributes!( mpSim )
    end  # wipeConfig

    for attribute in attributes
        mpSim.attributeList[ attribute.name ] = attribute
    end  # for attribute in attributes

    mpSim.isStale = true
    return true

end  # setSimAttributes!( mpSim, attributes, wipeConfig )


function setSimBaseNodes!( mpSim::MPsim, nodes::Vector{BaseNode},
    wipeConfig::Bool )

    nodeNames = getfield.( nodes, :name )

    if length( nodeNames ) != length( unique( nodeNames ) )
        @warn "Multiple nodes with same name in base node list, not making any changes."
        return false
    end  # if length( nodeNames ) != length( unique( nodeNames ) )

    if wipeConfig
        clearSimulationBaseNodes!( mpSim )
    end  # if wipeConfig

    for node in nodes
        mpSim.baseNodeList[ node.name ] = node
    end  # for node in nodes

    mpSim.isStale = true
    return true

end  # setSimBaseNodes!( mpSim, nodes, wipeConfig )


function setSimCompoundNodes!( mpSim::MPsim, nodes::Vector{CompoundNode},
    wipeConfig::Bool )

    nodeNames = getfield.( nodes, :name )

    if length( nodeNames ) != length( unique( nodeNames ) )
        @warn "Multiple nodes with same name in base node list, not making any changes."
        return false
    end  # if length( nodeNames ) != length( unique( nodeNames ) )

    if wipeConfig
        clearSimulationCompoundNodes!( mpSim )
    end  # if wipeConfig

    for node in nodes
        mpSim.compoundNodeList[ node.name ] = node
    end  # for node in nodes

    mpSim.isStale = true
    return true

end  # setSimCompoundNodes!( mpSim, nodes, wipeConfig )


function setSimRecruitment!( mpSim::MPsim, recruitmentList::Vector{Recruitment},
    wipeConfig::Bool )

    tmpRecruitment = filter( recruitment ->
        recruitment.targetNode ∉ [ "", "dummy" ], recruitmentList )

    if isempty( tmpRecruitment )
        return false
    end  # if isempty( tmpRecruitment )

    if wipeConfig
        clearSimulationRecruitment!( mpSim )
    end  # if wipeConfig

    # Add the recruitment schemes to the appropriate lists.
    for recruitment in tmpRecruitment
        if haskey( mpSim.recruitmentByName, recruitment.name )
            push!( mpSim.recruitmentByName[ recruitment.name ], recruitment )
        else
            mpSim.recruitmentByName[ recruitment.name ] = [ recruitment ]
        end  # if haskey( mpSim.recruitmentByName, recruitment.name )

        if haskey( mpSim.recruitmentByTarget, recruitment.targetNode )
            push!( mpSim.recruitmentByTarget[ recruitment.targetNode ],
                recruitment )
        else
            mpSim.recruitmentByTarget[ recruitment.targetNode ] =
                [ recruitment ]
        end  # if haskey( mpSim.recruitmentByTarget, recruitment.targetNode )
    end  # for recruitment in tmpRecruitment

    mpSim.isStale = true
    return true

end  # setSimRecruitment!( mpSim, recruitmentList, wipeConfig )


function setSimTransitions!( mpSim::MPsim, transitions::Vector{Transition},
    wipeConfig::Bool )

    tmpTransitions = filter( transitions ) do transition
        return ( lowercase( transition.sourceNode ) ∉ [ "", "dummy" ] ) &&
            ( transition.isOutTransition ? true :
            lowercase( transition.targetNode ) ∉ [ "", "dummy" ] )
    end  # filter( transitions ) do transition

    if isempty( tmpTransitions )
        return false
    end  # if isempty( tmpTransitions )

    # Add the transitions to the appropriate lists.
    for transition in tmpTransitions
        if haskey( mpSim.transitionsByName, transition.name )
            push!( mpSim.transitionsByName[ transition.name ], transition )
        else
            mpSim.transitionsByName[ transition.name ] = [ transition ]
        end  # if haskey( mpSim.transitionsByName, transitions.name )

        if haskey( mpSim.transitionsBySource, transition.sourceNode )
            push!( mpSim.transitionsBySource[ transition.sourceNode ],
                transition )
        else
            mpSim.transitionsBySource[ transition.sourceNode ] = [ transition ]
        end  # if haskey( mpSim.transitionsBySource, transitions.sourceNode )

        if transition.isOutTransition
            push!( mpSim.transitionsByTarget[ "OUT" ], transition )
        elseif haskey( mpSim.transitionsByTarget, transition.targetNode )
            push!( mpSim.transitionsByTarget[ transition.targetNode ],
                transition )
        else
            mpSim.transitionsByTarget[ transition.targetNode ] =
                [ transition ]
        end  # if transition.isOutTransition
    end  # for transition in tmpTransitions

    mpSim.isStale = true
    return true

end  # setSimTransitions!( mpSim, transitions, wipeConfig )


function setSimAttrition!( mpSim::MPsim, attritionList::Vector{Attrition},
    wipeConfig::Bool )

    attritionNames = getfield.( attritionList, :name )
    nDefaults = count( map( attrition -> lowercase( attrition ) ∈
        [ "", "default" ], attritionNames ) )

    if ( length( attritionNames ) != length( unique( attritionNames ) ) ) ||
        ( nDefaults > 1 )
        @warn "Multiple attrition schemes with same name in attribute list, not making any changes."
        return false
    end  # if length( attritionNames ) != length( unique( attritionNames ) )

    if wipeConfig
        clearSimulationAttrition!( mpSim )
    end  # if wipeConfig

    for attrition in attritionList
        attritionName = lowercase( attrition.name ) ∈ [ "", "default" ] ?
            "default" : attrition.name
        mpSim.attritionSchemes[ attritionName ] = deepcopy( attrition )
    end  # for attrition in attritionList

    mpSim.isStale = true
    return true

end  # setSimAttrition!( mpSim, attritionList, wipeConfig )


function validateDatabaseAge!( mpSim::MPsim )

    if mpSim.persDBname ∈ SQLite.tables( mpSim.simDB )[ :, :name ]
        mpSim.isOldDB = "startState" ∈ SQLite.columns( mpSim.simDB,
            mpSim.transDBname )[ :, :name ]
    else
        mpSim.isOldDB = false
    end  # mpSim.persDBname ∈ SQLite.tables( mpSim.simDB )[ :, :name ]

    if mpSim.isOldDB
        @warn "Old style simulation results database. This style will be deprecated in a future version."
    end  # if mpSim.isOldDB

    mpSim.sNode = mpSim.isOldDB ? "startState" : "sourceNode"
    mpSim.tNode = mpSim.isOldDB ? "endState" : "targetNode"

end  # validateDatabaseAge!( mpSim )