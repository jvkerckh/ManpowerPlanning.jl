# This file defines the MPcondition type, used to define the extra conditions on
#   transitions.

export MPcondition
"""
The `MPcondition` type defines a condition on a single attribute of a personnel member, to be used for checking if a transition will take place.

The type contains the following fields:
* `attribute::String`: the attribute upon which the prerequisite is defined.
* `value::Union{Real, String, Vector{String}}`: the value with which the attribute is compared.
* `operator::Function`: the relation between the attribute and the value. Valid relations are `==`, `!=`, `<`, `>`, `<=`, `>=`, `∈`, and `∉`. Naturally, the operator must make sense for the type of the value. This means that each type has the following restrictions:
1. `Real`: the operator must be `==`, `!=`, `<`, `>`, `<=`, or `>=`
2. `String`: the operator must be `==` or `!=`
3. `Vector{String}`: the operator must be `∈` or `∉`.

A condition is always of the form `attribute operator value`. For example, if a personnel member requires a physical fitness score of 14.0, the condition is written as "fitness" >= 14.0.

Constructor:
```
MPcondition(
    attribute::String,
    operator::Function,
    value::Union{Real, String, Vector{String}} )
```
This constructor creates a `MPcondition` object of the form `attribute` `operator` `value`.
"""
struct MPcondition

    attribute::String
    value::Union{Real, String, Vector{String}}
    operator::Function

    # Constructor
    function MPcondition( attribute::String, operator::Function,
        value::Union{Real, String, Vector{String}} )::MPcondition

        if ( value isa Real ) && ( operator ∉ [ ==, !=, <, <=, >, >= ] )
            error( "A numeric value permits only ==, !=, <, <=, >, and >= as operators." )
        elseif ( value isa String ) && ( operator ∉ [ ==, != ] )
            error( "A string value permits only == and != as operators." )
        elseif ( value isa Vector{String} ) && ( operator ∉ [ ∈, ∉ ] )
            error( "A vector of string values permits only ∈ and ∉ as operators." )
        end  # if ( value isa Real ) && ...

        return new( attribute, value, operator )

    end  # MPcondition( attribute, operator, value )

end  # struct MPcondition