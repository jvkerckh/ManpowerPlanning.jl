@testset "Transition order tests" begin

mpSim = ManpowerSimulation( "sim" )

# Attributes
attribute = Attribute( "Subkader" )
setPossibleAttributeValues!( attribute, ["BDL", "Beroeps"] )
addSimulationAttribute!( mpSim, attribute )

attribute = Attribute( "Categorie" )
setPossibleAttributeValues!( attribute, ["Vrijw", "OOffr", "Offr"] )
addSimulationAttribute!( mpSim, attribute )

attribute = Attribute( "Niveau" )
setPossibleAttributeValues!( attribute, ["D", "C", "B", "A"] )
addSimulationAttribute!( mpSim, attribute )

attribute = Attribute( "Geslacht" )
setInitialAttributeValues!( attribute, ("M", 65.0), ("V", 35.0) )
addSimulationAttribute!( mpSim, attribute )

attribute = Attribute( "Taalgroep" )
setInitialAttributeValues!( attribute, ("NL", 62.0), ("FR", 38.0) )
addSimulationAttribute!( mpSim, attribute )

# Base nodes
node = BaseNode( "3D-D" )
setNodeRequirements!( node, ["Subkader", "Categorie", "Niveau"],
    ["BDL", "Vrijw", "D"] )
addSimulationBaseNode!( mpSim, node )

node = BaseNode( "3D-B" )
setNodeRequirements!( node, ["Subkader", "Categorie", "Niveau"],
    ["Beroeps", "Vrijw", "D"] )
addSimulationBaseNode!( mpSim, node )

node = BaseNode( "2C-D" )
setNodeRequirements!( node, ["Subkader", "Categorie", "Niveau"],
    ["BDL", "OOffr", "C"] )
addSimulationBaseNode!( mpSim, node )

node = BaseNode( "2C-B" )
setNodeRequirements!( node, ["Subkader", "Categorie", "Niveau"],
    ["Beroeps", "OOffr", "C"] )
addSimulationBaseNode!( mpSim, node )

node = BaseNode( "2B-D" )
setNodeRequirements!( node, ["Subkader", "Categorie", "Niveau"],
    ["BDL", "OOffr", "B"] )
addSimulationBaseNode!( mpSim, node )

node = BaseNode( "2B-B" )
setNodeRequirements!( node, ["Subkader", "Categorie", "Niveau"],
    ["Beroeps", "OOffr", "B"] )
addSimulationBaseNode!( mpSim, node )

node = BaseNode( "1B-D" )
setNodeRequirements!( node, ["Subkader", "Categorie", "Niveau"],
    ["BDL", "Offr", "B"] )
addSimulationBaseNode!( mpSim, node )

node = BaseNode( "1B-B" )
setNodeRequirements!( node, ["Subkader", "Categorie", "Niveau"],
    ["Beroeps", "Offr", "B"] )
addSimulationBaseNode!( mpSim, node )

node = BaseNode( "1A-D" )
setNodeRequirements!( node, ["Subkader", "Categorie", "Niveau"],
    ["BDL", "Offr", "A"] )
addSimulationBaseNode!( mpSim, node )

node = BaseNode( "1A-B" )
setNodeRequirements!( node, ["Subkader", "Categorie", "Niveau"],
    ["Beroeps", "Offr", "A"] )
addSimulationBaseNode!( mpSim, node )

# Compound nodes
node = CompoundNode( "BDL" )
setCompoundNodeComponents!( node, "3D-D", "2C-D", "2B-D", "1B-D", "1A-D" )
addSimulationCompoundNode!( mpSim, node )

node = CompoundNode( "Beroeps" )
setCompoundNodeComponents!( node, "3D-B", "2C-B", "2B-B", "1B-B", "1A-B" )
addSimulationCompoundNode!( mpSim, node )

node = CompoundNode( "Vrijw" )
setCompoundNodeComponents!( node, "3D-D", "3D-B" )
addSimulationCompoundNode!( mpSim, node )

node = CompoundNode( "OOffr" )
setCompoundNodeComponents!( node, "2C-D", "2C-B", "2B-D", "2B-B" )
addSimulationCompoundNode!( mpSim, node )

node = CompoundNode( "Offr" )
setCompoundNodeComponents!( node, "1B-D", "1B-B", "1A-D", "1A-B" )
addSimulationCompoundNode!( mpSim, node )

