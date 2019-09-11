@testset "CompoundNode" begin

@testset "Constructor" begin
    @test_deprecated CompoundState( "Test" )
    compoundNode = CompoundNode( "Compound node" )
    @test all( [ compoundNode.name == "Compound node",
        isempty( compoundNode.baseNodeList ), compoundNode.nodeTarget == -1 ] )
end  # @testset "Constructor"

compoundNode = CompoundNode( "Compound node" )

@testset "function addCompoundNodeComponent!" begin
    @test_deprecated addStateToCompound!( compoundNode, "Air Officer",
        "Air Non-Com", "Air Officer" )
    @test ( length( compoundNode.baseNodeList ) == 2 ) &&
        ( [ "Air Officer", "Air Non-Com" ] ⊆ compoundNode.baseNodeList )
    addCompoundNodeComponent!( compoundNode, "Air Officer", "Air Volunteer" )
    @test ( length( compoundNode.baseNodeList ) == 3 ) &&
        ( "Air Volunteer" ∈ compoundNode.baseNodeList )
    @test !addCompoundNodeComponent!( compoundNode, "Air Officer" )
end  # @testset "function addCompoundNodeComponent!"

@testset "function removeCompoundNodeComponent!" begin
    @test_deprecated removeStateFromCompound!( compoundNode, "Air Officer",
        "Air General" )
    @test ( length( compoundNode.baseNodeList ) == 2 ) &&
        ( "Air Officer" ∉ compoundNode.baseNodeList )
    removeCompoundNodeComponent!( compoundNode, "Air Officer", "Air Non-Com" )
    @test ( length( compoundNode.baseNodeList ) == 1 ) &&
        ( "Air Non-Com" ∉ compoundNode.baseNodeList )
    @test !removeCompoundNodeComponent!( compoundNode, "Air Non-Com",
        "Air Officer" )
end  # @testset "function removeCompoundNodeComponent!"

@testset "function clearCompoundNodeComponents!" begin
    @test_deprecated clearStatesFromCompound!( compoundNode )
    @test isempty( compoundNode.baseNodeList)
end  # @testset "function clearCompoundNodeComponents!"

@testset "function setCompoundNodeComponents!" begin
    setCompoundNodeComponents!( compoundNode, [ "Ground Officer",
        "Ground Non-Com", "Ground Officer" ] )
    @test ( length( compoundNode.baseNodeList ) == 2 ) &&
        ( [ "Ground Officer", "Ground Non-Com" ] ⊆ compoundNode.baseNodeList )
    setCompoundNodeComponents!( compoundNode, "Medical Volunteer",
        "Medical Officer" )
    @test ( length( compoundNode.baseNodeList ) == 2 ) &&
        ( [ "Medical Officer", "Medical Volunteer" ] ⊆ 
        compoundNode.baseNodeList )
end  # @testset "function setCompoundNodeComponents!"

@testset "function setCompoundNodeTarget" begin
    @test_deprecated setStateTarget!( compoundNode, 1000 )
    @test compoundNode.nodeTarget == 1000
    setCompoundNodeTarget!( compoundNode, -500 )
    @test compoundNode.nodeTarget == -1
end  # @testset "function setCompoundNodeTarget"

end  # @testset "CompoundNode"

println()