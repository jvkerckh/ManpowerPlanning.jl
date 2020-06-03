@testset "Recruitment" begin

@testset "function Constructor" begin
    recruitment = Recruitment( "Recruitment" )
    @test all( [recruitment.name == "Recruitment", recruitment.freq == 1.0,
        recruitment.offset == 0.0, recruitment.targetNode == "dummy",
        recruitment.minRecruitment == 0, recruitment.maxRecruitment == -1,
        !recruitment.isAdaptive,
        recruitment.recruitmentDistType === :disc,
        recruitment.recruitmentDistNodes == Dict( 0 => 1.0 ),
        recruitment.ageDistType === :disc,
        recruitment.ageDistNodes == Dict( 0 => 1.0 )] )
end  # @testset "function Constructor"

recruitment = Recruitment( "Recruitment" )

@testset "function setRecruitmentSchedule!" begin
    setRecruitmentSchedule!( recruitment, 12 )
    @test ( recruitment.freq == 12.0 ) && ( recruitment.offset == 0.0 )
    setRecruitmentSchedule!( recruitment, 6, 8 )
    @test ( recruitment.freq == 6.0 ) && ( recruitment.offset == 2.0 )
    setRecruitmentSchedule!( recruitment, 12, -9 )
    @test ( recruitment.freq == 12.0 ) && ( recruitment.offset == 3.0 )
    @test !setRecruitmentSchedule!( recruitment, -12, 6 )
end  # @testset "function setRecruitmentSchedule!"

@testset "function setRecruitmentTarget!" begin
    setRecruitmentTarget!( recruitment, "Officer" )
    @test recruitment.targetNode == "Officer"
end  # @testset "function setRecruitmentTarget!"

@testset "function setRecruitmentAdaptiveRange!" begin
    setRecruitmentAdaptiveRange!( recruitment, 20 )
    @test all( [recruitment.isAdaptive, recruitment.minRecruitment == 20,
        recruitment.maxRecruitment == -1] )
    setRecruitmentAdaptiveRange!( recruitment, -20, -20 )
    @test ( recruitment.minRecruitment == 0 ) &&
        ( recruitment.maxRecruitment == -1 )
    setRecruitmentAdaptiveRange!( recruitment, 50, 100 )
    @test ( recruitment.minRecruitment == 50 ) &&
        ( recruitment.maxRecruitment == 100 )
    @test !setRecruitmentAdaptiveRange!( recruitment, 50, 30 )
    @test ( recruitment.minRecruitment == 50 ) &&
        ( recruitment.maxRecruitment == 100 )
end  # @testset "function setRecruitmentAdaptiveRange!"

@testset "function setRecruitmentFixed!" begin
    setRecruitmentFixed!( recruitment, 50 )
    @test all( [!recruitment.isAdaptive,
        recruitment.recruitmentDistType === :disc,
        recruitment.recruitmentDistNodes == Dict( 50 => 1.0 )] )
    setRecruitmentFixed!( recruitment, 200 )
    @test recruitment.recruitmentDistNodes == Dict( 200 => 1.0 )
    @test !setRecruitmentFixed!( recruitment, -500 )
    @test recruitment.recruitmentDistNodes == Dict( 200 => 1.0 )
end  # @testset "function setRecruitmentFixed!"

