@testset "Basic simulation run tests" begin
    mpSim = ManpowerSimulation( "sim" )
    setSimulationLength!( mpSim, 300 )

    node = BaseNode( "A junior" )
    setNodeRequirements!( node, ("level", "Junior"), ("branch", "A"),
        ("isCareer", "no") )
    addSimulationBaseNode!( mpSim, node )
    @test_throws ErrorException run( mpSim )
    removeSimulationBaseNode!( mpSim, "A junior" )
    run( mpSim )
    @test now( mpSim ) == mpSim.simLength
    
end  # @testset "Basic simulation run tests"