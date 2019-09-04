@testset "Attrition" begin

@testset "Constructor" begin
    @test_throws ErrorException Attrition( "AttrError", -1, 6 )
    @test_throws ErrorException Attrition( "AttrError", 2, 6 )
    @test_throws ErrorException Attrition( "AttrError", 0.02, -5 )
    attrition = Attrition( "Attr1", 0.05, 6 )
    @test all( [ attrition.name == "Attr1", attrition.rates == [ 0.05 ],
        attrition.curvePoints == [ 0.0 ], attrition.period == 6.0 ] )
end  # @testset "Constructor"

attrition = Attrition( "Test", 0.05, 6 )

@testset "function setAttritionRate!" begin
    @test_deprecated setAttritionRate( attrition, 0.04 )
    @test attrition.rates == [ 0.04 ]
    @test setAttritionRate!( attrition, 0.025 )
    @test all( [ attrition.rates == [ 0.025 ],
        attrition.lambdas == [ - log( 0.975 ) / 6 ],
        attrition.gammas == [ 1.0 ] ] )
    @test !setAttritionRate!( attrition, -0.5 )
    @test !setAttritionRate!( attrition, 2.5 )
end  # @testset "function setAttritionRate!"

@testset "function setAttritionPeriod!" begin
    @test_deprecated setAttritionPeriod( attrition, 12 )
    @test ( attrition.period == 12 ) &&
        ( attrition.lambdas == [ - log( 0.975 ) / 12 ] )
    @test setAttritionPeriod!( attrition, 6 )
    @test attrition.period == 6 &&
        ( attrition.lambdas == [ - log( 0.975 ) / 6 ] )
    @test !setAttritionPeriod!( attrition, -6 )
end  # @testset "function setAttritionRate!"

@testset "function setAttritionCurve!" begin
    @test_deprecated setAttritionCurve( attrition,
        Dict( 0.0 => 0.05, 24.0 => 0.03 ) )
    @test ( attrition.curvePoints == [ 0.0, 24.0 ] ) &&
        ( attrition.rates == [ 0.05, 0.03 ] )
    @test_deprecated setAttritionCurve( attrition, [ 0.0 0.04; 30.0 0.025 ] )
    @test ( attrition.curvePoints == [ 0.0, 30.0 ] ) &&
        ( attrition.rates == [ 0.04, 0.025 ] )
    @test setAttritionCurve!( attrition, [ 6.0 0.01; 30.0 0.02 ] )
    @test ( attrition.curvePoints == [ 0.0, 6.0, 30.0 ] ) &&
        ( attrition.rates == [ 0.0, 0.01, 0.02 ] )
    @test setAttritionCurve!( attrition,
        Dict( -6.0 => 0.02, 12.0 => 0.03, 30.0 => 0.01 ) )
    @test all( [ attrition.curvePoints == [ 0.0, 12.0, 30.0 ],
        attrition.rates == [ 0.02, 0.03, 0.01 ],
        attrition.lambdas == - log.( 1 .- [ 0.02, 0.03, 0.01 ] ) / 6,
        attrition.gammas == [ 1.0, 0.98^2, 0.98^2 * 0.97^3 ] ] )
    @test setAttritionCurve!( attrition,
        Dict( -12.0 => 0.02, -6.0 => 0.03, 24.0 => 0.01 ) )
    @test ( attrition.curvePoints == [ 0.0, 24.0 ] ) &&
        ( attrition.rates == [ 0.03, 0.01 ] )
    @test !setAttritionCurve!( attrition, Dict( 0.0 => -0.02, 30.0 => 1.5 ) )
    @test !setAttritionCurve!( attrition, [ 0.0 0.05 0.03; 30.0 0.02 0.05 ] )
    @test !setAttritionCurve!( attrition, [ 0.0 0.05; 18.0 0.03; 18.0 0.02 ] )
end  # @testset "function setAttritionCurve!"

@testset "Constructor part II" begin
    attrition = Attrition( "Attr",
        Dict( 6.0 => 0.01, 12.0 => 0.015, 36.0 => 0.03 ), 12.0 )
    @test all( [ attrition.name == "Attr",
        attrition.rates == [ 0.0, 0.01, 0.015, 0.03 ],
        attrition.curvePoints == [ 0.0, 6.0, 12.0, 36.0 ],
        attrition.period == 12.0 ] )
end  # @testset "Constructor part II"

end  # @testset "Attrition"

println()