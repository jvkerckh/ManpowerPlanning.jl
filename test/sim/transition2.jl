@testset "Transition process tests" begin

@testset "Basic transition test" begin
    mpSim = ManpowerSimulation()

    attribute = Attribute( "Level" )
    setPossibleAttributeValues!( attribute, ["A", "B"] )
    addSimulationAttribute!( mpSim, attribute )

    node = BaseNode( "A" )
    setNodeRequirements!( node, ["Level"], ["A"] )
    addSimulationBaseNode!( mpSim, node )

    node = BaseNode( "B" )
    setNodeRequirements!( node, ["Level"], ["B"] )
    setNodeTarget!( node, -1 )
    addSimulationBaseNode!( mpSim, node )

    recruitment = Recruitment( "EW" )
    setRecruitmentSchedule!( recruitment, 12 )
    setRecruitmentTarget!( recruitment, "A" )
    setRecruitmentFixed!( recruitment, 10 )
    setRecruitmentAgeFixed!( recruitment, 18 * 12 )
    addSimulationRecruitment!( mpSim, recruitment )

    transition = Transition( "trans", "A", "B" )
    setTransitionSchedule!( transition, 60 )
    addSimulationTransition!( mpSim, transition )

    retirement = Retirement()
    setRetirementCareerLength!( retirement, 120 )
    setRetirementSchedule!( retirement, 12 )
    setSimulationRetirement!( mpSim, retirement )

    setSimulationLength!( mpSim, 300.0 )

    @test verifySimulation!( mpSim )
    run( mpSim, saveConfig = false )

    report = nodeEvolutionReport( mpSim, 12, "A", "B" )
    popReport = report[1]
    fluxReportA = report[2]["A"]
    fluxReportB = report[2]["B"]
    
    @test all( popReport[:, :A] .== vcat( repeat( 10:10:50, 5 ), 10 ) ) &&
        all( popReport[:, :B] .==
        vcat( fill( 0, 5 ), fill( 50, 5 ), repeat( 90:-10:50, 3 ), 90 ) )
    @test all( fluxReportA[1][:, Symbol( "EW: external => A" )] .== 10 ) &&
        all( fluxReportA[2][:, Symbol( "trans: A => B" )] .==
        vcat( 0, repeat( [0, 0, 0, 0, 50], 5 ) ) )
    @test all( fluxReportB[1][:, Symbol( "trans: A => B" )] .==
        vcat( 0, repeat( [0, 0, 0, 0, 50], 5 ) ) ) &&
        all( fluxReportB[2][:, Symbol( "retirement: B => external" )] .==
        vcat( fill( 0, 10 ), fill( 10, 16 ) ) )

    clearSimulationTransitions!( mpSim )
    setTransitionSchedule!( transition, 48 )
    addSimulationTransition!( mpSim, transition )

    run( mpSim, saveConfig = false )
    report = nodePopReport( mpSim, 12, "A", "B" )
    @test all( report[:, :A] .== vcat( repeat( 10:10:40, 6 ), 10, 20 ) ) &&
        all( report[:, :B] .==
        vcat( fill( 0, 4 ), fill( 40, 4 ), 80, repeat( [80, 70, 60, 90], 4 ),
        80 ) )
    
    clearSimulationTransitions!( mpSim )
    setTransitionSchedule!( transition, 60, 24 )
    addSimulationTransition!( mpSim, transition )

    run( mpSim, saveConfig = false )
    report = nodePopReport( mpSim, 12, "A", "B" )
    @test all( report[:, :A] .==
        vcat( 10, 20, repeat( 10:10:50, 4 ), 10:10:40 ) ) &&
        all( report[:, :B] .== vcat( 0, 0, fill( 20, 5 ), 70, 70,
        repeat( [70, 60, 50, 90, 80], 3 ), 70, 60 ) )
end  # @testset "Basic transition test"

