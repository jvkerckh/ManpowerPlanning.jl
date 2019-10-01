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
    setNodeAttritionScheme!( node, attrition.name ) )
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
    isTargetNode::Bool = false ), setTransitionNode!( transition, node.name,
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
@deprecate( addCondition!( transition::Transition, condition::MPcondition ),
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


# Recruitment
@deprecate( setRecruitmentSchedule( recruitment::Recruitment, freq::Real,
    offset::Real = 0 ), setRecruitmentSchedule!( recruitment, freq, offset ) )
@deprecate( setRecruitmentLimits( recruitment::Recruitment, minRec::Integer,
    maxRec::Integer = -1 ), setRecruitmentAdaptiveRange!( recruitment, minRec,
    maxRec ) )
@deprecate( setRecruitmentFixed( recruitment::Recruitment, amount::Integer ),
    setRecruitmentFixed!( recruitment, amount ) )
@deprecate( setRecruitmentDistribution( recruitment::Recruitment,
    distNodes::Dict{Int, Float64}, distType::Symbol ),
    setRecruitmentDist!( recruitment, distType, distNodes ) )


# ManpowerSimulation
@deprecate( setKey( mpSim::MPsim, idKey::KeyType ),
    setSimulationKey!( mpSim, idKey ) )
@deprecate( addAttribute!( mpSim::MPsim, attribute::Attribute ),
    addSimulationAttribute!( mpSim, attribute ) )
@deprecate( clearAttributes!( mpSim::MPsim ),
    clearSimulationAttributes!( mpSim ) )
@deprecate( addState!( mpSim::MPsim, node::BaseNode ),
    addSimulationBaseNode!( mpSim, node ) )
@deprecate( removeState!( mpSim::MPsim, node::String ),
    removeSimulationBaseNode!( mpSim, node ) )
@deprecate( clearStates!( mpSim::MPsim ), clearSimulationBaseNodes!( mpSim ) )
@deprecate( addCompoundState!( mpSim::MPsim, compoundNode::CompoundNode ),
    addSimulationCompoundNode!( mpSim, compoundNode ) )
@deprecate( addCompoundState!( mpSim::MPsim, nodeName::String,
    nodeTarget::Integer, baseNodeList::String... ),
    addSimulationCompoundNode!( mpSim, nodeName, nodeTarget, baseNodeList... ) )
@deprecate( removeCompoundState!( mpSim::MPsim, nodes::String... ),
    removeSimulationCompoundNode!( mpSim, nodes... ) )
@deprecate( clearCompoundStates!( mpSim::MPsim ),
    clearSimulationCompoundNodes!( mpSim ) )
@deprecate( addRecruitmentScheme!( mpSim::MPsim, recruitment::Recruitment ),
    addSimulationRecruitment!( mpSim, recruitment ) )
@deprecate( clearRecruitmentSchemes!( mpSim::MPsim ),
    clearSimulationRecruitment!( mpSim ) )
@deprecate( addTransition!( mpSim::MPsim, transition::Transition ),
    addSimulationTransition!( mpSim, transition ) )
@deprecate( clearTransitions!( mpSim::MPsim ),
    clearSimulationTransitions!( mpSim ) )
@deprecate( setSimulationLength( mpSim::MPsim, simLength::Real ), 
    setSimulationLength!( mpSim, simLength ) )
@deprecate( setPersonnelCap( mpSim::MPsim, personnelTarget::Integer ),
    setSimulationPersonnelTarget!( mpSim, personnelTarget ) )