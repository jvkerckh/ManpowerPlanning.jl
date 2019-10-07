@testset "Subpopulation report" begin

@testset "function subpopulationPopReport" begin
    subpop1 = Subpopulation( "Subpop1" )
    addSubpopulationCondition!( subpop1, MPcondition( "branch", !=, "A" ) )
    subpop2 = Subpopulation( "Subpop2" )
    addSubpopulationCondition!( subpop2, MPcondition( "time in node", >=, 84 ) )
    subpop3 = Subpopulation( "Subpop3" )
    addSubpopulationCondition!( subpop3, MPcondition( "started as", ==,
        "Reserve junior" ) )
    subpop4 = Subpopulation( "Subpop4" )
    addSubpopulationCondition!( subpop4, MPcondition( "tenure", <, 12 ) )
    subpop5 = Subpopulation( "Subpop5" )
    addSubpopulationCondition!( subpop5, MPcondition( "was", !=, "B junior" ) )
    subpop6 = Subpopulation( "Subpop6" )
    subpop7 = Subpopulation( "Subpop7" )
    addSubpopulationCondition!( subpop7, MPcondition( "age", >=, 240 ) )

    setSubpopulationSourceNode!.( [ subpop1, subpop2, subpop3, subpop4,
        subpop5, subpop6, subpop7 ], [ "", "", "", "Reserve junior", "Career",
        "Branch A", "Foo" ] )

    @test isempty( subpopulationPopReport( mpSim, [ -12.0, -6.0 ], subpop1,
        subpop2, subpop3, subpop4, subpop5, subpop6, subpop7 ) )
    @test isempty( subpopulationPopReport( mpSim, [ 12.0, 6.0 ], subpop7 ) )
    @test isempty( subpopulationPopReport( mpSim, -12, subpop1, subpop2,
        subpop3, subpop4, subpop5, subpop6, subpop7 ) )

    nodeReport = nodePopReport( mpSim, 12, "A junior", "B junior", "Reserve junior", "A senior", "B senior", "Master", "" )
    
    report = subpopulationPopReport( mpSim, 12, subpop1, subpop2, subpop3,
        subpop4, subpop5, subpop6, subpop7 )
    @test all( report[ :, Symbol( "Subpop1" ) ] .==
        nodeReport[ :, Symbol( "B junior" ) ] +
        nodeReport[ :, Symbol( "Reserve junior" ) ] +
        nodeReport[ :, Symbol( "B senior" ) ] +
        nodeReport[ :, Symbol( "Master" ) ] )
    @test all( report[ :, Symbol( "Subpop2" ) ] .==
        vcat( fill( 0, 7 ), 24, 48, 64, 56, fill( 48, 15 ) ) )
    @test all( report[ :, Symbol( "Subpop3" ) ] .==
        vcat( 10, 20, 28, fill( 36, 7 ), 28, fill( 20, 15 ) ) )
    @test all( report[ :, Symbol( "Subpop4" ) ] .== 10 )
    @test all( report[ :, Symbol( "Subpop5" ) ] .==
        vcat( 0, 0, 16, 32:8:80, 72, fill( 64, 15 ) ) )
    @test all( report[ :, Symbol( "Subpop6" ) ] .==
        nodeReport[ :, Symbol( "A junior" ) ] +
        nodeReport[ :, Symbol( "A senior" ) ] )
    @test Symbol( "Subpop7" ) ∉ names( report )
end  # @testset "function subpopulationPopReport"

println()

end  # @testset "Subpopulation report"