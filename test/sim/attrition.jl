@testset "Attrition tests" begin

piseed = floor( Int, pi * 1_000_000 )
eseed = floor( Int, exp( 1 ) * 1_000_000 )
s2seed = floor( Int, sqrt( 2 ) * 1_000_000 )

mpSim = ManpowerSimulation( "sim" )
setSimulationLength!( mpSim, 300 )

attribute = Attribute( "attribute A" )
addInitialAttributeValue!( attribute, "value A", 1 )
addSimulationAttribute!( mpSim, attribute )

attrition = Attrition( "default" )
setAttritionRate!( attrition, 0.1 )
setAttritionPeriod!( attrition, 12 )
addSimulationAttrition!( mpSim, attrition )

node = BaseNode( "node A" )
addNodeRequirement!( node, "attribute A", "value A" )
addSimulationBaseNode!( mpSim, node )

recruitment = Recruitment( "EW" )
setRecruitmentSchedule!( recruitment, 600 )
setRecruitmentTarget!( recruitment, "node A" )
setRecruitmentFixed!( recruitment, 1000 )
addSimulationRecruitment!( mpSim, recruitment )

@testset "Basic attrition test" begin
    @test verifySimulation!( mpSim )
    run( mpSim, saveConfig=false )
    report = nodeFluxReport( mpSim, 12, :out, "active" )["active"]
    @test !all( report[:, "active => external"] .== 0 ) &&
        !all( report[:, Symbol( "attrition: node A => external" )] .== 0 )
end  # @testset "Basic attrition test"

@testset "Piecewise attrition test" begin
    attrition = Attrition( "default" )
    setAttritionPeriod!( attrition, 12 )
    setAttritionCurve!( attrition, Dict( 0.0 => 0.1, 120.0 => 0.0 ) )
    addSimulationAttrition!( mpSim, attrition )
    @test verifySimulation!( mpSim )
    run( mpSim, saveConfig=false )
    report = nodeFluxReport( mpSim, 12, :out, "active" )["active"]
    @test all( report[12:end, "active => external"] .== 0 )
end  # @testset "Piecewise attrition test"

@testset "Segregated attrition test" begin
    attribute = Attribute( "attribute A" )
    addInitialAttributeValue!( attribute, "value A", 1 )
    addInitialAttributeValue!( attribute, "value B", 1 )
    addSimulationAttribute!( mpSim, attribute )

    attrition = Attrition( "default" )
    setAttritionRate!( attrition, 0 )
    setAttritionPeriod!( attrition, 12 )
    addSimulationAttrition!( mpSim, attrition )

    attrition = Attrition( "attrition B" )
    setAttritionRate!( attrition, 0.1 )
    setAttritionPeriod!( attrition, 12 )
    addSimulationAttrition!( mpSim, attrition )

    node = BaseNode( "node B" )
    addNodeRequirement!( node, "attribute A", "value B" )
    setNodeAttritionScheme!( node, "attrition B" )
    addSimulationBaseNode!( mpSim, node )

    recruitment = Recruitment( "EW" )
    setRecruitmentSchedule!( recruitment, 600 )
    setRecruitmentTarget!( recruitment, "node B" )
    setRecruitmentFixed!( recruitment, 1000 )
    addSimulationRecruitment!( mpSim, recruitment )

    @test verifySimulation!( mpSim )
    run( mpSim, saveConfig=false )
    report = nodeFluxReport( mpSim, 12, :out, "node A", "node B" )
    @test all( report["node A"][:, Symbol( "node A => other" )] .== 0 )
end  # @testset "Segregated attrition test"

mpSim = ManpowerSimulation( "sim" )
setSimulationLength!( mpSim, 300 )

clearSimulationAttributes!( mpSim )
attribute = Attribute( "attribute A" )
addInitialAttributeValue!( attribute, "value A", 1 )
addSimulationAttribute!( mpSim, attribute )

clearSimulationBaseNodes!( mpSim )
node = BaseNode( "node A" )
addNodeRequirement!( node, "attribute A", "value A" )
addSimulationBaseNode!( mpSim, node )

clearSimulationRecruitment!( mpSim )
recruitment = Recruitment( "EW" )
setRecruitmentSchedule!( recruitment, 600 )
setRecruitmentTarget!( recruitment, "node A" )
setRecruitmentFixed!( recruitment, 1000 )
addSimulationRecruitment!( mpSim, recruitment )

