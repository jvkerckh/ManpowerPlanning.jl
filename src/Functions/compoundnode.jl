# This file holds the definition of the functions pertaining to the CompoundNode
#   type.

export  setCompoundNodeName!,
        addCompoundNodeComponent!,
        removeCompoundNodeComponent!,
        clearCompoundNodeComponents!,
        setCompoundNodeComponents!,
        setCompoundNodeTarget!


"""
```
setCompoundNodeName!(
    compoundNode::CompoundNode,
    name::String )
```
This function sets the name of the compound node `compoundNode` to `name`.

This function returns `nothing`.
"""
function setCompoundNodeName!( compoundNode::CompoundNode, name::String )::Bool

    compoundNode.name = name
    return true

end  # setCompoundNodeName!( compoundNodName, name )


"""
```
addCompoundNodeComponent!(
    compoundNode::CompoundNode,
    nodeList::String... )
```
This function adds the nodes in `nodeList` to the list of nodes composing the compound state `compoundNode`.

This function returns `true` if any base nodes have been successfully added to the component node list of the compound node, and `false` if all the base nodes were already in the component list.
"""
function addCompoundNodeComponent!( compoundNode::CompoundNode,
    nodeList::String... )::Bool

    tmpNodeList = filter( node -> node ∉ compoundNode.baseNodeList,
        collect( nodeList ) )

    if isempty( tmpNodeList )
        return false
    end  # if isempty( tmpNodeList )

    tmpNodeList = unique( tmpNodeList )
    append!( compoundNode.baseNodeList, tmpNodeList )
    return true

end  # addCompoundNodeComponent!( compoundNode, nodeList )


"""
```
removeCompoundNodeComponent!(
    compoundNode::CompoundNode,
    nodeList::String... )
```
This function removes the nodes in `nodeList` from the list of nodes composing the compound nodes `compoundNode`.

This function returns `true` if any ndoes have been successfully removed from the list, and `false` if none of the nodes in the entered list are component nodes of the compound nodes.
"""
function removeCompoundNodeComponent!( compoundNode::CompoundNode,
    nodeList::String... )::Bool

    nodeFlags = map( node -> node ∈ nodeList, compoundNode.baseNodeList )

    if !any( nodeFlags )
        return false
    end  # if !any( nodeFlags )

    deleteat!( compoundNode.baseNodeList, nodeFlags )
    return true

end  # removeCompoundNodeComponent!( compoundNode, nodeList )


"""
```
clearCompoundNodeComponents!( compoundNode::CompoundNode )
```
This function clears the list of nodes composing the compound node `compoundNode`.

This function returns `true`, indicating the list of component nodes of the compound node has been successfully cleared.
"""
function clearCompoundNodeComponents!( compoundNode::CompoundNode )::Bool

    empty!( compoundNode.baseNodeList )
    return true

end  # clearCompoundNodeComponents!( compoundNode )


"""
```
setCompoundNodeComponents!(
    compoundNode::CompoundNode,
    nodeList::Vector{String} )
```
This function sets the nodes in `nodeList` as the list of nodes composing the compound state `compoundNode`.

This function returns `true`, indicating the component nodes have been successfully set.
"""
function setCompoundNodeComponents!( compoundNode::CompoundNode,
    nodeList::Vector{String} )::Bool

    compoundNode.baseNodeList = unique( nodeList )
    return true

end  # setCompoundNodeComponents!( compoundNode, nodeList )

"""
```
setCompoundNodeComponents!(
    compoundNode::CompoundNode,
    nodeList::String... )
```
This function sets the nodes in `nodeList` as the list of nodes composing the compound state `compoundNode`.

This function returns `true`, indicating the component nodes have been successfully set.
"""
setCompoundNodeComponents!( compoundNode::CompoundNode,
    nodeList::String... )::Bool = setCompoundNodeComponents!( compoundNode,
    collect( nodeList ) )


"""
```
setCompoundNodeTarget!(
    compoundNode::CompoundNode,
    target::Integer )
```
This function sets the target number of personnel members in compound state
`compoundNode` to `target`. If the number is less than zero, it means there's no
target.

This function returns `nothing`.
"""
function setCompoundNodeTarget!( compoundNode::CompoundNode,
    target::Integer )::Bool

    compoundNode.nodeTarget = max( target, -1 )
    return true

end  # setCompoundNodeTarget!( compoundNode, target )
    


function Base.show( io::IO, compoundNode::CompoundNode )::Nothing

    print( io, "Compound node: ", compoundNode.name )

    if isempty( compoundNode.baseNodeList )
        print( io, "\n  No component base nodes in compound node." )
    else
        print( io, "\n  Component nodes: ",
            join( compoundNode.baseNodeList, ", " ) )
    end  # if isempty( compoundNode.baseNodeList )

    if compoundNode.nodeTarget >= 0
        print( io, "\n  Personnel target: ", compoundNode.nodeTarget,
            " personnel members" )
    else
        print( io, "\n  No personnel target for compound node." )
    end  # if compoundNode.nodeTarget >= 0

    return

end  # show( io, compoundState )
