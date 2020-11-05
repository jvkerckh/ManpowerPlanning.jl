@testset "Transition probability tests" begin

piseed = floor( Int, pi * 1_000_000 )
eseed = floor( Int, exp( 1 ) * 1_000_000 )
s2seed = floor( Int, sqrt( 2 ) * 1_000_000 )

@testset "Trans prob test I" begin
    mpSim = ManpowerSimulation()

    attribute = Attribute( "Level" )
    setPossibleAttributeValues!( attribute, ["A", "B"] )
    addSimulationAttribute!( mpSim, attribute )

    node = BaseNode( "A" )
    setNodeRequirements!( node, ["Level"], ["A"] )
    addSimulationBaseNode!( mpSim, node )

    node = BaseNode( "B" )
    setNodeRequirements!( node, ["Level"], ["B"] )
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
    setTransitionProbabilities!( transition, [p0] )
    addTransitionCondition!( transition, MPcondition( "time in node", >=, 12 ) )
    addSimulationTransition!( mpSim, transition )

    setSimulationLength!( mpSim, 60.0 )
    @test verifySimulation!( mpSim )

    run( mpSim, saveConfig=false, seed=piseed )
    report = nodeEvolutionReport( mpSim, 12, "A", "B" )
    popReport = report[1]
    fluxReport = report[2]["B"][1]
    nn, np = popReport[2, :A], popReport[2, :B]
    pval = pvalue( OneSampleZTest( np / nt, p0 * ( 1 - p0 ) * nt, nt, p0 ) )
    @test pval > 0.05
    @test all( fluxReport[:, "trans: A => B"] .== [0, 630, 0, 0, 0, 0] )

    run( mpSim, saveConfig=false, seed=piseed )
    report = nodeEvolutionReport( mpSim, 12, "A", "B" )
    popReport = report[1]
    fluxReport = report[2]["B"][1]
    nn, np = popReport[2, :A], popReport[2, :B]
    @test pval ==
        pvalue( OneSampleZTest( np / nt, p0 * ( 1 - p0 ) * nt, nt, p0 ) )
    @test all( fluxReport[:, "trans: A => B"] .== [0, 630, 0, 0, 0, 0] )

    run( mpSim, saveConfig=false, seed=piseed, sysEnt=true )
    report = nodeEvolutionReport( mpSim, 12, "A", "B" )
    popReport = report[1]
    fluxReport = report[2]["B"][1]
    nn, np = popReport[2, :A], popReport[2, :B]
    @test pval !=
        pvalue( OneSampleZTest( np / nt, p0 * ( 1 - p0 ) * nt, nt, p0 ) )
    @test fluxReport[:, "trans: A => B"] != [0, 630, 0, 0, 0, 0]

    run( mpSim, saveConfig=false, seed=eseed )
    report = nodeEvolutionReport( mpSim, 12, "A", "B" )
    popReport = report[1]
    fluxReport = report[2]["B"][1]
    nn, np = popReport[2, :A], popReport[2, :B]
    @test pvalue( OneSampleZTest( np / nt, p0 * ( 1 - p0 ) * nt, nt, p0 ) ) >
        0.05
    @test all( fluxReport[:, "trans: A => B"] .== [0, 598, 0, 0, 0, 0] )
    
    run( mpSim, saveConfig=false, seed=s2seed )
    report = nodeEvolutionReport( mpSim, 12, "A", "B" )
    popReport = report[1]
    fluxReport = report[2]["B"][1]
    nn, np = popReport[2, :A], popReport[2, :B]
    @test pvalue( OneSampleZTest( np / nt, p0 * ( 1 - p0 ) * nt, nt, p0 ) ) >
        0.05
    @test all( fluxReport[:, "trans: A => B"] .== [0, 614, 0, 0, 0, 0] )
end  # @testset "Trans prob test I"