@testset "OUT transition test" begin
    mpSim = ManpowerSimulation()

    attribute = Attribute( "Level" )
    setPossibleAttributeValues!( attribute, ["A"] )
    addSimulationAttribute!( mpSim, attribute )

    node = BaseNode( "A" )
    setNodeRequirements!( node, ["Level"], ["A"] )
    addSimulationBaseNode!( mpSim, node )

    recruitment = Recruitment( "EW" )
    setRecruitmentSchedule!( recruitment, 12 )
    setRecruitmentTarget!( recruitment, "A" )
    setRecruitmentFixed!( recruitment, 10 )
    setRecruitmentAgeFixed!( recruitment, 18 * 12 )
    addSimulationRecruitment!( mpSim, recruitment )

    transition = Transition( "PE", "A" )
    setTransitionSchedule!( transition, 60 )
    addSimulationTransition!( mpSim, transition )

    setSimulationLength!( mpSim, 300.0 )

    @test verifySimulation!( mpSim )
    run( mpSim, saveConfig = false )

    report = nodeEvolutionReport( mpSim, 12, "A" )
    popReport = report[1]
    fluxReport = report[2]["A"]
    @test all( popReport[:, :A] .== vcat( repeat( 10:10:50, 5 ), 10 ) )
    @test all( fluxReport[1][:, Symbol( "EW: external => A" )] .== 10 ) &&
        all( fluxReport[2][:, Symbol( "PE: A => external" )] .==
        vcat( 0, repeat( [0, 0, 0, 0, 50], 5 ) ) )

    clearSimulationTransitions!( mpSim )
    setTransitionSchedule!( transition, 48 )
    addSimulationTransition!( mpSim, transition )

    run( mpSim, saveConfig = false )
    report = nodePopReport( mpSim, 12, "A" )
    @test all( report[:, :A] .== vcat( repeat( 10:10:40, 6 ), 10, 20 ) )

    clearSimulationTransitions!( mpSim )
    setTransitionSchedule!( transition, 60, 24 )
    addSimulationTransition!( mpSim, transition )

    run( mpSim, saveConfig = false )
    report = nodePopReport( mpSim, 12, "A" )
    @test all( report[:, :A] .== vcat( 10, 20, repeat( 10:10:50, 4 ),
        10:10:40 ) )
end  # @testset "OUT transition test"

@testset "Time conditions test" begin
    mpSim = ManpowerSimulation()

    attribute = Attribute( "Level" )
    setPossibleAttributeValues!( attribute, ["A", "B", "C"] )
    addSimulationAttribute!( mpSim, attribute )

    node = BaseNode( "A" )
    setNodeRequirements!( node, ["Level"], ["A"] )
    addSimulationBaseNode!( mpSim, node )

    node = BaseNode( "B" )
    setNodeRequirements!( node, ["Level"], ["B"] )
    setNodeTarget!( node, -1 )
    addSimulationBaseNode!( mpSim, node )

    node = BaseNode( "C" )
    setNodeRequirements!( node, ["Level"], ["C"] )
    setNodeTarget!( node, -1 )
    addSimulationBaseNode!( mpSim, node )

    recruitment = Recruitment( "EW" )
    setRecruitmentSchedule!( recruitment, 12 )
    setRecruitmentTarget!( recruitment, "A" )
    setRecruitmentFixed!( recruitment, 10 )
    setRecruitmentAgeFixed!( recruitment, 18 * 12 )
    addSimulationRecruitment!( mpSim, recruitment )

    transition = Transition( "trans", "A", "B" )
    setTransitionSchedule!( transition, 24 )
    addTransitionCondition!( transition, MPcondition( "tenure", >=, 36 ) )
    addSimulationTransition!( mpSim, transition )

    retirement = Retirement()
    setRetirementCareerLength!( retirement, 120 )
    setRetirementSchedule!( retirement, 12 )
    setSimulationRetirement!( mpSim, retirement )

    setSimulationLength!( mpSim, 300.0 )

    @test verifySimulation!( mpSim )
    run( mpSim, saveConfig = false )

    report = nodeEvolutionReport( mpSim, 12, "A", "B" )
    popReport = report[1]
    fluxReportA = report[2]["A"]
    fluxReportB = report[2]["B"]
    @test all( popReport[:, :A] .==
        vcat( 10, 20, repeat( [30, 40], 12 ) ) ) &&
        all( popReport[:, :B] .==
        vcat( fill( 0, 4 ), 20, 20, 40, 40, 60, 60, repeat( [70, 60], 8 ) ) )
    @test all( fluxReportA[1][:, Symbol( "EW: external => A" )] .== 10 ) &&
        all( fluxReportA[2][:, Symbol( "trans: A => B" )] .==
        vcat( fill( 0, 4 ), repeat( [20, 0], 11 ) ) )
    @test all( fluxReportB[1][:, Symbol( "trans: A => B" )] .==
        vcat( fill( 0, 4 ), repeat( [20, 0], 11 ) ) ) &&
        all( fluxReportB[2][:, Symbol( "retirement: B => external" )] .==
        vcat( fill( 0, 10 ), fill( 10, 16 ) ) )

    clearSimulationTransitions!( mpSim )
    clearTransitionConditions!( transition )
    addTransitionCondition!( transition, MPcondition( "age", ==, 21 * 12 ) )
    addSimulationTransition!( mpSim, transition )

    run( mpSim, saveConfig = false )
    report = nodePopReport( mpSim, 12, "A", "B" )
    @test all( report[:, :A] .==
        vcat( 10:10:40, 40, 50, 50, 60, repeat( [60, 70], 9 ) ) ) &&
        all( report[:, :B] .==
        vcat( fill( 0, 4 ), 10, 10, 20, 20, 30, 30, repeat( [40, 30], 8 ) ) )
    
    clearSimulationTransitions!( mpSim )
    clearTransitionConditions!( transition )
    setTransitionSchedule!( transition, 12 )
    addTransitionCondition!( transition, MPcondition( "tenure", >=, 36 ) )
    addSimulationTransition!( mpSim, transition )

    transition = Transition( "trans", "B", "C" )
    setTransitionSchedule!( transition, 24 )
    addTransitionCondition!( transition, MPcondition( "tenure", >=, 60 ),
        MPcondition( "time in node", <=, 24 ) )
    addSimulationTransition!( mpSim, transition )
    
    run( mpSim, saveConfig = false )
    report = nodePopReport( mpSim, 12, "A", "B", "C" )
    @test all( report[:, :A] .== vcat( 10, 20, fill( 30, 24 ) ) ) &&
        all( report[:, :B] .==
        vcat( fill( 0, 3 ), 10:10:30, 30, 40, repeat( [40, 50], 9 ) ) ) &&
        all( report[:, :C] .==
        vcat( fill( 0, 6 ), 10, 10, 20, 20, repeat( [30, 20], 8 ) ) )
