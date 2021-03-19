# This file holds the definition of the functions pertaining to the
#   ManpowerSimulation type.

export  isSimulationFresh,
        isSimulationConsistent,
        verifySimulation!,
        setSimulationKey!,
        setSimulationName!,
        addSimulationAttribute!,
        removeSimulationAttribute!,
        clearSimulationAttributes!,
        setSimulationAttributes!,
        addSimulationBaseNode!,
        removeSimulationBaseNode!,
        clearSimulationBaseNodes!,
        setSimulationBaseNodes!,
        addSimulationCompoundNode!,
        removeSimulationCompoundNode!,
        clearSimulationCompoundNodes!,
        setSimulationCompoundNodes!,
        addSimulationRecruitment!,
        clearSimulationRecruitment!,
        setSimulationRecruitment!,
        addSimulationTransition!,
        clearSimulationTransitions!,
        setSimulationTransitions!,
        addSimulationTransitionTypeOrder!,
        removeSimulationTransitionTypeOrder!,
        clearSimulationTransitionTypeOrder!,
        setSimulationTransitionTypeOrder!,
        addSimulationBaseNodeOrder!,
        removeSimulationBaseNodeOrder!,
        clearSimulationBaseNodeOrder!,
        setSimulationBaseNodeOrder!,
        setSimulationRetirement!,
        removeSimulationRetirement!,
        clearSimulationRetirement!,
        addSimulationAttrition!,
        removeSimulationAttrition!,
        clearSimulationAttrition!,
        setSimulationAttrition!,
        setSimulationLength!,
        setSimulationPersonnelTarget!,
        setSimulationDatabaseName!,
        setSimulationDatabase!,
        setSimulationShowInfo!


"""
```
isSimulationFresh( mpSim::MPsim )
```
This function returns the freshness state of the configuration of the manpower simulation `mpSim`.
"""
isSimulationFresh( mpSim::MPsim )::Bool = !mpSim.isStale


"""
```
isSimulationConsistent( mpSim::MPsim )
```
This function returns the consistency state of the configuration of the manpower simulation `mpSim`. If the simulation is not fresh, it is automatically assumed to be inconsistent.
"""
isSimulationConsistent( mpSim::MPsim )::Bool =
    isSimulationFresh( mpSim ) && mpSim.isConsistent


"""
```
verifySimulation!(
    mpSim::MPsim,
    forceCheck::Bool = false )
```
This function verifies if the configuration of the manpower simulation `mpSim` is consistent, always doing a complete check if `forceCheck` is `true`. This means that:
1. all attributes and attribute values used in the base nodes,
2. all attrition schemes attached to the base nodes,
3. all source/target nodes of the transitions,
4. all attributes and attribute values used in the transitions,
5. all base nodes part of compound nodes, and
6. all target nodes of the recruitmentment schemes must be defined in the simulation.

The `isStale` flag will be set to `false`, and the `isConsistent` flag will be set to the result of the test.

If the simulation's configuration is fresh, and `forceCheck` is false, no complete check happens.

If a complete check happens, and there are issues, the function issues the appropriate warnings.

The function returns the value of the `isConsistent` flag.
"""
function verifySimulation!( mpSim::MPsim, forceCheck::Bool = false )::Bool

    if isSimulationFresh( mpSim ) && !forceCheck
        return isSimulationConsistent( mpSim )
    end  # if isSimulationFresh( mpSim ) && ...

    mpSim.isConsistent = true
    verifyBaseNodeAttributes!( mpSim )
    verifyBaseNodeAttrition!( mpSim )
    verifyTransitionBaseNodes!( mpSim )
    verifyTransitionConditions!( mpSim )
    verifyTransitionChanges!( mpSim )
    verifyCompoundNodeComponents!( mpSim )
    verifyRecruitmentTargets!( mpSim )
    mpSim.isStale = false
    return isSimulationConsistent( mpSim )

end  # verifySimulation!( mpSim, forceCheck )


"""
```
setSimulationKey!(
    mpSim::MPsim,
    idKey::KeyType = "id" )
```
This function sets the personnel identifier key in the manpower simulation `mpSim` to `idKey`. Note that the function does not perform any updates of the database.

The function returns `true`, indicating that the identifier key has been successfully set.
"""
function setSimulationKey!( mpSim::MPsim, idKey::KeyType = "id" )::Bool

    mpSim.idKey = string( idKey )
    return true

end  # setSimulationKey!( mpSim, idKey )


"""
```
setSimulationName!(
    mpSim::MPsim,
    simName::String )
```
This function sets the name of the manpower simulation `mpSim` to `simName` and adjusts the names of the results database tables.

This function returns `true`, indicating that the name of the simulation has been successfully set.
"""
function setSimulationName!( mpSim::MPsim, simName::String )::Bool

    mpSim.simName = simName
    mpSim.persDBname = string( "Personnel_", simName )
    mpSim.histDBname = string( "History_", simName )
    mpSim.transDBname = string( "Transitions_", simName )
    return true

end  # setSimulationName!( mpSim, simName )


"""
```
addSimulationAttribute!(
    mpSim::MPsim,
    attributes::Attribute... )
```
This function adds the attributes in `attributes` to the manpower simulation `mpSim`. This function makes the simulation configuration stale.

If there are multiple attributes with the same name, this function issues a warning and makes no changes.

This function returns `true` if the attributes have been successfully added, and `false` if multiple attributes had the same name.
"""
addSimulationAttribute!( mpSim::MPsim, attributes::Attribute... )::Bool =
    setSimAttributes!( mpSim, collect( attributes ), false )