@testset "function setRecruitmentDist!" begin
    setRecruitmentDist!( recruitment, :disc,
        Dict( 50 => 1.0, 75 => 2.0, 100 => 1.0 ) )
    @test ( recruitment.recruitmentDistType === :disc ) &&
        ( recruitment.recruitmentDistNodes ==
            Dict( 50 => 1.0, 75 => 2.0, 100 => 1.0 ) )
    @test all( map( ii -> recruitment.recruitmentDist() ∈ [50, 75, 100],
        1:10000 ) )
    setRecruitmentDist!( recruitment, :pUnif,
        Dict( 50 => 1.0, 70 => 2.0, 90 => 1.0 ) )
    @test ( recruitment.recruitmentDistType === :pUnif ) &&
        ( recruitment.recruitmentDistNodes ==
            Dict( 50 => 1.0, 70 => 2.0, 90 => 1.0 ) )
    @test all( map( ii -> recruitment.recruitmentDist() ∈ 50:89,
        1:10000 ) )
    setRecruitmentDist!( recruitment, :pLin,
        Dict( 50 => 1.0, 75 => 2.0, 100 => 1.0 ) )
    @test ( recruitment.recruitmentDistType === :pLin ) &&
        ( recruitment.recruitmentDistNodes ==
        Dict( 50 => 1.0, 75 => 2.0, 100 => 1.0 ) )
    @test all( map( ii -> recruitment.recruitmentDist() ∈ 50:100,
        1:10000 ) )
    @test !setRecruitmentDist!( recruitment, :test,
        Dict( 50 => 1.0, 75 => 2.0, 100 => 1.0 ) )
    @test !setRecruitmentDist!( recruitment, :disc,
        Dict( 50 => -1.0, -20 => 5.0 ) )
    @test !setRecruitmentDist!( recruitment, :disc,
        Dict( 50 => 0.0, 100 => 0.0 ) )
    @test !setRecruitmentDist!( recruitment, :pUnif,
        Dict( 50 => 0.0, 100 => 5.0 ) )
end  # @testset "function setRecruitmentDist!"

@testset "function setRecruitmentAgeFixed!" begin
    setRecruitmentAgeFixed!( recruitment, 60 )
    @test ( recruitment.ageDistType === :disc ) &&
        ( recruitment.ageDistNodes == Dict( 60.0 => 1 ) )
    @test !setRecruitmentAgeFixed!( recruitment, -60 )
end  # @testset "function setRecruitmentAgeFixed!"

@testset "function setRecruitmentAgeDist!" begin
    setRecruitmentAgeDist!( recruitment, :disc,
        Dict( 20.0 => 1.0, 30.0 => 2.0, 45.0 => 1.0 ) )
    @test ( recruitment.ageDistType === :disc ) &&
        ( recruitment.ageDistNodes ==
            Dict( 20.0 => 1.0, 30.0 => 2.0, 45.0 => 1.0 ) )
    @test all( map( age -> age ∈ [20.0, 30.0, 45.0],
        recruitment.ageDist( 10000 ) ) )
    setRecruitmentAgeDist!( recruitment, :pUnif,
        Dict( 20.0 => 1.0, 25.0 => 2.0, 40.0 => 1.0 ) )
    @test ( recruitment.ageDistType === :pUnif ) &&
        ( recruitment.ageDistNodes ==
            Dict( 20.0 => 1.0, 25.0 => 2.0, 40.0 => 1.0 ) )
    @test all( 20.0 .<= recruitment.ageDist( 10000 ) .<= 40.0 )
    setRecruitmentAgeDist!( recruitment, :pLin,
        Dict( 20.0 => 1.0, 30.0 => 2.0, 45.0 => 1.0 ) )
    @test ( recruitment.ageDistType === :pLin ) &&
        ( recruitment.ageDistNodes ==
            Dict( 20.0 => 1.0, 30.0 => 2.0, 45.0 => 1.0 ) )
    @test all( 20.0 .<= recruitment.ageDist( 10000 ) .<= 45.0 )
    @test !setRecruitmentAgeDist!( recruitment, :test,
        Dict( 20.0 => 1.0, 30.0 => 2.0, 50.0 => 1.0 ) )
    @test !setRecruitmentAgeDist!( recruitment, :disc,
        Dict( 20.0 => -1.0, -20.0 => 5.0 ) )
    @test !setRecruitmentAgeDist!( recruitment, :disc,
        Dict( 20.0 => 0.0, 50.0 => 0.0 ) )
    @test !setRecruitmentAgeDist!( recruitment, :pUnif,
        Dict( 20.0 => 0.0, 50.0 => 5.0 ) )
end  # @testset "function setRecruitmentAgeDist!"

end  # @testset "Recruitment"

println()