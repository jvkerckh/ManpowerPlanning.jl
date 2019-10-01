@testset "MPcondition" begin

@testset "Constructor" begin
    @test_throws ErrorException MP.MPcondition( "attribute", ∈, 5 )
    @test_throws ErrorException MP.MPcondition( "attribute", >, "beep" )
    @test_throws ErrorException MP.MPcondition( "attribute", <,
        [ "foo", "bar" ] )
    condition = MP.MPcondition( "attribute", >=, 5 )
    @test all( [ condition.attribute == "attribute",
        condition.operator == Base.:(>=), condition.value == 5 ] )
end  # @testset "Constructor"

end  # @testset "MPcondition"

println()