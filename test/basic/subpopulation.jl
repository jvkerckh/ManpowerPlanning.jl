@testset "Subpopulation" begin

@testset "Constructor" begin
    subpopulation = Subpopulation( "Subpop" )
    @test all( [ subpopulation.name == "Subpop",
        subpopulation.sourceNode == "active",
        isempty( subpopulation.timeConds ),
        isempty( subpopulation.historyConds ),
        isempty( subpopulation.attributeConds ) ] )
end  # @testset "Constructor"

subpopulation = Subpopulation( "Subpop" )

@testset "function setSubpopulationSourceNode!" begin
    setSubpopulationSourceNode!( subpopulation, "Node" )
    @test subpopulation.sourceNode == "Node"
    setSubpopulationSourceNode!( subpopulation, "" )
    @test subpopulation.sourceNode == "active"
end  # @testset "function setSubpopulationSourceNode!"

cond1 = MPcondition( "Attribute", !=, "value")
cond2 = MPcondition( "stARted AS", ==, "Pilot" )
cond3 = MPcondition( "TeNuRe", <=, 36 )

@testset "function addSubpopulationCondition!" begin
    addSubpopulationCondition!( subpopulation, cond1, cond2, cond3 )
    @test all( length.( [ subpopulation.timeConds, subpopulation.historyConds,
        subpopulation.attributeConds ] ) .== 1 )
    @test ( subpopulation.historyConds[ 1 ].attribute == "started as" ) &&
        ( subpopulation.timeConds[ 1 ].attribute == "tenure" )
end  # @testset "function addSubpopulationCondition!"

@testset "function clearSubpopulationConditions!" begin
    clearSubpopulationConditions!( subpopulation )
    @test all( isempty.( [ subpopulation.timeConds, subpopulation.historyConds,
        subpopulation.attributeConds ] ) )
end  # @testset "function clearSubpopulationConditions!"

@testset "function setSubpopulationConditions!" begin
    setSubpopulationConditions!( subpopulation, [ cond1, cond2, cond3 ] )
    @test all( length.( [ subpopulation.timeConds, subpopulation.historyConds,
        subpopulation.attributeConds ] ) .== 1 )
end  # @testset "function setSubpopulationConditions!"

println()

end  # @testset "Subpopulation"