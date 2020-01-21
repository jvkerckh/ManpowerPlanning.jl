@testset "Transition probability tests" begin

@testset "Trans prob test I" begin
    mpSim = ManpowerSimulation()

    attribute = Attribute( "Level" )
    setPossibleAttributeValues!( attribute, [ "A", "B" ] )
    addSimulationAttribute!( mpSim, attribute )

    node = BaseNode( "A" )
    setNodeRequirements!( node, [ "Level" ], [ "A" ] )
    addSimulationBaseNode!( mpSim, node )

    node = BaseNode( "B" )
    setNodeRequirements!( node, [ "Level" ], [ "B" ] )
    addSimulationBaseNode!( mpSim, node )

    recruitment = Recruitment( "EW" )
    setRecruitmentSchedule!( recruitment, 120 )
    setRecruitmentTarget!( recruitment, "A" )
    nt = 1000
    setRecruitmentFixed!( recruitment, nt )
    setRecruitmentAgeFixed!( recruitment, 18 * 12 )
    addSimulationRecruitment!( mpSim, recruitment )

    transition = Transition( "trans", "A", "B" )
    setTransitionSchedule!( transition, 12 )
    setTransitionMaxAttempts!( transition, 1 )
    p0 = 0.6
    setTransitionProbabilities!( transition, [ p0 ] )
    addTransitionCondition!( transition, MPcondition( "time in node", >=, 12 ) )
    addSimulationTransition!( mpSim, transition )

    setSimulationLength!( mpSim, 60.0 )
    @test verifySimulation!( mpSim )

    Random.seed!( 3141592 )
    run( mpSim, saveConfig = false )
    report = nodeEvolutionReport( mpSim, 12, "A", "B" )
    popReport = report[ 1 ]
    fluxReport = report[ 2 ][ "B" ][ 1 ]
    nn, np = popReport[ 2, :A ], popReport[ 2, :B ]
    @test pvalue( OneSampleZTest( np / nt, p0 * ( 1 - p0 ) * nt, nt, p0 ) ) >
        0.05
    @test all( fluxReport[ :, Symbol( "trans: A => B" ) ] .==
        [ 0, 601, 0, 0, 0, 0 ] )

    Random.seed!( 2718282 )
    run( mpSim, saveConfig = false )
    report = nodeEvolutionReport( mpSim, 12, "A", "B" )
    popReport = report[ 1 ]
    fluxReport = report[ 2 ][ "B" ][ 1 ]
    nn, np = popReport[ 2, :A ], popReport[ 2, :B ]
    @test pvalue( OneSampleZTest( np / nt, p0 * ( 1 - p0 ) * nt, nt, p0 ) ) >
        0.05
    @test all( fluxReport[ :, Symbol( "trans: A => B" ) ] .==
        [ 0, 600, 0, 0, 0, 0 ] )
    
    Random.seed!( 1414214 )
    run( mpSim, saveConfig = false )
    report = nodeEvolutionReport( mpSim, 12, "A", "B" )
    popReport = report[ 1 ]
    fluxReport = report[ 2 ][ "B" ][ 1 ]
    nn, np = popReport[ 2, :A ], popReport[ 2, :B ]
    @test pvalue( OneSampleZTest( np / nt, p0 * ( 1 - p0 ) * nt, nt, p0 ) ) >
        0.05
    @test all( fluxReport[ :, Symbol( "trans: A => B" ) ] .==
        [ 0, 609, 0, 0, 0, 0 ] )
end  # @testset "Trans prob test I"