"""
```
removeSimulationAttribute!(
    mpSim::MPsim,
    attributes::String... )
```
This function removes the attributes with names in `attributes` from the manpower simulation `mpSim`.

This function returns `true` if any attributes were successfully removed, and `false` if the simulation doesn't have any attributes matching the given names.
"""
function removeSimulationAttribute!( mpSim::MPsim, attributes::String... )::Bool

    if !any( attribute -> haskey( mpSim.attributeList, attribute ), attributes )
        return false
    end  # if !any( attribute -> ...

    for attribute in attributes
        delete!( mpSim.attributeList, attribute )
    end  # for attribute in attributes

    mpSim.isStale = true
    return true

end  # removeSimulationAttribute!( mpSim, attributes )


"""
```
clearSimulationAttributes!( mpSim::MPsim )
```
This function clears all the attributes from the manpower simulation `mpSim`.

This function returns `true`, indicating the attributes have been successfully cleared.
"""
function clearSimulationAttributes!( mpSim::MPsim )::Bool

    empty!( mpSim.attributeList )
    mpSim.isStale = true
    return true

end  # clearSimulationAttributes!( mpSim )


"""
```
setSimulationAttributes!(
    mpSim::MPsim,
    attributes::Vector{Attribute} )
```
This function sets the attributes of the manpower simulation `mpSim` to the list in `attributes`. This function makes the simulation configuration stale.

If there are multiple attributes with the same name, this function issues a warning and makes no changes.

This function returns `true` if the attributes have been successfully set, and `false` if multiple attributes had the same name.
"""
setSimulationAttributes!( mpSim::MPsim, attributes::Vector{Attribute} )::Bool =
    setSimAttributes!( mpSim, attributes, true )


"""
```
addSimulationBaseNode!(
    mpSim::MPsim,
    nodes::BaseNode... )
```
This function adds the base nodes in `nodes` to the manpower simulation `mpSim`. This function makes the simulation configuration stale.

If there are multiple nodes with the same name, this function issues a warning and makes no changes.

This function returns `true` if the base nodes have been successfully added, and `false` if multiple nodes had the same name.
"""
addSimulationBaseNode!( mpSim::MPsim, nodes::BaseNode... )::Bool =
    setSimBaseNodes!( mpSim, collect( nodes ), false )


"""
```
removeSimulationBaseNode!(
    mpSim::MPsim,
    nodes::String... )
```
This function removes the base nodes with names in `nodes` from the manpower simulation `mpSim`.

This function returns `true` if any nodes were successfully removed, and `false` if the simulation doesn't have any base nodes matching the given names.
"""
function removeSimulationBaseNode!( mpSim::MPsim, nodes::String... )::Bool

    if !any( node -> haskey( mpSim.baseNodeList, node ), nodes )
        return false
    end  # if !any( node -> ...

    for node in nodes
        delete!( mpSim.baseNodeList, node )
    end  # for node in nodes

    mpSim.isStale = true
    return true

end  # removeSimulationBaseNode!( mpSim, nodes )


"""
```
clearSimulationBaseNodes!( mpSim::MPsim )
```
This function clears all the base nodes from the manpower simulation `mpSim`.

This function returns `true`, indicating the base nodes have been successfully cleared.
"""
function clearSimulationBaseNodes!( mpSim::MPsim )::Bool

    empty!( mpSim.baseNodeList )
    mpSim.isStale = true
    return true

end  # clearSimulationBaseNodes!( mpSim )


"""
```
setSimulationBaseNodes!(
    mpSim::MPsim,
    nodes::Vector{BaseNode} )
```
This function sets the base nodes of the manpower simulation `mpSim` to the list in `nodes`. This function makes the simulation configuration stale.

If there are multiple base nodes with the same name, this function issues a warning and makes no changes.

This function returns `true` if the base nodes have been successfully set, and `false` if multiple nodes had the same name.
"""
setSimulationBaseNodes!( mpSim::MPsim, nodes::Vector{BaseNode} )::Bool =
    setSimBaseNodes!( mpSim, nodes, true )


"""
```
addSimulationCompoundNode!(
    mpSim::MPsim,
    nodes::CompoundNode... )
```
This function adds the compound nodes in `nodes` to the manpower simulation `mpSim`. This function makes the simulation configuration stale.

If there are multiple nodes with the same name, this function issues a warning and makes no changes.

This function returns `true` if the compound nodes have been successfully added, and `false` if multiple nodes had the same name.
"""
function addSimulationCompoundNode!( mpSim::MPsim,
    nodes::CompoundNode... )::Bool

    if isempty( nodes )
        return false
    end  # if isempty( nodes )

    return setSimCompoundNodes!( mpSim, collect( nodes ), false )

end  # addSimulationCompoundNode!( mpSim, nodes )

"""
```
addSimulationCompoundNode!(
    mpSim::MPsim,
    nodeName::String,
    nodeTarget::Integer,
    baseNodeList::String... )
```
This function adds a compound node with name `nodeName` to the manpower simulation `mpSim`. This compound node has a target population of `nodeTarget`, and consists of the base nodes in `baseNodeList`.

The function returns `true`, indicating that the compound node has been successfully added or replaced.
"""
function addSimulationCompoundNode!( mpSim::MPsim, nodeName::String, nodeTarget::Integer, baseNodeList::String... )::Bool

    newCompoundNode = CompoundNode( nodeName )
    addCompoundNodeComponent!( newCompoundNode, baseNodeList... )
    setCompoundNodeTarget!( newCompoundNode, nodeTarget )
    return addSimulationCompoundNode!( mpSim, newCompoundNode )

