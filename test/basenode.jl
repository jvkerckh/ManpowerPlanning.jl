@testset "BaseNode" begin

@testset "BaseNode" begin
    @test_deprecated State( "State" )
    node = BaseNode( "Node" )
    @test all( [ node.name == "Node", node.target == 0,
        isempty( node.requirements ) ] )
end  # @testset "Constructor"

node = BaseNode( "State" )

@testset "function setNodeName!" begin
    @test_deprecated setName!( node, "Beep" )
    @test node.name == "Beep"
    setNodeName!( node, "Node" )
    @test node.name == "Node"
end  # @testset "function setNodeName!"

@testset "function setNodeTarget!" begin
    @test_deprecated setStateTarget!( node, 1000 )
    @test node.target == 1000
    setNodeTarget!( node, -5 )
    @test node.target == -1
    setNodeTarget!( node, 250 )
    @test node.target == 250
end  # @testset "function setNodeTarget!"

@testset "function setNodeAttritionScheme!" begin
    attrition1 = Attrition( "Attrition 1" )
    @test_deprecated setStateAttritionScheme!( node, attrition1 )
    @test node.attrition === "Attrition 1"
    setNodeAttritionScheme!( node, "Attrition 2" )
    @test node.attrition === "Attrition 2"
end  # @testset "function setNodeAttritionScheme!"

@testset "function addNodeRequirement!" begin
    @test_deprecated addRequirement!( node, "rank category", "officer" )
    @test haskey( node.requirements, "rank category" ) &&
        ( node.requirements[ "rank category" ] == "officer" )
    addNodeRequirement!( node, "rank", "captain" )
    @test haskey( node.requirements, "rank" ) && 
        ( node.requirements[ "rank" ] == "captain" )
    addNodeRequirement!( node, ("branch", "ground force"), ("rank", "major") )
    @test all( [ haskey( node.requirements, "branch" ),
        node.requirements[ "branch" ] == "ground force",
        node.requirements[ "rank" ] == "major" ] )
    @test !addNodeRequirement!( node, ("sub branch", "artillery"),
        ("rank", "lieutenant"), ("sub branch", "engineers") )
    @test !haskey( node.requirements, "sub branch" ) &&
        ( node.requirements[ "rank" ] == "major" )
end  # @testset "function addNodeRequirement!"

@testset "function removeNodeRequirement!" begin
    @test_deprecated removeRequirement!( node, "rank category" )
    @test !haskey( node.requirements, "rank category" )
    removeNodeRequirement!( node, "branch", "rank category" )
    @test !haskey( node.requirements, "branch" )
    @test !removeNodeRequirement!( node, "branch" )
end  # @testset "function removeNodeRequirement!"

@testset "function clearNodeRequirements!" begin
    clearNodeRequirements!( node )
    @test isempty( node.requirements )
end  # @testset "function clearNodeRequirements!"

@testset "function setNodeRequirements!" begin
    setNodeRequirements!( node, Dict( "rank" => "captain", "grade" => "A" ) )
    @test all( [ length( node.requirements ) == 2,
        haskey( node.requirements, "rank" ),
        haskey( node.requirements, "grade" ),
        node.requirements[ "rank" ] == "captain",
        node.requirements[ "grade" ] == "A" ] )
    setNodeRequirements!( node, ("rank", "corporal"), ("branch", "air") )
    @test all( [ length( node.requirements ) == 2,
        haskey( node.requirements, "rank" ),
        haskey( node.requirements, "branch" ),
        node.requirements[ "rank" ] == "corporal",
        node.requirements[ "branch" ] == "air" ] )
    setNodeRequirements!( node, [ "grade" ], [ "D" ] )
    @test all( [ length( node.requirements ) == 1,
        haskey( node.requirements, "grade" ),
        node.requirements[ "grade" ] == "D" ] )
    @test !setNodeRequirements!( node, ("rank", "private"), ("grade", "D"),
        ("rank", "corporal") )
    @test !setNodeRequirements!( node, [ "rank", "grade", "rank" ],
        [ "lieutenant", "A", "colonel" ] )
    @test !setNodeRequirements!( node, [ "rank" ], [ "colonel", "A" ] )
end  # @testset "function setNodeRequirements!"

@testset "function isPersonnelOfNode" begin
    addNodeRequirement!( node, ("rank", "corporal") )
    @test MP.isPersonnelOfNode( Dict( "rank" => "corporal", "branch" => "navy",
        "grade" => "D" ), node )
    @test !MP.isPersonnelOfNode( Dict( "rank" => "sergeant", "grade" => "D" ),
        node )
    @test !MP.isPersonnelOfNode( Dict( "rank" => "corporal" ), node )
end  # @testset "function isPersonnelOfNode" begin

end  # @testset "BaseNode"

println()