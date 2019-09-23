# This file holds the definition of the functions pertaining to the BaseNode
#   type.

export  setNodeName!,
        setNodeTarget!,
        setNodeAttritionScheme!,
        addNodeRequirement!,
        removeNodeRequirement!,
        clearNodeRequirements!,
        setNodeRequirements!


"""
```
setNodeName!(
    node::BaseNode,
    name::String )
```
This function sets the name of the node `node` to `name`.

This function returns `true`, indication that the node name is set successfully.
"""
function setNodeName!( node::BaseNode, name::String )::Bool

    node.name = name
    return true

end  # setNodeName!( node, name )


"""
```
setNodeTarget!(
    node::BaseNode,
    target::Integer )
```
This function sets the target number of personnel members in node `node` to
`target`. If the number is less than zero, it means there's no target.

This function returns `true`, indicating the node population target is successfully set.
"""
function setNodeTarget!( node::BaseNode, target::Integer )::Bool

    node.target = max( target, -1 )
    return true

end  # setNodeTarget!( node, target )


"""
```
setNodeAttritionScheme!(
    node::BaseNode,
    attrition::String )
```
This function sets the name of the attrition scheme of the node `node` to `attrition`. The user must make sure that an attrition scheme with this name exists in the simulation.

This function returns `true`, indicating the attrition scheme is successfully set.
"""
function setNodeAttritionScheme!( node::BaseNode, attrition::String )::Bool

    node.attrition = lowercase( attrition ) ∈ [ "", "default" ] ? "default" :
        attrition
    return true

end  # setNodeAttritionScheme!( node, attrition )


"""
```
addNodeRequirement!(
    node::BaseNode,
    attrVals::NTuple{2,String}... )
```
This function adds the attribute requirements listed in `attrVals` to the node `node`. If attributes in the list already have a requirement on them, it gets overwritten.
    
If there are multiple entries for the same attribute, this function issues a warning and doesn't make any changes.

This function returns `true` if the requirements have been added successfully, and `false` if the list contained duplicates.
"""
function addNodeRequirement!( node::BaseNode,
    attrVals::NTuple{2,String}... )::Bool

    newAttrs = map( attrVal -> attrVal[ 1 ], collect( attrVals ) )

    if length( newAttrs ) != length( unique( newAttrs ) )
        @warn "Duplicate attribute entries in the requirement list, not making any changes."
        return false
    end  # if length( newAttrs ) != length( unique( newAttrs ) )

    newVals = map( attrVal -> attrVal[ 2 ], collect( attrVals ) )

    for ii in eachindex( newAttrs )
        node.requirements[ newAttrs[ ii ] ] = newVals[ ii ]
    end  # for ii in eachindex( newAttrs )

    return true

end  # addNodeRequirement!( node, attriVals )

"""
```
addNodeRequirement!(
    node::BaseNode,
    attribute::String,
    value::String )
```
This function adds the requirement that the attribute `attribute` must have the value `value` to qualify for the node `node`. If the node already has a requirement on that attribute, it gets overwritten.

This function returns `true`, indicating the requirement has been successfully added.
"""
addNodeRequirement!( node::BaseNode, attribute::String, value::String )::Bool =
    addNodeRequirement!( node, (attribute, value) )


"""
```
removeNodeRequirement!(
    node::BaseNode,
    attributes::String... )
```
This function removes the requirements on the attributes listed in `attributes` from the node `node`.

This function returns `true` if any requirements have been successfully removed, and `false` if the nodes didn't have any requirements on the given attributes.
"""
function removeNodeRequirement!( node::BaseNode, attributes::String... )::Bool

    hasRequirement = collect( haskey.( Ref( node.requirements ), attributes ) )

    if !any( hasRequirement )
        return false
    end  # if !any( hasRequirement )

    delete!.( Ref( node.requirements ), attributes[ hasRequirement ] )
    return true

end  # removeRequirement!( node, attributes )