end  # addSimulationCompoundNode!( mpSim, nodeName, nodeTarget, baseNodeList )


"""
```
removeSimulationCompoundNode!(
    mpSim::MPsim,
    nodes::String... )
```
This function removes the compound nodes with names in `nodes` from the manpower simulation `mpSim`.

This function returns `true` if any nodes were successfully removed, and `false` if the simulation doesn't have any compound nodes matching the given names.
"""
function removeSimulationCompoundNode!( mpSim::MPsim, nodes::String... )::Bool

    if !any( node -> haskey( mpSim.compoundNodeList, node ), nodes )
        return false
    end  # if !any( node -> ...

    for node in nodes
        delete!( mpSim.compoundNodeList, node )
    end  # for node in nodes

    mpSim.isStale = true
    return true

end  # removeSimulationCompoundNode!( mpSim, nodes )


"""
```
clearSimulationCompoundNodes!( mpSim::MPsim )
```
This function clears all the compound nodes from the manpower simulation `mpSim`.

This function returns `true`, indicating the compound nodes have been successfully cleared.
"""
function clearSimulationCompoundNodes!( mpSim::MPsim )::Bool

    empty!( mpSim.compoundNodeList )
    mpSim.isStale = true
    return true

end  # clearSimulationCompoundNodes!( mpSim )


"""
```
setSimulationCompoundNodes!(
    mpSim::MPsim,
    nodes::Vector{CompoundNode} )
```
This function sets the compound nodes of the manpower simulation `mpSim` to the list in `nodes`. This function makes the simulation configuration stale.

If there are multiple compound nodes with the same name, this function issues a warning and makes no changes.

This function returns `true` if the compound nodes have been successfully set, and `false` if multiple nodes had the same name.
"""
setSimulationCompoundNodes!( mpSim::MPsim, nodes::Vector{CompoundNode} )::Bool =
    setSimCompoundNodes!( mpSim, nodes, true )


"""
```
addSimulationRecruitment!(
    mpSim::MPsim,
    recruitmentList::Recruitment... )
```
This function adds the recruitment schemes in `recruitmentList` to the manpower simulation `mpSim`. Recruitment schemes with a target node left blank, or set to `"dummy"` will not be added. This function makes the simulation configuration stale.

This function returns `true` if any recruitment schemes have been successfully added, and `false` if all recruitment schemes had a blank or dummy target node.
"""
addSimulationRecruitment!( mpSim::MPsim,
    recruitmentList::Recruitment... )::Bool = setSimRecruitment!( mpSim,
    collect( recruitmentList ), false )


"""
```
clearSimulationRecruitment!( mpSim )
```
This function clears all recruitment schemes from the manpower simulation `mpSim`. Recruitment schemes with a target node left blank, or set to `"dummy"` will not be added. This function makes the simulation configuration stale.

This function returns `true`, indicating the recruitment schemes have been successfully cleared.
"""
function clearSimulationRecruitment!( mpSim::MPsim )::Bool

    empty!( mpSim.recruitmentByName )
    empty!( mpSim.recruitmentByTarget )
    mpSim.isStale = true
    return true

end  # clearSimulationRecruitment!( mpSim::MPsim )


"""
```
setSimulationRecruitment!(
    mpSim::MPsim,
    recruitmentList::Vector{Recruitment} )
```
This function sets the recruitment schemes of the manpower simulation `mpSim` to the list in `nodes`. This function makes the simulation configuration stale.

This function returns `true` if any recruitment schemes have been successfully added, and `false` if all recruitment schemes had a blank or dummy target node.
"""
setSimulationRecruitment!( mpSim::MPsim,
    recruitmentList::Vector{Recruitment} )::Bool = setSimRecruitment!( mpSim, recruitmentList, true )


"""
```
addSimulationTransition!(
    mpSim::MPsim,
    transitions::Transition... )
```
This function adds the transitions in `transitions` to the manpower simulation `mpSim`. Transitions with a source or target node left blank, or set to `"dummy"` will not be added (only source is checked for OUT transitions). This function makes the simulation configuration stale.

This function returns `true` if any transitions have been successfully added, and `false` if all transitions had a blank or dummy source or target node.
"""
addSimulationTransition!( mpSim::MPsim, transitions::Transition... )::Bool =
    setSimTransitions!( mpSim, collect( transitions ), false )


"""
```
clearSimulationTransitions!( mpSim::MPsim )
```
This function clears all the transitions from the manpower simulation `mpSim`.

The function returns `true`, indicating that the transitions have been successfully cleared.
"""
function clearSimulationTransitions!( mpSim::MPsim )::Bool

    empty!( mpSim.transitionsByName )
    empty!( mpSim.transitionsBySource )
    mpSim.transitionsByTarget = Dict( "OUT" => Vector{Transition}() )
    mpSim.isStale = true
    return true

end  # clearSimulationTransitions!( mpSim )


"""
```
setSimulationTransitions!(
    mpSim::MPsim,
    transitions::Vector{Transition} )
```
This function sets the transitions of the manpower simulation `mpSim` to the list of transitions in `transitions`. Transitions with a source or target node left blank, or set to `"dummy"` will not be added (only source is checked for OUT transitions). This function makes the simulation configuration stale.

This function returns `true` if any transitions have been successfully set, and `false` if all transitions had a blank or dummy source or target node.
"""
setSimulationTransitions!( mpSim::MPsim,
    transitions::Vector{Transition} )::Bool =
    setSimTransitions!( mpSim, collect( transitions ), true )


