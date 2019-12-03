@testset "Recruitment tests" begin

mpSim = ManpowerSimulation( "sim" )
setSimulationLength!( mpSim, 300 )

attribute = Attribute( "attribute A" )
addInitialAttributeValue!( attribute, "value A", 1 )
addSimulationAttribute!( mpSim, attribute )

node = BaseNode( "node A" )
setNodeTarget!( node, 50 )
addNodeRequirement!( node, "attribute A", "value A" )
addSimulationBaseNode!( mpSim, node )

@testset "Basic recruitment test" begin
    recruitment = Recruitment( "recruitment A" )
    setRecruitmentSchedule!( recruitment, 12 )
    setRecruitmentTarget!( recruitment, "node A" )
    setRecruitmentFixed!( recruitment, 10 )
    addSimulationRecruitment!( mpSim, recruitment )

    @test verifySimulation!( mpSim )
    run( mpSim, saveConfig = false )
    report = nodeFluxReport( mpSim, 12, :in, "active" )[ "active" ]
    @test all( report[ :, Symbol( "external => active" ) ] .== 10 ) &&
        all( report[ :, Symbol( "recruitment A: external => node A" ) ] .== 10 )
end  # @testset "Basic recruitment test"

@testset "Recruitment schedule" begin
    clearSimulationRecruitment!( mpSim )
    recruitment = Recruitment( "recruitment A" )
    setRecruitmentSchedule!( recruitment, 24 )
    setRecruitmentTarget!( recruitment, "node A" )
    setRecruitmentFixed!( recruitment, 10 )
    addSimulationRecruitment!( mpSim, recruitment )

    @test verifySimulation!( mpSim )
    run( mpSim, saveConfig = false )
    report = nodeFluxReport( mpSim, 12, :in, "active" )[ "active" ]
    @test all( report[ :, Symbol( "external => active" ) ] .==
        repeat( [ 10, 0 ], 13 ) )

    clearSimulationRecruitment!( mpSim )
    recruitment = Recruitment( "recruitment A" )
    setRecruitmentSchedule!( recruitment, 24, 12 )
    setRecruitmentTarget!( recruitment, "node A" )
    setRecruitmentFixed!( recruitment, 10 )
    addSimulationRecruitment!( mpSim, recruitment )

    @test verifySimulation!( mpSim )
    run( mpSim, saveConfig = false )
    report = nodeFluxReport( mpSim, 12, :in, "active" )[ "active" ]
    @test all( report[ :, Symbol( "external => active" ) ] .==
        repeat( [ 0, 10 ], 13 ) )

end  # @testset "Recruitment schedule"

@testset "Adaptive recruitment test" begin
    clearSimulationRecruitment!( mpSim )
    recruitment = Recruitment( "recruitment A" )
    setRecruitmentSchedule!( recruitment, 12 )
    setRecruitmentTarget!( recruitment, "node A" )
    setRecruitmentAdaptiveRange!( recruitment, 5, 10 )
    addSimulationRecruitment!( mpSim, recruitment )

    @test verifySimulation!( mpSim )
    run( mpSim, saveConfig = false )
    report = nodeFluxReport( mpSim, 12, :in, "active" )[ "active" ]
    report = report[ :, Symbol( "external => active" ) ]
    targetRec = vcat( fill( 10, 5 ), fill( 5, 21 ) )
    @test all( report .== targetRec )
end  # @testset "Adaptive recruitment test"

@testset "Disc random recruitment test" begin
    clearSimulationRecruitment!( mpSim )
    recruitment = Recruitment( "recruitment A" )
    setRecruitmentSchedule!( recruitment, 1 )
    setRecruitmentTarget!( recruitment, "node A" )
    setRecruitmentDist!( recruitment, :disc, Dict( 5 => 1.0, 10 => 2.0 ) )
    addSimulationRecruitment!( mpSim, recruitment )

    @test verifySimulation!( mpSim )

    Random.seed!( 3141592 )
    run( mpSim, saveConfig = false )
    report = nodeFluxReport( mpSim, 1, :in, "active" )[ "active" ]
    report = report[ :, Symbol( "external => active" ) ]
    reportCounts = counts( Vector{Int}( report ), 5:10 )[ [ 1, end ] ]
    @test pvalue( ChisqTest( reportCounts, [ 1/3, 2/3 ] ) ) > 0.05
    @test all( reportCounts .== [ 102, 199 ] )

    Random.seed!( 2718281 )
    run( mpSim, saveConfig = false )
    report = nodeFluxReport( mpSim, 1, :in, "active" )[ "active" ]
    report = report[ :, Symbol( "external => active" ) ]
    reportCounts = counts( Vector{Int}( report ), 5:10 )[ [ 1, end ] ]
    @test pvalue( ChisqTest( reportCounts, [ 1/3, 2/3 ] ) ) > 0.05
    @test all( reportCounts .== [ 107, 194 ] )

    Random.seed!( 1414213 )
    run( mpSim, saveConfig = false )
    report = nodeFluxReport( mpSim, 1, :in, "active" )[ "active" ]
    report = report[ :, Symbol( "external => active" ) ]
    reportCounts = counts( Vector{Int}( report ), 5:10 )[ [ 1, end ] ]
    @test pvalue( ChisqTest( reportCounts, [ 1/3, 2/3 ] ) ) > 0.05
    @test all( reportCounts .== [ 99, 202 ] )
