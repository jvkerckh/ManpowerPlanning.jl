# This file holds the definition of the functions pertaining to the Transition
#   type.

export  setTransitionName!,
        setTransitionNode!,
        setTransitionIsOut!,
        setTransitionSchedule!,
        setTransitionMaxAttempts!,
        setTransitionFluxLimits!,
        setTransitionHasPriority!,
        addTransitionCondition!,
        clearTransitionConditions!,
        setTransitionConditions!,
        addTransitionAttributeChange!,
        clearTransitionAttributeChanges!,
        setTransitionAttributeChanges!,
        setTransitionProbabilities!


"""
```
setTransitionName!(
    transition::Transition,
    name::String )
```
This function sets the name of the transition `transition` to `name`.

This function returns `true`, indication that the transition's name has been successfully set.
"""
function setTransitionName!( transition::Transition, name::String )::Bool

    transition.name = name
    return true

end  # setTransitionName!( trans, name )


"""
```
setTransitionNode!(
    transition::Transition,
    node::BaseNode,
    isTargetNode::Bool = false )
```
This function sets one of the nodes (source/target) of the transition `transitoin` to `node`. If `istargetNode` is `true`, the target node will be set, otherwise the source state will be set. Note that the target node will be ignored if the transition's `isOutTransition` flag is set to `true`.

This function returns `true`, indicating that the node has been successfully set.
"""
function setTransitionNode!( transition::Transition, node::BaseNode,
    isTargetNode::Bool = false )::Bool

    if isTargetNode
        transition.targetNode = node
    else
        transition.sourceNode = node
    end  # if isTargetNode

    return true

end  # setTransitionNode!( transition, node, isTargetNode )


"""
```
setTransitionIsOut!(
    transition::Transition,
    isOutTransition::Bool )
```
This function sets the `isOutTransition` flag of the transition `transition` to `isOutTransition`.

This function returns `true`, indicating the flag has been successfully set.
"""
function setTransitionIsOut!( transition::Transition,
    isOutTransition::Bool )::Bool

    transition.isOutTransition = isOutTransition
    return true

end  # setTransitionIsOut!( transition, isOutTransition )


"""
```
setTransitionSchedule!(
    transition::Transition,
    freq::Real,
    offset::Real = 0.0 )
```
This function sets the schedule of the transition `transition`. This transition will be checked every `freq` time units with an offset of `offset` with respect to the start of the simulation.

If the entered period is ⩽ 0, the function issues a warning and will make no changes.

This function returns `true` if the schedule has been successfully set, and `false` if the entered period was negative.
"""
function setTransitionSchedule!( transition::Transition, freq::Real,
    offset::Real = 0.0 )::Bool

    if freq <= 0.0
        @warn "Time between two transition checks must be > 0.0, not making any changes."
        return false
    end  # if freq <= 0.0

    transition.freq = freq
    transition.offset = offset % freq + ( offset < 0.0 ? freq : 0.0 )
    return true

end  # setTransitionSchedule!( transition, freq, offset )


"""
```
setTransitionMaxAttempts!(
    transition::Transition,
    maxAttempts::Integer )
```
This function sets the maximum number of times a personnel member may attempt the transition `transition` to `maxAttempts`.
    
A value < 0 for `maxAttempts`  means that there is no restriction on number of attempts, and 0 means there are as many attempts as entries in the vector of probabilities.

This function returns `true`, indicating that the maximum number of attempts at the transition is successfully set.
"""
function setTransitionMaxAttempts!( transition::Transition,
    maxAttempts::Integer )::Bool

    transition.maxAttempts = max( maxAttempts, -1 )
    return true

end  # setTransitionMaxAttempts!( transition, maxAttempts )


"""
```
setTransitionFluxLimits!(
    transition::Transition,
    minFlux::Integer,
    maxFlux::Integer )
```
This function sets the limits of the flux of the transition `transition` to the range `minFlux` to `maxFlux`.
    
A negative value for the maximum flux means that there is no upper bound on the flux.

If the minimum flux is larger than the maximum flux, the function gives a warning and doesn't make any changes.

This function returns `true` if the limits on the transition's flux have been successfully set, and `false` if the entered minimum flux was larger than the maximum flux.
"""
function setTransitionFluxLimits!( transition::Transition, minFlux::Integer, maxFlux::Integer )::Bool

    if ( maxFlux >= 0 ) && ( minFlux > maxFlux )
        @warn "The minimum flux of the transition cannot be higher than the maximum flux, not making any changes."
        return false
    end  # if ( maxFlux >= 0 ) && ...

    transition.minFlux = max( minFlux, 0 )
    transition.maxFlux = max( maxFlux, -1 )
    return true

end  # setTransitionFluxLimits!( transition, minFlux, maxFlux )