"""
```
addSimulationTransitionTypeOrder!(
    mpSim::MPsim,
    transOrder::Dict{String,Int} )
```
This function adds the transition type priorities in the list `transOrder` to the manpower simulation `mpSim`. The transition type priorities are given as a dictionary with the transition type as key, and the priority as the key's value, where lower numbers mean transitions of that type are handled first. Transition types that already have a priority, have their priority overwritten.

This function returns `true` if any transition type has a priority added or changed, and `false` otherwise.
"""
addSimulationTransitionTypeOrder!( mpSim::MPsim,
    transOrder::Dict{String,Int} )::Bool = setSimTransitionTypeOrder!( mpSim,
    transOrder, false )

"""
```
addSimulationTransitionTypeOrder!(
    mpSim::MPsim,
    transOrder::Tuple{String,Int}... )
```
This function adds the transition type priorities in the list `transOrder` to the manpower simulation `mpSim`. The transition type priorities are given as a list of transition type/priority, where lower numbers for the priority mean transitions of that type are handled first. Transition types that already have a priority, have their priority overwritten.

If this list contains multiple entries for the same transition type, this function issues a warning and makes no changes.

This function returns `true` if any transition type has a priority added or changed, and `false` otherwise.
"""
function addSimulationTransitionTypeOrder!( mpSim::MPsim,
    transOrder::Tuple{String,Int}... )::Bool

    transTypes = map( orderPair -> orderPair[1], transOrder )

    if length( transTypes ) != length( unique( transTypes ) )
        @warn "Duplicate entries in the transition type/priority list, not making any changes."
        return false
    end  # if length( transTypes ) != length( unique( transTypes ) )

    transOrderDict = Dict{String,Int}()

    for orderPair in transOrder
        transOrderDict[orderPair[1]] = orderPair[2]
    end  # for orderPair in transOrder

    return setSimTransitionTypeOrder!( mpSim, transOrderDict, false )

end  # addSimulationTransitionTypeOrder!( mpSim, transOrder )

"""
```
addSimulationTransitionTypeOrder!(
    mpSim::MPsim,
    transType::String,
    transPrio::Int )
```
This function adds the transition type `transType` to the manpower simulation `mpSim`, giving it priority `transPrio`, where a lower number for the priority means transitions of that type are handled earlier. If the transition type already has a priority, its priority gets overwritten.


This function returns `true`, indicating the transition type's priority has been added/changed successfully.
"""
addSimulationTransitionTypeOrder!( mpSim::MPsim, transType::String,
    transPrio::Int )::Bool = setSimTransitionTypeOrder!( mpSim,
    Dict( transType => transPrio ), false )


"""
```
removeSimulationTransitionTypeOrder!(
    mpSim::MPsim,
    transTypes::String... )
```
This function removes the transition type priorities in the manpower simulation `mpSim` for all transitions in `transTypes`.

This function returns `true` if any transition type priorities have been removes, and `false` otherwise.
"""
function removeSimulationTransitionTypeOrder!( mpSim::MPsim,
    transTypes::String... )::Bool

    if !any( haskey.( Ref( mpSim.transitionTypeOrder ), transTypes ) )
        return false
    end  # if !any( haskey.( Ref( mpSim.transitionTypeOrder ), transTypes ) )

    delete!.( Ref( mpSim.transitionTypeOrder ), transTypes )
    return true

end  # removeSimulationTransitionTypeOrder!( mpSim, transTypes )


"""
```
clearSimulationTransitionTypeOrder!( mpSim::MPsim )
```
This function clears all transition type priorities from the manpower simulation `mpSim`.

This function returns `true`, indicating the transition type priorities have been successfully cleared.
"""
function clearSimulationTransitionTypeOrder!( mpSim::MPsim )::Bool

    empty!( mpSim.transitionTypeOrder )
    return true

end  # clearSimulationTransitionTypeOrder!( mpSim )


"""
```
setSimulationTransitionTypeOrder!(
    mpSim::MPsim,
    transOrder::Dict{String,Int} )
```
This function sets the transition type priorities in the list `transOrder` to the manpower simulation `mpSim`. The transition type priorities are given as a dictionary with the transition type as key, and the priority as the key's value, where lower numbers mean transitions of that type are handled first.

This function returns `true` if the transition type priorities have been set successfully, and `false` otherwise.
"""
setSimulationTransitionTypeOrder!( mpSim::MPsim,
    transOrder::Dict{String,Int} )::Bool = setSimTransitionTypeOrder!( mpSim,
    transOrder, true )

"""
```
setSimulationTransitionTypeOrder!(
    mpSim::MPsim,
    transOrder::Tuple{String,Int}... )
```
This function sets the transition type priorities in the list `transOrder` to the manpower simulation `mpSim`. The transition type priorities are given as a list of transition type/priority, where lower numbers for the priority mean transitions of that type are handled first.

If this list contains multiple entries for the same transition type, this function issues a warning and makes no changes.

This function returns `true` if the transition type priorities have been set successfully, and `false` otherwise.
"""
function setSimulationTransitionTypeOrder!( mpSim::MPsim,
    transOrder::Tuple{String,Int}... )::Bool

    transTypes = map( orderPair -> orderPair[1], transOrder )

    if length( transTypes ) != length( unique( transTypes ) )
        @warn "Duplicate entries in the transition type/priority list, not making any changes."
        return false
    end  # if length( transTypes ) != length( unique( transTypes ) )

    transOrderDict = Dict{String,Int}()

    for orderPair in transOrder
        transOrderDict[orderPair[1]] = orderPair[2]
    end  # for orderPair in transOrder

    return setSimTransitionTypeOrder!( mpSim, transOrderDict, true )

