# This file defines the CompoundNode type. This type defines a node which is a 
#   collection of several base nodes.

export CompoundNode
"""
The `CompoundNode` type defines a compound node which groups a number of base nodes in a manpower simulation. This is used to generate a hierarchy of levels that personnel members can occupy. For example: assume that there are compound nodes for each combination of service branch (Land, Air, Marine, Medical) and grade category (Volunteer, Non-com, Officer). The compound nodes can then group all personnel members by service brance, so each compound node corresponds to a service branch.

The type contains the following fields:
* `name::String`: the name of the compound node.
* `stateList::Vector{String}`: the names of the (base) nodes the compound node consists of. Remark that the simulation must ensure that all the component base nodes actually exist.
* `nodeTarget::Int`: the target number of personnel members in the compound node, where no target is represented by -1. Default = -1

Constructor:
```
CompoundNode( name::String )
```
This constructor creates a `CompoundNode` object with name `name`.
"""
mutable struct CompoundNode

    name::String
    baseNodeList::Vector{String}
    nodeTarget::Int  # Necessary? It's not used in the simulation (yet).

    function CompoundNode( name::String )::CompoundNode

        newCompNode = new()
        newCompNode.name = name
        newCompNode.baseNodeList = Vector{String}()
        newCompNode.nodeTarget = -1
        return newCompNode

    end  # CompoundNode( name )

end  # mutable struct CompoundNode
