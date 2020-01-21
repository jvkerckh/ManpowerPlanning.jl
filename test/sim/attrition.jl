@testset "Attrition tests" begin

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
    run( mpSim, saveConfig = false )
    report = nodeFluxReport( mpSim, 12, :out, "active" )[ "active" ]
    @test !all( report[ :, Symbol( "active => external" ) ] .== 0 ) &&
        !all( report[ :, Symbol( "attrition: node A => external" ) ] .== 0 )
end  # @testset "Basic attrition test"

@testset "Piecewise attrition test" begin
    attrition = Attrition( "default" )
    setAttritionPeriod!( attrition, 12 )
    setAttritionCurve!( attrition, Dict( 0.0 => 0.1, 120.0 => 0.0 ) )
    addSimulationAttrition!( mpSim, attrition )
    @test verifySimulation!( mpSim )
    run( mpSim, saveConfig = false )
    report = nodeFluxReport( mpSim, 12, :out, "active" )[ "active" ]
    @test all( report[ 12:end, Symbol( "active => external" ) ] .== 0 )
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
    run( mpSim, saveConfig = false )
    report = nodeFluxReport( mpSim, 12, :out, "node A", "node B" )
    @test all( report[ "node A" ][ :, Symbol( "node A => other" ) ] .== 0 )
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
    testDistribution = Truncated( Exponential( -12 / log(0.9) ), 0, 300.0 )

    Random.seed!( 3141592 )
    run( mpSim, saveConfig = false )
    attritionTimes = Vector{Float64}( DataFrame( SQLite.Query( mpSim.simDB,
        "SELECT * FROM Transitions_Sim WHERE targetNode IS NULL" ) )[
        :timeIndex ] )
    report = nodeFluxReport( mpSim, 12, :out, "active" )[ "active" ]
    @test pvalue( ExactOneSampleKSTest( attritionTimes, testDistribution ) ) >
        0.05
    @test all( report[ 2:end, Symbol( "active => external" ) ] .==
        [ 102, 98, 88, 57, 62, 57, 47, 38, 48, 39, 32, 34, 38, 24, 22, 19, 20,
        16, 24, 14, 8, 13, 14, 10, 8 ] )

    Random.seed!( 2718281 )
    run( mpSim, saveConfig = false )
    attritionTimes = Vector{Float64}( DataFrame( SQLite.Query( mpSim.simDB,
        "SELECT * FROM Transitions_Sim WHERE targetNode IS NULL" ) )[
        :timeIndex ] )
    report = nodeFluxReport( mpSim, 12, :out, "active" )[ "active" ]
    @test pvalue( ExactOneSampleKSTest( attritionTimes, testDistribution ) ) >
        0.05
    @test all( report[ 2:end, Symbol( "active => external" ) ] .==
        [ 86, 91, 86, 74, 71, 65, 43, 53, 44, 38, 39, 30, 27, 25, 30, 20, 11,
        11, 13, 13, 16, 9, 9, 7, 11 ] )

    Random.seed!( 1414213 )
    run( mpSim, saveConfig = false )
    attritionTimes = Vector{Float64}( DataFrame( SQLite.Query( mpSim.simDB,
        "SELECT * FROM Transitions_Sim WHERE targetNode IS NULL" ) )[
        :timeIndex ] )
    report = nodeFluxReport( mpSim, 12, :out, "active" )[ "active" ]
    @test pvalue( ExactOneSampleKSTest( attritionTimes, testDistribution ) ) >
        0.05
    @test all( report[ 2:end, Symbol( "active => external" ) ] .==
        [ 81, 96, 83, 74, 56, 49, 47, 57, 44, 44, 29, 32, 34, 38, 18, 16, 18,
        19, 20, 17, 8, 6, 11, 8, 12 ] )
end  # @testset "Distribution test I"

@testset "Distribution test II" begin
    attrition = Attrition( "default" )
    setAttritionPeriod!( attrition, 12 )
    setAttritionCurve!( attrition, Dict( 0.0 => 0.1, 120.0 => 0.0, 180.0 => 0.25, 240.0 => 0.0 ) )
    addSimulationAttrition!( mpSim, attrition )

    @test verifySimulation!( mpSim )
    testDistribution1 = Truncated( Exponential( -12 / log(0.9) ), 0, 120.0 )
    p1 = 1 - 0.9^10
    testDistribution2 = Truncated( Exponential( -12 / log(0.75) ), 180.0,
        240.0 )
    p2 = 0.9^10 * ( 1 - 0.75^5 )
    p = [ p1, p2 ]
    p ./= sum( p )
    testDistribution = MixtureModel( [ testDistribution1, testDistribution2 ],
        p )
    
    Random.seed!( 3141592 )
    run( mpSim, saveConfig = false )
    attritionTimes = Vector{Float64}( DataFrame( SQLite.Query( mpSim.simDB,
        "SELECT * FROM Transitions_Sim WHERE targetNode IS NULL" ) )[
        :timeIndex ] )
    report = nodeFluxReport( mpSim, 12, :out, "active" )[ "active" ]
    @test pvalue( ExactOneSampleKSTest( attritionTimes, testDistribution ) ) >
        0.05
    @test all( report[ 2:end, Symbol( "active => external" ) ] .==
        [ 102, 98, 88, 57, 62, 57, 47, 38, 48, 39, 0, 0, 0, 0, 0, 90, 70, 50,
        41, 30, 0, 0, 0, 0, 0 ] )

    Random.seed!( 2718281 )
    run( mpSim, saveConfig = false )
    attritionTimes = Vector{Float64}( DataFrame( SQLite.Query( mpSim.simDB,
        "SELECT * FROM Transitions_Sim WHERE targetNode IS NULL" ) )[
        :timeIndex ] )
    report = nodeFluxReport( mpSim, 12, :out, "active" )[ "active" ]
    @test pvalue( ExactOneSampleKSTest( attritionTimes, testDistribution ) ) >
        0.05
    @test all( report[ 2:end, Symbol( "active => external" ) ] .==
        [ 86, 91, 86, 74, 71, 65, 43, 53, 44, 38, 0, 0, 0, 0, 0, 88, 72, 36, 37,
        24, 0, 0, 0, 0, 0 ] )

    Random.seed!( 1414213 )
    run( mpSim, saveConfig = false )
    attritionTimes = Vector{Float64}( DataFrame( SQLite.Query( mpSim.simDB,
        "SELECT * FROM Transitions_Sim WHERE targetNode IS NULL" ) )[
        :timeIndex ] )
    report = nodeFluxReport( mpSim, 12, :out, "active" )[ "active" ]
    @test pvalue( ExactOneSampleKSTest( attritionTimes, testDistribution ) ) >
        0.05
    @test all( report[ 2:end, Symbol( "active => external" ) ] .==
        [ 81, 96, 83, 74, 56, 49, 47, 57, 44, 44, 0, 0, 0, 0, 0, 87, 69, 52, 41,
        24, 0, 0, 0, 0, 0 ] )
end  # @testset "Distribution test II"

Random.seed!()
println()

end  # @testset "Attrition tests"