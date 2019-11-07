@testset "ManpowerSimulation" begin

mpSim = MPsim()

@testset "function isSimulationFresh" begin
    @test isSimulationFresh( mpSim )
end  # @testset "function isSimulationFresh"

@testset "function isSimulationConsistent" begin
    @test isSimulationConsistent( mpSim )
end  # @testset "function isSimulationConsistent"

@testset "function verifySimulation!" begin
    @test verifySimulation!( mpSim )
    @test verifySimulation!( mpSim, true )
end  # @testset "function verifySimulation!"

@testset "function setSimulationKey!" begin
    @test_deprecated setKey( mpSim, "testKey" )
    @test mpSim.idKey == "testKey"
    setSimulationKey!( mpSim, :testKey2 )
    @test mpSim.idKey == "testKey2"
    setSimulationKey!( mpSim )
    @test mpSim.idKey == "id"
    @test verifySimulation!( mpSim, true )
end  # @testset "function setSimulationKey!"

attribute1 = Attribute( "Attribute 1" )
setPossibleAttributeValues!( attribute1,
    [ "Lasgun", "Flak armour", "Stubber" ] )
attribute2 = Attribute( "Attribute 2" )
setPossibleAttributeValues!( attribute2,
    [ "Shuriken gun", "Psychoreactive armour", "Shuriken cannon" ] )
attribute3 = Attribute( "Attribute 3" )
setPossibleAttributeValues!( attribute3,
    [ "Bolter", "Power armour", "Stormbolter"] )
attribute4 = Attribute( "Attribute 1" )
setPossibleAttributeValues!( attribute4,
    [ "Gauss rifle", "Necrodermis", "Tesla rifle"] )

@testset "function addSimulationAttribute!" begin
    @test_deprecated addAttribute!( mpSim, attribute1 )
    @test haskey( mpSim.attributeList, "Attribute 1" ) &&
        ( mpSim.attributeList[ "Attribute 1" ] === attribute1 )
    @test !isSimulationConsistent( mpSim )
    addSimulationAttribute!( mpSim, attribute2, attribute4 )
    @test all( [ haskey( mpSim.attributeList, "Attribute 2" ),
        mpSim.attributeList[ "Attribute 2" ] === attribute2,
        mpSim.attributeList[ "Attribute 1" ] === attribute4,
        mpSim.attributeList[ "Attribute 1" ] !== attribute1 ] )
    @test !addSimulationAttribute!( mpSim, attribute1, attribute3, attribute4 )
    @test !haskey( mpSim.attributeList, "Attribute 3" )
    @test verifySimulation!( mpSim )
end  # @testset "function addSimulationAttribute!"

@testset "function removeSimulationAttribute!" begin
    removeSimulationAttribute!( mpSim, "Attribute 2", "Attribute 3" )
    @test !haskey( mpSim.attributeList, "Attribute 2" )
    @test !isSimulationConsistent( mpSim )
    @test !removeSimulationAttribute!( mpSim, "Attribute 2", "Attribute &" )
    @test verifySimulation!( mpSim )
end  # @testset "function removeSimulationAttribute!"

@testset "function clearSimulationAttributes!" begin
    @test_deprecated clearAttributes!( mpSim )
    @test isempty( mpSim.attributeList )
    @test !isSimulationConsistent( mpSim )
    @test verifySimulation!( mpSim )
end  # @testset "function clearSimulationAttributes!"

@testset "function setSimulationAttributes!" begin
    setSimulationAttributes!( mpSim, [ attribute1, attribute3 ] )
    @test all( [ length( mpSim.attributeList ) == 2,
        haskey( mpSim.attributeList, "Attribute 1" ),
        haskey( mpSim.attributeList, "Attribute 3" ) ] )
    @test !isSimulationConsistent( mpSim )
    @test !setSimulationAttributes!( mpSim,
        [ attribute4, attribute2, attribute1 ] )
    @test verifySimulation!( mpSim )
end  # @testset "function setSimulationAttributes!"

node1 = BaseNode( "Base Node 1" )
node2 = BaseNode( "Base Node 2" )
node3 = BaseNode( "Base Node 3" )
node4 = BaseNode( "Base Node 1" )

