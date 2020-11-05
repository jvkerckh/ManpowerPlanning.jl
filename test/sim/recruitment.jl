@testset "Recruitment tests" begin

piseed = floor( Int, pi * 1_000_000 )
eseed = floor( Int, exp( 1 ) * 1_000_000 )
s2seed = floor( Int, sqrt( 2 ) * 1_000_000 )

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
    run( mpSim, saveConfig=false )
    report = nodeFluxReport( mpSim, 12, :in, "active" )["active"]
    @test all( report[:, Symbol( "external => active" )] .== 10 ) &&
        all( report[:, Symbol( "recruitment A: external => node A" )] .== 10 )
end  # @testset "Basic recruitment test"

@testset "Recruitment schedule" begin
    clearSimulationRecruitment!( mpSim )
    recruitment = Recruitment( "recruitment A" )
    setRecruitmentSchedule!( recruitment, 24 )
    setRecruitmentTarget!( recruitment, "node A" )
    setRecruitmentFixed!( recruitment, 10 )
    addSimulationRecruitment!( mpSim, recruitment )

    @test verifySimulation!( mpSim )
    run( mpSim, saveConfig=false )
    report = nodeFluxReport( mpSim, 12, :in, "active" )["active"]
    @test all( report[:, Symbol( "external => active" )] .==
        repeat( [10, 0], 13 ) )

    clearSimulationRecruitment!( mpSim )
    recruitment = Recruitment( "recruitment A" )
    setRecruitmentSchedule!( recruitment, 24, 12 )
    setRecruitmentTarget!( recruitment, "node A" )
    setRecruitmentFixed!( recruitment, 10 )
    addSimulationRecruitment!( mpSim, recruitment )

    @test verifySimulation!( mpSim )
    run( mpSim, saveConfig=false )
    report = nodeFluxReport( mpSim, 12, :in, "active" )["active"]
    @test all( report[:, Symbol( "external => active" )] .==
        repeat( [0, 10], 13 ) )

end  # @testset "Recruitment schedule"

