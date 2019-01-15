# This file defines the CompoundState type. This type defines a state which
#   is a collection of several base states.

# The CompoundState type requires no other types.
requiredTypes = []

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( typePath, reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end  # for reqType in requiredTypes


export CompoundState
"""
This type defines a compound state which groups a number of states in a manpower
simulation. This is used to generate a hierarchy of levels that personnel
members can occupy. For example: assume that there are states for each
combination of service branch (Land, Air, Marine, Medical) and grade category
(Volunteer, Non-com, Officer). The compound states can then group all personnel
members by grade category, so each compound state corresponds to a service
branch.

The type contains the following fields:
* `name::String`: the name of the compound state.
* `stateTarget::Int`: the target number of personnel members in this state.
* `stateList::Vector{String}`: the names of the (base) states the compound state
  consists of. Remark that the simulation must ensure that all the component
  base states actually exist.
"""
type CompoundState

    name::String
    stateTarget::Int
    stateList::Vector{String}

    function CompoundState( name::String )

        newCompState = new()
        newCompState.name = name
        newCompState.stateTarget = -1
        newCompState.stateList = Vector{String}()
        return newCompState

    end  # CompoundState( name )

end  # CompoundState
