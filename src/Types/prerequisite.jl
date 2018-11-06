# This file defines the Prerequisite type, used to define all types of
#   prerequisites.

# It is important to note that prerequisites that define an inequality relation,
#   the relation is ALWAYS stated as
#     "prereqValue prereqRelation value_in_personnel_record".
# For example, if something requires a minimum age of 21.0, the prerequisite is
#   written as
#     "21.0 <= :age"

# The Prerequisite type requires no extra types.
requiredTypes = [ ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( typePath, reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end  # for reqType in requiredTypes


export Prerequisite
"""
This type defines a prerequisite on a single attribute of a personnel member.

The type contains the following fields:
* `attr::String`: the attribute upon which the prerequisite is defined.
* `val::Union{String,Vector{String}}`: the value with which the the attribute is
compared.
* `rel::Function`: the relation between the attribute and the value. Valid
relations are `==`, `!=`, `∈`, and `∉`.

The prerequisites are always of the form `attr rel val`.
"""
type Prerequisite

    attr::String
    val::Union{String, Vector{String}}
    rel::Function

    # Constructors.
    function Prerequisite( attr::String, rel::Function, val::String )

        if rel ∉ [ ==, != ]
            error( "A String value permits only == and != as operators for a Prerequisite." )
        end  # if rel ∉ [ ==, != ]

        newPrereq = new()
        newPrereq.attr = attr
        newPrereq.val = val
        newPrereq.rel = rel
        return newPrereq

    end  # Prerequisite( attr, rel, val )

    function Prerequisite( attr::String, rel::Function, valList::Vector{String} )

        if rel ∉ [ ∈, ∉ ]
            error( "A Vector{String} value permits only ∈ and ∉ as operators for a Prerequisite." )
        end  # if rel ∉ [ ==, != ]

        newPrereq = new()
        newPrereq.attr = attr
        newPrereq.val = valList
        newPrereq.rel = rel
        return newPrereq

    end  # Prerequisite( attr, rel, valList )

end  # type Prerequisite