@testset "Adaptive recruitment test" begin
    clearSimulationRecruitment!( mpSim )
    recruitment = Recruitment( "recruitment A" )
    setRecruitmentSchedule!( recruitment, 12 )
    setRecruitmentTarget!( recruitment, "node A" )
    setRecruitmentAdaptiveRange!( recruitment, 5, 10 )
    addSimulationRecruitment!( mpSim, recruitment )

    @test verifySimulation!( mpSim )
    run( mpSim, saveConfig=false )
    report = nodeFluxReport( mpSim, 12, :in, "active" )["active"]
    report = report[:, Symbol( "external => active" )]
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

    run( mpSim, saveConfig=false, seed=piseed )
    report = nodeFluxReport( mpSim, 1, :in, "active" )["active"]
    report = report[:, Symbol( "external => active" )]
    reportCounts = counts( Vector{Int}( report ), 5:10 )[[1, end]]
    pval = pvalue( ChisqTest( reportCounts, [1/3, 2/3] ) )
    @test pval > 0.05
    @test all( reportCounts .== [93, 208] )

    run( mpSim, saveConfig=false, seed=piseed )
    report = nodeFluxReport( mpSim, 1, :in, "active" )["active"]
    report = report[:, Symbol( "external => active" )]
    reportCounts = counts( Vector{Int}( report ), 5:10 )[[1, end]]
    @test pvalue( ChisqTest( reportCounts, [1/3, 2/3] ) ) == pval
    @test all( reportCounts .== [93, 208] )

    run( mpSim, saveConfig=false, seed=piseed, sysEnt=true )
    report = nodeFluxReport( mpSim, 1, :in, "active" )["active"]
    report = report[:, Symbol( "external => active" )]
    reportCounts = counts( Vector{Int}( report ), 5:10 )[[1, end]]
    @test pvalue( ChisqTest( reportCounts, [1/3, 2/3] ) ) != pval
    @test reportCounts != [93, 208]

    run( mpSim, saveConfig=false, seed=eseed )
    report = nodeFluxReport( mpSim, 1, :in, "active" )["active"]
    report = report[:, Symbol( "external => active" )]
    reportCounts = counts( Vector{Int}( report ), 5:10 )[[1, end]]
    @test pvalue( ChisqTest( reportCounts, [1/3, 2/3] ) ) > 0.05
    @test all( reportCounts .== [105, 196] )

    run( mpSim, saveConfig=false, seed=s2seed )
    report = nodeFluxReport( mpSim, 1, :in, "active" )["active"]
    report = report[:, Symbol( "external => active" )]
    reportCounts = counts( Vector{Int}( report ), 5:10 )[[1, end]]
    @test pvalue( ChisqTest( reportCounts, [1/3, 2/3] ) ) > 0.05
    @test all( reportCounts .== [90, 211] )
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
    p = [1.0, 1.0, 1.0, 2.0, 2.0, 2.0]
    p /= sum( p )

    run( mpSim, saveConfig=false, seed=piseed )
    report = nodeFluxReport( mpSim, 1, :in, "active" )["active"]
    report = report[:, Symbol( "external => active" )]
    reportCounts = counts( Vector{Int}( report ), 5:10 )
    pval = pvalue( ChisqTest( reportCounts, p ) )
    @test pval > 0.05
    @test all( reportCounts .== [28, 33, 38, 73, 62, 67] )
   
    run( mpSim, saveConfig=false, seed=piseed )
    report = nodeFluxReport( mpSim, 1, :in, "active" )["active"]
    report = report[:, Symbol( "external => active" )]
    reportCounts = counts( Vector{Int}( report ), 5:10 )
    @test pvalue( ChisqTest( reportCounts, p ) ) == pval
    @test all( reportCounts .== [28, 33, 38, 73, 62, 67] )
   
    run( mpSim, saveConfig=false, seed=piseed, sysEnt=true )
    report = nodeFluxReport( mpSim, 1, :in, "active" )["active"]
    report = report[:, Symbol( "external => active" )]
    reportCounts = counts( Vector{Int}( report ), 5:10 )
    @test pvalue( ChisqTest( reportCounts, p ) ) != pval
    @test reportCounts != [28, 33, 38, 73, 62, 67]
   
    run( mpSim, saveConfig=false, seed=eseed )
    report = nodeFluxReport( mpSim, 1, :in, "active" )["active"]
    report = report[:, Symbol( "external => active" )]
    reportCounts = counts( Vector{Int}( report ), 5:10 )
    @test pvalue( ChisqTest( reportCounts, p ) ) > 0.05
    @test all( reportCounts .== [38, 27, 36, 49, 77, 74] )

    run( mpSim, saveConfig=false, seed=s2seed )
    report = nodeFluxReport( mpSim, 1, :in, "active" )["active"]
    report = report[:, Symbol( "external => active" )]
    reportCounts = counts( Vector{Int}( report ), 5:10 )
    @test pvalue( ChisqTest( reportCounts, p ) ) > 0.05
    @test all( reportCounts .== [38, 27, 30, 68, 61, 77] )
end  # @testset "PUnif random recruitment test"

@testset "PLin random recruitment test" begin
    clearSimulationRecruitment!( mpSim )
    recruitment = Recruitment( "recruitment A" )
    setRecruitmentSchedule!( recruitment, 1 )
    setRecruitmentTarget!( recruitment, "node A" )
    setRecruitmentDist!( recruitment, :pLin, Dict( 5 => 1.0, 10 => 11.0 ) )
    addSimulationRecruitment!( mpSim, recruitment )

    @test verifySimulation!( mpSim )
    p = [1.0, 3.0, 5.0, 7.0, 9.0, 11.0]
    p /= sum( p )

    run( mpSim, saveConfig=false, seed=piseed )
    report = nodeFluxReport( mpSim, 1, :in, "active" )["active"]
    report = report[:, Symbol( "external => active" )]
    reportCounts = counts( Vector{Int}( report ), 5:10 )
    pval = pvalue( ChisqTest( reportCounts, p ) )
    @test pval > 0.05
    @test all( reportCounts .== [5, 30, 34, 71, 72, 89] )

    run( mpSim, saveConfig=false, seed=piseed )
    report = nodeFluxReport( mpSim, 1, :in, "active" )["active"]
    report = report[:, Symbol( "external => active" )]
    reportCounts = counts( Vector{Int}( report ), 5:10 )
    @test pvalue( ChisqTest( reportCounts, p ) ) == pval
    @test all( reportCounts .== [5, 30, 34, 71, 72, 89] )

    run( mpSim, saveConfig=false, seed=piseed, sysEnt=true )
    report = nodeFluxReport( mpSim, 1, :in, "active" )["active"]
    report = report[:, Symbol( "external => active" )]
    reportCounts = counts( Vector{Int}( report ), 5:10 )
    @test pvalue( ChisqTest( reportCounts, p ) ) != pval
    @test reportCounts != [5, 30, 34, 71, 72, 89]

    run( mpSim, saveConfig=false, seed=eseed )
    report = nodeFluxReport( mpSim, 1, :in, "active" )["active"]
    report = report[:, Symbol( "external => active" )]
    reportCounts = counts( Vector{Int}( report ), 5:10 )
    @test pvalue( ChisqTest( reportCounts, p ) ) > 0.05
    @test all( reportCounts .== [9, 28, 40, 76, 56, 92] )

    run( mpSim, saveConfig=false, seed=s2seed )
    report = nodeFluxReport( mpSim, 1, :in, "active" )["active"]
    report = report[:, Symbol( "external => active" )]
    reportCounts = counts( Vector{Int}( report ), 5:10 )
    @test pvalue( ChisqTest( reportCounts, p ) ) > 0.05
    @test all( reportCounts .== [10, 20, 35, 62, 80, 94] )