"""
```
setTransitionHasPriority!(
    transition::Transition,
    hasPriority::Bool )
```
This function sets the `hasPriority` flag of the transition `transition` to `hasPriority`, where `true` means the transition can overrule the target state's population target.

This function returns `true`, indicating that the flas is successfully set.
"""
function setTransitionHasPriority!( transition::Transition,
    hasPriority::Bool )::Bool

    transition.hasPriority = hasPriority

    if hasPriority && ( transition.priority > 0 )
        transition.priority *= -1
    elseif !hasPriority && ( transition.priority < 0 )
        transition.priority *= -1
    end  # if hasPriority && ( transition.priority > 0 )

    return true

end  # setTransitionHasPriority!( transition, hasPriority )


"""
```
addTransitionCondition!(
    transition::Transition,
    conditions::Condition... )
```
This function adds the conditions in  `conditions` as extra conditions to the transition `transition`. This function does NOT check if these conditions are contradictory with each other, with the existing ones, or with the source node.

This function returns `true`, indicating that the condition has been successfully added.
"""
function addTransitionCondition!( transition::Transition,
    conditions::Condition... )::Bool

    append!( transition.extraConditions, collect( conditions ) )
    return true

end  # addTransitionCondition!( transition, conditions )


"""
```
clearTransitionConditions!( transition::Transition )
```
This function clear all extra conditions from the transition `transition`.

This function returns `true`, indicating that the list of conditions has been successfully cleared.
"""
function clearTransitionConditions!( transition::Transition )::Bool

    empty!( transition.extraConditions )
    return true

end  # clearTransitionConditions!( transition )


"""
```
setTransitionConditions!(
    transition::Transition,
    conditions::Vector{Condition} )
```
This function sets the extra conditions for the transition `transition` to the list of conditions `conditions`. This function does NOT check if these conditions are contradictory with each other or with the source node.
"""
function setTransitionConditions!( transition::Transition,
    conditions::Vector{Condition} )::Bool

    transition.extraConditions = conditions
    return true

end  # setTransitionConditions!( transition, conditions )


"""
```
addTransitionAttributeChange!(
    transition::Transition,
    attrVals::NTuple{2, String}... )
```
This function adds the extra attribute changes in the list `attrVals` to the transition `transition`. These changes take priority over the changes imposed by moving from the source to the target node.
    
If the list contains multiple changes for the attribute, the function issues a warning and doesn't make any changes.

This function returns `true` if the attribute changes have been successfully added, and `false` if there were duplicate entries in the list.
"""
function addTransitionAttributeChange!( transition::Transition,
    attrVals::NTuple{2, String}... )::Bool

    newAttrs = map( attrVal -> attrVal[ 1 ], collect( attrVals ) )

    if length( newAttrs ) != length( unique( newAttrs ) )
        @warn "Duplicate entries in the attribute/value list, not making any changes."
        return false
    end  # if length( newAttrs ) != length( unique( newAttrs ) )

    for attrVal in attrVals
        transition.extraChanges[ attrVal[ 1 ] ] = attrVal[ 2 ]
    end  # for attrVal in attrVals

    return true

end  # addTransitionAttributeChange!( transition, attrVals )


"""
```
clearTransitionAttributeChanges!( transition::Transition )
```
This function clears all attribute changes from the transition `transition`.

This function returns `true`, indicating that the list of attribute changes has been successfully cleared.
"""
function clearTransitionAttributeChanges!( transition::Transition )::Bool

    empty!( transition.extraChanges )
    return true

end  # clearTransitionAttributeChanges!( trans )


"""
```
setTransitionAttributeChanges!(
    transition::Transition,
    attrVals::Dict{String, String} )
```
This function sets the additional attribute changes made by the transition `transition` to the list in `attrVals`. These changes take priority over the changes imposed by moving from the source to the target node.

This function returns `true`, indicating the list of changes has been successfully set.
"""
function setTransitionAttributeChanges!( transition::Transition,
    attrVals::Dict{String, String} )::Bool

    transition.extraChanges = deepcopy( attrVals )
    return true

end  # setTransitionAttributeChanges!( transition, attrVals )

"""
```
setTransitionAttributeChanges!(
    transition::Transition,
    attrVals::NTuple{2, String}... )
```
This function sets the additional attribute changes made by the transition `transition` to the list in `attrVals`. These changes take priority over the changes imposed by moving from the source to the target node.

If the list contains multiple entries for the same attribute, the function issues a warning and doesn't make any changes.

This function returns `true` if the list of changes has been successfully set, and `false` if that list contained duplicate entries.
    
"""
function setTransitionAttributeChanges!( transition::Transition, attrVals::NTuple{2, String}... )::Bool

    # Check for duplicates.
    newAttrs = map( attrVal -> attrVal[ 1 ], collect( attrVals ) )

    if length( newAttrs ) != length( unique( newAttrs ) )
        @warn "Duplicate entries in the attribute/value list, not making any changes."
        return false
    end  # if length( newAttrs ) != length( unique( newAttrs ) )

    # Convert the val/weight pairs to a dictionary.
    attrValDict = Dict{String, String}()

    for attrVal in attrVals
        attrValDict[ attrVal[ 1 ] ] = attrVal[ 2 ]
    end  # for attrVal in attrVals

    return setTransitionAttributeChanges!( transition, attrValDict )