@testset "Trans prob test II" begin
    mpSim = ManpowerSimulation()

    attribute = Attribute( "Level" )
    setPossibleAttributeValues!( attribute, [ "A", "B" ] )
    addSimulationAttribute!( mpSim, attribute )

    node = BaseNode( "A" )
    setNodeRequirements!( node, [ "Level" ], [ "A" ] )
    addSimulationBaseNode!( mpSim, node )

    node = BaseNode( "B" )
    setNodeRequirements!( node, [ "Level" ], [ "B" ] )
    addSimulationBaseNode!( mpSim, node )

    recruitment = Recruitment( "EW" )
    setRecruitmentSchedule!( recruitment, 120 )
    setRecruitmentTarget!( recruitment, "A" )
    nt = 1000
    setRecruitmentFixed!( recruitment, nt )
    setRecruitmentAgeFixed!( recruitment, 18 * 12 )
    addSimulationRecruitment!( mpSim, recruitment )

    transition = Transition( "trans", "A", "B" )
    setTransitionSchedule!( transition, 12 )
    setTransitionMaxAttempts!( transition, 2 )
    p = [ 0.25, 0.6 ]
    setTransitionProbabilities!( transition, p )
    addTransitionCondition!( transition, MPcondition( "time in node", >=, 12 ) )
    addSimulationTransition!( mpSim, transition )

    setSimulationLength!( mpSim, 60.0 )
    @test verifySimulation!( mpSim )
    p .*= cumprod( vcat( 1, 1 .- p[ 1:(end - 1) ] ) )
    p = vcat( p, 1.0 - sum( p ) )

    Random.seed!( 3141592 )
    run( mpSim, saveConfig = false )
    report = nodeEvolutionReport( mpSim, 12, "A", "B" )
    fluxReport = Int.( report[ 2 ][ "B" ][ 1 ][ :, Symbol( "trans: A => B" ) ] )
    countReport = fluxReport[ 2:3 ]
    countReport = vcat( countReport, nt - sum( countReport ) )
    @test pvalue( ChisqTest( countReport, p ) ) > 0.05
    @test all( fluxReport .== [ 0, 258, 460, 0, 0, 0 ] )

    Random.seed!( 2718282 )
    run( mpSim, saveConfig = false )
    report = nodeEvolutionReport( mpSim, 12, "A", "B" )
    fluxReport = Int.( report[ 2 ][ "B" ][ 1 ][ :, Symbol( "trans: A => B" ) ] )
    countReport = fluxReport[ 2:3 ]
    countReport = vcat( countReport, nt - sum( countReport ) )
    @test pvalue( ChisqTest( countReport, p ) ) > 0.05
    @test all( fluxReport .== [ 0, 258, 444, 0, 0, 0 ] )
    
    Random.seed!( 1414214 )
    run( mpSim, saveConfig = false )
    report = nodeEvolutionReport( mpSim, 12, "A", "B" )
    fluxReport = Int.( report[ 2 ][ "B" ][ 1 ][ :, Symbol( "trans: A => B" ) ] )
    countReport = fluxReport[ 2:3 ]
    countReport = vcat( countReport, nt - sum( countReport ) )
    @test pvalue( ChisqTest( countReport, p ) ) > 0.05
    @test all( fluxReport .== [ 0, 261, 438, 0, 0, 0 ] )
end  # @testset "Trans prob test II"