@testset "Trans prob test II" begin
    mpSim = ManpowerSimulation()

    attribute = Attribute( "Level" )
    setPossibleAttributeValues!( attribute, ["A", "B"] )
    addSimulationAttribute!( mpSim, attribute )

    node = BaseNode( "A" )
    setNodeRequirements!( node, ["Level"], ["A"] )
    addSimulationBaseNode!( mpSim, node )

    node = BaseNode( "B" )
    setNodeRequirements!( node, ["Level"], ["B"] )
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
    p = [0.25, 0.6]
    setTransitionProbabilities!( transition, p )
    addTransitionCondition!( transition, MPcondition( "time in node", >=, 12 ) )
    addSimulationTransition!( mpSim, transition )

    setSimulationLength!( mpSim, 60.0 )
    @test verifySimulation!( mpSim )
    p .*= cumprod( vcat( 1, 1 .- p[1:(end - 1)] ) )
    p = vcat( p, 1.0 - sum( p ) )

    run( mpSim, saveConfig=false, seed=piseed )
    report = nodeEvolutionReport( mpSim, 12, "A", "B" )
    fluxReport = Int.( report[2]["B"][1][:, "trans: A => B"] )
    countReport = fluxReport[2:3]
    countReport = vcat( countReport, nt - sum( countReport ) )
    pval = pvalue( ChisqTest( countReport, p ) )
    @test pval > 0.05
    @test all( fluxReport .== [0, 253, 454, 0, 0, 0] )

    run( mpSim, saveConfig=false, seed=piseed )
    report = nodeEvolutionReport( mpSim, 12, "A", "B" )
    fluxReport = Int.( report[2]["B"][1][:, "trans: A => B"] )
    countReport = fluxReport[2:3]
    countReport = vcat( countReport, nt - sum( countReport ) )
    @test pvalue( ChisqTest( countReport, p ) ) == pval
    @test all( fluxReport .== [0, 253, 454, 0, 0, 0] )

    run( mpSim, saveConfig=false, seed=piseed, sysEnt=true )
    report = nodeEvolutionReport( mpSim, 12, "A", "B" )
    fluxReport = Int.( report[2]["B"][1][:, "trans: A => B"] )
    countReport = fluxReport[2:3]
    countReport = vcat( countReport, nt - sum( countReport ) )
    @test pvalue( ChisqTest( countReport, p ) ) != pval
    @test fluxReport != [0, 253, 454, 0, 0, 0] 

    run( mpSim, saveConfig=false, seed=eseed )
    report = nodeEvolutionReport( mpSim, 12, "A", "B" )
    fluxReport = Int.( report[2]["B"][1][:, "trans: A => B"] )
    countReport = fluxReport[2:3]
    countReport = vcat( countReport, nt - sum( countReport ) )
    @test pvalue( ChisqTest( countReport, p ) ) > 0.05
    @test all( fluxReport .== [0, 260, 447, 0, 0, 0] )
    
    run( mpSim, saveConfig=false, seed=s2seed )
    report = nodeEvolutionReport( mpSim, 12, "A", "B" )
    fluxReport = Int.( report[2]["B"][1][:, "trans: A => B"] )
    countReport = fluxReport[2:3]
    countReport = vcat( countReport, nt - sum( countReport ) )
    @test pvalue( ChisqTest( countReport, p ) ) > 0.05
    @test all( fluxReport .== [0, 263, 452, 0, 0, 0] )
end  # @testset "Trans prob test II"