end  # setSimulationTransitionTypeOrder!( mpSim, transOrder )

"""
```
setSimulationTransitionTypeOrder!(
    mpSim::MPsim,
    transTypes::Vector{String},
    transPrios::Vector{Int} )
```
This function sets the transition type priorities in the lists `transTypes` and `transPrios` to the manpower simulation `mpSim`. The vector `transTypes` has the transition types, and the vector `transPrios` has the corresponding priorities, where lower numbers for the priority mean transitions of that type are handled first.

If the vectors are of unequal length, the function issues a warning and makes no changes.

If this list contains multiple entries for the same transition type, the function issues a warning and makes no changes.

This function returns `true` if the transition type priorities have been set successfully, and `false` otherwise.
"""
function setSimulationTransitionTypeOrder!( mpSim::MPsim,
    transTypes::Vector{String}, transPrios::Vector{Int} )::Bool

    if length( transTypes ) != length( transPrios )
        @warn "Mismatched lengths of vector of transition types and priorities, not making any changes."
        return false
    end  # if length( transTypes ) != length( transPrios )

    if length( transTypes ) != length( unique( transTypes ) )
        @warn "Duplicate entries in the transition type/priority list, not making any changes."
        return false
    end  # if length( transTypes ) != length( unique( transTypes ) )

    transOrderDict = Dict{String,Int}()

    for ii in eachindex( transTypes )
        transOrderDict[transTypes[ii]] = transPrios[ii]
    end  # for ii in eachindex( transTypes )

    return setSimTransitionTypeOrder!( mpSim, transOrderDict, true )

end  # setSimulationTransitionTypeOrder!( mpSim, transTypes, transPrios )


"""
```
addSimulationBaseNodeOrder!(
    mpSim::MPsim,
    nodeOrder::Dict{String,Int} )
```
This function adds the base node priorities in the list `nodeOrder` to the manpower simulation `mpSim`. The base node priorities are given as a dictionary with the base node names as key, and the priority as the key's value, where lower numbers mean transitions to/from that node are handled first. Base nodes that already have a priority, have their priority overwritten.

This function returns `true` if any base node has a priority added or changed, and `false` otherwise.
"""
addSimulationBaseNodeOrder!( mpSim::MPsim,
    nodeOrder::Dict{String,Int} )::Bool = setSimBaseNodeOrder!( mpSim,
    nodeOrder, false )

"""
```
addSimulationBaseNodeOrder!(
    mpSim::MPsim,
    nodeOrder::Tuple{String,Int}... )
```
This function adds the base node priorities in the list `nodeOrder` to the manpower simulation `mpSim`. The base node priorities are given as a list of base node/priority, where lower numbers for the priority mean transitions to/from that node are handled first. Base nodes that already have a priority, have their priority overwritten.

If this list contains multiple entries for the same base node, this function issues a warning and makes no changes.

This function returns `true` if any base node has a priority added or changed, and `false` otherwise.
"""
function addSimulationBaseNodeOrder!( mpSim::MPsim,
    nodeOrder::Tuple{String,Int}... )::Bool

    baseNodes = map( orderPair -> orderPair[1], nodeOrder )

    if length( baseNodes ) != length( unique( baseNodes ) )
        @warn "Duplicate entries in the base node/priority list, not making any changes."
        return false
    end  # if length( baseNodes ) != length( unique( baseNodes ) )

    nodeOrderDict = Dict{String,Int}()

    for orderPair in nodeOrder
        nodeOrderDict[orderPair[1]] = orderPair[2]
    end  # for orderPair in nodeOrder

    return setSimBaseNodeOrder!( mpSim, nodeOrderDict, false )

end  # addSimulationBaseNodeOrder!( mpSim, nodeOrder )

"""
```
addSimulationBaseNodeOrder!(
    mpSim::MPsim,
    baseNode::String,
    nodePrio::Int )
```
This function adds the base node `baseNode` to the manpower simulation `mpSim`, giving it priority `nodePrio`, where a lower number for the priority means transitions to/from that node are handled earlier. If the base node already has a priority, its priority gets overwritten.


This function returns `true`, indicating the transition type's priority has been added/changed successfully.
"""
addSimulationBaseNodeOrder!( mpSim::MPsim, baseNode::String,
    nodePrio::Int )::Bool = setSimBaseNodeOrder!( mpSim,
    Dict( baseNode => nodePrio ), false )


"""
```
removeSimulationBaseNodeOrder!(
    mpSim::MPsim,
    baseNodes::String... )
```
This function removes the base node priorities in the manpower simulation `mpSim` for all nodes in `baseNodes`.

This function returns `true` if any base node priorities have been removes, and `false` otherwise.
"""
function removeSimulationBaseNodeOrder!( mpSim::MPsim,
    baseNodes::String... )::Bool

    if !any( haskey.( Ref( mpSim.baseNodeOrder ), baseNodes ) )
        return false
    end  # if !any( haskey.( Ref( mpSim.baseNodeOrder ), baseNodes ) )

    delete!.( Ref( mpSim.baseNodeOrder ), baseNodes )
    return true

