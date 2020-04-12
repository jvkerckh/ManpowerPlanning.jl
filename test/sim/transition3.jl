@testset "Transition priority tests" begin

@testset "OUT before IN priority test" begin
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
    setRecruitmentFixed!( recruitment, 10 )
    setRecruitmentAgeFixed!( recruitment, 18 * 12 )
    addSimulationRecruitment!( mpSim, recruitment )

    transition = Transition( "trans", "A", "B" )
    setTransitionSchedule!( transition, 12 )
    addTransitionCondition!( transition, MPcondition( "time in node", >=, 36 ) )
    addSimulationTransition!( mpSim, transition )

    transition = Transition( "trans", "B" )
    setTransitionSchedule!( transition, 12 )
    addTransitionCondition!( transition,
        MPcondition( "tenure", >=, 120 ) )
    addSimulationTransition!( mpSim, transition )

    retirement = Retirement()
    setRetirementCareerLength!( retirement, 120 )
    setRetirementSchedule!( retirement, 12 )
    setSimulationRetirement!( mpSim, retirement )

    setSimulationLength!( mpSim, 300.0 )

    @test verifySimulation!( mpSim )
    run( mpSim, saveConfig = false )

    report = nodePopReport( mpSim, 12, "A", "B" )
    @test all( report[:, :A] .==
        vcat( 10, 20, fill( 30, 5 ), 40, 50, fill( 60, 17 ) ) ) &&
        all( report[:, :B] .== vcat( 0, 0, 0, 10:10:30, fill( 40, 20 ) ) )
    
    clearSimulationTransitions!( mpSim )

    transition = Transition( "trans1", "A", "B" )
    setTransitionSchedule!( transition, 12 )
    addTransitionCondition!( transition, MPcondition( "time in node", >=, 36 ) )
    addSimulationTransition!( mpSim, transition )

    transition = Transition( "trans2", "B" )
    setTransitionSchedule!( transition, 12 )
    addTransitionCondition!( transition,
        MPcondition( "tenure", >=, 120 ) )
    addSimulationTransition!( mpSim, transition )

    setSimulationTransitionTypeOrder!( mpSim,
        Dict( "trans1" => 1, "trans2" => 2 ) )

    run( mpSim, saveConfig = false )
    report = nodePopReport( mpSim, 12, "A", "B" )
    @test all( report[:, :A] .==
        vcat( 10, 20, fill( 30, 5 ), 40, 50, fill( 60, 17 ) ) ) &&
        all( report[:, :B] .== vcat( 0, 0, 0, 10:10:30, fill( 40, 20 ) ) )
end  # @testset "OUT before IN priority test"

