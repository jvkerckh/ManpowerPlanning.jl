@testset "Attribute" begin

@testset "Constructor" begin
    attribute = Attribute( "Attribute" )
    @test all( [ attribute.name == "Attribute",
        isempty( attribute.possibleValues ), isempty( attribute.initValues ) ] )
end  # @testset "Constructor"

attribute = Attribute( "Attribute" )

@testset "function addPossibleAttributeValue!" begin
    addPossibleAttributeValue!( attribute, "bim" )
    @test attribute.possibleValues == [ "bim" ]
    addPossibleAttributeValue!( attribute, "bam", "boom", "bim" )
    @test all( [ "bim" ∈ attribute.possibleValues,
        "boom" ∈ attribute.possibleValues,
        length( attribute.possibleValues ) == 3 ] )
    @test !addPossibleAttributeValue!( attribute, "bim", "boom" )
end  # @testset "function addPossibleAttributeValue!"

@testset "function removePossibleAttributeValue!" begin
    removePossibleAttributeValue!( attribute, "bing", "bim", "bang" )
    @test ( length( attribute.possibleValues ) == 2 ) &&
        ( "bim" ∉ attribute.possibleValues )
    @test !removePossibleAttributeValue!( attribute, "boop", "beep" )
end  # @testset "function removePossibleAttributeValue!"

@testset "function clearPossibleAttributeValues!" begin
    @test clearPossibleAttributeValues!( attribute )
    @test isempty( attribute.possibleValues )
end  # @testset "function clearPossibleAttributeValues!"

@testset "function setPossibleAttributeValues!" begin
    @test_deprecated setPossibleValues!( attribute, [ "beep", "boop" ] )
    @test attribute.possibleValues == [ "beep", "boop" ]
    setPossibleAttributeValues!( attribute, [ "foo", "bar" ] )
    @test attribute.possibleValues == [ "foo", "bar" ]
end  # @testset "function setPossibleAttributeValues!"

@testset "function addInitialAttributeValue!" begin
    addInitialAttributeValue!( attribute, ("foo", 2.0) )
    @test ( attribute.initValues == [ "foo" ] ) &&
        ( attribute.initValueWeights == [ 2.0 ] )
    addInitialAttributeValue!( attribute, ("beep", 5.0), ("bar", -3.0),
        ("foo", 4.0) )
    @test all( [ attribute.initValues == [ "foo", "beep" ],
        attribute.initValueWeights == [ 4.0, 5.0 ],
        "beep" ∈ attribute.possibleValues ] )
    addInitialAttributeValue!( attribute, "boop", 1 )
    @test ( "boop" ∈ attribute.initValues ) &&
        ( "boop" ∈ attribute.possibleValues )
    @test !addInitialAttributeValue!( attribute, ("foo", -2.0), ("foo", 1.5) )
end  # @testset "function addInitialAttributeValue!"

@testset "function removeInitialAttributeValue!" begin
    removeInitialAttributeValue!( attribute, "beep" )
    @test ( "beep" ∉ attribute.initValues ) &&
        ( "beep" ∈ attribute.possibleValues )
    removeInitialAttributeValue!( attribute, "beep", "boop", "flub" )
    @test attribute.initValues == [ "foo" ]
    @test !removeInitialAttributeValue!( attribute, "beep" )
end  # @testset "function removeInitialAttributeValue!"

@testset "function clearInitialAttributeValues!" begin
    @test clearInitialAttributeValues!( attribute )
    @test isempty( attribute.initValues ) &&
        isempty( attribute.initValueWeights )
end  # @testset "function clearInitialAttributeValues!"

@testset "function setInitialAttributeValues!" begin
    setInitialAttributeValues!( attribute, Dict( "foo" => 3.0, "boop" => 2.0 ) )
    @test all( [ length( attribute.initValues ) == 2,
        length( attribute.initValueWeights ) == 2, "foo" ∈ attribute.initValues,
        "boop" ∈ attribute.initValues ] )
    setInitialAttributeValues!( attribute,
        Dict( "boop" => 2.0, "boom" => 3.0 ) )
    @test "boom" ∈ attribute.possibleValues
    @test !setInitialAttributeValues!( attribute,
        Dict( "foo" => -3.0, "bar" => -4.0 ) )
    @test length( attribute.initValues ) == 2
    setInitialAttributeValues!( attribute, ("foo", 4.0), ("beep", -3.0),
        ("boop", 1.0) )
    @test ( length( attribute.initValues ) == 2 ) &&
        ( [ "foo", "boop" ] ⊆ attribute.initValues )
    @test !setInitialAttributeValues!( attribute, ("foo", 2.0), ("boop", 6.0),
        ("foo", 1.0) )
    setInitialAttributeValues!( attribute, [ "foo", "beep", "boop" ],
        [ 2.0, 3.0, 1.0 ] )
    @test ( length( attribute.initValues ) == 3 ) &&
        ( [ "foo", "beep", "boop" ] ⊆ attribute.initValues )
    @test !setInitialAttributeValues!( attribute, [ "foo" ], [ 2.0, 5.0 ] )
    @test !setInitialAttributeValues!( attribute, [ "foo", "boop", "foo" ],
        [ 3.0, 4.0, 2.0 ] )
end  # @testset "function setInitialAttributeValues!"

@testset "Constructor part II" begin
    attribute = Attribute( "Attribute", [ "foo", "bar" ] )
    @test attribute.possibleValues == [ "foo", "bar" ]
    attribute = Attribute( "Attribute", Dict( "boop" => 1.5, "beep" => 2.5 ) )
    @test all( [ [ "boop", "beep" ] ⊆ attribute.possibleValues,
        [ "boop", "beep" ] ⊆ attribute.initValues,
        length( attribute.possibleValues ) == 2,
        length( attribute.initValues ) == 2 ] )
    attribute = Attribute( "Attribute", [ "bar", "foo" ],
        Dict( "boop" => 1.5, "beep" => 2.5 ) )
    @test all( [ [ "bar", "foo", "boop", "beep" ] ⊆ attribute.possibleValues,
        [ "boop", "beep" ] ⊆ attribute.initValues,
        length( attribute.possibleValues ) == 4,
        length( attribute.initValues ) == 2 ] )
    end  # @testset "Constructor part II"

end  # @testset "Attribute"

println()