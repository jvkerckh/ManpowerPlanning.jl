# This file holds the definition of the functions pertaining to the
#   Subpopulation type.

export  setSubpopulationName!,
        setSubpopulationSourceNode!,
        addSubpopulationCondition!,
        clearSubpopulationConditions!,
        setSubpopulationConditions!


"""
```
setSubpopulationName!(
    subpopulation::Subpopulation,
    name::String )
```
This function sets the name of the subpopulation `subpopulation` to `name`.

The function returns `true`, indicating the name is successfully set.
"""
function setSubpopulationName!( subpopulation::Subpopulation,
    name::String )::Bool

    subpopulation.name = name
    return true

end  # setSubpopulationName!( subpopulation, name )


"""
```
setSubpopulationSourceNode!(
    subpopulation::Subpopulation,
    sourceNode::String )
```
This function sets the source node of the subpopulation `subpopulation` to `node`. The source node can be any base node, compound node, or the entire population. The latter is entered by `""` or `"active"`.

The function returns `true`, indicating the source node is successfully set.
"""
function setSubpopulationSourceNode!( subpopulation::Subpopulation,
    sourceNode::String )::Bool

    subpopulation.sourceNode = lowercase( sourceNode ) ∈ [ "active", "" ] ?
        "active" : sourceNode
    return true

end  # setSubpopulationSourceNode!( subpopulation, sourceNode )


"""
```
addSubpopulationCondition!(
    subpopulation::Subpopulation,
    conditions::MPcondition... )
```
This function adds the conditions in `conditions` to the subpopulation `subpopulation`.

Several other conditions are also permitted, relating to time and/or the history of the personnel members:
* `"age"`: the age of the personnel members,
* `"tenure"`: the tenure of the personnel members,
* `"time in node"`: the time in the personnel members' current base node,
* `"had transition"`: the personnel member did a transition with the given name,
* `"started as"`: the personnel member entered the system in the given base node,
* `"was"`: the personnel member was in the given base node at any point.

Note that this function performs no checks on whether the conditions are feasible, contradict each other or contradict the source node of the subpopulation.

This function returns `true`, indicating the conditions are successfully added.
"""
function addSubpopulationCondition!( subpopulation::Subpopulation,
    conditions::MPcondition... )::Bool

    for cond in conditions
        tmpCond = MPcondition( lowercase( cond.attribute ), cond.operator,
            cond.value )  # MPcondition is immutable!

        if tmpCond.attribute ∈ timeAttributes
            push!( subpopulation.timeConds, tmpCond )
        elseif tmpCond.attribute ∈ histAttributes
            push!( subpopulation.historyConds, tmpCond )
        else
            push!( subpopulation.attributeConds, deepcopy( cond ) )
        end  # if tmpCond.attribute ∈ timeAttributes
    end  # for cond in conditions

    return true

end  # addSubpopulationCondition!( subpopulation, conditions )


"""
```
clearSubpopulationConditions!( subpopulation::Subpopulation )
```
This function clears all conditions from the subpopulation `subpopulation`.

The function returns `true`, indicating the conditions are successfully cleared.
"""
function clearSubpopulationConditions!( subpopulation::Subpopulation )::Bool

    empty!( subpopulation.timeConds )
    empty!( subpopulation.historyConds )
    empty!( subpopulation.attributeConds )
    return true

end  # clearSubpopulationConditions!( subpopulation::Subpopulation )


"""
```
setSubpopulationConditions!(
    subpopulation::Subpopulation,
    conditions::Vector{MPcondition} )
```
This function sets the conditions in `conditions` to the subpopulation `subpopulation`.

Several other conditions are also permitted, relating to time and/or the history of the personnel members:
* `"age"`: the age of the personnel members,
* `"tenure"`: the tenure of the personnel members,
* `"time in node"`: the time in the personnel members' current base node,
* `"had transition"`: the personnel member did a transition with the given name,
* `"started as"`: the personnel member entered the system in the given base node,
* `"was"`: the personnel member was in the given base node at any point.

Note that this function performs no checks on whether the conditions are feasible, contradict each other or contradict the source node of the subpopulation.

This function returns `true`, indicating the conditions are successfully set.
"""
function setSubpopulationConditions!( subpopulation::Subpopulation,
    conditions::Vector{MPcondition} )::Bool

    clearSubpopulationConditions!( subpopulation )
    return addSubpopulationCondition!( subpopulation, conditions... )

end  # setSubpopulationConditions!( subpopulation, conditions )


function Base.show( io::IO, subpopulation::Subpopulation )

    print( io, "Subpopulation: ", subpopulation.name )
    print( io, "\n  Root node: ", subpopulation.sourceNode )

    if !all( [ isempty( subpopulation.timeConds ),
        isempty( subpopulation.historyConds ),
        isempty( subpopulation.attributeConds ) ] )
        print( io, "\n  Conditions\n    ", join( vcat( subpopulation.timeConds,
            subpopulation.historyConds, subpopulation.attributeConds ),
            "\n    " ) )
    end  # if !all( [ ... ] )

    return

end  # show( io, state )