end  # @testset "Time conditions test"

@testset "Extra conditions test" begin
    mpSim = ManpowerSimulation()

    attribute = Attribute( "Level" )
    setPossibleAttributeValues!( attribute, ["A", "B", "C"] )
    addSimulationAttribute!( mpSim, attribute )

    attribute = Attribute( "Branch" )
    setPossibleAttributeValues!( attribute, ["A", "B"] )
    addSimulationAttribute!( mpSim, attribute )

    node = BaseNode( "A" )
    setNodeRequirements!( node, ["Level", "Branch"], ["A", "A"] )
    addSimulationBaseNode!( mpSim, node )

    node = BaseNode( "B" )
    setNodeRequirements!( node, ["Level", "Branch"], ["A", "B"] )
    addSimulationBaseNode!( mpSim, node )

    node = BaseNode( "C" )
    setNodeRequirements!( node, ["Level"], ["B"] )
    setNodeTarget!( node, -1 )
    addSimulationBaseNode!( mpSim, node )

    node = BaseNode( "D" )
    setNodeRequirements!( node, ["Level"], ["C"] )
    setNodeTarget!( node, -1 )
    addSimulationBaseNode!( mpSim, node )

    recruitment = Recruitment( "EW" )
    setRecruitmentSchedule!( recruitment, 12 )
    setRecruitmentTarget!( recruitment, "A" )
    setRecruitmentFixed!( recruitment, 10 )
    setRecruitmentAgeFixed!( recruitment, 18 * 12 )
    addSimulationRecruitment!( mpSim, recruitment )

    recruitment = Recruitment( "EW" )
    setRecruitmentSchedule!( recruitment, 12 )
    setRecruitmentTarget!( recruitment, "B" )
    setRecruitmentFixed!( recruitment, 10 )
    setRecruitmentAgeFixed!( recruitment, 18 * 12 )
    addSimulationRecruitment!( mpSim, recruitment )

    transition = Transition( "trans", "A", "C" )
    setTransitionSchedule!( transition, 12 )
    addTransitionCondition!( transition, MPcondition( "time in node", >=, 24 ) )
    addSimulationTransition!( mpSim, transition )

    transition = Transition( "trans", "B", "C" )
    setTransitionSchedule!( transition, 12 )
    addTransitionCondition!( transition, MPcondition( "time in node", >=, 24 ) )
    addSimulationTransition!( mpSim, transition )

    transition = Transition( "trans", "C", "D" )
    setTransitionSchedule!( transition, 12 )
    addTransitionCondition!( transition,
        MPcondition( "time in node", >=, 36 ),
        MPcondition( "Branch", !=, "B" ) )
    addSimulationTransition!( mpSim, transition )

    retirement = Retirement()
    setRetirementCareerLength!( retirement, 120 )
    setRetirementSchedule!( retirement, 12 )
    setSimulationRetirement!( mpSim, retirement )

    setSimulationLength!( mpSim, 300.0 )

    @test verifySimulation!( mpSim )
    run( mpSim, saveConfig = false )

    subpop1 = Subpopulation( "Subpop1" )
    addSubpopulationCondition!( subpop1, MPcondition( "Branch", ==, "A" ) )
    subpop2 = Subpopulation( "Subpop2" )
    addSubpopulationCondition!( subpop2, MPcondition( "Branch", ==, "B" ) )
    subpop3 = Subpopulation( "Subpop3" )
    addSubpopulationCondition!( subpop3, MPcondition( "Branch", ==, "A" ) )
    subpop4 = Subpopulation( "Subpop4" )
    addSubpopulationCondition!( subpop4, MPcondition( "Branch", ==, "B" ) )

    setSubpopulationSourceNode!.( [subpop1, subpop2, subpop3, subpop4],
        ["C", "C", "D", "D"] )

    report = nodePopReport( mpSim, 12, "A", "B", "C", "D" )
    @test all( report[:, :A] .== vcat( 10, fill( 20, 25 ) ) ) &&
        all( report[:, :B] .== vcat( 10, fill( 20, 25 ) ) ) &&
        all( report[:, :C] .==
        vcat( 0, 0, 20, 40, 60:10:100, fill( 110, 17 ) ) ) &&
        all( report[:, :D] .==
        vcat( fill( 0, 5 ), 10:10:40, fill( 50, 17 ) ) )

    report = subpopulationPopReport( mpSim, 12, subpop1, subpop2, subpop3,
        subpop4 )
    @test all( report[:, :Subpop1] .==
        vcat( 0, 0, 10, 20, fill( 30, 22 ) ) ) &&
        all( report[:, :Subpop2] .==
        vcat( 0, 0, 10:10:70, fill( 80, 17 ) ) ) &&
        all( report[:, :Subpop3] .==
        vcat( fill( 0, 5 ), 10:10:40, fill( 50, 17 ) ) ) &&
        all( report[:, :Subpop4] .== 0 )