@testset "Trans prob test III" begin
    mpSim = ManpowerSimulation()

    attribute = Attribute( "Level" )
    setPossibleAttributeValues!( attribute, [ "A", "B" ] )
    addSimulationAttribute!( mpSim, attribute )

    node = BaseNode( "A" )
    setNodeRequirements!( node, [ "Level" ], [ "A" ] )
    addSimulationBaseNode!( mpSim, node )

    node = BaseNode( "B" )
    setNodeRequirements!( node, [ "Level" ], [ "B" ] )
    addSimulationBaseNode!( mpSim, node )

    recruitment = Recruitment( "EW" )
    setRecruitmentSchedule!( recruitment, 120 )
    setRecruitmentTarget!( recruitment, "A" )
    nt = 1000
    setRecruitmentFixed!( recruitment, nt )
    setRecruitmentAgeFixed!( recruitment, 18 * 12 )
    addSimulationRecruitment!( mpSim, recruitment )

    transition = Transition( "trans", "A", "B" )
    setTransitionSchedule!( transition, 12 )
    setTransitionMaxAttempts!( transition, 0 )
    p = [ 0.25, 0.6 ]
    setTransitionProbabilities!( transition, p )
    addTransitionCondition!( transition, MPcondition( "time in node", >=, 12 ) )
    addSimulationTransition!( mpSim, transition )

    setSimulationLength!( mpSim, 60.0 )
    @test verifySimulation!( mpSim )
    p .*= cumprod( vcat( 1, 1 .- p[ 1:(end - 1) ] ) )
    p = vcat( p, 1.0 - sum( p ) )

    Random.seed!( 3141592 )
    run( mpSim, saveConfig = false )
    report = nodeEvolutionReport( mpSim, 12, "A", "B" )
    fluxReport = Int.( report[ 2 ][ "B" ][ 1 ][ :, Symbol( "trans: A => B" ) ] )
    countReport = fluxReport[ 2:3 ]
    countReport = vcat( countReport, nt - sum( countReport ) )
    @test pvalue( ChisqTest( countReport, p ) ) > 0.05
    @test all( fluxReport .== [ 0, 258, 460, 0, 0, 0 ] )

    Random.seed!( 2718282 )
    run( mpSim, saveConfig = false )
    report = nodeEvolutionReport( mpSim, 12, "A", "B" )
    fluxReport = Int.( report[ 2 ][ "B" ][ 1 ][ :, Symbol( "trans: A => B" ) ] )
    countReport = fluxReport[ 2:3 ]
    countReport = vcat( countReport, nt - sum( countReport ) )
    @test pvalue( ChisqTest( countReport, p ) ) > 0.05
    @test all( fluxReport .== [ 0, 258, 444, 0, 0, 0 ] )
    
    Random.seed!( 1414214 )
    run( mpSim, saveConfig = false )
    report = nodeEvolutionReport( mpSim, 12, "A", "B" )
    fluxReport = Int.( report[ 2 ][ "B" ][ 1 ][ :, Symbol( "trans: A => B" ) ] )
    countReport = fluxReport[ 2:3 ]
    countReport = vcat( countReport, nt - sum( countReport ) )
    @test pvalue( ChisqTest( countReport, p ) ) > 0.05
    @test all( fluxReport .== [ 0, 261, 438, 0, 0, 0 ] )
end  # @testset "Trans prob test III"

@testset "Trans prob test IV" begin
    mpSim = ManpowerSimulation()

    attribute = Attribute( "Level" )
    setPossibleAttributeValues!( attribute, [ "A", "B" ] )
    addSimulationAttribute!( mpSim, attribute )

    node = BaseNode( "A" )
    setNodeRequirements!( node, [ "Level" ], [ "A" ] )
    addSimulationBaseNode!( mpSim, node )

    node = BaseNode( "B" )
    setNodeRequirements!( node, [ "Level" ], [ "B" ] )
    addSimulationBaseNode!( mpSim, node )

    recruitment = Recruitment( "EW" )
    setRecruitmentSchedule!( recruitment, 120 )
    setRecruitmentTarget!( recruitment, "A" )
    nt = 1000
    setRecruitmentFixed!( recruitment, nt )
    setRecruitmentAgeFixed!( recruitment, 18 * 12 )
    addSimulationRecruitment!( mpSim, recruitment )

    transition = Transition( "trans", "A", "B" )
    setTransitionSchedule!( transition, 12 )
    setTransitionMaxAttempts!( transition, 2 )
    p = [ 0.25, 0.6, 0.75 ]
    setTransitionProbabilities!( transition, p )
    addTransitionCondition!( transition, MPcondition( "time in node", >=, 12 ) )
    addSimulationTransition!( mpSim, transition )

    setSimulationLength!( mpSim, 60.0 )
    @test verifySimulation!( mpSim )
    p = p[ 1:2 ]
    p .*= cumprod( vcat( 1, 1 .- p[ 1:(end - 1) ] ) )
    p = vcat( p, 1.0 - sum( p ) )

    Random.seed!( 3141592 )
    run( mpSim, saveConfig = false )
    report = nodeEvolutionReport( mpSim, 12, "A", "B" )
    fluxReport = Int.( report[ 2 ][ "B" ][ 1 ][ :, Symbol( "trans: A => B" ) ] )
    countReport = fluxReport[ 2:3 ]
    countReport = vcat( countReport, nt - sum( countReport ) )
    @test pvalue( ChisqTest( countReport, p ) ) > 0.05
    @test all( fluxReport .== [ 0, 258, 460, 0, 0, 0 ] )

    Random.seed!( 2718282 )
    run( mpSim, saveConfig = false )
    report = nodeEvolutionReport( mpSim, 12, "A", "B" )
    fluxReport = Int.( report[ 2 ][ "B" ][ 1 ][ :, Symbol( "trans: A => B" ) ] )
    countReport = fluxReport[ 2:3 ]
    countReport = vcat( countReport, nt - sum( countReport ) )
    @test pvalue( ChisqTest( countReport, p ) ) > 0.05
    @test all( fluxReport .== [ 0, 258, 444, 0, 0, 0 ] )
    
    Random.seed!( 1414214 )
    run( mpSim, saveConfig = false )
    report = nodeEvolutionReport( mpSim, 12, "A", "B" )
    fluxReport = Int.( report[ 2 ][ "B" ][ 1 ][ :, Symbol( "trans: A => B" ) ] )
    countReport = fluxReport[ 2:3 ]
    countReport = vcat( countReport, nt - sum( countReport ) )
    @test pvalue( ChisqTest( countReport, p ) ) > 0.05
    @test all( fluxReport .== [ 0, 261, 438, 0, 0, 0 ] )
