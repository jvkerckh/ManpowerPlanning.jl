# This file defines the BaseNode type. This type defines a network node that a #   personnel member can be in.


export BaseNode
"""
This type defines a state that a personnel member in the simulation can have. A
state in this instance is a collection of attributes and values that must be
satisfied before a personnel member is considered to be in that state.

The type contains the following fields:
* `name::String`: the name of the state.
* `target::Int`: the target number of personnel members in this state.
* `attrition::Attrition`: The attrition scheme attached to this state.
* `inStateSince::Dict{String, Float64}`: a record of all the persons in the
  state, including the time they last entered the state.
* `requirements::Dict{String, String}`: the attributes (key) and the
value(s) these attributes must have (value) for the personnel member to have
this particular state.
"""
mutable struct BaseNode

    name::String
    target::Int
    attrition::Attrition
    requirements::Dict{String, String}

    inStateSince::Dict{String, Float64}


    # Basic constructor.
    function BaseNode( name::String, target::Integer = 0 )::BaseNode
        
        newNode = new()
        newNode.name = name
        newNode.target = max( target, -1 )
        newNode.attrition = Attrition()
        newNode.requirements = Dict{String, String}()
        newNode.inStateSince = Dict{String, Float64}()
        return newNode

    end  # BaseNode( name )

end  # type BaseNode