@testset "function addSimulationBaseNode!" begin
    @test_deprecated addState!( mpSim, node1 )
    @test haskey( mpSim.baseNodeList, "Base Node 1" ) &&
        ( mpSim.baseNodeList[ "Base Node 1" ] === node1 )
    @test !isSimulationConsistent( mpSim )
    addSimulationBaseNode!( mpSim, node2, node4 )
    @test all( [ haskey( mpSim.baseNodeList, "Base Node 2" ),
        mpSim.baseNodeList[ "Base Node 2" ] === node2,
        mpSim.baseNodeList[ "Base Node 1" ] === node4,
        mpSim.baseNodeList[ "Base Node 1" ] !== node1 ] )
    @test !addSimulationBaseNode!( mpSim, node1, node3, node4 )
    @test !haskey( mpSim.baseNodeList, "Base Node 3" )
    @test verifySimulation!( mpSim )
    addNodeRequirement!( node4, ("Attribute 2", "Shuriken gun") )
    @test !verifySimulation!( mpSim, true )
    clearNodeRequirements!( node4 )
    addNodeRequirement!( node4, ("Attribute 1", "Gauss rifle") )
    @test !verifySimulation!( mpSim, true )
    clearNodeRequirements!( node4 )
end  # @testset "function addSimulationBaseNode!"

@testset "function removeSimulationBaseNode!" begin
    removeSimulationBaseNode!( mpSim, "Base Node 1", "Base Node 3" )
    @test !haskey( mpSim.attributeList, "Base Node 1" )
    @test !isSimulationConsistent( mpSim )
    @test !removeSimulationBaseNode!( mpSim, "Base Node 3", "Attribute &" )
    @test verifySimulation!( mpSim )
end  # @testset "function removeSimulationBaseNode!"

@testset "function clearSimulationBaseNodes!" begin
    @test_deprecated clearStates!( mpSim )
    @test isempty( mpSim.baseNodeList )
    @test !isSimulationConsistent( mpSim )
    @test verifySimulation!( mpSim )
end  # @testset "function clearSimulationBaseNodes!"

@testset "function setSimulationBaseNodes!" begin
    setSimulationBaseNodes!( mpSim, [ node1, node3 ] )
    @test all( [ length( mpSim.baseNodeList ) == 2,
        haskey( mpSim.baseNodeList, "Base Node 1" ),
        haskey( mpSim.baseNodeList, "Base Node 3" ) ] )
    @test !isSimulationConsistent( mpSim )
    @test !setSimulationBaseNodes!( mpSim,
        [ node4, node2, node1 ] )
    @test verifySimulation!( mpSim )
end  # @testset "function setSimulationBaseNodes!"

node5 = CompoundNode( "Compound Node 1" )
node6 = CompoundNode( "Compound Node 2" )
node7 = CompoundNode( "Compound Node 1" )

@testset "function addSimulationCompoundNode!" begin
    @test_deprecated addCompoundState!( mpSim, node5 )
    @test haskey( mpSim.compoundNodeList, "Compound Node 1" ) &&
        ( mpSim.compoundNodeList[ "Compound Node 1" ] === node5 )
    @test !isSimulationConsistent( mpSim )
    addSimulationCompoundNode!( mpSim, "Compound Node 1", 1000, "Base Node 4" )
    @test ( length( mpSim.compoundNodeList ) == 1 ) &&
        ( mpSim.compoundNodeList[ "Compound Node 1" ] !== node5 )
    @test !addSimulationCompoundNode!( mpSim, node5, node6, node7 )
    @test !haskey( mpSim.compoundNodeList, "Compound Node 2" )
    @test !verifySimulation!( mpSim, true )
end  # @testset "function addSimulationCompoundNode!"

@testset "function removeSimulationCompoundNode!" begin
    @test_deprecated removeCompoundState!( mpSim, "Compound Node 1" )
    @test !haskey( mpSim.compoundNodeList, "Compound Node 1" )
    @test !isSimulationConsistent( mpSim )
    @test !removeSimulationCompoundNode!( mpSim, "Compound Node 2",
        "Compound Node 3" )
    @test verifySimulation!( mpSim )
end  # @testset "function removeSimulationCompoundNode!"

@testset "function clearSimulationCompoundNodes!" begin
    @test_deprecated clearCompoundStates!( mpSim )
    @test isempty( mpSim.compoundNodeList )
    @test !isSimulationConsistent( mpSim )
    @test verifySimulation!( mpSim )
end  # @testset "function clearSimulationCompoundNodes!"

