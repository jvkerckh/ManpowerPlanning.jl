# This file defines the Subpopulation type. This type defines an arbitrary
#   subpopulation in the system.

# The Subpopulation type requires the Condition type.
requiredTypes = [ "condition" ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( typePath, reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end  # for reqType in requiredTypes


export Subpopulation
"""
This type defines a subpopulation in the system. Subpopulations here are based
on a node, base or compound, and a number of conditions based on time, the
personnel member's history, and their attributes.

The type contains the following fields:
* `name::String`: the name of the subpopulation.
* `sourceNodeName`: the name of the node (base or compound) from which to
   generate the subpopulation.
* `timeConds::Vector{Condition}`: the list of conditions relating to time. These
  are conditions on the age, the tenure, and the time since the last transition
  of the personnel member.
* `histConds::Vector{Condition}`: the list of conditions relating to the history
  of personnel members. These are conditions on the node they entered the system
  in, on nodes they were in during their career, and transitions they did.
* `attribConds::Vector{Condition}`: the list of conditions relating to the
  attributes of the personnel members.
"""
type Subpopulation

    name::String
    sourceNodeName::String
    timeConds::Vector{Condition}
    histConds::Vector{Condition}
    attribConds::Vector{Condition}

    function Subpopulation( name::String,
        sourceNodeName::String )::Subpopulation

        newSubpop = new()
        newSubpop.name = name
        newSubpop.sourceNodeName = sourceNodeName
        newSubpop.timeConds = Vector{Condition}()
        newSubpop.histConds = Vector{Condition}()
        newSubpop.attribConds = Vector{Condition}()
        return newSubpop

    end  # Subpopulation( name, sourceNodeName )

end  # type Subpopulation
