@testset "Time grid generation" begin
    @test isempty( MP.generateTimeGrid( mpSim, -12 ) )
    @test MP.generateTimeGrid( mpSim, 12 ) == [0.0]
    run( mpSim.sim )
    @test MP.generateTimeGrid( mpSim, 12 ) == collect( 0.0:12.0:300.0 )
end  # @testset "Time grid generation"