end  # @testset "Trans prob test IV"

@testset "Trans prob test V" begin
    mpSim = ManpowerSimulation()

    attribute = Attribute( "Level" )
    setPossibleAttributeValues!( attribute, [ "A", "B" ] )
    addSimulationAttribute!( mpSim, attribute )

    node = BaseNode( "A" )
    setNodeRequirements!( node, [ "Level" ], [ "A" ] )
    addSimulationBaseNode!( mpSim, node )

    node = BaseNode( "B" )
    setNodeRequirements!( node, [ "Level" ], [ "B" ] )
    addSimulationBaseNode!( mpSim, node )

    recruitment = Recruitment( "EW" )
    setRecruitmentSchedule!( recruitment, 120 )
    setRecruitmentTarget!( recruitment, "A" )
    nt = 1000
    setRecruitmentFixed!( recruitment, nt )
    setRecruitmentAgeFixed!( recruitment, 18 * 12 )
    addSimulationRecruitment!( mpSim, recruitment )

    transition = Transition( "trans", "A", "B" )
    setTransitionSchedule!( transition, 12 )
    setTransitionMaxAttempts!( transition, 3 )
    p = [ 0.25, 0.5 ]
    setTransitionProbabilities!( transition, p )
    addTransitionCondition!( transition, MPcondition( "time in node", >=, 12 ) )
    addSimulationTransition!( mpSim, transition )

    setSimulationLength!( mpSim, 60.0 )
    @test verifySimulation!( mpSim )
    p = vcat( p, p[ end ] )
    p .*= cumprod( vcat( 1, 1 .- p[ 1:(end - 1) ] ) )
    p = vcat( p, 1.0 - sum( p ) )

    Random.seed!( 3141592 )
    run( mpSim, saveConfig = false )
    report = nodeEvolutionReport( mpSim, 12, "A", "B" )
    fluxReport = Int.( report[ 2 ][ "B" ][ 1 ][ :, Symbol( "trans: A => B" ) ] )
    countReport = fluxReport[ 2:4 ]
    countReport = vcat( countReport, nt - sum( countReport ) )
    @test pvalue( ChisqTest( countReport, p ) ) > 0.05
    @test all( fluxReport .== [ 0, 258, 381, 175, 0, 0 ] )

    Random.seed!( 2718282 )
    run( mpSim, saveConfig = false )
    report = nodeEvolutionReport( mpSim, 12, "A", "B" )
    fluxReport = Int.( report[ 2 ][ "B" ][ 1 ][ :, Symbol( "trans: A => B" ) ] )
    countReport = fluxReport[ 2:4 ]
    countReport = vcat( countReport, nt - sum( countReport ) )
    @test pvalue( ChisqTest( countReport, p ) ) > 0.05
    @test all( fluxReport .== [ 0, 258, 381, 183, 0, 0 ] )
    
    Random.seed!( 1414214 )
    run( mpSim, saveConfig = false )
    report = nodeEvolutionReport( mpSim, 12, "A", "B" )
    fluxReport = Int.( report[ 2 ][ "B" ][ 1 ][ :, Symbol( "trans: A => B" ) ] )
    countReport = fluxReport[ 2:4 ]
    countReport = vcat( countReport, nt - sum( countReport ) )
    @test pvalue( ChisqTest( countReport, p ) ) > 0.05
    @test all( fluxReport .== [ 0, 261, 369, 174, 0, 0 ] )