"""
```
clearNodeRequirements!( node::BaseNode )
```
This function clears all the requirements for node `node`.

This function returns `true`, indicating all requirements on the node have been successfully cleared.
"""
function clearNodeRequirements!( node::BaseNode )::Bool

    empty!( node.requirements )
    return true

end  # clearNodeRequirements!( node )


"""
```
setNodeRequirements!(
    node::BaseNode,
    attrVals::Dict{String, String} )
```
This function sets the requirements for the node `node` to the attribute/value combinations in `attrVals`.

This function returns `true`, indicating the requirements have been successfully set.
"""
function setNodeRequirements!( node::BaseNode,
    attrVals::Dict{String, String} )::Bool

    node.requirements = deepcopy( attrVals )
    return true

end  # setNodeRequirements!( node, attrVals )

"""
```
setNodeRequirements!(
    node::BaseNode,
    attrVals::NTuple{2, String}... )
```
This function sets the requirements for the node `node` to the attribute/value combinations in `attrVals`.

If there are multiple entries for the same attribute, this function isues a warning and doesn't make any changes.

This function returns `true` when the requirements have been set successfully, and `false` when the list contains duplicate entries.
"""
function setNodeRequirements!( node::BaseNode,
    attrVals::NTuple{2, String}... )::Bool

    newAttrs = map( attrVal -> attrVal[ 1 ], collect( attrVals ) )

    if length( newAttrs ) != length( unique( newAttrs ) )
        @warn "Duplicate attribute entries in the requirement list, not making any changes."
        return false
    end  # if length( newAttrs ) != length( unique( newAttrs ) )

    attrValDict = Dict{String, String}()

    for attrVal in attrVals
        attrValDict[ attrVal[ 1 ] ] = attrVal[ 2 ]
    end  # for attrVal in attrVals

    return setNodeRequirements!( node, attrValDict )

end  # setNodeRequirements!( node, attrVals )

"""
```
setNodeRequirements!(
    node::BaseNode,
    attributes::Vector{String},
    values::Vector{String} )
```
This function sets the requirements of the node `node` to the attributes and corresponding values in `attributes` resp. `values`.

If the two vectors differ in length or if there are duplicate entries in the list of attributes, the function will issue a warning and not make any changes.

This function returns `true` when the requirements have been set successfully, and `false` when the list contains duplicate entries or the attributes and values lists don't match up.
"""
function setNodeRequirements!( node::BaseNode, attributes::Vector{String}, values::Vector{String} )::Bool

    if length( attributes ) != length( values )
        @warn "Mismatched lengths of vector of attributes and values, not making any changes."
        return false
    end  # if length( values ) != length( weights )

    if length( attributes ) != length( unique( attributes ) )
        @warn "Duplicate entries in the attributes list, not making any changes."
        return false
    end  # if length( values ) != length( unique( values ) )

    attrValDict = Dict{String, String}()

    for ii in eachindex( attributes )
        attrValDict[ attributes[ 1 ] ] = values[ 1 ]
    end  # for ii in eachindex( attributes )

    return setNodeRequirements!( node, attrValDict )

end  # setNodeRequirements!( node, attributes, values )


function Base.show( io::IO, node::BaseNode )::Nothing

    print( io, "Node: ", node.name )
    print( io, "\n  Associated attrition scheme: ", node.attrition )

    if node.target >= 0
        print( io, "\n  Population target of ", node.target,
            " personnel members in node." )
    else
        print( io, "\n  Node has no population target." )
    end  # if node.target >= 0

    if isempty( node.requirements )
        print( io, "\n  Node '", node.name, "' has no attribute requirements." )
        return
    end  # if isempty( node.requirements )

    print( io, "\n  Requirements" )

    for attribute in keys( node.requirements )
        print( io, "\n    ", attribute, " = ", node.requirements[ attribute ] )
    end  # for attr in keys( node.requirements )

    return

end  # show( io, node )


include( joinpath( privPath, "basenode.jl" ) )