@testset "Distribution test I" begin
    attrition = Attrition( "default" )
    setAttritionRate!( attrition, 0.1 )
    setAttritionPeriod!( attrition, 12 )
    addSimulationAttrition!( mpSim, attrition )

    @test verifySimulation!( mpSim )
    testDistribution = truncated( Exponential( -12 / log(0.9) ), 0, 300.0 )

    run( mpSim, saveConfig=false, seed=piseed )
    attritionTimes = Vector{Float64}( DataFrame( DBInterface.execute(
        mpSim.simDB,
        "SELECT * FROM Transitions_Sim WHERE targetNode IS NULL" ) )[:,
        :timeIndex] )
    report = nodeFluxReport( mpSim, 12, :out, "active" )["active"]
    pval = pvalue( ExactOneSampleKSTest( attritionTimes, testDistribution ) )
    @test pval > 0.05
    @test all( report[2:end, "active => external"] .==
        [116, 81, 81, 77, 53, 58, 45, 57, 52, 41, 37, 31, 28, 23, 23, 15, 19,
        13, 18, 9, 18, 14, 9, 11, 4] )

    run( mpSim, saveConfig=false, seed=piseed )
    attritionTimes = Vector{Float64}( DataFrame( DBInterface.execute(
        mpSim.simDB,
        "SELECT * FROM Transitions_Sim WHERE targetNode IS NULL" ) )[:,
        :timeIndex] )
    report = nodeFluxReport( mpSim, 12, :out, "active" )["active"]
    @test pval ==
        pvalue( ExactOneSampleKSTest( attritionTimes, testDistribution ) )
    @test all( report[2:end, "active => external"] .==
        [116, 81, 81, 77, 53, 58, 45, 57, 52, 41, 37, 31, 28, 23, 23, 15, 19,
        13, 18, 9, 18, 14, 9, 11, 4] )

    run( mpSim, saveConfig=false, seed=piseed, sysEnt=true )
    attritionTimes = Vector{Float64}( DataFrame( DBInterface.execute(
        mpSim.simDB,
        "SELECT * FROM Transitions_Sim WHERE targetNode IS NULL" ) )[:,
        :timeIndex] )
    report = nodeFluxReport( mpSim, 12, :out, "active" )["active"]
    @test pval !=
        pvalue( ExactOneSampleKSTest( attritionTimes, testDistribution ) )
    @test report[2:end, "active => external"] !=
        [116, 81, 81, 77, 53, 58, 45, 57, 52, 41, 37, 31, 28, 23, 23, 15, 19,
        13, 18, 9, 18, 14, 9, 11, 4]
            
    run( mpSim, saveConfig=false, seed=eseed )
    attritionTimes = Vector{Float64}( DataFrame( DBInterface.execute(
        mpSim.simDB,
        "SELECT * FROM Transitions_Sim WHERE targetNode IS NULL" ) )[:,
        :timeIndex] )
    report = nodeFluxReport( mpSim, 12, :out, "active" )["active"]
    @test pvalue( ExactOneSampleKSTest( attritionTimes, testDistribution ) ) >
        0.05
    @test all( report[2:end, "active => external"] .==
        [112, 85, 76, 83, 51, 60, 60, 52, 40, 39, 34, 36, 21, 26, 22, 20, 20,
        14, 16, 15, 15, 8, 7, 14, 7] )

    run( mpSim, saveConfig=false, seed=s2seed )
    attritionTimes = Vector{Float64}( DataFrame( DBInterface.execute(
        mpSim.simDB,
        "SELECT * FROM Transitions_Sim WHERE targetNode IS NULL" ) )[:,
        :timeIndex] )
    report = nodeFluxReport( mpSim, 12, :out, "active" )["active"]
    @test pvalue( ExactOneSampleKSTest( attritionTimes, testDistribution ) ) >
        0.05
    @test all( report[2:end, "active => external"] .==
        [118, 91, 70, 63, 69, 55, 56, 50, 35, 44, 37, 36, 27, 21, 16, 24, 18,
        14, 7, 14, 8, 10, 10, 12, 7] )
end  # @testset "Distribution test I"

