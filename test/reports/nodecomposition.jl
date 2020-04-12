@testset "Node composition report" begin

@testset "function nodeCompositionReport" begin
    @test isempty( nodeCompositionReport( mpSim, [-12.0, -8.0], "A junior",
        "Foo", "B senior", "Career", "Branch A", "Bar" ) )
    @test isempty( nodeCompositionReport( mpSim, [12.0, 8.0], "Foo", "Bar" ) )
    @test isempty( nodeCompositionReport( mpSim, -12, "A junior", "Foo",
        "B senior", "Career", "Branch A", "Bar" ) )
    report = nodeCompositionReport( mpSim, 12, "A junior", "Empty", "Foo",
        "B senior", "Career", "Branch A", "Bar" )
    @test haskey( report, "Base nodes" ) &&
        ( Symbol.( ["A junior", "B senior"] ) ⊆
        names( report["Base nodes"] ) )
    @test all( [haskey( report, "Career" ), haskey( report, "Branch A" ),
        !haskey( report, "Foo" ), !haskey( report, "Bar" ),
        haskey( report, "Empty" )] )
    @test ( size( report["Empty"], 2 ) == 2 ) &&
        all( report["Empty"][:, :Empty] .== 0 )
end  # @testset "function nodeCompositionReport"

println()

end  # @testset "Node composition report"