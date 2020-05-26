mpSim = MPsim()

attributes = Attribute.( ["atA", "atB", "atC"] )
setPossibleAttributeValues!( attributes[1], ["A1", "A2"] )
setInitialAttributeValues!( attributes[2], Dict( "B1" => 5, "B2" => 5 ) )
setPossibleAttributeValues!( attributes[3], ["C1", "C2", "C3"] )
setSimulationAttributes!( mpSim, attributes )

nodes = BaseNode.( ["A", "B", "C", "D", "E"] )
setNodeRequirements!( nodes[1], Dict( "atA" => "A1", "atC" => "C1" ) )
setNodeRequirements!( nodes[2], Dict( "atA" => "A2", "atC" => "C1" ) )
setNodeRequirements!( nodes[3], Dict( "atA" => "A1", "atC" => "C2" ) )
setNodeRequirements!( nodes[4], Dict( "atA" => "A2", "atC" => "C2" ) )
setNodeRequirements!( nodes[5], Dict( "atC" => "C3" ) )
setSimulationBaseNodes!( mpSim, nodes )

recruitments = Recruitment.( ["EW", "EW"] )
setRecruitmentTarget!.( recruitments, ["A", "B"] )
setRecruitmentFixed!.( recruitments, 15 )
setRecruitmentSchedule!.( recruitments, 12 )
setSimulationRecruitment!( mpSim, recruitments )

transitions = [Transition( "B+", "A", "C" ), Transition( "B+", "B", "D" ),
    Transition( "Adv", "C", "E" ), Transition( "Adv", "D", "E" ),
    Transition( "B-", "A" ), Transition( "B-", "B" )]
setTransitionSchedule!.( transitions, 12 )
setTransitionFluxLimits!.( transitions[1:4], [10, 10, 2, 2], [10, 10, 2, 2] )
addTransitionCondition!.( transitions,
    MPcondition.( "tenure", ==, [24, 24, 60, 60, 24, 24] ) )
setSimulationTransitions!( mpSim, transitions )

retirement = Retirement()
setRetirementSchedule!( retirement, 12 )
setRetirementCareerLength!( retirement, 120 )
setSimulationRetirement!( mpSim, retirement )

setSimulationLength!( mpSim, 600 )

attritions = Attrition.( ["A/B", "C/D", "E"] )
setAttritionPeriod!.( attritions, 12 )
setAttritionRate!.( attritions, [0.2, 0.1, 0.05] )
addSimulationAttrition!( mpSim, attritions... )