end  # @testset "Extra conditions test"

@testset "Min/max flux test" begin
    mpSim = ManpowerSimulation()

    attribute = Attribute( "Level" )
    setPossibleAttributeValues!( attribute, ["A", "B"] )
    addSimulationAttribute!( mpSim, attribute )

    node = BaseNode( "A" )
    setNodeRequirements!( node, ["Level"], ["A"] )
    addSimulationBaseNode!( mpSim, node )

    node = BaseNode( "B" )
    setNodeRequirements!( node, ["Level"], ["B"] )
    setNodeTarget!( node, 40 )
    addSimulationBaseNode!( mpSim, node )

    recruitment = Recruitment( "EW" )
    setRecruitmentSchedule!( recruitment, 12 )
    setRecruitmentTarget!( recruitment, "A" )
    setRecruitmentFixed!( recruitment, 20 )
    setRecruitmentAgeFixed!( recruitment, 18 * 12 )
    addSimulationRecruitment!( mpSim, recruitment )

    transition = Transition( "trans", "A", "B" )
    setTransitionSchedule!( transition, 12 )
    setTransitionFluxLimits!( transition, 5, 10 )
    addTransitionCondition!( transition, MPcondition( "time in node", >=, 36 ) )
    addSimulationTransition!( mpSim, transition )

    transition = Transition( "trans", "B" )
    setTransitionSchedule!( transition, 12 )
    addTransitionCondition!( transition, MPcondition( "tenure", >=, 120 ) )
    addSimulationTransition!( mpSim, transition )

    retirement = Retirement()
    setRetirementCareerLength!( retirement, 120 )
    setRetirementSchedule!( retirement, 12 )
    setSimulationRetirement!( mpSim, retirement )

    setSimulationLength!( mpSim, 300.0 )

    @test verifySimulation!( mpSim )
    run( mpSim, saveConfig = false )

    report = nodeEvolutionReport( mpSim, 12, "A", "B" )
    popReport = report[1]
    fluxReportB = report[2]["B"]
    @test all( popReport[:, :B] .==
        vcat( 0, 0, 0, 10:10:40, 45:5:55, 50, 45, fill( 40, 14 ) ) )
    @test all( fluxReportB[1][:, Symbol( "other => B" )] .==
        vcat( 0, 0, 0, fill( 10, 4 ), fill( 5, 6 ), 10, fill( 5, 6 ), 10,
        fill( 5, 5 ) ) )
end  # @testset "Min/max flux test"