@testset "function setSimulationCompoundNodes!" begin
    setSimulationCompoundNodes!( mpSim, [ node5, node6 ] )
    @test all( [ length( mpSim.compoundNodeList ) == 2,
        haskey( mpSim.compoundNodeList, "Compound Node 1" ),
        haskey( mpSim.compoundNodeList, "Compound Node 2" ),
        mpSim.compoundNodeList[ "Compound Node 1" ] === node5,
        mpSim.compoundNodeList[ "Compound Node 2" ] === node6 ] )
    @test !isSimulationConsistent( mpSim )
    @test !setSimulationCompoundNodes!( mpSim, [ node7, node6, node5 ] )
    @test verifySimulation!( mpSim )
end  # @testset "function setSimulationCompoundNodes!"

recruitment1 = Recruitment( "Recruitment 1" )
recruitment2 = Recruitment( "Recruitment 2" )
recruitment3 = Recruitment( "Recruitment 3" )
recruitment4 = Recruitment( "Recruitment 1" )

@testset "function addSimulationRecruitment!" begin
    @test_deprecated addRecruitmentScheme!( mpSim, recruitment1 )
    @test !addSimulationRecruitment!( mpSim, recruitment1, recruitment2,
        recruitment3 )
    setRecruitmentTarget!( recruitment1, "Base Node 1" )
    setRecruitmentTarget!( recruitment2, "Base Node 2" )
    setRecruitmentTarget!( recruitment3, "Base Node 3" )
    setRecruitmentTarget!( recruitment4, "Base Node 3" )
    addSimulationRecruitment!( mpSim, recruitment1, recruitment3, recruitment4 )
    @test all( [ length( mpSim.recruitmentByName ) == 2,
        haskey( mpSim.recruitmentByName, "Recruitment 1" ),
        haskey( mpSim.recruitmentByName, "Recruitment 3" ),
        length( mpSim.recruitmentByName[ "Recruitment 1" ] ) == 2,
        length( mpSim.recruitmentByName[ "Recruitment 3" ] ) == 1 ] )
    @test all( [ length( mpSim.recruitmentByTarget ) == 2,
        haskey( mpSim.recruitmentByTarget, "Base Node 1" ),
        haskey( mpSim.recruitmentByTarget, "Base Node 3" ),
        length( mpSim.recruitmentByTarget[ "Base Node 1" ] ) == 1,
        length( mpSim.recruitmentByTarget[ "Base Node 3" ] ) == 2 ] )
    @test !isSimulationConsistent( mpSim )
    @test verifySimulation!( mpSim )
    addSimulationRecruitment!( mpSim, recruitment2 )
    @test !verifySimulation!( mpSim )
end  # @testset "function addSimulationRecruitment!"

@testset "function clearSimulationRecruitment!" begin
    @test_deprecated clearRecruitmentSchemes!( mpSim )
    @test isempty( mpSim.recruitmentByName ) &&
        isempty( mpSim.recruitmentByTarget )
    @test verifySimulation!( mpSim )
end  # @testset "function clearSimulationRecruitment!"

@testset "function setSimulationRecruitment!" begin
    setRecruitmentTarget!( recruitment2, "Base Node 3" )
    setSimulationRecruitment!( mpSim, [ recruitment1, recruitment2,
        recruitment3, recruitment4 ] )
    @test all( [ length( mpSim.recruitmentByName[ "Recruitment 1" ] ) == 2,
        length( mpSim.recruitmentByName[ "Recruitment 2" ] ) == 1,
        length( mpSim.recruitmentByName[ "Recruitment 3" ] ) == 1,
        length( mpSim.recruitmentByTarget[ "Base Node 1" ] ) == 1,
        length( mpSim.recruitmentByTarget[ "Base Node 3" ] ) == 3 ] )
    @test !isSimulationConsistent( mpSim )
    @test verifySimulation!( mpSim )
end  # @testset "function setSimulationRecruitment!"

transition1 = Transition( "Transition 1", "dummy" )
transition2 = Transition( "Transition 2", "Base Node 1", "Base Node 3" )
transition3 = Transition( "Transition 3", "dummy", "dummy" )
transition4 = Transition( "Transition 4", "Base Node 2", "Base Node 3" )
transition5 = Transition( "Transition 5", "dummy", "Base Node 1" )
transition6 = Transition( "Transition 1", "Base Node 3", "Base Node 1" )