end  # @testset "Disc random recruitment test"

@testset "PUnif random recruitment test" begin
    clearSimulationRecruitment!( mpSim )
    recruitment = Recruitment( "recruitment A" )
    setRecruitmentSchedule!( recruitment, 1 )
    setRecruitmentTarget!( recruitment, "node A" )
    setRecruitmentDist!( recruitment, :pUnif,
        Dict( 5 => 1.0, 8 => 2.0, 11 => 1.0 ) )
    addSimulationRecruitment!( mpSim, recruitment )

    @test verifySimulation!( mpSim )
    p = [ 1.0, 1.0, 1.0, 2.0, 2.0, 2.0 ]
    p /= sum( p )

    Random.seed!( 3141592 )
    run( mpSim, saveConfig = false )
    report = nodeFluxReport( mpSim, 1, :in, "active" )[ "active" ]
    report = report[ :, Symbol( "external => active" ) ]
    reportCounts = counts( Vector{Int}( report ), 5:10 )
    @test pvalue( ChisqTest( reportCounts, p ) ) > 0.05
    @test all( reportCounts .== [ 34, 25, 27, 71, 65, 79 ] )
    
    Random.seed!( 2718281 )
    run( mpSim, saveConfig = false )
    report = nodeFluxReport( mpSim, 1, :in, "active" )[ "active" ]
    report = report[ :, Symbol( "external => active" ) ]
    reportCounts = counts( Vector{Int}( report ), 5:10 )
    @test pvalue( ChisqTest( reportCounts, p ) ) > 0.05
    @test all( reportCounts .== [ 33, 44, 27, 72, 63, 62 ] )

    Random.seed!( 1414213 )
    run( mpSim, saveConfig = false )
    report = nodeFluxReport( mpSim, 1, :in, "active" )[ "active" ]
    report = report[ :, Symbol( "external => active" ) ]
    reportCounts = counts( Vector{Int}( report ), 5:10 )
    @test pvalue( ChisqTest( reportCounts, p ) ) > 0.05
    @test all( reportCounts .== [ 29, 36, 43, 59, 62, 72 ] )
end  # @testset "PUnif random recruitment test"

@testset "PLin random recruitment test" begin
    clearSimulationRecruitment!( mpSim )
    recruitment = Recruitment( "recruitment A" )
    setRecruitmentSchedule!( recruitment, 1 )
    setRecruitmentTarget!( recruitment, "node A" )
    setRecruitmentDist!( recruitment, :pLin, Dict( 5 => 1.0, 10 => 11.0 ) )
    addSimulationRecruitment!( mpSim, recruitment )

    @test verifySimulation!( mpSim )
    p = [ 1.0, 3.0, 5.0, 7.0, 9.0, 11.0 ]
    p /= sum( p )

    Random.seed!( 3141593 )
    run( mpSim, saveConfig = false )
    report = nodeFluxReport( mpSim, 1, :in, "active" )[ "active" ]
    report = report[ :, Symbol( "external => active" ) ]
    reportCounts = counts( Vector{Int}( report ), 5:10 )
    @test pvalue( ChisqTest( reportCounts, p ) ) > 0.05
    @test all( reportCounts .== [ 11, 29, 41, 59, 70, 91 ] )

    Random.seed!( 2718281 )
    run( mpSim, saveConfig = false )
    report = nodeFluxReport( mpSim, 1, :in, "active" )[ "active" ]
    report = report[ :, Symbol( "external => active" ) ]
    reportCounts = counts( Vector{Int}( report ), 5:10 )
    @test pvalue( ChisqTest( reportCounts, p ) ) > 0.05
    @test all( reportCounts .== [ 10, 25, 46, 53, 76, 91 ] )

    Random.seed!( 1414213 )
    run( mpSim, saveConfig = false )
    report = nodeFluxReport( mpSim, 1, :in, "active" )[ "active" ]
    report = report[ :, Symbol( "external => active" ) ]
    reportCounts = counts( Vector{Int}( report ), 5:10 )
    @test pvalue( ChisqTest( reportCounts, p ) ) > 0.05
    @test all( reportCounts .== [ 6, 31, 35, 60, 76, 93 ] )