end  # setTransitionAttributeChanges!( transition, attrVals )

"""
```
setTransitionAttributeChanges!(
    transition::Transition,
    attributes::Vector{String},
    values::Vector{String} )
```
This function sets the additional attribute changes made by the transition `transition` to the attributes in `attributes` and the values in `values`. These changes take priority over the changes imposed by moving from the source to the target node.

If the list contains multiple entries for the same attribute, the function issues a warning and doesn't make any changes.

If there is a mismatch between the lengths of the list of attributes and the list of values, the function issues a warning and doesn't make any changes.
    
This function returns `true` if the list of changes has been successfully set, and `false` if that list contained duplicate entries.
"""
function setTransitionAttributeChanges!( transition::Transition,
    attributes::Vector{String}, values::Vector{String} )::Bool

    if length( attributes ) != length( values )
        @warn "Mismatched lengths of vector of attributes and values, not making any changes."
        return false
    end  # if length( attributes ) != length( values )

    if length( attributes ) != length( unique( attributes ) )
        @warn "Duplicate entries in the attributes list, not making any changes."
        return false
    end  # if length( attributes ) != length( unique( attributes ) )

    attrValDict = Dict{String, String}()

    for ii in eachindex( attributes )
        attrValDict[ attributes[ ii ] ] = values[ ii ]
    end  # for ii in eachindex( attributes )

    return setTransitionAttributeChanges!( transition, attrValDict )

end  # setTransitionAttributeChanges!( transition, attributes, values )


"""
```
setTransitionProbabilities!(
    transition::Transition,
    probabilities::Vector{Float64} )
```
This function sets the execution probabilities of the state transition `trans`
to the valid entries in `probs`. Valid entries are between 0.0 and 1.0
inclusive, and invalid entries are removed. Additionally, all leading 0.0
entries will be removed as well.

This function returns `nothing`. If there are no valid probabilities, the
function will issue a warning to that effect, and won't make any changes.
"""
function setTransitionProbabilities!( transition::Transition, probabilities::Vector{Float64} )::Bool

    # Filter out all invalid probabilities.
    tmpProbs = filter( prob -> 0.0 <= prob <= 1.0, probabilities )

    if isempty( tmpProbs )
        @warn "No valid probabilities entered, not making any changes."
        return false
    end  # if isempty( tmpProbs )

    transition.probabilityList = tmpProbs
    return true

end  # setTransitionProbabilities!( trans, probs )


function Base.show( io::IO, transition::Transition )

    print( io, "Transition '", transition.name, "': '",
        transition.sourceNode.name, "' to '",
        transition.isOutTransition ? "external" : transition.targetNode.name, "'" )
    print( io, "\n  Occurs with period ", transition.freq, " (offset ",
        transition.offset, ")" )

    if !isempty( transition.extraConditions )
        print( io, "\n  Extra conditions: ", transition.extraConditions )
    end  # if !isempty( transition.extraConditions )

    if !isempty( transition.extraChanges )
        print( io, "\n  Extra changes: ",
            join( map( attr -> string( attr, " to ",
            transition.extraChanges[ attr ] ),
            collect( keys( transition.extraChanges ) ) ), ", " ) )
    end  # if !isempty( transition.extraChanges )

    if transition.maxAttempts == -1
        print( io, "\n  Infinite number of" )
    else
        nAttempts = transition.maxAttempts == 0 ?
            length( transition.probabilityList ) : transition.maxAttempts
        print( io, "\n  Max ", nAttempts )
    end  # if transition.maxAttempts == -1

    print( io, " attempts" )

    if transition.minFlux > 0
        print( io, "\n  Min flux: ", transition.minFlux )
    end  # if transition.minFlux > 0

    if transition.maxFlux >= 0
        print( io, "\n  Max flux: ", transition.maxFlux )

        if transition.hasPriority
            print( io, " (overrides state pop. constraint)" )
        end  # if transition.hasPriority
    end  # if transition.maxFlux >= 0

    print( io, "\n  Transition execution probabilities: ",
        join( transition.probabilityList .* 100, "%, " ), '%' )
    print( io, "\n Transition at priority ", - transition.priority )

end  # Base.show( io, transition )