# Attrition
@deprecate( setAttritionRate( attrition::Attrition, rate::Real ),
    setAttritionRate!( attrition, rate ) )
@deprecate( setAttritionPeriod( attrition::Attrition, period::Real ),
    setAttritionPeriod!( attrition, period ) )
# TODO: make sure these deprecations covers all bases.
@deprecate( setAttritionCurve( attrition::Attrition,
    curve::Dict{Float64, Float64} ), setAttritionCurve!( attrition, curve ) )
@deprecate( setAttritionCurve( attrition::Attrition,
    curve::Array{Float64, 2} ), setAttritionCurve!( attrition, curve ) )




# Attribute
@deprecate( PersonnelAttribute, Attribute )
@deprecate( setPossibleValues!( attribute::Attribute, vals::Vector{String} ),
    setPossibleAttributeValues!( attribute, vals ) )
@deprecate( addValueToAttr!( attribute::Attribute, val::String, weight::Real ),
    addInitialAttributeValue!( attribute, val, weight ) )
@deprecate( removeValueFromAttr!( attribute::Attribute, val::String ),
    removeInitialAttributeValue!( attribute, val ) )
@deprecate( setAttrValues!( attribute::Attribute,
    valWeights::Dict{String, Float64} ), setInitialAttributeValues!( attribute,
    valWeights ) )


# BaseNode
@deprecate( State, BaseNode )
@deprecate( setName!( node::BaseNode, name::String ),
    setNodeName!( node, name ) )
@deprecate( setStateTarget!( node::BaseNode, target::Integer ),
    setNodeTarget!( node, target ) )
@deprecate( setStateAttritionScheme!( node::BaseNode, attrition::Attrition ),
    setNodeAttritionScheme!( node, attrition ) )
@deprecate( addRequirement!( node::BaseNode, attribute::String, value::String ),
    addNodeRequirement!( node, attribute, value ) )
@deprecate( removeRequirement!( node::BaseNode, attribute::String ),
    removeNodeRequirement!( node, attribute ) )
@deprecate( clearRequirements!( node::BaseNode ),
    clearNodeRequirements!( node::BaseNode ) )