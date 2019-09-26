@testset "MPCondition" begin

@testset "Constructor" begin
    @test_throws ErrorException MP.MPCondition( "attribute", ∈, 5 )
    @test_throws ErrorException MP.MPCondition( "attribute", >, "beep" )
    @test_throws ErrorException MP.MPCondition( "attribute", <,
        [ "foo", "bar" ] )
    condition = MP.MPCondition( "attribute", >=, 5 )
    @test all( [ condition.attribute == "attribute",
        condition.operator == Base.:(>=), condition.value == 5 ] )
end  # @testset "Constructor"

end  # @testset "MPCondition"

println()