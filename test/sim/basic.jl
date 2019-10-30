
mpSim = ManpowerSimulation( "sim" )
setSimulationLength!( mpSim, 300 )
setSimulationDatabase!( mpSim, joinpath( "sim", "simDB" ) )


@testset "Basic simulation run tests" begin
    node = BaseNode( "A junior" )
    setNodeRequirements!( node, ("level", "Junior"), ("branch", "A"),
        ("isCareer", "no") )
    addSimulationBaseNode!( mpSim, node )
    @test_throws ErrorException run( mpSim, true )
    removeSimulationBaseNode!( mpSim, "A junior" )
    run( mpSim, true )
    @test now( mpSim ) == mpSim.simLength
    
end  # @testset "Basic simulation run tests"
