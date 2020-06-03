@testset "Attrition" begin

@testset "Constructor" begin
    attrition = Attrition()
    @test all( [attrition.name == "default", attrition.rates == [0.0],
        attrition.curvePoints == [0.0], attrition.period == 1.0] )
    attrition = Attrition( "Attr1" )
    @test attrition.name == "Attr1"
end  # @testset "Constructor"

attrition = Attrition( "Attrition" )

@testset "function setAttritionRate!" begin
    setAttritionRate!( attrition, 0.04 )
    @test attrition.rates == [0.04]
    setAttritionRate!( attrition, 0.025 )
    @test all( [attrition.rates == [0.025],
        attrition.lambdas == [- log( 0.975 )],
        attrition.gammas == [1.0]] )
    @test !setAttritionRate!( attrition, -0.5 )
    @test !setAttritionRate!( attrition, 2.5 )
end  # @testset "function setAttritionRate!"

@testset "function setAttritionPeriod!" begin
    setAttritionPeriod!( attrition, 12 )
    @test ( attrition.period == 12 ) &&
        ( attrition.lambdas == [- log( 0.975 ) / 12] )
    setAttritionPeriod!( attrition, 6 )
    @test attrition.period == 6 &&
        ( attrition.lambdas == [- log( 0.975 ) / 6] )
    @test !setAttritionPeriod!( attrition, -6 )
end  # @testset "function setAttritionRate!"

@testset "function setAttritionCurve!" begin
    setAttritionCurve!( attrition, Dict( 0.0 => 0.05, 24.0 => 0.03 ) )
    @test ( attrition.curvePoints == [0.0, 24.0] ) &&
        ( attrition.rates == [0.05, 0.03] )
    setAttritionCurve!( attrition, [0.0 0.04; 30.0 0.025] )
    @test ( attrition.curvePoints == [0.0, 30.0] ) &&
        ( attrition.rates == [0.04, 0.025] )
    @test setAttritionCurve!( attrition, [6.0 0.01; 30.0 0.02] )
    @test ( attrition.curvePoints == [0.0, 6.0, 30.0] ) &&
        ( attrition.rates == [0.0, 0.01, 0.02] )
    @test setAttritionCurve!( attrition,
        Dict( -6.0 => 0.02, 12.0 => 0.03, 30.0 => 0.01 ) )
    @test all( [attrition.curvePoints == [0.0, 12.0, 30.0],
        attrition.rates == [0.02, 0.03, 0.01],
        attrition.lambdas == - log.( 1 .- [0.02, 0.03, 0.01] ) / 6,
        attrition.gammas == [1.0, 0.98^2, 0.98^2 * 0.97^3]] )
    @test setAttritionCurve!( attrition,
        Dict( -12.0 => 0.02, -6.0 => 0.03, 24.0 => 0.01 ) )
    @test ( attrition.curvePoints == [0.0, 24.0] ) &&
        ( attrition.rates == [0.03, 0.01] )
    @test !setAttritionCurve!( attrition, Dict( 0.0 => -0.02, 30.0 => 1.5 ) )
    @test !setAttritionCurve!( attrition, [0.0 0.05 0.03; 30.0 0.02 0.05] )
    @test !setAttritionCurve!( attrition, [0.0 0.05; 18.0 0.03; 18.0 0.02] )
end  # @testset "function setAttritionCurve!"

end  # @testset "Attrition"

println()