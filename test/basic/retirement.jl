@testset "Retirement" begin

@testset "Constructor" begin
    retirement = Retirement()
    @test all( [retirement.maxCareerLength == 0, retirement.retirementAge == 0,
        retirement.freq == 1, retirement.offset == 0, retirement.isEither] )
end  # @testset "Constructor"

retirement = Retirement()

@testset "function setRetirementCareerLength!" begin
    setRetirementCareerLength!( retirement, 120 )
    @test retirement.maxCareerLength == 120
    @test !setRetirementCareerLength!( retirement, -60 )
end  # @testset "function setRetirementCareerLength!"

@testset "function setRetirementAge!" begin
    setRetirementAge!( retirement, 600 )
    @test retirement.retirementAge == 600
    @test !setRetirementAge!( retirement, -60 )
end  # @testset "function setRetirementAge!"

@testset "function setRetirementSchedule!" begin
    setRetirementSchedule!( retirement, 12, 18 )
    @test ( retirement.freq == 12.0 ) &&
        ( retirement.offset == 6.0 )
    setRetirementSchedule!( retirement, 6, -4 )
    @test ( retirement.freq == 6.0 ) &&
        ( retirement.offset == 2.0 )
    @test !setRetirementSchedule!( retirement, -24 )
end  # @testset "function setRetirementSchedule!"

@testset "function setRetirementIsEither!" begin
    setRetirementIsEither!( retirement, false )
    @test !retirement.isEither
end  # @testset "function setRetirementIsEither!"

end  # @testset "Retirement"