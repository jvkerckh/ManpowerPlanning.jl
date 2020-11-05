@testset "Retirement tests" begin

mpSim = ManpowerSimulation( "sim" )
setSimulationLength!( mpSim, 300 )

attribute = Attribute( "attribute A" )
addInitialAttributeValue!( attribute, "value A", 1 )
addInitialAttributeValue!( attribute, "value B", 1 )
addSimulationAttribute!( mpSim, attribute )

node = BaseNode( "node A" )
addNodeRequirement!( node, "attribute A", "value A" )
addSimulationBaseNode!( mpSim, node )

@testset "Retirement at tenure" begin
    recruitment = Recruitment( "recruitment A" )
    setRecruitmentSchedule!( recruitment, 12 )
    setRecruitmentTarget!( recruitment, "node A" )
    setRecruitmentFixed!( recruitment, 10 )
    addSimulationRecruitment!( mpSim, recruitment )
    
    retirement = Retirement()
    setRetirementCareerLength!( retirement, 120 )
    setRetirementSchedule!( retirement, 12 )
    setSimulationRetirement!( mpSim, retirement )

    @test verifySimulation!( mpSim )
    run( mpSim, saveConfig = false )
    report = nodeFluxReport( mpSim, 12, :out, "active" )["active"]
    @test all( report[:, Symbol( "active => external" )] .==
        vcat( zeros( 10 ), fill( 10, 16 ) ) ) &&
        all( report[:, Symbol( "retirement: node A => external" )] .==
        vcat( zeros( 10 ), fill( 10, 16 ) ) )
end  # @testset "Retirement at tenure"

@testset "Retirement schedule" begin
    retirement = Retirement()
    setRetirementCareerLength!( retirement, 120 )
    setRetirementSchedule!( retirement, 24 )
    setSimulationRetirement!( mpSim, retirement )

    @test verifySimulation!( mpSim )
    run( mpSim, saveConfig = false )
    report = nodeFluxReport( mpSim, 12, :out, "active" )["active"]
    @test all( report[:, Symbol( "active => external" )] .==
        vcat( zeros( 10 ), 10, 0, repeat( [20, 0], 7 ) ) )
    
    retirement = Retirement()
    setRetirementCareerLength!( retirement, 120 )
    setRetirementSchedule!( retirement, 24, 12 )
    setSimulationRetirement!( mpSim, retirement )

    @test verifySimulation!( mpSim )
    run( mpSim, saveConfig = false )
    report = nodeFluxReport( mpSim, 12, :out, "active" )["active"]
    @test all( report[:, Symbol( "active => external" )] .==
        vcat( zeros( 10 ), repeat( [0, 20], 8 ) ) )
end  # @testset "Retirement schedule"

@testset "Retirement at age" begin
    clearSimulationRecruitment!( mpSim )
    recruitment = Recruitment( "recruitment A" )
    setRecruitmentSchedule!( recruitment, 12 )
    setRecruitmentTarget!( recruitment, "node A" )
    setRecruitmentFixed!( recruitment, 10 )
    setRecruitmentAgeFixed!( recruitment, 60 )
    addSimulationRecruitment!( mpSim, recruitment )
    
    retirement = Retirement()
    setRetirementAge!( retirement, 180 )
    setRetirementSchedule!( retirement, 12 )
    setSimulationRetirement!( mpSim, retirement )

    @test verifySimulation!( mpSim )
    run( mpSim, saveConfig = false )
    report = nodeFluxReport( mpSim, 12, :out, "active" )["active"]
    @test all( report[:, Symbol( "active => external" )] .==
        vcat( zeros( 10 ), fill( 10, 16 ) ) )
end  # @testset "Retirement at age"

@testset "Retirement at age/tenure" begin
    node = BaseNode( "node B" )
    addNodeRequirement!( node, "attribute A", "value B" )
    addSimulationBaseNode!( mpSim, node )

    clearSimulationRecruitment!( mpSim )
    recruitment = Recruitment( "recruitment A" )
    setRecruitmentSchedule!( recruitment, 12 )
    setRecruitmentTarget!( recruitment, "node A" )
    setRecruitmentFixed!( recruitment, 10 )
    addSimulationRecruitment!( mpSim, recruitment )

    recruitment = Recruitment( "recruitment B" )
    setRecruitmentSchedule!( recruitment, 12 )
    setRecruitmentTarget!( recruitment, "node B" )
    setRecruitmentFixed!( recruitment, 10 )
    setRecruitmentAgeFixed!( recruitment, 60 )
    addSimulationRecruitment!( mpSim, recruitment )

    retirement = Retirement()
    setRetirementAge!( retirement, 144 )
    setRetirementCareerLength!( retirement, 120 )
    setRetirementSchedule!( retirement, 12 )
    setSimulationRetirement!( mpSim, retirement )

    @test verifySimulation!( mpSim )
    run( mpSim, saveConfig = false )
    report = nodeFluxReport( mpSim, 12, :out, "active" )["active"]
    @test all( report[:, Symbol( "retirement: node A => external" )] .==
        vcat( fill( 0, 10 ), fill( 10, 16 ) ) ) &&
        all( report[:, Symbol( "retirement: node B => external" )] .==
        vcat( fill( 0, 7 ), fill( 10, 19 ) ) )

    retirement = Retirement()
    setRetirementAge!( retirement, 144 )
    setRetirementCareerLength!( retirement, 120 )
    setRetirementIsEither!( retirement, false )
    setRetirementSchedule!( retirement, 12 )
    setSimulationRetirement!( mpSim, retirement )

    @test verifySimulation!( mpSim )
    run( mpSim, saveConfig = false )
    report = nodeFluxReport( mpSim, 12, :out, "active" )["active"]
    @test all( report[:, Symbol( "retirement: node A => external" )] .==
        vcat( fill( 0, 12 ), fill( 10, 14 ) ) ) &&
        all( report[:, Symbol( "retirement: node B => external" )] .==
        vcat( fill( 0, 10 ), fill( 10, 16 ) ) )
end  # @testset "Retirement at age/tenure"

end  # @testset "Retirement tests"