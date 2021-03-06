mpSim = ManpowerSimulation( "sim" )

# Setting Attributes.
attribute1 = Attribute( "level" )
setPossibleAttributeValues!( attribute1, ["Junior", "Senior", "Master"] )
setInitialAttributeValues!( attribute1, Dict( "Junior" => 1.0 ) )
attribute2 = Attribute( "branch" )
setPossibleAttributeValues!( attribute2, ["A", "B", "reserve", "none"] )
setInitialAttributeValues!( attribute2, Dict( "none" => 1.0 ) )
attribute3 = Attribute( "isCareer" )
setPossibleAttributeValues!( attribute3, ["yes", "no"] )
setInitialAttributeValues!( attribute3, Dict( "no" => 1.0 ) )
setSimulationAttributes!( mpSim, [attribute1, attribute2, attribute3] )

# Setting Base Nodes.
node1 = BaseNode( "A junior" )
setNodeRequirements!( node1, ("level", "Junior"), ("branch", "A"),
    ("isCareer", "no") )
node2 = BaseNode( "B junior" )
setNodeRequirements!( node2, ("level", "Junior"), ("branch", "B"),
    ("isCareer", "no") )
node3 = BaseNode( "Reserve junior" )
setNodeRequirements!( node3, ("level", "Junior"), ("branch", "reserve"),
    ("isCareer", "no") )
node4 = BaseNode( "A senior" )
setNodeRequirements!( node4, ("level", "Senior"), ("branch", "A"),
    ("isCareer", "yes") )
node5 = BaseNode( "B senior" )
setNodeRequirements!( node5, ("level", "Senior"), ("branch", "B"),
    ("isCareer", "yes") )
node6 = BaseNode( "Master" )
setNodeRequirements!( node6, ("level", "Master"), ("branch", "none"),
    ("isCareer", "yes") )
setNodeTarget!.( [node1, node2, node3, node4, node5, node6],
    [-1, -1, -1, 30, 30, 25] )
setSimulationBaseNodes!( mpSim, [node1, node2, node3, node4, node5, node6] )
setSimulationBaseNodeOrder!( mpSim, Dict( "Master" => 1, "A senior" => 2,
    "B senior" => 2, "A junior" => 3, "B junior" => 3 ) )

# Setting Compound Nodes.
cnode1 = CompoundNode( "Branch A" )
setCompoundNodeComponents!( cnode1, ["A junior", "A senior"] )
cnode2 = CompoundNode( "Branch B" )
setCompoundNodeComponents!( cnode2, ["B junior", "B senior"] )
cnode3 = CompoundNode( "Junior" )
setCompoundNodeComponents!( cnode3,
    ["A junior", "B junior", "Reserve junior"] )
cnode4 = CompoundNode( "Career" )
setCompoundNodeComponents!( cnode4, ["A senior", "B senior", "Master"] )
cnode5 = CompoundNode( "Empty" )
setSimulationCompoundNodes!( mpSim,
    [cnode1, cnode2, cnode3, cnode4 , cnode5] )

# Setting recruitment.
rec1 = Recruitment( "EW" )
setRecruitmentTarget!( rec1, "A junior" )
rec2 = Recruitment( "EW" )
setRecruitmentTarget!( rec2, "B junior" )
rec3 = Recruitment( "EW" )
setRecruitmentTarget!( rec3, "Reserve junior" )

setRecruitmentSchedule!.( [rec1, rec2, rec3], 12 )
setRecruitmentFixed!.( [rec1, rec2, rec3], 10 )
setRecruitmentAgeFixed!.( [rec1, rec2, rec3], 240 )
addSimulationRecruitment!( mpSim, rec1, rec2, rec3 )

# Setting THROUGH Transitions.
ttrans1 = Transition( "Promotion", "A junior", "A senior" )
addTransitionCondition!( ttrans1, MPcondition( "time in node", >=, 24 ) )
ttrans2 = Transition( "Promotion", "B junior", "B senior" )
addTransitionCondition!( ttrans2, MPcondition( "time in node", >=, 24 ) )
ttrans3 = Transition( "Promotion", "A senior", "Master" )
addTransitionCondition!( ttrans3, MPcondition( "time in node", >=, 36 ) )
ttrans4 = Transition( "Promotion", "B senior", "Master" )
addTransitionCondition!( ttrans4, MPcondition( "time in node", >=, 36 ) )
ttrans5 = Transition( "Reserve", "Reserve junior", "A senior" )
addTransitionCondition!( ttrans5, MPcondition( "time in node", >=, 24 ) )
ttrans6 = Transition( "Reserve", "Reserve junior", "B senior" )
addTransitionCondition!( ttrans6, MPcondition( "time in node", >=, 24 ) )

setTransitionSchedule!.( [ttrans1, ttrans2, ttrans3, ttrans4, ttrans5,
    ttrans6], 12 )
setTransitionMaxAttempts!.( [ttrans1, ttrans2, ttrans3, ttrans4, ttrans5,
    ttrans6], 1 )
setTransitionFluxLimits!.( [ttrans1, ttrans2, ttrans3, ttrans4, ttrans5,
    ttrans6], [8, 8, 0, 0, 0, 0], [8, 8, 5, 5, 4, 4] )
addSimulationTransition!( mpSim, ttrans1, ttrans2, ttrans3, ttrans4, ttrans5,
    ttrans6 )

# Setting OUT Transitions.
otrans1 = Transition( "B-", "A junior" )
addTransitionCondition!( otrans1, MPcondition( "time in node", >=, 24 ) )
otrans2 = Transition( "B-", "B junior" )
addTransitionCondition!( otrans2, MPcondition( "time in node", >=, 24 ) )
otrans3 = Transition( "B-", "Reserve junior" )
addTransitionCondition!( otrans3, MPcondition( "time in node", >=, 24 ) )
otrans4 = Transition( "PE", "A senior" )
addTransitionCondition!( otrans4, MPcondition( "tenure", >=, 120 ) )
otrans5 = Transition( "PE", "B senior" )
addTransitionCondition!( otrans5, MPcondition( "tenure", >=, 120 ) )
otrans6 = Transition( "PE", "Master" )
addTransitionCondition!( otrans6, MPcondition( "tenure", >=, 120 ) )

setTransitionMaxAttempts!.( [otrans1, otrans2, otrans3, otrans4, otrans5,
    otrans6], 1 )
setTransitionFluxLimits!.( [otrans1, otrans2, otrans3, otrans4, otrans5,
    otrans6], 0, -1 )
addSimulationTransition!( mpSim, otrans1, otrans2, otrans3, otrans4, otrans5,
    otrans6 )
setSimulationTransitionTypeOrder!( mpSim, Dict( "PE" => 1, "Promotion" => 2,
    "Reserve" => 3, "B-" => 4 ) )

# Miscellaneous configs.
setSimulationLength!( mpSim, 300 )