end  # removeSimulationBaseNodeOrder!( mpSim, baseNodes )


"""
```
clearSimulationBaseNodeOrder!( mpSim::MPsim )
```
This function clears all base node priorities from the manpower simulation `mpSim`.

This function returns `true`, indicating the base node priorities have been successfully cleared.
"""
function clearSimulationBaseNodeOrder!( mpSim::MPsim )::Bool

    empty!( mpSim.baseNodeOrder )
    return true

end  # clearSimulationBaseNodeOrder!( mpSim )


"""
```
setSimulationBaseNodeOrder!(
    mpSim::MPsim,
    nodeOrder::Dict{String,Int} )
```
This function sets the transition type priorities in the list `nodeOrder` to the manpower simulation `mpSim`. The transition type priorities are given as a dictionary with the transition type as key, and the priority as the key's value, where lower numbers mean transitions of that type are handled first.

This function returns `true` if the transition type priorities have been set successfully, and `false` otherwise.
"""
setSimulationBaseNodeOrder!( mpSim::MPsim,
    nodeOrder::Dict{String,Int} )::Bool = setSimBaseNodeOrder!( mpSim,
    nodeOrder, true )

"""
```
setSimulationBaseNodeOrder!(
    mpSim::MPsim,
    nodeOrder::Tuple{String,Int}... )
```
This function sets the base node priorities in the list `nodeOrder` to the manpower simulation `mpSim`. The base node priorities are given as a list of base node/priority, where lower numbers for the priority mean transitions to/from that node are handled first.

If this list contains multiple entries for the same base node, this function issues a warning and makes no changes.

This function returns `true` if the base node priorities have been set successfully, and `false` otherwise.
"""
function setSimulationBaseNodeOrder!( mpSim::MPsim,
    nodeOrder::Tuple{String,Int}... )::Bool

    baseNodes = map( orderPair -> orderPair[1], nodeOrder )

    if length( baseNodes ) != length( unique( baseNodes ) )
        @warn "Duplicate entries in the transition type/priority list, not making any changes."
        return false
    end  # if length( baseNodes ) != length( unique( baseNodes ) )

    nodeOrderDict = Dict{String,Int}()

    for orderPair in nodeOrder
        nodeOrderDict[orderPair[1]] = orderPair[2]
    end  # for orderPair in nodeOrder

    return setSimBaseNodeOrder!( mpSim, nodeOrderDict, true )

end  # setSimulationBaseNodeOrder!( mpSim, nodeOrder )

"""
```
setSimulationBaseNodeOrder!(
    mpSim::MPsim,
    baseNodes::Vector{String},
    nodePrios::Vector{Int} )
```
This function sets the base node priorities in the lists `baseNodes` and `nodePrios` to the manpower simulation `mpSim`. The vector `baseNodes` has the base nodes, and the vector `nodePrios` has the corresponding priorities, where lower numbers for the priority mean transitions to/from that node are handled first.

If the vectors are of unequal length, the function issues a warning and makes no changes.

If this list contains multiple entries for the same base node, the function issues a warning and makes no changes.

This function returns `true` if the base node priorities have been set successfully, and `false` otherwise.
"""
function setSimulationBaseNodeOrder!( mpSim::MPsim,
    baseNodes::Vector{String}, nodePrios::Vector{Int} )::Bool

    if length( baseNodes ) != length( nodePrios )
        @warn "Mismatched lengths of vector of base nodes and priorities, not making any changes."
        return false
    end  # if length( baseNodes ) != length( nodePrios )

    if length( baseNodes ) != length( unique( baseNodes ) )
        @warn "Duplicate entries in the base node/priority list, not making any changes."
        return false
    end  # if length( baseNodes ) != length( unique( baseNodes ) )

    transOrderDict = Dict{String,Int}()

    for ii in eachindex( baseNodes )
        transOrderDict[baseNodes[ii]] = nodePrios[ii]
    end  # for ii in eachindex( baseNodes )

    return setSimBaseNodeOrder!( mpSim, transOrderDict, true )

end  # setSimulationBaseNodeOrder!( mpSim, baseNodes, nodePrios )