@testset "Distribution test II" begin
    attrition = Attrition( "default" )
    setAttritionPeriod!( attrition, 12 )
    setAttritionCurve!( attrition, Dict( 0.0 => 0.1, 120.0 => 0.0, 180.0 => 0.25, 240.0 => 0.0 ) )
    addSimulationAttrition!( mpSim, attrition )

    @test verifySimulation!( mpSim )
    testDistribution1 = truncated( Exponential( -12 / log(0.9) ), 0, 120.0 )
    p1 = 1 - 0.9^10
    testDistribution2 = truncated( Exponential( -12 / log(0.75) ), 180.0,
        240.0 )
    p2 = 0.9^10 * ( 1 - 0.75^5 )
    p = [p1, p2]
    p ./= sum( p )
    testDistribution = MixtureModel( [testDistribution1, testDistribution2],
        p )
    
    run( mpSim, saveConfig=false, seed=piseed )
    attritionTimes = Vector{Float64}( DataFrame( DBInterface.execute(
        mpSim.simDB,
        "SELECT * FROM Transitions_Sim WHERE targetNode IS NULL" ) )[:,
        :timeIndex] )
    report = nodeFluxReport( mpSim, 12, :out, "active" )["active"]
    pval = pvalue( ExactOneSampleKSTest( attritionTimes, testDistribution ) )
    @test pval > 0.05
    @test all( report[2:end, "active => external"] .==
        [116, 81, 81, 77, 53, 58, 45, 57, 52, 41, 0, 0, 0, 0, 0, 87, 61, 46,
        40, 29, 0, 0, 0, 0, 0] )

    run( mpSim, saveConfig=false, seed=piseed )
    attritionTimes = Vector{Float64}( DataFrame( DBInterface.execute(
        mpSim.simDB,
        "SELECT * FROM Transitions_Sim WHERE targetNode IS NULL" ) )[:,
        :timeIndex] )
    report = nodeFluxReport( mpSim, 12, :out, "active" )["active"]
    @test pval ==
        pvalue( ExactOneSampleKSTest( attritionTimes, testDistribution ) )
    @test all( report[2:end, "active => external"] .==
        [116, 81, 81, 77, 53, 58, 45, 57, 52, 41, 0, 0, 0, 0, 0, 87, 61, 46,
        40, 29, 0, 0, 0, 0, 0] )

    run( mpSim, saveConfig=false, seed=piseed, sysEnt=true )
    attritionTimes = Vector{Float64}( DataFrame( DBInterface.execute(
        mpSim.simDB,
        "SELECT * FROM Transitions_Sim WHERE targetNode IS NULL" ) )[:,
        :timeIndex] )
    report = nodeFluxReport( mpSim, 12, :out, "active" )["active"]
    @test pval !=
        pvalue( ExactOneSampleKSTest( attritionTimes, testDistribution ) )
    @test report[2:end, "active => external"] !=
        [116, 81, 81, 77, 53, 58, 45, 57, 52, 41, 0, 0, 0, 0, 0, 87, 61, 46,
        40, 29, 0, 0, 0, 0, 0]
    
    run( mpSim, saveConfig=false, seed=eseed )
    attritionTimes = Vector{Float64}( DataFrame( DBInterface.execute(
        mpSim.simDB,
        "SELECT * FROM Transitions_Sim WHERE targetNode IS NULL" ) )[:,
        :timeIndex] )
    report = nodeFluxReport( mpSim, 12, :out, "active" )["active"]
    @test pvalue( ExactOneSampleKSTest( attritionTimes, testDistribution ) ) >
        0.05
    @test all( report[2:end, "active => external"] .==
        [112, 85, 76, 83, 51, 60, 60, 52, 40, 39, 0, 0, 0, 0, 0, 90, 58, 47,
        42, 24, 0, 0, 0, 0, 0] )

    run( mpSim, saveConfig=false, seed=s2seed )
    attritionTimes = Vector{Float64}( DataFrame( DBInterface.execute(
        mpSim.simDB,
        "SELECT * FROM Transitions_Sim WHERE targetNode IS NULL" ) )[:,
        :timeIndex] )
    report = nodeFluxReport( mpSim, 12, :out, "active" )["active"]
    @test pvalue( ExactOneSampleKSTest( attritionTimes, testDistribution ) ) >
        0.05
    @test all( report[2:end, "active => external"] .==
        [118, 91, 70, 63, 69, 55, 56, 50, 35, 44, 0, 0, 0, 0, 0, 96, 54, 46,
        24, 30, 0, 0, 0, 0, 0] )
end  # @testset "Distribution test II"

Random.seed!()
println()

end  # @testset "Attrition tests"