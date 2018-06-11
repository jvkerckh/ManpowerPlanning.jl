# This file defines the State type. This type defines a state that a personnel
#   member can be in.

# The State type does not require any other types.
requiredTypes = []

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( dirname( Base.source_path() ), reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end  # for reqType in requiredTypes


export State
"""
This type defines a state that a personnel member in the simulation can have. A
state in this instance is a collection of attributes and values that must be
satisfied before a personnel member is considered to be in that state.

The type contains the following fields:
* `name::String`: the name of the state.
* `requirements::Dict{String, Vector{String}}`: the attributes (key) and the
  value(s) these attributes must have (value) for the personnel member to have
  this particular state.
* `isInitial::Bool`: this flag states whether the state is an initial state or
  not.
"""
type State

    name::String
    requirements::Dict{String, Vector{String}}
    isInitial::Bool


    # Basic constructor.
    function State( name::String, isInitial::Bool = false )

        newAttr = new()
        newAttr.name = name
        newAttr.requirements = Dict{String, Vector{String}}()
        newAttr.isInitial = isInitial
        return newAttr

    end  # State( name )

end  # type State