@testset "function addSimulationTransition!" begin
    @test_deprecated addTransition!( mpSim, transition1 )
    @test !addSimulationTransition!( mpSim, transition1, transition3,
        transition5 )
    setTransitionNode!( transition1, "Base Node 3" )
    setTransitionNode!( transition3, "Base Node 3" )
    setTransitionNode!( transition3, "Base Node 2", true )
    setTransitionNode!( transition5, "Base Node 1" )
    addTransitionCondition!( transition1,
        MPcondition( "Attribute 1", ==, "Stubber" ) )
    addTransitionCondition!( transition2,
        MPcondition( "Attribute 2", ==, "Shuriken Gun" ) )
    addTransitionCondition!( transition3,
        MPcondition( "Attribute 1", !=, "Lascannon" ) )
    addTransitionCondition!( transition4,
        MPcondition( "Attribute 1", ∈, [ "Stubber", "Gauss Rifle" ] ) )
    addTransitionCondition!( transition5,
        MPcondition( "Attribute 3", ∉, [ "Stubber", "Assault Cannon" ] ) )
    addSimulationTransition!( mpSim, transition1, transition2, transition3,
        transition4, transition5, transition6 )
    @test all( [ haskey( mpSim.transitionsByName, "Transition 1" ),
        haskey( mpSim.transitionsByName, "Transition 2" ),
        haskey( mpSim.transitionsByName, "Transition 3" ),
        haskey( mpSim.transitionsByName, "Transition 4" ),
        haskey( mpSim.transitionsByName, "Transition 5" ),
        length( mpSim.transitionsByName[ "Transition 1" ] ) == 2,
        length( mpSim.transitionsByName[ "Transition 2" ] ) == 1,
        length( mpSim.transitionsByName[ "Transition 3" ] ) == 1,
        length( mpSim.transitionsByName[ "Transition 4" ] ) == 1,
        length( mpSim.transitionsByName[ "Transition 5" ] ) == 1 ] )
    @test all( [ haskey( mpSim.transitionsBySource, "Base Node 1" ),
        haskey( mpSim.transitionsBySource, "Base Node 2" ),
        haskey( mpSim.transitionsBySource, "Base Node 3" ),
        length( mpSim.transitionsBySource[ "Base Node 1" ] ) == 2,
        length( mpSim.transitionsBySource[ "Base Node 2" ] ) == 1,
        length( mpSim.transitionsBySource[ "Base Node 3" ] ) == 3 ] )
    @test all( [ haskey( mpSim.transitionsByTarget, "Base Node 1" ),
        haskey( mpSim.transitionsByTarget, "Base Node 2" ),
        haskey( mpSim.transitionsByTarget, "Base Node 3" ),
        length( mpSim.transitionsByTarget[ "OUT" ] ) == 1,
        length( mpSim.transitionsByTarget[ "Base Node 1" ] ) == 2,
        length( mpSim.transitionsByTarget[ "Base Node 2" ] ) == 1,
        length( mpSim.transitionsByTarget[ "Base Node 3" ] ) == 2 ] )
    @test !isSimulationConsistent( mpSim )
    @test !verifySimulation!( mpSim )
end  # @testset "function addSimulationTransition!"

@testset "function clearSimulationTransitions!" begin
    @test_deprecated clearTransitions!( mpSim )
    @test all( [ isempty( mpSim.transitionsByName ),
        isempty( mpSim.transitionsBySource ),
        length( mpSim.transitionsByTarget ) == 1,
        haskey( mpSim.transitionsByTarget, "OUT" ) ] )
    @test !isSimulationConsistent( mpSim )
    @test verifySimulation!( mpSim )
end  # @testset "function clearSimulationTransitions!"

@testset "function setSimulationTransitions!" begin
    setTransitionNode!( transition4, "Base Node 1" )
    setTransitionNode!( transition3, "Base Node 3", true )
    clearTransitionConditions!( transition2 )
    clearTransitionConditions!( transition4 )
    setSimulationTransitions!( mpSim, [ transition1, transition2, transition3,
        transition4, transition5, transition6 ] )
    @test !isSimulationConsistent( mpSim )
    @test verifySimulation!( mpSim )
end  # @testset "function setSimulationTransitions!"

@testset "function setSimulationRetirement!" begin
    retirement = Retirement()
    setRetirementSchedule!( retirement, 12 )
    setRetirementAge!( retirement, 240 )
    setSimulationRetirement!( mpSim, retirement )
    @test all( [ mpSim.retirement.retirementAge == 240,
        mpSim.retirement.maxCareerLength == 0,
        mpSim.retirement.freq == 12, mpSim.retirement.offset == 0,
        retirement.isEither ] )
    setRetirementCareerLength!( retirement, 120 )
    setRetirementIsEither!( retirement, false )
    @test ( mpSim.retirement.maxCareerLength == 0 ) &&
        mpSim.retirement.isEither
    setSimulationRetirement!( mpSim, retirement, "Base Node 3" )
    @test length( mpSim.transitionsByTarget[ "OUT" ] ) == 1
    setRetirementIsEither!( retirement, true )
    setSimulationRetirement!( mpSim, retirement, "Base Node 1" )
    @test length( mpSim.transitionsByTarget[ "OUT" ] ) == 3
    @test !setSimulationRetirement!( mpSim, retirement, "Base Node 4" )