"""
```
setSimulationRetirement!(
    mpSim::MPsim,
    retirement::Retirement,
    node::String = "default";
    name::String = "retirement",
    overwrite::Bool = true )
```
This function sets the retirement scheme of the base node `node` in the manpower simulation to `retirement`, giving it the name `name`. If the node is `"default"`, this becomes the fallback retirement scheme for any personnel members who do not have a specific retirement schedule for their node. If the flag `overwrite` is `true`, this function also clears the existing retirement schedule(s) for the node.

This function returns `true` if the retirement schedule has been successfully set, or `false` if the target node did not exist, or the given retirement schedule is a non-retirement (no max age or tenure defined).
"""
function setSimulationRetirement!( mpSim::MPsim, retirement::Retirement, node::String = "default"; name::String = "retirement", overwrite::Bool = true )::Bool

    if ( lowercase( node ) != "default" ) && !haskey( mpSim.baseNodeList, node )
        return false
    end  # if ( lowercase( node ) != "default" ) && ...
    
    # If the node is "default", change the fallback retirement scheme.
    if lowercase( node ) == "default"
        mpSim.retirement = deepcopy( retirement )
        return true
    end  # if lowercase( node ) == "default"

    # No change if there's no real retirement happening.
    if ( retirement.maxCareerLength == 0.0 ) &&
        ( retirement.retirementAge == 0.0 )
        return false
    end  # if ( retirement.maxCareerLength == 0.0 ) && ...

    # Find transitions which already cover retirement from this node and remove 
    #   them.
    if overwrite
        removeSimulationRetirement!( mpSim, node )
    end  # if overwrite

    # Both retirement conditions apply.
    if !retirement.isEither
        transition = Transition( name, node )
        setTransitionSchedule!( transition, retirement.freq, retirement.offset )
        
        if retirement.maxCareerLength > 0.0
            addTransitionCondition!( transition,
                MPcondition( "tenure", >=, retirement.maxCareerLength ) )
        end  # if retirement.maxCareerLength > 0.0

        if retirement.retirementAge > 0.0
            addTransitionCondition!( transition,
                MPcondition( "age", >=, retirement.retirementAge ) )
        end  # if retirement.retirementAge > 0.0

        addSimulationTransition!( mpSim, transition )
        return true
    end  # if !retirement.isEither
    
    # Either retirement condition applies.
    if retirement.maxCareerLength > 0.0
        transition = Transition( name, node )
        setTransitionSchedule!( transition, retirement.freq, retirement.offset )
        addTransitionCondition!( transition,
            MPcondition( "tenure", >=, retirement.maxCareerLength ) )
        addSimulationTransition!( mpSim, transition )
    end  # if retirement.maxCareerLength > 0.0

    if retirement.retirementAge > 0.0
        transition = Transition( name, node )
        setTransitionSchedule!( transition, retirement.freq, retirement.offset )
        addTransitionCondition!( transition,
            MPcondition( "age", >=, retirement.retirementAge ) )
        addSimulationTransition!( mpSim, transition )
    end  # if retirement.retirementAge > 0.0

    return true

end  # setSimulationRetirement!( mpSim, retirement, node, name, overwrite )


"""
```
removeSimulationRetirement!(
    mpSim::MPsim,
    node::String )
```
This function removes all OUT transitions from the base node `node` from the manpower simulation `mpSim`.

The function returns `true` if the retirement schemes have been successfully removed, and `false` if the node didn't exist in the simulation.
"""
function removeSimulationRetirement!( mpSim::MPsim, node::String )::Bool

    if !haskey( mpSim.baseNodeList, node )
        return false
    end  # if haskey( mpSim.baseNodeList, node )

    if haskey( mpSim.transitionsBySource, node )
        for transition in filter( transition -> transition.isOutTransition,
            mpSim.transitionsBySource[node] )
            nameInd = findfirst( map( trans -> transition === trans,
                mpSim.transitionsByName[transition.name] ) )
            sourceInd = findfirst( map( trans -> transition === trans,
                mpSim.transitionsBySource[node] ) )
            targetInd = findfirst( map( trans -> transition === trans,
                mpSim.transitionsByTarget["OUT"] ) )

            deleteat!( mpSim.transitionsByName[transition.name], nameInd )
            deleteat!( mpSim.transitionsBySource[node], sourceInd )
            deleteat!( mpSim.transitionsByTarget["OUT"], targetInd )
        end  # for transition in filter( ... )
    end  # if haskey( mpSim.transitionsBySource, node )

    return true

end  # removeSimulationRetirement!( mpSim, node )


"""
```
clearSimulationRetirement!( mpSim::MPsim )
```
This function clears all OUT transitions from the manpower simulation `mpSim`, and sets the default retirement scheme to "no retirement".

This function returns `true`, indicating that all OUT transitions have been successfully cleared.
"""
function clearSimulationRetirement!( mpSim::MPsim )::Bool

    for transition in mpSim.transitionsByTarget["OUT"]
        nameInd = findfirst( map( trans -> transition === trans,
            mpSim.transitionsByName[transition.name] ) )
        sourceInd = findfirst( map( trans -> transition === trans,
            mpSim.transitionsBySource[transition.sourceNode] ) )
        
        deleteat!( mpSim.transitionsByName[transition.name], nameInd )
        deleteat!( mpSim.transitionsBySource[transition.sourceNode],
            sourceInd )
    end  # for transition in mpSim.transitionsByTarget["OUT"]

    empty!( mpSim.transitionsByTarget["OUT"] )
    mpSim.retirement = Retirement()
    return true

end  # function clearSimulationRetirement!( mpSim )


"""
```
addSimulationAttrition!(
    mpSim::MPsim,
    attritionList::Attrition... )
```
This function adds the attrition schemes in `attritionList` to the manpower simulation `mpSim`.

If there are multiple attrition schemes with the same name, the function issues a warning and makes no changes. For the default attrition scheme, `""` and any capitalisation of `"default"` are considered the same name.

This function returns `true` if the attrition schemes have been successfully added, and `false` if multiple attrition schemes have the same name.
"""
addSimulationAttrition!( mpSim::MPsim, attritionList::Attrition... )::Bool =
    setSimAttrition!( mpSim, collect( attritionList ), false )


"""
```
removeSimulationAttrition!(
    mpSim::MPsim,
    attritionList::String... )
```
This function removes the attrition schemes with names in `attritionList` form the manpower simulation `mpSim`. For the default attrition scheme, `""` and any capitalisation of `"default"` are considered the same name, and the default attrition scheme is set to a no-attrition scheme (flat zero attrition rate).

This function returns `true` if any attrition scheme has been successfully removed, and `false` if no names in the list referred to attrition schemes in the simulation.
"""
function removeSimulationAttrition!( mpSim::MPsim,
    attritionList::String... )::Bool

    tmpAttritionNames = collect( attritionList )
    tmpAttritionNames[map( attrition -> lowercase( attrition ) ∈
        ["", "default"], tmpAttritionNames )] .= "default"
    
    if !any( haskey.( Ref( mpSim.attritionSchemes ), tmpAttritionNames ) )
        return false
    end  # if !any( ... ) )

    delete!.( Ref( mpSim.attritionSchemes ), tmpAttritionNames )

    if "default" ∈ tmpAttritionNames
        mpSim.attritionSchemes["default"] = Attrition()
    end  # if "default" ∈ tmpAttritionNames

    mpSim.isStale = true
    return true

