@testset "Flux reports" begin

@testset "Time grid generation" begin
    @test isempty( MP.generateTimeGrid( mpSim, -12 ) )
    @test MP.generateTimeGrid( mpSim, 12 ) == [ 0.0 ]
    run( mpSim.sim )
    @test MP.generateTimeGrid( mpSim, 12 ) == collect( 0.0:12.0:300.0 )
end  # @testset "Time grid generation"

@testset "function nodeFluxReport" begin
    @test isempty( nodeFluxReport( mpSim, [ -6.0, -12.0 ], :in, "active",
        "A junior", "Career", "Blort" ) )
    @test isempty( nodeFluxReport( mpSim, [ 12.0, 8.0, 0.0 ], :bang, "active",
        "A junior", "Career", "Blort" ) )
    @test isempty( nodeFluxReport( mpSim, [ 12.0, 8.0, 0.0 ], :in, "Blort" ) )
    @test isempty( nodeFluxReport( mpSim, -6, :in, "active",
        "A junior", "Career", "Blort" ) )

    report = nodeFluxReport( mpSim, 12, :in, "active", "A junior", "Career",
        "Blort" )
    @test !haskey( report, "Blort" ) && all( haskey.( Ref( report ), [ "active",
        "Career", "A junior" ] ) )
    @test all( report[ "active" ][ Symbol( "external => active" ) ] .== 30 )
    @test all( report[ "A junior" ][ Symbol( "other => A junior" ) ] .== 10 )
    @test all( report[ "Career" ][ Symbol( "other => Career" ) ] .==
        vcat( 0, 0, 24, 24, fill( 16, 22 ) ) )

    report = nodeFluxReport( mpSim, 12, :out, "active", "A junior", "Career",
        "Blort" )
    @test all( report[ "active" ][ Symbol( "active => external" ) ] .==
        vcat( 0, 0, 6, 6, fill( 14, 6 ), 38, 38, fill( 30, 14 ) ) )
    @test all( report[ "A junior" ][ Symbol( "A junior => other" ) ] .==
        vcat( 0, 0, fill( 10, 24 ) ) )
    @test all( report[ "Career" ][ Symbol( "Career => other" ) ] .==
        vcat( fill( 0, 10 ), 24, 24, fill( 16, 14 ) ) )

    report = nodeFluxReport( mpSim, 12, :within, "active", "A junior", "Career",
        "Blort" )
    @test all( report[ "active" ][ Symbol( "within active" ) ] .== [ 0, 0, 24,
        24, 16, 26, 26, 21, 16, 16, 26, 26, 21, 16, 16, 26, 26, 21, 16, 16, 26,
        26, 21, 16, 16, 26 ] )
end  # @testset "function nodeFluxReport"

println()

end  # @testset "Flux reports"