node = CompoundNode( "Niveau D" )
setCompoundNodeComponents!( node, "3D-D", "3D-B" )
addSimulationCompoundNode!( mpSim, node )

node = CompoundNode( "Niveau C" )
setCompoundNodeComponents!( node, "2C-D", "2C-B" )
addSimulationCompoundNode!( mpSim, node )

node = CompoundNode( "Niveau B" )
setCompoundNodeComponents!( node, "2B-D", "2B-B", "1B-D", "1B-B" )
addSimulationCompoundNode!( mpSim, node )

node = CompoundNode( "Niveau A" )
setCompoundNodeComponents!( node, "1A-D", "1A-B" )
addSimulationCompoundNode!( mpSim, node )

# Recruitment
recruitment = Recruitment( "EW" )
setRecruitmentSchedule!( recruitment, 12 )
setRecruitmentTarget!( recruitment, "3D-D" )
setRecruitmentAdaptiveRange!( recruitment, 408, 815 )
setRecruitmentAgeFixed!( recruitment, 18 * 12 )
addSimulationRecruitment!( mpSim, recruitment )

recruitment = Recruitment( "EW" )
setRecruitmentSchedule!( recruitment, 12 )
setRecruitmentTarget!( recruitment, "2C-D" )
setRecruitmentAdaptiveRange!( recruitment, 487, 974 )
setRecruitmentAgeFixed!( recruitment, 18 * 12 )
addSimulationRecruitment!( mpSim, recruitment )

recruitment = Recruitment( "EW" )
setRecruitmentSchedule!( recruitment, 12 )
setRecruitmentTarget!( recruitment, "2B-D" )
setRecruitmentAdaptiveRange!( recruitment, 31, 61 )
setRecruitmentAgeFixed!( recruitment, 18 * 12 )
addSimulationRecruitment!( mpSim, recruitment )

recruitment = Recruitment( "EW" )
setRecruitmentSchedule!( recruitment, 12 )
setRecruitmentTarget!( recruitment, "1B-D" )
setRecruitmentAdaptiveRange!( recruitment, 67, 134 )
setRecruitmentAgeFixed!( recruitment, 18 * 12 )
addSimulationRecruitment!( mpSim, recruitment )

recruitment = Recruitment( "EW" )
setRecruitmentSchedule!( recruitment, 12 )
setRecruitmentTarget!( recruitment, "1A-D" )
setRecruitmentAdaptiveRange!( recruitment, 136, 271 )
setRecruitmentAgeFixed!( recruitment, 18 * 12 )
addSimulationRecruitment!( mpSim, recruitment )

# Transitions
transition = Transition( "B+", "3D-D", "3D-B" )
setTransitionSchedule!( transition, 12 )
addTransitionCondition!( transition, MPcondition( "tenure", >=, 12 * 12 ) )
setTransitionProbabilities!( transition, [0.22] )
addSimulationTransition!( mpSim, transition )

transition = Transition( "B+", "2C-D", "2C-B" )
setTransitionSchedule!( transition, 12 )
addTransitionCondition!( transition, MPcondition( "tenure", >=, 12 * 12 ) )
setTransitionProbabilities!( transition, [0.64] )
addSimulationTransition!( mpSim, transition )

transition = Transition( "B+", "2B-D", "2B-B" )
setTransitionSchedule!( transition, 12 )
addTransitionCondition!( transition, MPcondition( "tenure", >=, 12 * 12 ) )
setTransitionProbabilities!( transition, [0.67] )
addSimulationTransition!( mpSim, transition )

transition = Transition( "B+", "1B-D", "1B-B" )
setTransitionSchedule!( transition, 12 )
addTransitionCondition!( transition, MPcondition( "tenure", >=, 12 * 12 ) )
setTransitionProbabilities!( transition, [0.90] )
addSimulationTransition!( mpSim, transition )

transition = Transition( "B+", "1A-D", "1A-B" )
setTransitionSchedule!( transition, 12 )
addTransitionCondition!( transition, MPcondition( "tenure", >=, 16 * 12 ) )
setTransitionProbabilities!( transition, [0.62] )
addSimulationTransition!( mpSim, transition )

transition = Transition( "B-", "3D-D" )
setTransitionSchedule!( transition, 12 )
addTransitionCondition!( transition, MPcondition( "tenure", >=, 12 * 12 ) )
addSimulationTransition!( mpSim, transition )

transition = Transition( "B-", "2C-D" )
setTransitionSchedule!( transition, 12 )
addTransitionCondition!( transition, MPcondition( "tenure", >=, 12 * 12 ) )
addSimulationTransition!( mpSim, transition )