end  # @testset "PLin random recruitment test"

setSimulationLength!( mpSim, 12 )
subpop = Subpopulation( "All" )

@testset "Fixed age recruitment test" begin
    clearSimulationRecruitment!( mpSim )
    recruitment = Recruitment( "recruitment A" )
    setRecruitmentSchedule!( recruitment, 24 )
    setRecruitmentTarget!( recruitment, "node A" )
    setRecruitmentFixed!( recruitment, 1000 )
    setRecruitmentAgeFixed!( recruitment, 60 )
    addSimulationRecruitment!( mpSim, recruitment )

    @test verifySimulation!( mpSim )
    run( mpSim, saveConfig=false )
    report = subpopulationAgeReport( mpSim, [0.0], 12, :age, subpop )["All"]
    @test report[1, Symbol( 60.0 )] == 1000
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

    run( mpSim, saveConfig=false, seed=piseed )
    report = subpopulationAgeReport( mpSim, [0.0], 12, :age, subpop )["All"]
    reportCounts = Vector{Int}( [report[1, Symbol( 60.0 )],
        report[1, Symbol( 120.0 )]] )
    pval = pvalue( ChisqTest( reportCounts, [1/3, 2/3] ) )
    @test pval > 0.05
    @test all( reportCounts .== [344, 656] )

    for age in 72.0:12.0:108.0
        @test report[1, Symbol( age )] == 0
    end  # for age in 72.0:12.0:108.0

    run( mpSim, saveConfig=false, seed=piseed )
    report = subpopulationAgeReport( mpSim, [0.0], 12, :age, subpop )["All"]
    reportCounts = Vector{Int}( [report[1, Symbol( 60.0 )],
        report[1, Symbol( 120.0 )]] )
    @test pvalue( ChisqTest( reportCounts, [1/3, 2/3] ) ) == pval
    @test all( reportCounts .== [344, 656] )

    run( mpSim, saveConfig=false, seed=piseed, sysEnt=true )
    report = subpopulationAgeReport( mpSim, [0.0], 12, :age, subpop )["All"]
    reportCounts = Vector{Int}( [report[1, Symbol( 60.0 )],
        report[1, Symbol( 120.0 )]] )
    @test pvalue( ChisqTest( reportCounts, [1/3, 2/3] ) ) != pval
    @test reportCounts != [344, 656]

    run( mpSim, saveConfig=false, seed=eseed )
    report = subpopulationAgeReport( mpSim, [0.0], 12, :age, subpop )["All"]
    reportCounts = Vector{Int}( [report[1, Symbol( 60.0 )],
        report[1, Symbol( 120.0 )]] )
    @test pvalue( ChisqTest( reportCounts, [1/3, 2/3] ) ) > 0.05
    @test all( reportCounts .== [346, 654] )

    run( mpSim, saveConfig=false, seed=s2seed )
    report = subpopulationAgeReport( mpSim, [0.0], 12, :age, subpop )["All"]
    reportCounts = Vector{Int}( [report[1, Symbol( 60.0 )],
        report[1, Symbol( 120.0 )]] )
    @test pvalue( ChisqTest( reportCounts, [1/3, 2/3] ) ) > 0.05
    @test all( reportCounts .== [323, 677] )
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
    testDistribution = MixtureModel( [testDistribution1, testDistribution2],
        [0.25, 0.75] )

    run( mpSim, saveConfig=false, seed=piseed )
    recruitmentAges = Vector{Float64}( DataFrame( DBInterface.execute(
        mpSim.simDB, "SELECT * FROM Personnel_Sim" ) )[:, :ageAtRecruitment] )
    pval = pvalue( ExactOneSampleKSTest( recruitmentAges, testDistribution ) )
    @test pval > 0.05

    run( mpSim, saveConfig=false, seed=piseed )
    recruitmentAges = Vector{Float64}( DataFrame( DBInterface.execute(
        mpSim.simDB, "SELECT * FROM Personnel_Sim" ) )[:, :ageAtRecruitment] )
    @test pvalue( ExactOneSampleKSTest( recruitmentAges,
        testDistribution ) ) == pval

    run( mpSim, saveConfig=false, seed=piseed, sysEnt=true )
    recruitmentAges = Vector{Float64}( DataFrame( DBInterface.execute(
        mpSim.simDB, "SELECT * FROM Personnel_Sim" ) )[:, :ageAtRecruitment] )
    @test pvalue( ExactOneSampleKSTest( recruitmentAges,
        testDistribution ) ) != pval

    run( mpSim, saveConfig=false, seed=eseed )
    recruitmentAges = Vector{Float64}( DataFrame( DBInterface.execute(
        mpSim.simDB, "SELECT * FROM Personnel_Sim" ) )[:, :ageAtRecruitment] )
    @test pvalue( ExactOneSampleKSTest( recruitmentAges, testDistribution ) ) >
        0.05

    run( mpSim, saveConfig=false, seed=s2seed )
    recruitmentAges = Vector{Float64}( DataFrame( DBInterface.execute(
        mpSim.simDB, "SELECT * FROM Personnel_Sim" ) )[:, :ageAtRecruitment] )
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

    run( mpSim, saveConfig=false, seed=piseed )
    recruitmentAges = Vector{Float64}( DataFrame( DBInterface.execute(
        mpSim.simDB, "SELECT * FROM Personnel_Sim" ) )[:, :ageAtRecruitment] )
    pval = pvalue( ExactOneSampleKSTest( recruitmentAges, testDistribution ) )
    @test pval > 0.05

    run( mpSim, saveConfig=false, seed=piseed )
    recruitmentAges = Vector{Float64}( DataFrame( DBInterface.execute(
        mpSim.simDB, "SELECT * FROM Personnel_Sim" ) )[:, :ageAtRecruitment] )
    @test pvalue( ExactOneSampleKSTest( recruitmentAges,
        testDistribution ) ) == pval

    run( mpSim, saveConfig=false, seed=piseed, sysEnt=true )
    recruitmentAges = Vector{Float64}( DataFrame( DBInterface.execute(
        mpSim.simDB, "SELECT * FROM Personnel_Sim" ) )[:, :ageAtRecruitment] )
    @test pvalue( ExactOneSampleKSTest( recruitmentAges,
        testDistribution ) ) != pval
    
    run( mpSim, saveConfig=false, seed=eseed )
    recruitmentAges = Vector{Float64}( DataFrame( DBInterface.execute(
        mpSim.simDB, "SELECT * FROM Personnel_Sim" ) )[:, :ageAtRecruitment] )
    @test pvalue( ExactOneSampleKSTest( recruitmentAges, testDistribution ) ) >
        0.05

    run( mpSim, saveConfig=false, seed=s2seed + 1 )
    recruitmentAges = Vector{Float64}( DataFrame( DBInterface.execute(
        mpSim.simDB, "SELECT * FROM Personnel_Sim" ) )[:, :ageAtRecruitment] )
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

    run( mpSim, saveConfig=false, seed=piseed - 1 )
    recruitmentAges = Vector{Float64}( DataFrame( DBInterface.execute(
        mpSim.simDB, "SELECT * FROM Personnel_Sim" ) )[:, :ageAtRecruitment] )
    pval = pvalue( ExactOneSampleKSTest( recruitmentAges, testDistribution ) )
    @test pval > 0.05

    run( mpSim, saveConfig=false, seed=piseed - 1 )
    recruitmentAges = Vector{Float64}( DataFrame( DBInterface.execute(
        mpSim.simDB, "SELECT * FROM Personnel_Sim" ) )[:, :ageAtRecruitment] )
    @test pvalue( ExactOneSampleKSTest( recruitmentAges, testDistribution ) ) ==
        pval

    run( mpSim, saveConfig=false, seed=piseed - 1, sysEnt=true )
    recruitmentAges = Vector{Float64}( DataFrame( DBInterface.execute(
        mpSim.simDB, "SELECT * FROM Personnel_Sim" ) )[:, :ageAtRecruitment] )
    @test pvalue( ExactOneSampleKSTest( recruitmentAges,
        testDistribution ) ) != pval

    run( mpSim, saveConfig=false, seed=eseed )
    recruitmentAges = Vector{Float64}( DataFrame( DBInterface.execute(
        mpSim.simDB, "SELECT * FROM Personnel_Sim" ) )[:, :ageAtRecruitment] )
    @test pvalue( ExactOneSampleKSTest( recruitmentAges, testDistribution ) ) >
        0.05

    run( mpSim, saveConfig=false, seed=s2seed )
    recruitmentAges = Vector{Float64}( DataFrame( DBInterface.execute(
        mpSim.simDB, "SELECT * FROM Personnel_Sim" ) )[:, :ageAtRecruitment] )
    @test pvalue( ExactOneSampleKSTest( recruitmentAges, testDistribution ) ) >
        0.05