@testset "# of attempts test" begin
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
    setRecruitmentSchedule!( recruitment, 360 )
    setRecruitmentTarget!( recruitment, "A" )
    setRecruitmentFixed!( recruitment, 100 )
    setRecruitmentAgeFixed!( recruitment, 18 * 12 )
    addSimulationRecruitment!( mpSim, recruitment )

    transition = Transition( "trans", "A", "B" )
    setTransitionSchedule!( transition, 12 )
    setTransitionFluxLimits!( transition, 10, 10 )
    setTransitionMaxAttempts!( transition, 1 )
    addTransitionCondition!( transition, MPcondition( "time in node", >=, 60 ) )
    addSimulationTransition!( mpSim, transition )

    setSimulationLength!( mpSim, 300.0 )

    @test verifySimulation!( mpSim )
    run( mpSim, saveConfig = false )

    report = nodePopReport( mpSim, 12, "A", "B" )
    @test all( report[:, :B] .== vcat( fill( 0, 5 ), fill( 10, 21 ) ) )

    clearSimulationTransitions!( mpSim )
    setTransitionMaxAttempts!( transition, 5 )
    addSimulationTransition!( mpSim, transition )
    run( mpSim, saveConfig = false )

    report = nodePopReport( mpSim, 12, "A", "B" )
    @test all( report[:, :B] .==
        vcat( fill( 0, 5 ), 10:10:40, fill( 50, 17 ) ) )

    clearSimulationTransitions!( mpSim )
    setTransitionMaxAttempts!( transition, -1 )
    addSimulationTransition!( mpSim, transition )
    run( mpSim, saveConfig = false )

    report = nodePopReport( mpSim, 12, "A", "B" )
    @test all( report[:, :B] .==
        vcat( fill( 0, 5 ), 10:10:90, fill( 100, 12 ) ) )
end  # @testset "# of attempts test"

@testset "Extra changes test" begin
    mpSim = ManpowerSimulation()

    attribute = Attribute( "Level" )
    setPossibleAttributeValues!( attribute, ["A", "B"] )
    addSimulationAttribute!( mpSim, attribute )

    attribute = Attribute( "Extra" )
    addInitialAttributeValue!( attribute, ("A", 1.0) )
    addPossibleAttributeValue!( attribute, "B" )
    addSimulationAttribute!( mpSim, attribute )

    node = BaseNode( "A" )
    setNodeRequirements!( node, ["Level"], ["A"] )
    addSimulationBaseNode!( mpSim, node )

    node = BaseNode( "B" )
    setNodeRequirements!( node, ["Level"], ["B"] )
    addSimulationBaseNode!( mpSim, node )

    recruitment = Recruitment( "EW" )
    setRecruitmentSchedule!( recruitment, 12 )
    setRecruitmentTarget!( recruitment, "A" )
    setRecruitmentFixed!( recruitment, 10 )
    setRecruitmentAgeFixed!( recruitment, 18 * 12 )
    addSimulationRecruitment!( mpSim, recruitment )

    transition = Transition( "trans", "A", "B" )
    setTransitionSchedule!( transition, 12 )
    setTransitionMaxAttempts!( transition, 1 )
    addTransitionCondition!( transition, MPcondition( "time in node", >=, 36 ) )
    addTransitionAttributeChange!( transition, ("Extra", "B") )
    addSimulationTransition!( mpSim, transition )

    retirement = Retirement()
    setRetirementCareerLength!( retirement, 120 )
    setRetirementSchedule!( retirement, 12 )
    setSimulationRetirement!( mpSim, retirement )

    setSimulationLength!( mpSim, 300.0 )

    subpop = Subpopulation( "B" )
    addSubpopulationCondition!( subpop, MPcondition( "Extra", ==, "B" ) )
    setSubpopulationSourceNode!( subpop, "B" )

    @test verifySimulation!( mpSim )
    run( mpSim, saveConfig = false )

    popReport = nodePopReport( mpSim, 12, "A", "B" )
    subpopReport = subpopulationPopReport( mpSim, 12, subpop )
    @test all( popReport[:, :B] .== subpopReport[:, :B] )

    clearSimulationTransitions!( mpSim )
    addTransitionAttributeChange!( transition, ("Level", "A") )
    addSimulationTransition!( mpSim, transition )

    subpop = Subpopulation( "A" )
    addSubpopulationCondition!( subpop, MPcondition( "Level", ==, "A" ) )
    setSubpopulationSourceNode!( subpop, "B" )

    run( mpSim, saveConfig = false )
    popReport = nodePopReport( mpSim, 12, "A", "B" )
    subpopReport = subpopulationPopReport( mpSim, 12, subpop )
    @test all( popReport[:, :B] .== subpopReport[:, :A] )

end  # @testset "Extra changes test"

end  # @testset "Transition process tests"