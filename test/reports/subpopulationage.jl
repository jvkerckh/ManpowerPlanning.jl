@testset "Subpopulation age report" begin

@testset "function subpopulationAgeReport" begin
    subpop1 = Subpopulation( "Subpop1" )
    addSubpopulationCondition!( subpop1, MPcondition( "branch", !=, "A" ) )
    subpop2 = Subpopulation( "Subpop2" )
    addSubpopulationCondition!( subpop2, MPcondition( "time in node", >=, 84 ) )
    subpop3 = Subpopulation( "Subpop3" )
    addSubpopulationCondition!( subpop3, MPcondition( "started as", ==,
        "Reserve junior" ) )
    subpop4 = Subpopulation( "Subpop4" )
    addSubpopulationCondition!( subpop4, MPcondition( "tenure", <, 12 ) )
    subpop5 = Subpopulation( "Subpop5" )
    addSubpopulationCondition!( subpop5, MPcondition( "was", !=, "B junior" ) )
    subpop6 = Subpopulation( "Subpop6" )
    subpop7 = Subpopulation( "Subpop7" )
    addSubpopulationCondition!( subpop7, MPcondition( "age", >=, 240 ) )

    setSubpopulationSourceNode!.( [ subpop1, subpop2, subpop3, subpop4,
        subpop5, subpop6, subpop7 ], [ "", "", "", "Reserve junior", "Career",
        "Branch A", "Foo" ] )

    @test isempty( subpopulationAgeReport( mpSim, [ -12.0, -6.0 ], 12, :age,
        subpop1, subpop2, subpop3, subpop4, subpop5, subpop6, subpop7 ) )
    @test isempty( subpopulationAgeReport( mpSim, [ 12.0, 6.0 ], -12, :age,
        subpop1, subpop2, subpop3, subpop4, subpop5, subpop6, subpop7 ) )
    @test isempty( subpopulationAgeReport( mpSim, [ 12.0, 6.0 ], 12, :age,
        subpop7 ) )
    @test isempty( subpopulationAgeReport( mpSim, [ 12.0, 6.0 ], 12, :foo,
        subpop1, subpop2, subpop3, subpop4, subpop5, subpop6, subpop7 ) )
    @test isempty( subpopulationAgeReport( mpSim, -12, 12, :age, subpop1,
        subpop2, subpop3, subpop4, subpop5, subpop6, subpop7 ) )

    report = subpopulationAgeReport( mpSim, 12, 12, :age, subpop1, subpop2,
        subpop3, subpop4, subpop5, subpop6, subpop7 )
    @test all( haskey.( Ref( report ), string.( "Subpop", 1:6 ) ) ) &&
        !haskey( report, "Subpop7" )
    @test all( map( collect( keys( report ) ) ) do subpopName
        subpopReport = report[ subpopName ]
        return all( isa.( subpopReport[ :min ], Missing ) .|
            ( 240 .<= subpopReport[ :min ] .<= 360 ) )
    end )
    @test all( map( collect( keys( report ) ) ) do subpopName
        subpopReport = report[ subpopName ]
        return all( isa.( subpopReport[ :max ], Missing ) .|
            ( 240 .<= subpopReport[ :max ] .<= 360 ) )
    end )

    report = subpopulationAgeReport( mpSim, 12, 12, :tenure, subpop1, subpop2,
        subpop3, subpop4, subpop5, subpop6, subpop7 )
    @test all( map( collect( keys( report ) ) ) do subpopName
        subpopReport = report[ subpopName ]
        return all( isa.( subpopReport[ :min ], Missing ) .|
            ( 0 .<= subpopReport[ :min ] .<= 120 ) )
    end )
    @test all( map( collect( keys( report ) ) ) do subpopName
        subpopReport = report[ subpopName ]
        return all( isa.( subpopReport[ :max ], Missing ) .|
            ( 0 .<= subpopReport[ :max ] .<= 120 ) )
    end )
    
    report = subpopulationAgeReport( mpSim, 12, 12, :timeInNode, subpop1,
        subpop2, subpop3, subpop4, subpop5, subpop6, subpop7 )
    
    @test all( map( collect( keys( report ) ) ) do subpopName
        subpopReport = report[ subpopName ]
        return all( isa.( subpopReport[ :min ], Missing ) .|
            ( 0 .<= subpopReport[ :min ] .<= 120 ) )
    end )
    @test all( map( collect( keys( report ) ) ) do subpopName
        subpopReport = report[ subpopName ]
        return all( isa.( subpopReport[ :max ], Missing ) .|
            ( 0 .<= subpopReport[ :max ] .<= 120 ) )
    end )
end  # @testset "function subpopulationAgeReport"

println()

end  # @testset "Subpopulation age report"