end  # @testset "PLin random age recruitment test 2"

@testset "Attribute initialisation test" begin
    attribute = Attribute( "attribute B" )
    addInitialAttributeValue!( attribute, ("A", 1.0), ("B", 2.0), ("C", 1.0) )
    addSimulationAttribute!( mpSim, attribute )

    clearSimulationRecruitment!( mpSim )
    recruitment = Recruitment( "recruitment A" )
    setRecruitmentSchedule!( recruitment, 24 )
    setRecruitmentTarget!( recruitment, "node A" )
    setRecruitmentFixed!( recruitment, 1000 )
    addSimulationRecruitment!( mpSim, recruitment )

    subpop1 = Subpopulation( "B/A" )
    subpop2 = Subpopulation( "B/B" )
    subpop3 = Subpopulation( "B/C" )
    addSubpopulationCondition!.( [subpop1, subpop2, subpop3],
        MPcondition.( "attribute B", ==, ["A", "B", "C"] ) )
    setSubpopulationSourceNode!.( [subpop1, subpop2, subpop3], "node A" )

    @test verifySimulation!( mpSim )

    run( mpSim, saveConfig=false, seed=piseed )
    report = subpopulationPopReport( mpSim, 12, subpop1, subpop2, subpop3 )
    reportCounts = Int.( [report[1, Symbol( "B/A" )],
        report[1, Symbol( "B/B" )], report[1, Symbol( "B/C" )]] )
    @test pvalue( ChisqTest( reportCounts, [1/4, 1/2, 1/4] ) ) > 0.05
    @test all( reportCounts .== [250, 486, 264] )

    run( mpSim, saveConfig=false, seed=piseed )
    report = subpopulationPopReport( mpSim, 12, subpop1, subpop2, subpop3 )
    reportCounts = Int.( [report[1, Symbol( "B/A" )],
        report[1, Symbol( "B/B" )], report[1, Symbol( "B/C" )]] )
    @test all( reportCounts .== [250, 486, 264] )

    run( mpSim, saveConfig=false, seed=piseed, sysEnt=true )
    report = subpopulationPopReport( mpSim, 12, subpop1, subpop2, subpop3 )
    reportCounts = Int.( [report[1, Symbol( "B/A" )],
        report[1, Symbol( "B/B" )], report[1, Symbol( "B/C" )]] )
    @test reportCounts != [250, 486, 264]

    run( mpSim, saveConfig=false, seed=eseed )
    report = subpopulationPopReport( mpSim, 12, subpop1, subpop2, subpop3 )
    reportCounts = Int.( [report[1, Symbol( "B/A" )],
        report[1, Symbol( "B/B" )], report[1, Symbol( "B/C" )]] )
    @test pvalue( ChisqTest( reportCounts, [1/4, 1/2, 1/4] ) ) > 0.05
    @test all( reportCounts .==[243, 496, 261] )

    run( mpSim, saveConfig=false, seed=s2seed )
    report = subpopulationPopReport( mpSim, 12, subpop1, subpop2, subpop3 )
    reportCounts = Int.( [report[1, Symbol( "B/A" )],
        report[1, Symbol( "B/B" )], report[1, Symbol( "B/C" )]] )
    @test pvalue( ChisqTest( reportCounts, [1/4, 1/2, 1/4] ) ) > 0.05
    @test all( reportCounts .== [248, 500, 252] )
end  # @testset "Attribute initialisation test"

end  # @testset "Recruitment tests"