@testset "Trans prob test III" begin
    mpSim = ManpowerSimulation()

    attribute = Attribute( "Level" )
    setPossibleAttributeValues!( attribute, ["A", "B"] )
    addSimulationAttribute!( mpSim, attribute )

    node = BaseNode( "A" )
    setNodeRequirements!( node, ["Level"], ["A"] )
    addSimulationBaseNode!( mpSim, node )

    node = BaseNode( "B" )
    setNodeRequirements!( node, ["Level"], ["B"] )
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
    p = [0.25, 0.6]
    setTransitionProbabilities!( transition, p )
    addTransitionCondition!( transition, MPcondition( "time in node", >=, 12 ) )
    addSimulationTransition!( mpSim, transition )

    setSimulationLength!( mpSim, 60.0 )
    @test verifySimulation!( mpSim )
    p .*= cumprod( vcat( 1, 1 .- p[1:(end - 1)] ) )
    p = vcat( p, 1.0 - sum( p ) )

    run( mpSim, saveConfig=false, seed=piseed )
    report = nodeEvolutionReport( mpSim, 12, "A", "B" )
    fluxReport = Int.( report[2]["B"][1][:, "trans: A => B"] )
    countReport = fluxReport[2:3]
    countReport = vcat( countReport, nt - sum( countReport ) )
    pval = pvalue( ChisqTest( countReport, p ) )
    @test pval > 0.05
    @test all( fluxReport .== [0, 253, 454, 0, 0, 0] )

    run( mpSim, saveConfig=false, seed=piseed )
    report = nodeEvolutionReport( mpSim, 12, "A", "B" )
    fluxReport = Int.( report[2]["B"][1][:, "trans: A => B"] )
    countReport = fluxReport[2:3]
    countReport = vcat( countReport, nt - sum( countReport ) )
    @test pvalue( ChisqTest( countReport, p ) ) == pval
    @test all( fluxReport .== [0, 253, 454, 0, 0, 0] )

    run( mpSim, saveConfig=false, seed=piseed, sysEnt=true )
    report = nodeEvolutionReport( mpSim, 12, "A", "B" )
    fluxReport = Int.( report[2]["B"][1][:, "trans: A => B"] )
    countReport = fluxReport[2:3]
    countReport = vcat( countReport, nt - sum( countReport ) )
    @test pvalue( ChisqTest( countReport, p ) ) != pval
    @test fluxReport != [0, 253, 454, 0, 0, 0]

    run( mpSim, saveConfig=false, seed=eseed )
    report = nodeEvolutionReport( mpSim, 12, "A", "B" )
    fluxReport = Int.( report[2]["B"][1][:, "trans: A => B"] )
    countReport = fluxReport[2:3]
    countReport = vcat( countReport, nt - sum( countReport ) )
    @test pvalue( ChisqTest( countReport, p ) ) > 0.05
    @test all( fluxReport .== [0, 260, 447, 0, 0, 0] )
    
    run( mpSim, saveConfig=false, seed=s2seed )
    report = nodeEvolutionReport( mpSim, 12, "A", "B" )
    fluxReport = Int.( report[2]["B"][1][:, "trans: A => B"] )
    countReport = fluxReport[2:3]
    countReport = vcat( countReport, nt - sum( countReport ) )
    @test pvalue( ChisqTest( countReport, p ) ) > 0.05
    @test all( fluxReport .== [0, 263, 452, 0, 0, 0] )
end  # @testset "Trans prob test III"

@testset "Trans prob test IV" begin
    mpSim = ManpowerSimulation()

    attribute = Attribute( "Level" )
    setPossibleAttributeValues!( attribute, ["A", "B"] )
    addSimulationAttribute!( mpSim, attribute )

    node = BaseNode( "A" )
    setNodeRequirements!( node, ["Level"], ["A"] )
    addSimulationBaseNode!( mpSim, node )

    node = BaseNode( "B" )
    setNodeRequirements!( node, ["Level"], ["B"] )
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
    p = [0.25, 0.6, 0.75]
    setTransitionProbabilities!( transition, p )
    addTransitionCondition!( transition, MPcondition( "time in node", >=, 12 ) )
    addSimulationTransition!( mpSim, transition )

    setSimulationLength!( mpSim, 60.0 )
    @test verifySimulation!( mpSim )
    p = p[1:2]
    p .*= cumprod( vcat( 1, 1 .- p[1:(end - 1)] ) )
    p = vcat( p, 1.0 - sum( p ) )

    run( mpSim, saveConfig=false, seed=piseed )
    report = nodeEvolutionReport( mpSim, 12, "A", "B" )
    fluxReport = Int.( report[2]["B"][1][:, "trans: A => B"] )
    countReport = fluxReport[2:3]
    countReport = vcat( countReport, nt - sum( countReport ) )
    pval = pvalue( ChisqTest( countReport, p ) )
    @test pval > 0.05
    @test all( fluxReport .== [0, 253, 454, 0, 0, 0] )

    run( mpSim, saveConfig=false, seed=piseed )
    report = nodeEvolutionReport( mpSim, 12, "A", "B" )
    fluxReport = Int.( report[2]["B"][1][:, "trans: A => B"] )
    countReport = fluxReport[2:3]
    countReport = vcat( countReport, nt - sum( countReport ) )
    @test pvalue( ChisqTest( countReport, p ) ) == pval
    @test all( fluxReport .== [0, 253, 454, 0, 0, 0] )

    run( mpSim, saveConfig=false, seed=piseed, sysEnt=true )
    report = nodeEvolutionReport( mpSim, 12, "A", "B" )
    fluxReport = Int.( report[2]["B"][1][:, "trans: A => B"] )
    countReport = fluxReport[2:3]
    countReport = vcat( countReport, nt - sum( countReport ) )
    @test pvalue( ChisqTest( countReport, p ) ) != pval
    @test fluxReport != [0, 253, 454, 0, 0, 0]

    run( mpSim, saveConfig=false, seed=eseed )
    report = nodeEvolutionReport( mpSim, 12, "A", "B" )
    fluxReport = Int.( report[2]["B"][1][:, "trans: A => B"] )
    countReport = fluxReport[2:3]
    countReport = vcat( countReport, nt - sum( countReport ) )
    @test pvalue( ChisqTest( countReport, p ) ) > 0.05
    @test all( fluxReport .== [0, 260, 447, 0, 0, 0] )
    
    run( mpSim, saveConfig=false, seed=s2seed )
    report = nodeEvolutionReport( mpSim, 12, "A", "B" )
    fluxReport = Int.( report[2]["B"][1][:, "trans: A => B"] )
    countReport = fluxReport[2:3]
    countReport = vcat( countReport, nt - sum( countReport ) )
    @test pvalue( ChisqTest( countReport, p ) ) > 0.05
    @test all( fluxReport .== [0, 263, 452, 0, 0, 0] )