end  # @testset "function setSimulationRetirement!"

@testset "function removeSimulationRetirement!" begin
    removeSimulationRetirement!( mpSim, "Base Node 3" )
    @test length( mpSim.transitionsByTarget[ "OUT" ] ) == 2
    @test !removeSimulationRetirement!( mpSim, "Base Node 4" )
end  # @testset "function removeSimulationRetirement!"

@testset "function clearSimulationRetirement!" begin
    clearSimulationRetirement!( mpSim )
    @test isempty( mpSim. transitionsByTarget[ "OUT" ] )
end  # @testset "function clearSimulationRetirement!"

attrition1 = Attrition()
attrition2 = Attrition( "Attrition" )
attrition3 = Attrition( "" )
setAttritionRate!( attrition3, 0.01 )

@testset "function addSimulationAttrition!" begin
    addSimulationAttrition!( mpSim, attrition1, attrition2 )
    @test !isSimulationConsistent( mpSim )
    @test all( [ length( mpSim.attritionSchemes ) == 2,
        haskey( mpSim.attritionSchemes, "default" ),
        haskey( mpSim.attritionSchemes, "Attrition" ),
        mpSim.attritionSchemes[ "Attrition" ].rates == [ 0.0 ] ] )
    addSimulationAttrition!( mpSim, attrition3 )
    @test ( length( mpSim.attritionSchemes ) == 2 ) &&
        ( mpSim.attritionSchemes[ "default" ].rates == [ 0.01 ] )
    @test !addSimulationAttrition!( mpSim, attrition1, attrition3 )
    @test verifySimulation!( mpSim )
end  # @testset "function addSimulationAttrition!"

@testset "function removeSimulationAttrition!" begin
    removeSimulationAttrition!( mpSim, "Attrition", "Devil" )
    @test length( mpSim.attritionSchemes ) == 1
    @test !isSimulationConsistent( mpSim )
    removeSimulationAttrition!( mpSim, "" )
    @test ( length( mpSim.attritionSchemes ) == 1 ) &&
        ( mpSim.attritionSchemes[ "default" ].rates == [ 0.0 ] )
    @test !removeSimulationAttrition!( mpSim, "Attrition" )
    @test verifySimulation!( mpSim )
end  # @testset "function removeSimulationAttrition!"

@testset "function clearSimulationAttrition!" begin
    addSimulationAttrition!( mpSim, attrition3, attrition2 )
    @test length( mpSim.attritionSchemes ) == 2
    clearSimulationAttrition!( mpSim )
    @test ( length( mpSim.attritionSchemes ) == 1 ) &&
        ( mpSim.attritionSchemes[ "default" ].rates == [ 0.0 ] )
    @test !isSimulationConsistent( mpSim )
    @test verifySimulation!( mpSim )
end  # @testset "function clearSimulationAttrition!"

@testset "function setSimulationAttrition!" begin
    setNodeAttritionScheme!( node3, "Attrition" )
    @test !verifySimulation!( mpSim, true )
    setSimulationAttrition!( mpSim, [ attrition2 ] )
    @test verifySimulation!( mpSim )
end  # @testset "function setSimulationAttrition!"

@testset "function setSimulationLength!" begin
    @test_deprecated setSimulationLength( mpSim, 300 )
    @test mpSim.simLength == 300.0
    @test !setSimulationLength!( mpSim, -240 )
    @test mpSim.simLength == 300.0
end  # @testset "function setSimulationLength!"

@testset "function setSimulationPersonnelTarget!" begin
    @test_deprecated setPersonnelCap( mpSim, 1000 )
    @test mpSim.personnelTarget == 1000
    setSimulationPersonnelTarget!( mpSim,  -2000 )
    @test mpSim.personnelTarget == 0
end  # @testset "function setSimulationPersonnelTarget!"

@testset "function setSimulationDatabaseName!" begin
    setSimulationDatabaseName!( mpSim, "testDB" )
    @test mpSim.dbName == "testDB.sqlite"
end  # @testset "function setSimulationDatabaseName!"

end  # @testset "ManpowerSimulation"

println()