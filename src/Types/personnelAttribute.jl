# This file defines the PersonnelAttribute type. This type defines an attribute
#   of personnel members (field in the database).

# The PersonnelAttribute type does not require any other times.
requiredTypes = []

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( dirname( Base.source_path() ), reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end  # for reqType in requiredTypes


export PersonnelAttribute
"""
This type defines an attribute of the personnel members in the simulation --
equivalent to a field in the personnel database.

The type contains the following fields:
* `name::String`: the name of the attribute.
* `values::Dict{String, Float64}`: all the values the attribute can take, along
with the probability that the values are generated upon creation of a new
personnel member in the simulation.
* `isFixed::Bool`: a flag that indicates whether the value of the attribute
remains constant throughout the lifetime of a personnel member in the
simulation.
"""
type PersonnelAttribute

    name::String
    values::Dict{String, Float64}
    isFixed::Bool


    # Basic constructor.
    function PersonnelAttribute( name::String, isFixed::Bool = true )

        newAttr = new()
        newAttr.name = replace( name, " ", "_" )
        newAttr.values = Dict{String, Float64}()
        newAttr.isFixed = isFixed
        return newAttr

    end  # PersonnelAttribute( name, isFixed )


    # Constructor with possible values.
    function PersonnelAttribute( name::String, vals::Dict{String, Float64},
        isFixed::Bool = true )

        newAttr = PersonnelAttribute( name, isFixed )
        setAttrValues!( newAttr, vals )
        return newAttr

    end  # PersonnelAttribute( name, vals, isFixed )

end  # type PersonnelAttribute