transition = Transition( "B-", "2B-D" )
setTransitionSchedule!( transition, 12 )
addTransitionCondition!( transition, MPcondition( "tenure", >=, 12 * 12 ) )
addSimulationTransition!( mpSim, transition )

transition = Transition( "B-", "1B-D" )
setTransitionSchedule!( transition, 12 )
addTransitionCondition!( transition, MPcondition( "tenure", >=, 12 * 12 ) )
addSimulationTransition!( mpSim, transition )

transition = Transition( "B-", "1A-D" )
setTransitionSchedule!( transition, 12 )
addTransitionCondition!( transition, MPcondition( "tenure", >=, 16 * 12 ) )
addSimulationTransition!( mpSim, transition )

transition = Transition( "DI", "3D-D", "2C-B" )
setTransitionSchedule!( transition, 12 )
addTransitionCondition!( transition, MPcondition( "tenure", >=, 4 * 12 ) )
setTransitionFluxLimits!( transition, 0, 20 )
addSimulationTransition!( mpSim, transition )

transition = Transition( "DI", "2C-D", "2B-B" )
setTransitionSchedule!( transition, 12 )
addTransitionCondition!( transition, MPcondition( "tenure", >=, 4 * 12 ) )
setTransitionFluxLimits!( transition, 0, 10 )
addSimulationTransition!( mpSim, transition )

transition = Transition( "DI", "2C-B", "2B-B" )
setTransitionSchedule!( transition, 12 )
addTransitionCondition!( transition, MPcondition( "age", >=, 40 * 12 ) )
setTransitionFluxLimits!( transition, 0, 5 )
addSimulationTransition!( mpSim, transition )

transition = Transition( "OV", "1B-B", "1A-B" )
setTransitionSchedule!( transition, 12 )
addTransitionCondition!( transition, MPcondition( "age", >=, 40 * 12 ) )
setTransitionFluxLimits!( transition, 0, 3 )
addSimulationTransition!( mpSim, transition )

transition = Transition( "SP", "3D-B", "2C-B" )
setTransitionSchedule!( transition, 12 )
addTransitionCondition!( transition, MPcondition( "age", >=, 40 * 12 ) )
setTransitionFluxLimits!( transition, 0, 10 )
addSimulationTransition!( mpSim, transition )

transition = Transition( "SP", "2C-B", "1B-B" )
setTransitionSchedule!( transition, 12 )
addTransitionCondition!( transition, MPcondition( "age", >=, 42 * 12 ) )
setTransitionFluxLimits!( transition, 0, 3 )
addSimulationTransition!( mpSim, transition )

transition = Transition( "SP", "2C-B", "1A-B" )
setTransitionSchedule!( transition, 12 )
addTransitionCondition!( transition, MPcondition( "age", >=, 42 * 12 ) )
setTransitionFluxLimits!( transition, 0, 1 )
addSimulationTransition!( mpSim, transition )

transition = Transition( "PE", "3D-B" )
setTransitionSchedule!( transition, 1 )
addTransitionCondition!( transition, MPcondition( "age", >=, 58 * 12 ) )
addSimulationTransition!( mpSim, transition )

transition = Transition( "PE", "2C-B" )
setTransitionSchedule!( transition, 1 )
addTransitionCondition!( transition, MPcondition( "age", >=, 60 * 12 ) )
addSimulationTransition!( mpSim, transition )

transition = Transition( "PE", "2B-B" )
setTransitionSchedule!( transition, 1 )
addTransitionCondition!( transition, MPcondition( "age", >=, 60 * 12 ) )
addSimulationTransition!( mpSim, transition )

transition = Transition( "PE", "1B-B" )
setTransitionSchedule!( transition, 1 )
addTransitionCondition!( transition, MPcondition( "age", >=, 63 * 12 ) )
addSimulationTransition!( mpSim, transition )

transition = Transition( "PE", "1A-B" )
setTransitionSchedule!( transition, 1 )
addTransitionCondition!( transition, MPcondition( "age", >=, 63 * 12 ) )
addSimulationTransition!( mpSim, transition )

# Misc
setSimulationLength!( mpSim, 120.0 )

