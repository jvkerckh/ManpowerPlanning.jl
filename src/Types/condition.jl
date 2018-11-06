# This file defines the Condition type, used to define the extra conditions on
#   transitions.

# It is important to note that conditions that define an inequality relation,
#   the relation is ALWAYS stated as
#     "attribute operator value".
# For example, if something requires a physical fitness score of 14.0, the
#   condition is written as "fitness" >= 14.0

# The Condition type requires no extra types.
requiredTypes = [ ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( typePath, reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end  # for reqType in requiredTypes


# This type is not exported.
"""
This type defines a condition on a single attribute of a personnel member, to be
used for checking if a transition will take place.

The type contains the following fields:
* `attr::String`: the attribute upon which the prerequisite is defined.
* `val::T <: Union{Real, String, Vector{String}}`: the value with which the
  attribute is compared.
* `rel::Function`: the relation between the attribute and the value. Valid
relations are `==`, `!=`, `∈`, and `∉`.

A condition is always of the form `attr rel val`.
"""
type Condition{T <: Union{Real, String, Vector{String}}}

    attr::String
    val::T
    rel::Function

    # Constructor.
    function Condition{T}( attr::String, rel::Function, val::T ) where T

        if ( T <: Real ) && ( rel ∉ [ ==, !=, <, <=, >, >= ] )
            error( "A numeric value permits only ==, !=, <, <=, >, and >= as operators." )
        elseif ( T === String ) && ( rel ∉ [ ==, != ] )
            error( "A string value permits only == and != as operators." )
        elseif ( T === Vector{String} ) && ( rel ∉ [ ∈, ∉ ] )
            error( "A vector of string values permits only ∈ and ∉ as operators." )
        end  # if ( T <: Real ) && ...

        newPrereq = new()
        newPrereq.attr = attr
        newPrereq.val = val
        newPrereq.rel = rel
        return newPrereq

    end  # Condition( attr, rel, val )

end  # type Condition
