# This file defines the BaseNode type. This type defines a network node that a #   personnel member can be in.


export BaseNode
"""
The `BaseNode` type defines a node that a personnel member in the simulation can have. A node in this instance is a collection of attributes and values that must be satisfied before a personnel member is considered to be in that node.

The type contains the following fields:
* `name::String`: the name of the node.
* `target::Int`: the target number of personnel members in this node. Default = 0
* `attrition::String`: The name of the attrition scheme attached to this node. Default = "default"
* `requirements::Dict{String, String}`: the attributes (key) and the value(s) these attributes must have (value) for the personnel member to have this particular node.

The type also contains one other field, used only during the simulation:
* `inStateSince::Dict{String, Float64}`: a record of all the persons in the   node, including the time they last entered the node.

Constructor:
```
BaseNode( name::String )
```
This constructor generates a `BaseNode` with name `name` and population target `target`. If the entered population target is < 0, this will be interpreted as no target.
"""
mutable struct BaseNode

    name::String
    target::Int
    attrition::String
    requirements::Dict{String, String}

    inStateSince::Dict{String, Float64}


    # Basic constructor.
    function BaseNode( name::String )::BaseNode
        
        newNode = new()
        newNode.name = name
        newNode.target = 0
        newNode.attrition = "default"
        newNode.requirements = Dict{String, String}()

        newNode.inStateSince = Dict{String, Float64}()
        return newNode

    end  # BaseNode( name )

end  # type BaseNode