@testset "function addSimulationTransitionTypeOrder!" begin
    addSimulationTransitionTypeOrder!( mpSim, Dict( "DI" => 3, "B+" => 1 ) )
    @test ( length( mpSim.transitionTypeOrder ) == 2 ) &&
        all( haskey.( Ref( mpSim.transitionTypeOrder ), ["DI", "B+"] ) ) &&
        ( mpSim.transitionTypeOrder["DI"] == 3 ) &&
        ( mpSim.transitionTypeOrder["B+"] == 1 )
    addSimulationTransitionTypeOrder!( mpSim, ( "DI", 4 ), ( "B-", 5 ) )
    @test ( length( mpSim.transitionTypeOrder ) == 3 ) &&
        all( haskey.( Ref( mpSim.transitionTypeOrder ),
        ["DI", "B+", "B-"] ) ) &&
        ( mpSim.transitionTypeOrder["DI"] == 4 ) &&
        ( mpSim.transitionTypeOrder["B+"] == 1 ) &&
        ( mpSim.transitionTypeOrder["B-"] == 5 )
        addSimulationTransitionTypeOrder!( mpSim, "OV", 3 )
    @test ( length( mpSim.transitionTypeOrder ) == 4 ) &&
        all( haskey.( Ref( mpSim.transitionTypeOrder ),
        ["DI", "B+", "B-", "OV"] ) ) &&
        ( mpSim.transitionTypeOrder["OV"] == 3 )
    @test !addSimulationTransitionTypeOrder!( mpSim, Dict{String, Int}() )
    @test !addSimulationTransitionTypeOrder!( mpSim, ( "EW", 3 ), ( "EW", 2 ) )
end  # @testset "function addSimulationTransitionTypeOrder!"

@testset "function removeSimulationTransitionTypeOrder!" begin
    removeSimulationTransitionTypeOrder!( mpSim, "B+", "B-" )
    @test ( length( mpSim.transitionTypeOrder ) == 2 ) &&
        !any( haskey.( Ref( mpSim.transitionTypeOrder ), ["B+", "B-"] ) )
    @test !removeSimulationTransitionTypeOrder!( mpSim, "EW" )
end  # @testset "function removeSimulationTransitionTypeOrder!"

@testset "function clearSimulationTransitionTypeOrder!" begin
    @test clearSimulationTransitionTypeOrder!( mpSim )
    @test isempty( mpSim.transitionTypeOrder )
end  # @testset "function clearSimulationTransitionTypeOrder!"

@testset "function setSimulationTransitionTypeOrder!" begin
    setSimulationTransitionTypeOrder!( mpSim, Dict( "B+" => 4, "B-" => 8 ) )
    @test ( length( mpSim.transitionTypeOrder ) == 2 ) &&
        all( haskey.( Ref( mpSim.transitionTypeOrder ), ["B+", "B-"] ) ) &&
        ( mpSim.transitionTypeOrder["B-"] == 8 ) &&
        ( mpSim.transitionTypeOrder["B+"] == 4 )
    setSimulationTransitionTypeOrder!( mpSim, ( "OV", 3 ), ( "DI", 4 ) )
    @test ( length( mpSim.transitionTypeOrder ) == 2 ) &&
        all( haskey.( Ref( mpSim.transitionTypeOrder ), ["OV", "DI"] ) ) &&
        ( mpSim.transitionTypeOrder["OV"] == 3 ) &&
        ( mpSim.transitionTypeOrder["DI"] == 4 )
    setSimulationTransitionTypeOrder!( mpSim, ["PE", "EW"], [3, 2] )
    @test ( length( mpSim.transitionTypeOrder ) == 2 ) &&
        all( haskey.( Ref( mpSim.transitionTypeOrder ), ["PE", "EW"] ) ) &&
        ( mpSim.transitionTypeOrder["PE"] == 3 ) &&
        ( mpSim.transitionTypeOrder["EW"] == 2 )
    
    @test !setSimulationTransitionTypeOrder!( mpSim, ( "B+", 5 ), ( "B+", 2 ) )
    @test !setSimulationTransitionTypeOrder!( mpSim, ["B-"], [5, 2] )
    @test !setSimulationTransitionTypeOrder!( mpSim, ["B-", "B-"], [5, 2] )
end  # @testset "function setSimulationTransitionTypeOrder!"

setSimulationTransitionTypeOrder!( mpSim, Dict( "B+" => 1, "B-" => 4, "PE" => 4,
    "DI" => 3, "SP" => 3, "OV" => 3, "EW" => 2 ) )