end  # @testset "PLin random recruitment test"

setSimulationLength!( mpSim, 12 )
subpop = Subpopulation( "All" )
Random.seed!()

@testset "Fixed age recruitment test" begin
    clearSimulationRecruitment!( mpSim )
    recruitment = Recruitment( "recruitment A" )
    setRecruitmentSchedule!( recruitment, 24 )
    setRecruitmentTarget!( recruitment, "node A" )
    setRecruitmentFixed!( recruitment, 1000 )
    setRecruitmentAgeFixed!( recruitment, 60 )
    addSimulationRecruitment!( mpSim, recruitment )

    @test verifySimulation!( mpSim )
    run( mpSim, saveConfig = false )
    report = subpopulationAgeReport( mpSim, [ 0.0 ], 12, :age, subpop )[ "All" ]
    @test report[ 1, Symbol( 60.0 ) ] == 1000
end  # @testset "Fixed Age recruitment test"

@testset "Disc random age recruitment test" begin
    clearSimulationRecruitment!( mpSim )
    recruitment = Recruitment( "recruitment A" )
    setRecruitmentSchedule!( recruitment, 24 )
    setRecruitmentTarget!( recruitment, "node A" )
    setRecruitmentFixed!( recruitment, 1000 )
    setRecruitmentAgeDist!( recruitment, :disc,
        Dict( 60.0 => 1.0, 120.0 => 2.0 ) )
    addSimulationRecruitment!( mpSim, recruitment )

    @test verifySimulation!( mpSim )

    Random.seed!( 3141592 )
    run( mpSim, saveConfig = false )
    report = subpopulationAgeReport( mpSim, [ 0.0 ], 12, :age, subpop )[ "All" ]
    reportCounts = Vector{Int}( [ report[ 1, Symbol( 60.0 ) ],
        report[ 1, Symbol( 120.0 ) ] ] )
    @test pvalue( ChisqTest( reportCounts, [ 1/3, 2/3 ] ) ) > 0.05
    @test all( reportCounts .== [ 325, 675 ] )

    for age in 72.0:12.0:108.0
        @test report[ 1, Symbol( age ) ] == 0
    end  # for age in 72.0:12.0:108.0

    Random.seed!( 2718281 )
    run( mpSim, saveConfig = false )
    report = subpopulationAgeReport( mpSim, [ 0.0 ], 12, :age, subpop )[ "All" ]
    reportCounts = Vector{Int}( [ report[ 1, Symbol( 60.0 ) ],
        report[ 1, Symbol( 120.0 ) ] ] )
    @test pvalue( ChisqTest( reportCounts, [ 1/3, 2/3 ] ) ) > 0.05
    @test all( reportCounts .== [ 344, 656 ] )

    Random.seed!( 1414213 )
    run( mpSim, saveConfig = false )
    report = subpopulationAgeReport( mpSim, [ 0.0 ], 12, :age, subpop )[ "All" ]
    reportCounts = Vector{Int}( [ report[ 1, Symbol( 60.0 ) ],
        report[ 1, Symbol( 120.0 ) ] ] )
    @test pvalue( ChisqTest( reportCounts, [ 1/3, 2/3 ] ) ) > 0.05
    @test all( reportCounts .== [ 341, 659 ] )
end  # @testset "Disc random age recruitment test"

@testset "PUnif random age recruitment test" begin
    clearSimulationRecruitment!( mpSim )
    recruitment = Recruitment( "recruitment A" )
    setRecruitmentSchedule!( recruitment, 24 )
    setRecruitmentTarget!( recruitment, "node A" )
    setRecruitmentFixed!( recruitment, 1000 )
    setRecruitmentAgeDist!( recruitment, :pUnif,
        Dict( 60.0 => 1.0, 96.0 => 3.0, 120.0 => 1.0 ) )
    addSimulationRecruitment!( mpSim, recruitment )

    @test verifySimulation!( mpSim )
    testDistribution1 = Uniform( 60, 96 )
    testDistribution2 = Uniform( 96, 120 )
    testDistribution = MixtureModel( [ testDistribution1, testDistribution2 ],
        [ 0.25, 0.75 ] )

    Random.seed!( 3141592 )
    run( mpSim, saveConfig = false )
    recruitmentAges = Vector{Float64}( DataFrame( SQLite.Query( mpSim.simDB,
        "SELECT * FROM Personnel_Sim" ) )[ :ageAtRecruitment ] )
    @test pvalue( ExactOneSampleKSTest( recruitmentAges, testDistribution ) ) >
        0.05

    Random.seed!( 2718281 )
    run( mpSim, saveConfig = false )
    run( mpSim, saveConfig = false )
    recruitmentAges = Vector{Float64}( DataFrame( SQLite.Query( mpSim.simDB,
        "SELECT * FROM Personnel_Sim" ) )[ :ageAtRecruitment ] )
    @test pvalue( ExactOneSampleKSTest( recruitmentAges, testDistribution ) ) >
        0.05

    Random.seed!( 1414213 )
    run( mpSim, saveConfig = false )
    run( mpSim, saveConfig = false )
    recruitmentAges = Vector{Float64}( DataFrame( SQLite.Query( mpSim.simDB,
        "SELECT * FROM Personnel_Sim" ) )[ :ageAtRecruitment ] )
    @test pvalue( ExactOneSampleKSTest( recruitmentAges, testDistribution ) ) >
        0.05