end  # @testset "Trans prob test IV"

@testset "Trans prob test V" begin
    mpSim = ManpowerSimulation()

    attribute = Attribute( "Level" )
    setPossibleAttributeValues!( attribute, ["A", "B"] )
    addSimulationAttribute!( mpSim, attribute )

    node = BaseNode( "A" )
    setNodeRequirements!( node, ["Level"], ["A"] )
    addSimulationBaseNode!( mpSim, node )

    node = BaseNode( "B" )
    setNodeRequirements!( node, ["Level"], ["B"] )
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
    p = [0.25, 0.5]
    setTransitionProbabilities!( transition, p )
    addTransitionCondition!( transition, MPcondition( "time in node", >=, 12 ) )
    addSimulationTransition!( mpSim, transition )

    setSimulationLength!( mpSim, 60.0 )
    @test verifySimulation!( mpSim )
    p = vcat( p, p[end] )
    p .*= cumprod( vcat( 1, 1 .- p[1:(end - 1)] ) )
    p = vcat( p, 1.0 - sum( p ) )

    run( mpSim, saveConfig=false, seed=piseed )
    report = nodeEvolutionReport( mpSim, 12, "A", "B" )
    fluxReport = Int.( report[2]["B"][1][:, "trans: A => B"] )
    countReport = fluxReport[2:4]
    countReport = vcat( countReport, nt - sum( countReport ) )
    pval = pvalue( ChisqTest( countReport, p ) )
    @test pval > 0.05
    @test all( fluxReport .== [0, 253, 391, 179, 0, 0] )

    run( mpSim, saveConfig=false, seed=piseed )
    report = nodeEvolutionReport( mpSim, 12, "A", "B" )
    fluxReport = Int.( report[2]["B"][1][:, "trans: A => B"] )
    countReport = fluxReport[2:4]
    countReport = vcat( countReport, nt - sum( countReport ) )
    @test pvalue( ChisqTest( countReport, p ) ) == pval
    @test all( fluxReport .== [0, 253, 391, 179, 0, 0] )

    run( mpSim, saveConfig=false, seed=piseed, sysEnt=true )
    report = nodeEvolutionReport( mpSim, 12, "A", "B" )
    fluxReport = Int.( report[2]["B"][1][:, "trans: A => B"] )
    countReport = fluxReport[2:4]
    countReport = vcat( countReport, nt - sum( countReport ) )
    @test pvalue( ChisqTest( countReport, p ) ) != pval
    @test fluxReport != [0, 253, 391, 179, 0, 0]

    run( mpSim, saveConfig=false, seed=eseed )
    report = nodeEvolutionReport( mpSim, 12, "A", "B" )
    fluxReport = Int.( report[2]["B"][1][:, "trans: A => B"] )
    countReport = fluxReport[2:4]
    countReport = vcat( countReport, nt - sum( countReport ) )
    @test pvalue( ChisqTest( countReport, p ) ) > 0.05
    @test all( fluxReport .== [0, 260, 366, 189, 0, 0] )
    
    run( mpSim, saveConfig=false, seed=s2seed )
    report = nodeEvolutionReport( mpSim, 12, "A", "B" )
    fluxReport = Int.( report[2]["B"][1][:, "trans: A => B"] )
    countReport = fluxReport[2:4]
    countReport = vcat( countReport, nt - sum( countReport ) )
    @test pvalue( ChisqTest( countReport, p ) ) > 0.05
    @test all( fluxReport .== [0, 263, 377, 171, 0, 0] )
