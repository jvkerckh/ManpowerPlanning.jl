# This file defines the State type. This type defines a state that a personnel
#   member can be in.

# The State type requires the Attrition type.
requiredTypes = [ "attrition" ]

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
* `stateTarget::Int`: the target number of personnel members in this state.
* `attrScheme::Attrition`: The attrition scheme attached to this state.
* `inStateSince::Dict{String, Float64}`: a record of all the persons in the
  state, including the time they last entered the state.
* `isLockedForTransition::Dict{String, Bool}`: a record of all the persons ready
  to undergo a transition.
"""
type State

    name::String
    requirements::Dict{String, Vector{String}}
    isInitial::Bool
    stateTarget::Int
    attrScheme::Attrition
    inStateSince::Dict{String, Float64}
    isLockedForTransition::Dict{String, Bool}


    # Basic constructor.
    function State( name::String, isInitial::Bool = false )

        newState = new()
        newState.name = name
        newState.requirements = Dict{String, Vector{String}}()
        newState.isInitial = isInitial
        newState.stateTarget = 0
        newState.attrScheme = Attrition()
        newState.inStateSince = Dict{String, Float64}()
        newState.isLockedForTransition = Dict{String, Bool}()
        return newState

    end  # State( name, isInitial )

end  # type State