end  # @testset "PUnif random age recruitment test"

@testset "PLin random age recruitment test" begin
    clearSimulationRecruitment!( mpSim )
    recruitment = Recruitment( "recruitment A" )
    setRecruitmentSchedule!( recruitment, 24 )
    setRecruitmentTarget!( recruitment, "node A" )
    setRecruitmentFixed!( recruitment, 1000 )
    setRecruitmentAgeDist!( recruitment, :pLin,
        Dict( 60.0 => 1.0, 120.0 => 6.0 ) )
    addSimulationRecruitment!( mpSim, recruitment )

    @test verifySimulation!( mpSim )
    testDistribution = Truncated( SymTriangularDist( 120, 72 ), 60, 120 )

    Random.seed!( 3141592 )
    run( mpSim, saveConfig = false )
    recruitmentAges = Vector{Float64}( DataFrame( SQLite.Query( mpSim.simDB,
        "SELECT * FROM Personnel_Sim" ) )[ :ageAtRecruitment ] )
    @test pvalue( ExactOneSampleKSTest( recruitmentAges, testDistribution ) ) >
        0.05

    Random.seed!( 2718281 )
    run( mpSim, saveConfig = false )
    run( mpSim, saveConfig = false )
    recruitmentAges = Vector{Float64}( DataFrame( SQLite.Query( mpSim.simDB,
        "SELECT * FROM Personnel_Sim" ) )[ :ageAtRecruitment ] )
    @test pvalue( ExactOneSampleKSTest( recruitmentAges, testDistribution ) ) >
        0.05

    Random.seed!( 1414213 )
    run( mpSim, saveConfig = false )
    run( mpSim, saveConfig = false )
    recruitmentAges = Vector{Float64}( DataFrame( SQLite.Query( mpSim.simDB,
        "SELECT * FROM Personnel_Sim" ) )[ :ageAtRecruitment ] )
    @test pvalue( ExactOneSampleKSTest( recruitmentAges, testDistribution ) ) >
        0.05
end  # @testset "PLin random age recruitment test"

@testset "PLin random age recruitment test 2" begin
    clearSimulationRecruitment!( mpSim )
    recruitment = Recruitment( "recruitment A" )
    setRecruitmentSchedule!( recruitment, 24 )
    setRecruitmentTarget!( recruitment, "node A" )
    setRecruitmentFixed!( recruitment, 1000 )
    setRecruitmentAgeDist!( recruitment, :pLin,
        Dict( 60.0 => 1.0, 90.0 => 6.0, 120.0 => 1.0 ) )
    addSimulationRecruitment!( mpSim, recruitment )

    @test verifySimulation!( mpSim )
    testDistribution = Truncated( SymTriangularDist( 90, 36 ), 60, 120 )

    Random.seed!( 3141592 )
    run( mpSim, saveConfig = false )
    recruitmentAges = Vector{Float64}( DataFrame( SQLite.Query( mpSim.simDB,
        "SELECT * FROM Personnel_Sim" ) )[ :ageAtRecruitment ] )
    @test pvalue( ExactOneSampleKSTest( recruitmentAges, testDistribution ) ) >
        0.05

    Random.seed!( 2718281 )
    run( mpSim, saveConfig = false )
    run( mpSim, saveConfig = false )
    recruitmentAges = Vector{Float64}( DataFrame( SQLite.Query( mpSim.simDB,
        "SELECT * FROM Personnel_Sim" ) )[ :ageAtRecruitment ] )
    @test pvalue( ExactOneSampleKSTest( recruitmentAges, testDistribution ) ) >
        0.05

    Random.seed!( 1414213 )
    run( mpSim, saveConfig = false )
    run( mpSim, saveConfig = false )
    recruitmentAges = Vector{Float64}( DataFrame( SQLite.Query( mpSim.simDB,
        "SELECT * FROM Personnel_Sim" ) )[ :ageAtRecruitment ] )
    @test pvalue( ExactOneSampleKSTest( recruitmentAges, testDistribution ) ) >
        0.05
end  # @testset "PLin random age recruitment test 2"

Random.seed!()

end  # @testset "Recruitment tests"