@testset "OUT transitions priority test" begin
    mpSim = ManpowerSimulation()

    attribute = Attribute( "Level" )
    setPossibleAttributeValues!( attribute, ["A", "B"] )
    addSimulationAttribute!( mpSim, attribute )

    attribute = Attribute( "Branch" )
    setPossibleAttributeValues!( attribute, ["none", "A", "B"] )
    setInitialAttributeValues!( attribute, Dict( "none" => 1.0 ) )
    addSimulationAttribute!( mpSim, attribute )

    node = BaseNode( "A" )
    setNodeRequirements!( node, ["Level"], ["A"] )
    addSimulationBaseNode!( mpSim, node )

    node = BaseNode( "B" )
    setNodeRequirements!( node, ["Level", "Branch"], ["B", "A"] )
    setNodeTarget!( node, -1 )
    addSimulationBaseNode!( mpSim, node )

    node = BaseNode( "C" )
    setNodeRequirements!( node, ["Level", "Branch"], ["B", "B"] )
    setNodeTarget!( node, -1 )
    addSimulationBaseNode!( mpSim, node )

    recruitment = Recruitment( "EW" )
    setRecruitmentSchedule!( recruitment, 12 )
    setRecruitmentTarget!( recruitment, "A" )
    setRecruitmentFixed!( recruitment, 6 )
    setRecruitmentAgeFixed!( recruitment, 18 * 12 )
    addSimulationRecruitment!( mpSim, recruitment )

    transition = Transition( "trans1", "A", "B" )
    setTransitionSchedule!( transition, 12 )
    setTransitionFluxLimits!( transition, 4, 8 )
    setTransitionMaxAttempts!( transition, 1 )
    addTransitionCondition!( transition, MPcondition( "time in node", >=, 36 ) )
    addSimulationTransition!( mpSim, transition )

    transition = Transition( "trans2", "A", "C" )
    setTransitionSchedule!( transition, 12 )
    setTransitionFluxLimits!( transition, 4, 8 )
    setTransitionMaxAttempts!( transition, 1 )
    addTransitionCondition!( transition, MPcondition( "time in node", >=, 36 ) )
    addSimulationTransition!( mpSim, transition )

    setSimulationTransitionTypeOrder!( mpSim,
        Dict( "trans1" => 2, "trans2" => 1 ) )

    retirement = Retirement()
    setRetirementCareerLength!( retirement, 120 )
    setRetirementSchedule!( retirement, 12 )
    setSimulationRetirement!( mpSim, retirement )

    setSimulationLength!( mpSim, 300.0 )

    @test verifySimulation!( mpSim )
    run( mpSim, saveConfig = false )

    report = nodeEvolutionReport( mpSim, 12, "A", "B", "C" )[2]["A"][2]
    @test all( report[:, Symbol( "trans1: A => B" )] .==
        vcat( 0, 0, 0, fill( 2, 23 ) ) ) &&
        all( report[:, Symbol( "trans2: A => C" )] .==
        vcat( 0, 0, 0, fill( 4, 23 ) ) )
    
    clearSimulationRecruitment!( mpSim )
    setRecruitmentFixed!( recruitment, 10 )
    addSimulationRecruitment!( mpSim, recruitment )

    run( mpSim, saveConfig = false )
    report = nodeEvolutionReport( mpSim, 12, "A", "B", "C" )[2]["A"][2]
    @test all( report[:, Symbol( "trans1: A => B" )] .==
        vcat( 0, 0, 0, fill( 4, 23 ) ) ) &&
        all( report[:, Symbol( "trans2: A => C" )] .==
        vcat( 0, 0, 0, fill( 6, 23 ) ) )

    clearSimulationRecruitment!( mpSim )
    setRecruitmentFixed!( recruitment, 14 )
    addSimulationRecruitment!( mpSim, recruitment )

    run( mpSim, saveConfig = false )
    report = nodeEvolutionReport( mpSim, 12, "A", "B", "C" )[2]["A"][2]
    @test all( report[:, Symbol( "trans1: A => B" )] .==
        vcat( 0, 0, 0, fill( 6, 23 ) ) ) &&
        all( report[:, Symbol( "trans2: A => C" )] .==
        vcat( 0, 0, 0, fill( 8, 23 ) ) )

    clearSimulationRecruitment!( mpSim )
    setRecruitmentFixed!( recruitment, 18 )
    addSimulationRecruitment!( mpSim, recruitment )

    run( mpSim, saveConfig = false )
    report = nodeEvolutionReport( mpSim, 12, "A", "B", "C" )[2]["A"][2]
    @test all( report[:, Symbol( "trans1: A => B" )] .==
        vcat( 0, 0, 0, fill( 8, 23 ) ) ) &&
        all( report[:, Symbol( "trans2: A => C" )] .==
        vcat( 0, 0, 0, fill( 8, 23 ) ) )

    clearSimulationRecruitment!( mpSim )
    setRecruitmentFixed!( recruitment, 10 )
    addSimulationRecruitment!( mpSim, recruitment )
    
    clearSimulationTransitions!( mpSim )
    setSimulationBaseNodeOrder!( mpSim, Dict( "B" => 2, "C" => 1 ) )
    transition = Transition( "trans", "A", "B" )
    setTransitionSchedule!( transition, 12 )
    setTransitionFluxLimits!( transition, 4, 8 )
    setTransitionMaxAttempts!( transition, 1 )
    addTransitionCondition!( transition, MPcondition( "time in node", >=, 36 ) )
    addSimulationTransition!( mpSim, transition )

    transition = Transition( "trans", "A", "C" )
    setTransitionSchedule!( transition, 12 )
    setTransitionFluxLimits!( transition, 4, 8 )
    setTransitionMaxAttempts!( transition, 1 )
    addTransitionCondition!( transition, MPcondition( "time in node", >=, 36 ) )
    addSimulationTransition!( mpSim, transition )

    run( mpSim, saveConfig = false )
    report = nodeEvolutionReport( mpSim, 12, "A", "B", "C" )[2]["A"][2]
    @test all( report[:, Symbol( "trans: A => B" )] .==
        vcat( 0, 0, 0, fill( 4, 23 ) ) ) &&
        all( report[:, Symbol( "trans: A => C" )] .==
        vcat( 0, 0, 0, fill( 6, 23 ) ) )
end  # @testset ""OUT transitions priority test""