@testset "function addSimulationBaseNodeOrder!" begin
    addSimulationBaseNodeOrder!( mpSim, Dict( "3D-D" => 3, "2C-D" => 1 ) )
    @test ( length( mpSim.baseNodeOrder ) == 2 ) &&
        all( haskey.( Ref( mpSim.baseNodeOrder ), ["3D-D", "2C-D"] ) ) &&
        ( mpSim.baseNodeOrder["3D-D"] == 3 ) &&
        ( mpSim.baseNodeOrder["2C-D"] == 1 )
        addSimulationBaseNodeOrder!( mpSim, ( "2B-B", 4 ), ( "2C-D", 5 ) )
    @test ( length( mpSim.baseNodeOrder ) == 3 ) &&
        all( haskey.( Ref( mpSim.baseNodeOrder ),
        ["3D-D", "2C-D", "2B-B"] ) ) &&
        ( mpSim.baseNodeOrder["3D-D"] == 3 ) &&
        ( mpSim.baseNodeOrder["2C-D"] == 5 ) &&
        ( mpSim.baseNodeOrder["2B-B"] == 4 )
        addSimulationBaseNodeOrder!( mpSim, "1A-B", 1 )
    @test ( length( mpSim.baseNodeOrder ) == 4 ) &&
        all( haskey.( Ref( mpSim.baseNodeOrder ),
        ["3D-D", "2C-D", "2B-B", "1A-B"] ) ) &&
        ( mpSim.baseNodeOrder["1A-B"] == 1 )
    @test !addSimulationBaseNodeOrder!( mpSim, Dict{String, Int}() )
    @test !addSimulationBaseNodeOrder!( mpSim, ( "1B-B", 3 ), ( "1B-B", 2 ) )
end  # @testset "function addSimulationBaseNodeOrder!"

@testset "function removeSimulationBaseNodeOrder!" begin
    removeSimulationBaseNodeOrder!( mpSim, "1A-B", "2C-D" )
    @test ( length( mpSim.baseNodeOrder ) == 2 ) &&
        !any( haskey.( Ref( mpSim.baseNodeOrder ), ["1A-B", "2C-D"] ) )
    @test !removeSimulationBaseNodeOrder!( mpSim, "2B-D" )
end  # @testset "function removeSimulationBaseNodeOrder!"

@testset "function clearSimulationBaseNodeOrder!" begin
    @test clearSimulationBaseNodeOrder!( mpSim )
    @test isempty( mpSim.baseNodeOrder )
end  # @testset "function clearSimulationBaseNodeOrder!"

@testset "function setSimulationBaseNodeOrder!" begin
    setSimulationBaseNodeOrder!( mpSim, Dict( "3D-B" => 4, "2B-D" => 8 ) )
    @test ( length( mpSim.baseNodeOrder ) == 2 ) &&
        all( haskey.( Ref( mpSim.baseNodeOrder ), ["3D-B", "2B-D"] ) ) &&
        ( mpSim.baseNodeOrder["2B-D"] == 8 ) &&
        ( mpSim.baseNodeOrder["3D-B"] == 4 )
    setSimulationBaseNodeOrder!( mpSim, ( "1A-D", 3 ), ( "2B-B", 4 ) )
    @test ( length( mpSim.baseNodeOrder ) == 2 ) &&
        all( haskey.( Ref( mpSim.baseNodeOrder ), ["1A-D", "2B-B"] ) ) &&
        ( mpSim.baseNodeOrder["1A-D"] == 3 ) &&
        ( mpSim.baseNodeOrder["2B-B"] == 4 )
    setSimulationBaseNodeOrder!( mpSim, ["2C-D", "2B-D"], [3, 2] )
    @test ( length( mpSim.baseNodeOrder ) == 2 ) &&
        all( haskey.( Ref( mpSim.baseNodeOrder ), ["2C-D", "2B-D"] ) ) &&
        ( mpSim.baseNodeOrder["2C-D"] == 3 ) &&
        ( mpSim.baseNodeOrder["2B-D"] == 2 )
    
    @test !setSimulationBaseNodeOrder!( mpSim, ( "3D-B", 5 ), ( "3D-B", 2 ) )
    @test !setSimulationBaseNodeOrder!( mpSim, ["3D-B"], [5, 2] )
    @test !setSimulationBaseNodeOrder!( mpSim, ["3D-B", "3D-B"], [5, 2] )
end  # @testset "function setSimulationBaseNodeOrder!"

@test verifySimulation!( mpSim )

end  # @testset "Transition order tests"