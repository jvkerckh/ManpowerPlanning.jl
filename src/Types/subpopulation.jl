# This file defines the Subpopulation type. This type defines an arbitrary
#   subpopulation in the system.

export Subpopulation
"""
This type defines a subpopulation in the system. Subpopulations here are based on a node, base or compound, and a number of conditions based on time, the personnel member's history, and their attributes.

The type contains the following fields:
* `name::String`: the name of the subpopulation.
* `sourceNode`: the name of the node (base or compound) from which to generate the subpopulation.
* `timeConds::Vector{MPcondition}`: the list of conditions relating to time. These are conditions on the age, the tenure, and the time since the last transition of the personnel member.
* `historyConds::Vector{MPcondition}`: the list of conditions relating to the history of personnel members. These are conditions on the node they entered the system in, on nodes they were in during their career, and transitions they did.
* `attributeConds::Vector{MPcondition}`: the list of conditions relating to the attributes of the personnel members.

Constructor
```
Subpopulation( name::String )
```
This constructor creates a `Subpopulation` object with name `name`, the entire population as its source node, and no extra conditions.
"""
mutable struct Subpopulation

    name::String
    sourceNode::String
    timeConds::Vector{MPcondition}
    historyConds::Vector{MPcondition}
    attributeConds::Vector{MPcondition}

    function Subpopulation( name::String )::Subpopulation

        newSubpop = new()
        newSubpop.name = name
        newSubpop.sourceNode = "active"
        newSubpop.timeConds = Vector{MPcondition}()
        newSubpop.historyConds = Vector{MPcondition}()
        newSubpop.attributeConds = Vector{MPcondition}()
        return newSubpop

    end  # Subpopulation( name )

end  # mutable struct Subpopulation