@testset "IN transition priority test" begin
    mpSim = ManpowerSimulation()

    attribute = Attribute( "Level" )
    setPossibleAttributeValues!( attribute, ["A", "B"] )
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
    setNodeTarget!( node, 6 )
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

    transition = Transition( "trans1", "A", "C" )
    setTransitionSchedule!( transition, 12 )
    setTransitionFluxLimits!( transition, 4, 8 )
    setTransitionMaxAttempts!( transition, 1 )
    addTransitionCondition!( transition, MPcondition( "time in node", >=, 36 ) )
    addSimulationTransition!( mpSim, transition )

    transition = Transition( "trans2", "B", "C" )
    setTransitionSchedule!( transition, 12 )
    setTransitionFluxLimits!( transition, 4, 8 )
    setTransitionMaxAttempts!( transition, 1 )
    addTransitionCondition!( transition, MPcondition( "time in node", >=, 36 ) )
    addSimulationTransition!( mpSim, transition )

    transition = Transition( "PE", "C" )
    setTransitionSchedule!( transition, 12 )
    addTransitionCondition!( transition, MPcondition( "time in node", >=, 12 ) )
    addSimulationTransition!( mpSim, transition )

    setSimulationTransitionTypeOrder!( mpSim,
    Dict( "trans1" => 2, "trans2" => 1 ) )

    retirement = Retirement()
    setRetirementCareerLength!( retirement, 120 )
    setRetirementSchedule!( retirement, 12 )
    setSimulationRetirement!( mpSim, retirement )

    setSimulationLength!( mpSim, 300.0 )

    @test verifySimulation!( mpSim )
    run( mpSim, saveConfig = false )

    report = nodeEvolutionReport( mpSim, 12, "A", "B", "C" )[2]["C"][1]
    @test all( report[:, Symbol( "trans1: A => C" )] .==
        vcat( 0, 0, 0, fill( 4, 23 ) ) ) &&
        all( report[:, Symbol( "trans2: B => C" )] .==
        vcat( 0, 0, 0, fill( 4, 23 ) ) )

    setNodeTarget!( node, 10 )
    addSimulationBaseNode!( mpSim, node )

    run( mpSim, saveConfig = false )
    report = nodeEvolutionReport( mpSim, 12, "A", "B", "C" )[2]["C"][1]
    @test all( report[:, Symbol( "trans1: A => C" )] .==
        vcat( 0, 0, 0, fill( 4, 23 ) ) ) &&
        all( report[:, Symbol( "trans2: B => C" )] .==
        vcat( 0, 0, 0, fill( 6, 23 ) ) )

    setNodeTarget!( node, 14 )
    addSimulationBaseNode!( mpSim, node )

    run( mpSim, saveConfig = false )
    report = nodeEvolutionReport( mpSim, 12, "A", "B", "C" )[2]["C"][1]
    @test all( report[:, Symbol( "trans1: A => C" )] .==
        vcat( 0, 0, 0, fill( 6, 23 ) ) ) &&
        all( report[:, Symbol( "trans2: B => C" )] .==
        vcat( 0, 0, 0, fill( 8, 23 ) ) )

    setNodeTarget!( node, 18 )
    addSimulationBaseNode!( mpSim, node )

    run( mpSim, saveConfig = false )
    report = nodeEvolutionReport( mpSim, 12, "A", "B", "C" )[2]["C"][1]
    @test all( report[:, Symbol( "trans1: A => C" )] .==
        vcat( 0, 0, 0, fill( 8, 23 ) ) ) &&
        all( report[:, Symbol( "trans2: B => C" )] .==
        vcat( 0, 0, 0, fill( 8, 23 ) ) )
    
    clearSimulationTransitions!( mpSim )
    setSimulationBaseNodeOrder!( mpSim, Dict( "A" => 2, "B" => 1 ) )
    setNodeTarget!( node, 10 )

    transition = Transition( "trans", "A", "C" )
    setTransitionSchedule!( transition, 12 )
    setTransitionFluxLimits!( transition, 4, 8 )
    setTransitionMaxAttempts!( transition, 1 )
    addTransitionCondition!( transition, MPcondition( "time in node", >=, 36 ) )
    addSimulationTransition!( mpSim, transition )

    transition = Transition( "trans", "B", "C" )
    setTransitionSchedule!( transition, 12 )
    setTransitionFluxLimits!( transition, 4, 8 )
    setTransitionMaxAttempts!( transition, 1 )
    addTransitionCondition!( transition, MPcondition( "time in node", >=, 36 ) )
    addSimulationTransition!( mpSim, transition )

    transition = Transition( "PE", "C" )
    setTransitionSchedule!( transition, 12 )
    addTransitionCondition!( transition, MPcondition( "time in node", >=, 12 ) )
    addSimulationTransition!( mpSim, transition )

    run( mpSim, saveConfig = false )
    report = nodeEvolutionReport( mpSim, 12, "A", "B", "C" )[2]["C"][1]
    @test all( report[:, Symbol( "trans: A => C" )] .==
        vcat( 0, 0, 0, fill( 4, 23 ) ) ) &&
        all( report[:, Symbol( "trans: B => C" )] .==
        vcat( 0, 0, 0, fill( 6, 23 ) ) )
end  # @testset "IN transition priority test"

println()

end  # @testset "Transition priority tests"