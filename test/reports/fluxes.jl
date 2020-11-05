@testset "Flux reports" begin

@testset "function nodeFluxReport" begin
    @test isempty( nodeFluxReport( mpSim, [-6.0, -12.0], :in, "active",
        "A junior", "Career", "Blort" ) )
    @test isempty( nodeFluxReport( mpSim, [12.0, 8.0, 0.0], :bang, "active",
        "A junior", "Career", "Blort" ) )
    @test isempty( nodeFluxReport( mpSim, [12.0, 8.0, 0.0], :in, "Blort" ) )
    @test isempty( nodeFluxReport( mpSim, -6, :in, "active",
        "A junior", "Career", "Blort" ) )

    report = nodeFluxReport( mpSim, 12, :in, "active", "A junior", "Career",
        "Blort" )
    @test !haskey( report, "Blort" ) && all( haskey.( Ref( report ), ["active",
        "Career", "A junior"] ) )
    @test all( report["active"][:, "external => active"] .== 30 )
    @test all( report["A junior"][:, "other => A junior"] .== 10 )
    @test all( report["Career"][:, "other => Career"] .==
        vcat( 0, 0, 24, 24, fill( 16, 22 ) ) )

    report = nodeFluxReport( mpSim, 12, :out, "active", "A junior", "Career",
        "Blort" )
    @test all( report["active"][:, "active => external"] .==
        vcat( 0, 0, 6, 6, fill( 14, 6 ), 38, 38, fill( 30, 14 ) ) )
    @test all( report["A junior"][:, "A junior => other"] .==
        vcat( 0, 0, fill( 10, 24 ) ) )
    @test all( report["Career"][:, "Career => other"] .==
        vcat( fill( 0, 10 ), 24, 24, fill( 16, 14 ) ) )

    report = nodeFluxReport( mpSim, 12, :within, "active", "A junior", "Career",
        "Blort" )
    @test all( report["active"][:, "within active"] .== [0, 0,
        24, 24, 16, 26, 26, 21, 16, 16, 26, 26, 21, 16, 16, 26, 26, 21, 16, 16,
        26, 26, 21, 16, 16, 26] )
end  # @testset "function nodeFluxReport"

@testset "function transitionFluxReport" begin
    @test isempty( transitionFluxReport( mpSim, [-12.0, -8.0], "Promotion",
        ("A junior", "A senior"), ("Reserve", "Reserve junior", "B senior") ) )
    @test isempty( transitionFluxReport( mpSim, [12.0, 24.0], "Blook",
        ("Foo", "Bar"), ("A senior", "B junior"), ("Blook", "Foo", "Bar"),
        ("Reserve", "A junior", "A senior") ) )
    @test isempty( transitionFluxReport( mpSim, -12.0, "Promotion",
        ("A junior", "A senior"), ("Reserve", "Reserve junior", "B senior") ) )
    report = transitionFluxReport( mpSim, 12, "attrition", "Promotion", "EW",
        "B-" )
    @test all( report[:, "attrition"] .== 0 )
    @test all( report[:, "Promotion"] .== [0, 0, 16, 16, 16, 26, 26, 21, 16,
        16, 26, 26, 21, 16, 16, 26, 26, 21, 16, 16, 26, 26, 21, 16, 16, 26] )
    @test all( report[:, "EW"] .== 30 )
    @test all( report[:, "B-"] .==
        vcat( 0, 0, 6, 6, fill( 14, 22 ) ) )
    
    report = transitionFluxReport( mpSim, 12, ("external", "A junior"),
        ("B senior", ""), ("Reserve junior", "A senior") )
    @test all( report[:, "external => A junior"] .== 10 )
    @test all( report[:, "B senior => external"] .==
        vcat( fill( 0, 10 ), 7, 7, 8, 8, 8, 3, 3, 8, 8, 8, 3, 3, 8, 8, 8, 3 ) )
    @test all( report[:, "Reserve junior => A senior"] .==
        vcat( 0, 0, 4, 4, fill( 0, 22 ) ) ) 

    report = transitionFluxReport( mpSim, 12, ("attrition", "Master", "out"),
        ("PE", "A senior", ""), ("EW", "OUT", "A junior"),
        ("Reserve", "Reserve junior", "B senior") )
    @test all( report[:, "attrition: Master => external"] .== 0 )
    @test all( report[:, "PE: A senior => external"] .==
        vcat( fill( 0, 10 ), 7, 7, 3, 8, 8, 3, 3, 3, 8, 8, 3, 3, 3, 8, 8, 3 ) )
    @test all( report[:, "EW: external => A junior"] .== 10 )
    @test all( report[:, "Reserve: Reserve junior => B senior"] .==
        vcat( 0, 0, 4, 4, fill( 0, 22 ) ) )
end  # @testset "function transitionFluxReport"

end  # @testset "Flux reports"