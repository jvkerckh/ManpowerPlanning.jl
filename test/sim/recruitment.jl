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
    run( mpSim, saveConfig = false )
    report = nodeFluxReport( mpSim, 1, :in, "active" )[ "active" ]
    report = report[ :, Symbol( "external => active" ) ]
    @test count( report .== 5 ) < count( report .== 10 )
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
    run( mpSim, saveConfig = false )
    report = nodeFluxReport( mpSim, 1, :in, "active" )[ "active" ]
    report = report[ :, Symbol( "external => active" ) ]
    @test all( 5 .<= report .<= 10 )
    @test count( report .<= 7 ) < count( report .> 7 )
end  # @testset "PUnif random recruitment test"

@testset "PLin random recruitment test" begin
    clearSimulationRecruitment!( mpSim )
    recruitment = Recruitment( "recruitment A" )
    setRecruitmentSchedule!( recruitment, 1 )
    setRecruitmentTarget!( recruitment, "node A" )
    setRecruitmentDist!( recruitment, :pLin, Dict( 5 => 1.0, 10 => 11.0 ) )
    addSimulationRecruitment!( mpSim, recruitment )

    @test verifySimulation!( mpSim )
    run( mpSim, saveConfig = false )
    report = nodeFluxReport( mpSim, 1, :in, "active" )[ "active" ]
    report = report[ :, Symbol( "external => active" ) ]
    @test all( 5 .<= report .<= 10 )
    @test all( [ count( report .== 5 ) < count( report .== 7 ),
        count( report .== 6 ) < count( report .== 8 ),
        count( report .== 7 ) < count( report .== 9 ),
        count( report .== 8 ) < count( report .== 10 ) ] )
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
    run( mpSim, saveConfig = false )
    report = subpopulationAgeReport( mpSim, [ 0.0 ], 12, :age, subpop )[ "All" ]
    @test report[ 1, Symbol( 60.0 ) ] < report[ 1, Symbol( 120.0 ) ]
    @test all( [ report[ 1, Symbol( 72.0 ) ], report[ 1, Symbol( 84.0 ) ],
        report[ 1, Symbol( 96.0 ) ], report[ 1, Symbol( 108.0 ) ] ] .== 0 )
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
    run( mpSim, saveConfig = false )
    report = subpopulationAgeReport( mpSim, [ 0.0 ], 12, :age, subpop )[ "All" ]
    @test all( [ report[ 1, Symbol( 60.0 ) ] < report[ 1, Symbol( 96.0 ) ],
        report[ 1, Symbol( 72.0 ) ] < report[ 1, Symbol( 96.0 ) ],
        report[ 1, Symbol( 84.0 ) ] < report[ 1, Symbol( 96.0 ) ],
        report[ 1, Symbol( 60.0 ) ] < report[ 1, Symbol( 108.0 ) ],
        report[ 1, Symbol( 72.0 ) ] < report[ 1, Symbol( 108.0 ) ],
        report[ 1, Symbol( 84.0 ) ] < report[ 1, Symbol( 108.0 ) ] ] )
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
    run( mpSim, saveConfig = false )
    report = subpopulationAgeReport( mpSim, [ 0.0 ], 12, :age, subpop )[ "All" ]
    @test ( report[ 1, :min ] >= 60 ) && ( report[ 1, :max ] <= 120 )
    @test all( [ report[ 1, Symbol( 60.0 ) ] < report[ 1, Symbol( 72.0 ) ],
        report[ 1, Symbol( 72.0 ) ] < report[ 1, Symbol( 84.0 ) ],
        report[ 1, Symbol( 84.0 ) ] < report[ 1, Symbol( 96.0 ) ],
        report[ 1, Symbol( 96.0 ) ] < report[ 1, Symbol( 108.0 ) ] ] )
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
    run( mpSim, saveConfig = false )
    report = subpopulationAgeReport( mpSim, [ 0.0 ], 12, :age, subpop )[ "All" ]
    @test ( report[ 1, :min ] >= 60 ) && ( report[ 1, :max ] <= 120 )
    @test all( [ report[ 1, Symbol( 60.0 ) ] < report[ 1, Symbol( 72.0 ) ],
        report[ 1, Symbol( 72.0 ) ] < report[ 1, Symbol( 84.0 ) ],
        report[ 1, Symbol( 84.0 ) ] > report[ 1, Symbol( 96.0 ) ],
        report[ 1, Symbol( 96.0 ) ] > report[ 1, Symbol( 108.0 ) ],
        report[ 1, Symbol( 72.0 ) ] > report[ 1, Symbol( 108.0 ) ],
        report[ 1, Symbol( 60.0 ) ] < report[ 1, Symbol( 96.0 ) ] ] )
end  # @testset "PLin random age recruitment test 2"

end  # @testset "Recruitment tests"