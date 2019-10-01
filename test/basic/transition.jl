@testset "Transition" begin

@testset "Constructor" begin
    transition = Transition( "Transition", "Node A", "Node B" )
    @test all( [ transition.name == "Transition",
        transition.sourceNode == "Node A", transition.targetNode == "Node B",
        !transition.isOutTransition, transition.freq == 1.0,
        transition.offset == 0.0, transition.maxAttempts == 1,
        transition.minFlux == 0, transition.maxFlux == -1,
        !transition.hasPriority ] )
    transition = Transition( "Transition", "Node A" )
    @test ( transition.sourceNode == "Node A" ) &&
        ( transition.targetNode == "dummy" ) && transition.isOutTransition
end  # @testset "Constructor"

transition = Transition( "Transition", "dummy", "dummy" )

@testset "function setTransitionNode!" begin
    @test_deprecated setState( transition, BaseNode( "Node A" ) )
    @test transition.sourceNode == "Node A"
    setTransitionNode!( transition, "Node B", true )
    @test transition.targetNode == "Node B"
end  # @testset "function setTransitionNode!"

@testset "function setTransitionIsOut!" begin
    @test_deprecated setIsOutTrans!( transition, true )
    @test transition.isOutTransition
    setTransitionIsOut!( transition, false )
    @test !transition.isOutTransition
end  # @testset "function setTransitionIsOut!"

@testset "function setTransitionSchedule!" begin
    @test_deprecated setSchedule( transition, 12, 4 )
    @test ( transition.freq == 12.0 ) && ( transition.offset == 4.0 )
    setTransitionSchedule!( transition, 6 )
    @test ( transition.freq == 6.0 ) && ( transition.offset == 0.0 )
    setTransitionSchedule!( transition, 6, 10 )
    @test transition.offset == 4.0
    setTransitionSchedule!( transition, 6, -3 )
    @test transition.offset == 3.0
    @test !setTransitionSchedule!( transition, -9 ) &&
        ( transition.freq == 6.0 )
end  # @testset "function setTransitionSchedule!"

@testset "function setTransitionMaxAttempts!" begin
    @test_deprecated setMaxAttempts( transition, 5 )
    @test transition.maxAttempts == 5
    setTransitionMaxAttempts!( transition, -10 )
    @test transition.maxAttempts == -1
end  # @testset "function setTransitionMaxAttempts!"

@testset "function setTransitionFluxLimits!" begin
    @test_deprecated setFluxBounds( transition, 10, 100 )
    @test ( transition.minFlux == 10 ) && ( transition.maxFlux == 100 )
    setTransitionFluxLimits!( transition, -50, -10 )
    @test ( transition.minFlux == 0 ) && ( transition.maxFlux == -1 )
    @test !setTransitionFluxLimits!( transition, 25, 10 )
    setTransitionFluxLimits!( transition, 20, 100 )
end  # @testset "function setTransitionFluxLimits!"

@testset "function setTransitionHasPriority!" begin
    @test_deprecated setHasPriority( transition, true )
    @test transition.hasPriority && ( transition.priority < 0 )
    setTransitionHasPriority!( transition, false )
    @test !transition.hasPriority && ( transition.priority > 0 )
end  # @testset "function setTransitionHasPriority!"

@testset "function addTransitionCondition!" begin
    cond = MP.MPcondition( "rank", ==, "captain" )
    @test_deprecated addCondition!( transition, cond )
    @test ( length( transition.extraConditions ) == 1 ) &&
        ( cond ∈ transition.extraConditions )
    cond = MP.MPcondition( "branch", ∈, [ "air", "navy" ] )
    addTransitionCondition!( transition, cond )
    @test cond ∈ transition.extraConditions 
end  # @testset "function addTransitionCondition!"

@testset "function clearTransitionCondition!" begin
    @test_deprecated clearConditions!( transition )
    @test isempty( transition.extraConditions )
end  # @testset "function clearTransitionCondition!"

@testset "function setTransitionConditions!" begin
    cond1 = MP.MPcondition( "rank", ==, "adjutant" )
    cond2 = MP.MPcondition( "branch", ∈, [ "air", "medical" ] )
    setTransitionConditions!( transition, [ cond1, cond2 ] )
    @test ( length( transition.extraConditions ) == 2 ) &&
        ( [ cond1, cond2 ] ⊆ transition.extraConditions )
end  # @testset "function setTransitionConditions!"

@testset "function addTransitionAttributeChange!" begin
    @test_deprecated addAttributeChange!( transition, "rank", "chief adjutant" )
    @test haskey( transition.extraChanges, "rank" ) &&
        ( transition.extraChanges[ "rank" ] == "chief adjutant" )
    addTransitionAttributeChange!( transition, ("branch", "navy"),
        ("rank", "lieutenant") )
    @test all( [ transition.extraChanges[ "rank" ] == "lieutenant",
        haskey( transition.extraChanges, "branch" ),
        transition.extraChanges[ "branch" ] == "navy" ] )
    @test !addTransitionAttributeChange!( transition, ("rank", "captain"), ("career", "limited"), ("rank", "major") )
end  # @testset "function addTransitionAttributeChange!"

@testset "function clearTransitionAttributeChanges!" begin
    @test_deprecated clearAttributeChanges!( transition )
    @test isempty( transition.extraChanges )
end  # @testset "function clearTransitionAttributeChanges!"

@testset "function setTransitionAttributeChanges!" begin
    setTransitionAttributeChanges!( transition, Dict( "rank" => "captain",
        "grade" => "A" ) )
    @test all( [ length( transition.extraChanges ) == 2,
        haskey( transition.extraChanges, "rank" ),
        haskey( transition.extraChanges, "grade" ),
        transition.extraChanges[ "rank" ] == "captain",
        transition.extraChanges[ "grade" ] == "A" ] )
    setTransitionAttributeChanges!( transition, ("rank", "corporal"),
        ("branch", "air") )
    @test all( [ length( transition.extraChanges ) == 2,
        haskey( transition.extraChanges, "rank" ),
        haskey( transition.extraChanges, "branch" ),
        transition.extraChanges[ "rank" ] == "corporal",
        transition.extraChanges[ "branch" ] == "air" ] )
    setTransitionAttributeChanges!( transition, [ "grade" ], [ "D" ] )
    @test all( [ length( transition.extraChanges ) == 1,
        haskey( transition.extraChanges, "grade" ),
        transition.extraChanges[ "grade" ] == "D" ] )
    @test !setTransitionAttributeChanges!( transition, ("rank", "private"),
        ("grade", "D"), ("rank", "corporal") )
    @test !setTransitionAttributeChanges!( transition,
        [ "rank", "grade", "rank" ], [ "lieutenant", "A", "colonel" ] )
    @test !setTransitionAttributeChanges!( transition, [ "rank" ],
        [ "colonel", "A" ] )
end  # @testset "function setTransitionAttributeChanges!"

@testset "function setTransitionProbabilities!" begin
    @test_deprecated setTransProbabilities( transition, [ 0.3, 1.2, -0.5, 0.9,
        1.0 ] )
    @test transition.probabilityList == [ 0.3, 0.9, 1.0 ]
    setTransitionProbabilities!( transition, [ 0.2, 0.5, 1.0 ] )
    @test transition.probabilityList == [ 0.2, 0.5, 1.0 ]
    @test !setTransitionProbabilities!( transition, [ 1.2, 1.3, -0.5 ] )
end  # @testset "function setTransitionProbabilities!"

end  # @testset "Transition"

println()