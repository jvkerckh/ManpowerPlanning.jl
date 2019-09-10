const dummyNode = BaseNode( "Dummy" )


"""
```
isPersonnelOfNode(
    persAttrVals::Dict{String, Any},
    node::BaseNode )
```
This function tests if the personnel members with initialised attributes
`persAttrVals` satisfies the requirements of node `node`.

If the node has a requirement on an attribute which isn't in the list of attribute/value pairs, it means the requirement isn't satisfied.

This function returns a `Bool` with the result of the test.
"""
function isPersonnelOfNode( persAttrVals::Dict{String, String},
    node::BaseNode )::Bool

    for attribute in keys( node.requirements )
        # If the attribute isn't initialised for the personnel member, the
        #   personnel doesn't satisfy it, and isn't in the node. Otherwise,
        #   the attribute's value must match with the requirements of the node.
        if !haskey( persAttrVals, attribute ) ||
            ( persAttrVals[ attribute ] != node.requirements[ attribute ] )
            return false
        end  # if !haskey( persAttrVals, attribute ) || ...
    end  # for attr in keys( node.requirements )

    return true

end  # isPersonnelOfNode( persAttrs, node )