end  # @testset "Trans prob test V"

@testset "Trans prob test VI" begin
    mpSim = ManpowerSimulation()

    attribute = Attribute( "Level" )
    setPossibleAttributeValues!( attribute, [ "A", "B" ] )
    addSimulationAttribute!( mpSim, attribute )

    node = BaseNode( "A" )
    setNodeRequirements!( node, [ "Level" ], [ "A" ] )
    addSimulationBaseNode!( mpSim, node )

    node = BaseNode( "B" )
    setNodeRequirements!( node, [ "Level" ], [ "B" ] )
    addSimulationBaseNode!( mpSim, node )

    recruitment = Recruitment( "EW" )
    setRecruitmentSchedule!( recruitment, 120 )
    setRecruitmentTarget!( recruitment, "A" )
    nt = 1000
    setRecruitmentFixed!( recruitment, nt )
    setRecruitmentAgeFixed!( recruitment, 18 * 12 )
    addSimulationRecruitment!( mpSim, recruitment )

    transition = Transition( "trans", "A", "B" )
    setTransitionSchedule!( transition, 12 )
    setTransitionMaxAttempts!( transition, -1 )
    p = [ 0.25, 0.5 ]
    setTransitionProbabilities!( transition, p )
    addTransitionCondition!( transition, MPcondition( "time in node", >=, 12 ) )
    addSimulationTransition!( mpSim, transition )

    setSimulationLength!( mpSim, 60.0 )
    @test verifySimulation!( mpSim )
    p = vcat( p, fill( p[ end ], 3 ) )
    p .*= cumprod( vcat( 1, 1 .- p[ 1:(end - 1) ] ) )
    p = vcat( p, 1.0 - sum( p ) )

    Random.seed!( 3141592 )
    run( mpSim, saveConfig = false )
    report = nodeEvolutionReport( mpSim, 12, "A", "B" )
    fluxReport = Int.( report[ 2 ][ "B" ][ 1 ][ :, Symbol( "trans: A => B" ) ] )
    countReport = fluxReport[ 2:end ]
    countReport = vcat( countReport, nt - sum( countReport ) )
    @test pvalue( ChisqTest( countReport, p ) ) > 0.05
    @test all( fluxReport .== [ 0, 258, 381, 175, 108, 33 ] )

    Random.seed!( 2718282 )
    run( mpSim, saveConfig = false )
    report = nodeEvolutionReport( mpSim, 12, "A", "B" )
    fluxReport = Int.( report[ 2 ][ "B" ][ 1 ][ :, Symbol( "trans: A => B" ) ] )
    countReport = fluxReport[ 2:end ]
    countReport = vcat( countReport, nt - sum( countReport ) )
    @test pvalue( ChisqTest( countReport, p ) ) > 0.05
    @test all( fluxReport .== [ 0, 258, 381, 183, 87, 49 ] )
    
    Random.seed!( 1414214 )
    run( mpSim, saveConfig = false )
    report = nodeEvolutionReport( mpSim, 12, "A", "B" )
    fluxReport = Int.( report[ 2 ][ "B" ][ 1 ][ :, Symbol( "trans: A => B" ) ] )
    countReport = fluxReport[ 2:end ]
    countReport = vcat( countReport, nt - sum( countReport ) )
    @test pvalue( ChisqTest( countReport, p ) ) > 0.05
    @test all( fluxReport .== [ 0, 261, 369, 174, 111, 35 ] )
end  # @testset "Trans prob test VI"

println()

end  # @testset "Transition probability tests"