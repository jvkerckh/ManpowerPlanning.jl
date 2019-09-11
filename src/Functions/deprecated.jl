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


# Transition
@deprecate( setName( transition::Transition, name::String ),
    setTransitionName!( transition, name ) )
@deprecate( setState( transition::Transition, node::BaseNode,
    isTargetNode::Bool = false ), setTransitionNode!( transition, node,
    isTargetNode ) )
@deprecate( setIsOutTrans!( transition::Transition, isOutTrans::Bool ),
    setTransitionIsOut!( transition, isOutTrans ) )
@deprecate( setSchedule( transition::Transition, freq::Real, offset::Real = 0 ),
    setTransitionSchedule!( transition, freq, offset ) )
@deprecate( setMaxAttempts( transition::Transition, maxAttempts::Integer ),
    setTransitionMaxAttempts!( transition, maxAttempts ) )
@deprecate( setFluxBounds( transition::Transition, minFlux::Integer,
    maxFlux::Integer ), setTransitionFluxLimits!( transition, minFlux,
    maxFlux ) )
@deprecate( setHasPriority( transition::Transition, hasPriority::Bool ),
    setTransitionHasPriority!( transition, hasPriority ) )
@deprecate( addCondition!( transition::Transition, condition::MPCondition ),
    addTransitionCondition!( transition, condition ) )
@deprecate( clearConditions!( transition::Transition ),
    clearTransitionConditions!( transition ) )
@deprecate( addAttributeChange!( transition::Transition, attribute::String,
    value::String ), addTransitionAttributeChange!( transition,
    (attribute, value) ) )
@deprecate( clearAttributeChanges!( transition::Transition ),
    clearTransitionAttributeChanges!( transition ) )
@deprecate( setTransProbabilities( transition::Transition,
    probabilities::Vector{Float64} ), setTransitionProbabilities!( transition,
    probabilities ) )


# CompoundNode
@deprecate( CompoundState, CompoundNode )
@deprecate( setName!( compoundNode::CompoundNode, name::String ),
    setCompoundNodeName!( compoundNode, name ) )
@deprecate( addStateToCompound!( compoundNode::CompoundNode,
    nodeList::String... ), addCompoundNodeComponent!( compoundNode,
    nodeList... ) )
@deprecate( removeStateFromCompound!( compoundNode::CompoundNode,
    nodeList::String... ), removeCompoundNodeComponent!( compoundNode,
    nodeList... ) )
@deprecate( clearStatesFromCompound!( compoundNode::CompoundNode ),
    clearCompoundNodeComponents!( compoundNode ) )
@deprecate( setStateTarget!( compoundNode::CompoundNode, target::Integer ),
    setCompoundNodeTarget!( compoundNode, target ) )