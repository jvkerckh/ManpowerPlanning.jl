# This file defines the Transition type. This type defines a transition between
#   nodes that a personnel member can make.


export Transition
"""
This type defines a transition between two nodes that a personnel member can perform, along with all the necessary information  about the conditions of the transition.

The type contains the following fields:
* `name::string`: the name of the transition.
* `sourceNode::BaseNode`: the node that the personnel member is currently in.
* `targetNode::BaseNode`: the node that the personnel member can attain.
* `isOutTransition::Bool`: a flag to indicate if this is a transition out of the organisation. If this is `true`, the end node gets ignored.
* `freq::Float64`: the time between two checks in the transition's schedule. Default = 1.0
* `offset::Float64`: the offset of the transition's schedule with respect to the start of the simulation. Default = 0.0
* `maxAttempts::Int`: the maximum number of tries a personnel member has to undergo the transition. A value of 0 means as many as there are entries in the list of transition probabilites, and a value of -1 means there is no maximum. Default = 1
* `minFlux::Int`: the minimum number of people that must undergo the transition at the same time, if this many people are eligible. Default = 0
* `maxFlux::Int`: the maximum number of people that can undergo the transition at the same time. A value of -1 means there is no maximum. Default = Inf
* `hasPriority::Bool`: a flag indicating that this transition can override the target population of the transition's target node. If the flag is `true`, it means that if the max flux of the node is 15, and only 10 spots are available in the target node, 15 people will undergo the transition nonetheless. If the flag is `false`, 10 persons would.
* `extraConditions::Vector{Condition}`: the extra conditions that must be satisfied before the transition can take place.
* `extraChanges::Dict{String, String}`: the extra changes to attributes that happen during the transition.
* `probabilityList::Vector{Float64}`: the list of probabilities for this transition to occur.

The type has one extra field, computed at the start of the simulation:
* `priority::Int`: the priority in the simulation on which the transition gets executed. This priority will be 0 (or > 0) for transitions with the `hasPriority` flag set to `true`, and < 0 otherwise. A priority == 1 means it needs to be determined first.

Constructors:
```
Transition(
    name::String,
    sourceNode::BaseNode,
    targetNode::BaseNode )
```
This constructor creates a `Transition` object with source node `sourceNode` and target node `targetNode`.

```
Transition( name::String,
    sourceNode::BaseNode;
    freq::Real = 1.0,
    offset::Real = 0.0,
    maxAttempts::Integer = 1,
    minFlux::Integer = 0,
    maxFlux::Integer = -1,
    hasPriority::Bool = false )
```
This constructor creates a `Transition` object with source node `sourceNode` and `isOutTrransition` flag to `true`.
"""
mutable struct Transition

    name::String
    sourceNode::BaseNode
    targetNode::BaseNode
    isOutTransition::Bool
    freq::Float64
    offset::Float64
    maxAttempts::Int
    minFlux::Int
    maxFlux::Int
    hasPriority::Bool
    extraConditions::Vector{Condition}
    extraChanges::Dict{String, String}
    probabilityList::Vector{Float64}
    
    priority::Int


    # Basic constructor.
    function Transition( name::String, sourceNode::BaseNode,
        targetNode::BaseNode )::Transition

        newTrans = new()
        newTrans.name = name
        newTrans.sourceNode = sourceNode
        newTrans.targetNode = targetNode
        newTrans.isOutTransition = false
        newTrans.freq = 1.0
        newTrans.offset = 0.0
        newTrans.maxAttempts = 1
        newTrans.minFlux = 0
        newTrans.maxFlux = -1
        newTrans.hasPriority = false
        newTrans.extraConditions = Vector{Condition}()
        newTrans.extraChanges = Dict{String, String}()
        newTrans.probabilityList = [ 1.0 ]
        newTrans.priority = 1
        return newTrans

    end  # Transition( name, sourceNode, targetNode, freq, offset, maxAttempts,
         #   minFlux, maxFlux, hasPriority )

    function Transition( name::String, sourceNode::BaseNode )::Transition

        newTrans = Transition( name, sourceNode, dummyNode )
        newTrans.isOutTransition = true
        return newTrans

    end  # Transition( name, sourceNode )

end  # mutable struct Transition
