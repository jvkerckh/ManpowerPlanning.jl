@testset "Condition" begin

@testset "Constructor" begin
    @test_throws ErrorException MP.Condition( "attribute", ∈, 5 )
    @test_throws ErrorException MP.Condition( "attribute", >, "beep" )
    @test_throws ErrorException MP.Condition( "attribute", <, [ "foo", "bar" ] )
    condition = MP.Condition( "attribute", >=, 5 )
    @test all( [ condition.attribute == "attribute", condition.operator == Base.:(>=), condition.value == 5 ] )
end  # @testset "Constructor"

end  # @testset "Condition"

println()