end  # removeSimulationAttrition!( mpSim, attritionList )


"""
```
clearSimulationAttrition!( mpSim::MPsim )
```
This function clears all attrition schemes from the manpower simulation `mpSim`, and sets the default attrition scheme to a no-attrition scheme (flat zero attrition rate).

This funciton returns `true`, indicatin ght at the attrition schemes have been successfully cleared.
"""
function clearSimulationAttrition!( mpSim::MPsim )::Bool

    mpSim.attritionSchemes = Dict( "default" => Attrition() )
    mpSim.isStale = true
    return true

end  # clearSimulationAttrition!( mpSim )


"""
```
setSimulationAttrition!(
    mpSim::MPsim,
    attritionList::Vector{Attrition} )
```
This function set the attrition schemes of the manpower simulation `mpSim` to the ones in `attritionList`.

If there are multiple attrition schemes with the same name, the function issues a warning and makes no changes. For the default attrition scheme, `""` and any capitalisation of `"default"` are considered the same name.

This function returns `true` if the attrition schemes have been successfully set, and `false` if multiple attrition schemes have the same name.
"""
setSimulationAttrition!( mpSim::MPsim,
    attritionList::Vector{Attrition} )::Bool = setSimAttrition!( mpSim,
    attritionList, true )


"""
```
setSimulationLength!(
    mpSim::MPsim,
    simLength::Real )
```
This function sets the length of the simulation `mpSim` to `simLength`.

If a length < 0 is entered, the function issues a warning and makes no changes.

This function returns `true` if the simulation length is successfully set, and `false` if the entered length is < 0.
"""
function setSimulationLength!( mpSim::MPsim, simLength::Real )::Bool

    if simLength < 0
        @warn "Simulation length must be ⩾ 0, not making any changes."
        return false
    end

    mpSim.simLength = simLength
    return true

end  # setSimulationLength!( mpSim, simLength )


"""
```
setSimulationPersonnelTarget!(
    mpSim::MPsim,
    personnelTarget::Integer )
```
This function sets the personnel target of the manpower simulation `mpSim` to `personnelTarget`. Any value ⩽ 0 is treated as "no target".

This function returns `true`, indicating that the personnel target is successfully set.
"""
function setSimulationPersonnelTarget!( mpSim::MPsim,
    personnelTarget::Integer )::Bool

    mpSim.personnelTarget = max( 0, personnelTarget )
    return true

end  # setSimulationPersonnelTarget!( mpSim, personnelTarget )


"""
```
setSimulationDatabaseName!(
    mpSim::MPsim,
    dbName::String = "" )
```
This function sets the name of the results database of the manpower simulation `mpSim` to `dbName`, adding the extension `.sqlite` if needed. If the name is the empty string `""`, the database will be stored in memory instead.

This function returns `true`, indicating that the database name is successfully set.
"""
function setSimulationDatabaseName!( mpSim::MPsim, dbName::String = "" )::Bool

    mpSim.dbName = endswith( dbName, ".sqlite" ) || isempty( dbName ) ? dbName :
        string( dbName, ".sqlite" )
    mpSim.reportFolder = dirname( dbName )
    return true

end  # setSimulationDatabaseName!( mpSim, dbName )


"""
```
setSimulationDatabase!(
    mpSim::MPsim,
    dbName::String = "" )
```
This function sets the results database of the manpower simulation `mpSim` to a database with name `dbName`, adding the extension `.sqlite` if needed. If the name is the empty string `""`, the database will be stored in memory instead.

If the database is an existing database, the function also checks if it's a new or old style database, and will give a deprecation warning in the latter case.

This function returns `true`, indicating that the database is successfully set.
"""
function setSimulationDatabase!( mpSim::MPsim, dbName::String="" )::Bool
    setSimulationDatabaseName!( mpSim, dbName )
    dbpath = dirname(mpSim.dbName)
    !ispath(dbpath) && mkpath(dbpath)
    mpSim.simDB = SQLite.DB(mpSim.dbName)
    validateDatabaseAge!(mpSim)
    true
end  # setSimulationDatabase!( mpSim, dbName )


"""
```
setShowInfo!(
    mpSim::MPsim,
    showInfo::Bool )
```
This function sets the flag controlling whether timing and other information about the manpower simulation (`mpSim`) run is displayed to `showInfo`.

This function returns `true`, indicating that the flag is successfully set.
"""
function setSimulationShowInfo!( mpSim::MPsim, showInfo::Bool )::Bool

    mpSim.showInfo = showInfo
    return true

end  # setSimulationShowInfo!( mpSim, showInfo )


"""
```
Dates.now( mpSim::MPsim )
```
This function returns the current simulation time in the manpower simulation `mpSim`.
"""
Dates.now( mpSim::MPsim ) = min( now( mpSim.sim ), mpSim.simLength )


include( joinpath( privPath, "manpowersimulation.jl" ) )
include( joinpath( simPath, "manpowersimulation.jl" ) )