end  # @testset "Trans prob test V"

@testset "Trans prob test VI" begin
    mpSim = ManpowerSimulation()

    attribute = Attribute( "Level" )
    setPossibleAttributeValues!( attribute, ["A", "B"] )
    addSimulationAttribute!( mpSim, attribute )

    node = BaseNode( "A" )
    setNodeRequirements!( node, ["Level"], ["A"] )
    addSimulationBaseNode!( mpSim, node )

    node = BaseNode( "B" )
    setNodeRequirements!( node, ["Level"], ["B"] )
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
    p = [0.25, 0.5]
    setTransitionProbabilities!( transition, p )
    addTransitionCondition!( transition, MPcondition( "time in node", >=, 12 ) )
    addSimulationTransition!( mpSim, transition )

    setSimulationLength!( mpSim, 60.0 )
    @test verifySimulation!( mpSim )
    p = vcat( p, fill( p[end], 3 ) )
    p .*= cumprod( vcat( 1, 1 .- p[1:(end - 1)] ) )
    p = vcat( p, 1.0 - sum( p ) )

    run( mpSim, saveConfig=false, seed=piseed )
    report = nodeEvolutionReport( mpSim, 12, "A", "B" )
    fluxReport = Int.( report[2]["B"][1][:, "trans: A => B"] )
    countReport = fluxReport[2:end]
    countReport = vcat( countReport, nt - sum( countReport ) )
    pval = pvalue( ChisqTest( countReport, p ) )
    @test pval > 0.05
    @test all( fluxReport .== [0, 253, 391, 179, 81, 46] )

    run( mpSim, saveConfig=false, seed=piseed )
    report = nodeEvolutionReport( mpSim, 12, "A", "B" )
    fluxReport = Int.( report[2]["B"][1][:, "trans: A => B"] )
    countReport = fluxReport[2:end]
    countReport = vcat( countReport, nt - sum( countReport ) )
    @test pvalue( ChisqTest( countReport, p ) ) == pval
    @test all( fluxReport .== [0, 253, 391, 179, 81, 46] )

    run( mpSim, saveConfig=false, seed=piseed, sysEnt=true )
    report = nodeEvolutionReport( mpSim, 12, "A", "B" )
    fluxReport = Int.( report[2]["B"][1][:, "trans: A => B"] )
    countReport = fluxReport[2:end]
    countReport = vcat( countReport, nt - sum( countReport ) )
    @test pvalue( ChisqTest( countReport, p ) ) != pval
    @test fluxReport != [0, 253, 391, 179, 81, 46]

    run( mpSim, saveConfig=false, seed=eseed )
    report = nodeEvolutionReport( mpSim, 12, "A", "B" )
    fluxReport = Int.( report[2]["B"][1][:, "trans: A => B"] )
    countReport = fluxReport[2:end]
    countReport = vcat( countReport, nt - sum( countReport ) )
    @test pvalue( ChisqTest( countReport, p ) ) > 0.05
    @test all( fluxReport .== [0, 260, 366, 189, 94, 52] )
    
    run( mpSim, saveConfig=false, seed=s2seed )
    report = nodeEvolutionReport( mpSim, 12, "A", "B" )
    fluxReport = Int.( report[2]["B"][1][:, "trans: A => B"] )
    countReport = fluxReport[2:end]
    countReport = vcat( countReport, nt - sum( countReport ) )
    @test pvalue( ChisqTest( countReport, p ) ) > 0.05
    @test all( fluxReport .== [0, 263, 377, 171, 84, 51] )
end  # @testset "Trans prob test VI"

end  # @testset "Transition probability tests"