@testset "Node population reports" begin

@testset "function nodePopReport" begin
    @test isempty( nodePopReport( mpSim, [-12.0, -6.0], "active", "Career",
        "Blort", "A junior" ) )
    @test isempty( nodePopReport( mpSim, [7.5, 3.2], "Blort" ) )
    @test isempty( nodePopReport( mpSim, -12, "active", "Career", "Blort",
        "A junior" ) )
    report = nodePopReport( mpSim, 12, "active", "Career", "Blort", "A junior" )
    @test ( :Blort ∉ names( report ) ) &&
        ( ["active", "Career", "A junior"] ⊆ names( report ) )
    @test all( report[:, "active"] .== vcat( 30, 60, 84, 108, 124, 140, 156,
        172, 188, 204, 196, fill( 188, 15 ) ) )
    @test all( report[:, "A junior"] .== vcat( 10, fill( 20, 25 ) ) )
    @test all( report[:, "Career"] .== vcat( 0, 0, 24, 48, 64, 80, 96, 112,
        128, 144, 136, fill( 128, 15 ) ) )
end  # @testset "function nodePopReport"

@testset "function nodeEvolutionReport" begin
    report = nodeEvolutionReport( mpSim, [-12.0, -6.0], "active", "Career",
        "Blort", "A junior" )
    @test isempty( report[1] ) && isempty( report[2] )
    report = nodeEvolutionReport( mpSim, [7.5, 3.2], "Blort" )
    @test isempty( report[1] ) && isempty( report[2] )
    report = nodeEvolutionReport( mpSim, -12, "active", "Career", "Blort",
        "A junior" )
    @test isempty( report[1] ) && isempty( report[2] )
    report = nodeEvolutionReport( mpSim, 12, "active", "Career", "Blort",
        "A junior" )
    @test ["active", "Career", "A junior"] ⊆ names( report[1] )
    @test all( haskey.( Ref( report[2] ),
        ["active", "Career", "A junior"] ) )
    @test all( [length( report[2]["active"] ) == 2,
        length( report[2]["Career"] ) == 4,
        length( report[2]["A junior"] ) == 2] )
end  # @testset "function nodeEvolutionReport"

end  # @testset "Node population reports"