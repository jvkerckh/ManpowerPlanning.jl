# This file holds the definition of the functions pertaining to the Personnel
#   type.

# The functions of the Personnel type require the HistoryEvent and HistoryEntry
#   types.
requiredTypes = [ "personnel" ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( dirname( Base.source_path() ), "..", "Types",
            reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end  # for reqType in requiredTypes


# Load in the type aliases.
include( joinpath( dirname( Base.source_path() ), "..", "Types",
    "typeAliases.jl" ) )


# This function tests if a personnel member has the requested attribute.
export hasAttribute
function hasAttribute( person::Personnel, attr::AttributeType )
    return haskey( person.persData, Symbol( attr ) )
end # hasAttribute( person, attr )


# This funciton tests if a personnel member has a history of the requested
#   attribute.
# This test consists of test to see if the personnel member has a history
#   attribute at all, if it's the correct type (Dict{Symbol, History}), and the
#   history has an entry for the requested attribute.
export hasHistory
function hasHistory( person::Personnel, attr::AttributeType )
    return hasAttribute( person, :history ) &&
        isa( person[ :history ], Dict{Symbol, History} ) &&
        haskey( person[ :history ], Symbol( attr ) )
end  # hasHistory( person, attr )


# This function removes the respested attribute from the personnel member.
export removeAttribute!
function removeAttribute!( person::Personnel, attr::AttributeType )
    tmpAttr = Symbol( attr )

    if hasAttribute( person, tmpAttr )
        delete!( person.persData, tmpAttr )
    end  # if hasAttribute( person, tmpAttr )
end  # removeAttribute!( person, attr )


# This function adds a value to a vector attribute. If the attribute's value is
#   nothing, a vector will be created. If the attribute's value is not a vector,
#   nothing will happen.
export addValue
function addValue( person::Personnel, attr::AttributeType, value::String )
    tmpAttr = Symbol( attr )
    # If the attribute doesn't exist, if the attribute's value is nothing, or if
    #   the attribute is an empty Vector, turn it into an empty Vector{String}.
    if !hasAttribute( person, tmpAttr ) || ( person[ tmpAttr ] === nothing ) ||
        isempty( person[ tmpAttr ] )
        person[ tmpAttr ] = Vector{String}()
    end  # if !hasAttribute( person, tmpAttr ) ...

    # If the attribute isn't of Vector{String} type, do nothing.
    if !isa( person[ tmpAttr ], Vector{String} )
        return
    end  # if !isa( person[ tmpAttr ], ...

    if !in( value, person[ tmpAttr ] )
        push!( person[ tmpAttr ], value )
    end
end  # addValue( person, attr, value )


# This function displays a personnel record onto the entered IO stream.
export displayPersonnel
function displayPersonnel( io::IO, person::Personnel )
    linePrinted = false

    for attr in keys( person.persData )
        val = person[ attr ]

        if nothing !== val
            if linePrinted
                print( io, "\n" )
            else
                linePrinted = true
            end  # if linePrinted

            print( io, string( attr ), ": $(val)" )
        end  # if nothing !== val
    end  # for attr ...
end  # displayPersonnel( io, person )

# This function displays a personnel record onto the entered IO stream, with the
#   index key displayed first.
function displayPersonnel( io::IO, person::Personnel, idKey::AttributeType )
    tmpKey = Symbol( idKey )

    if hasAttribute( person, tmpKey )
        keyVal = person[ tmpKey ]
        println( io, string( tmpKey ), " (key): ",
            nothing === keyVal ? "Undefined" : keyVal )
    end  # if hasAttribute( person, tmpKey )

    for attr in keys( person.persData )
        val = person[ attr ]

        if ( tmpKey !== attr ) && ( nothing !== val )
            println( io, string( attr ), ": $val" )
        end  # if ( tmpKey !== attr ) ...
    end  # for attr ...
end  # displayPersonnel( io, person, idKey )


# This function displays a personnel record onto the entered IO stream, showing
#   the requested attributes.
function displayPersonnel( io::IO, person::Personnel, attrs::Array{Symbol} )
    for attr in attrs
        if hasAttribute( person, attr ) && ( nothing !== person[ attr ] )
            println( io, string( attr ), ": $(person[ attr ])" )
        end  # if hasField( person, attr )
    end  # for attr in attrs
end  # displayPersnnel( io, person, attrs )

# This function retrieves the requested attributes for a personnel record,
#   without needing to access the dictionary directly (syntactic sugar).
# If the personnel record does not contain the attributes, this function returns
#   nothing.
function Base.getindex( person::Personnel, attr::AttributeType )
    tmpAttr = Symbol( attr )

    if !hasAttribute( person, tmpAttr )
        return nothing
    end  # if !hasField( person, tmpAttr )

    return person.persData[ Symbol( tmpAttr ) ]
end  # Base.getindex( person, attr )

function Base.getindex( person::Personnel, attrs::Array{Symbol} )
    out = similar( attrs, Any )

    for ii in eachindex( attrs )
        out[ ii ] = person[ attrs[ ii ] ]
    end  # for ii in eachindex( attrs )

    return out
end  # Base.getindex( person, attrs )


# This function returns the value of the specified attribute at the given time.
# If the personnel record does not have a history for this attribute, the
#   attribute itself is returned if possible.
function Base.getindex( person::Personnel, attr::AttributeType,
    timestamp::T ) where T <: Real
    tmpAttr = Symbol( attr )
    # If the personnel record has no history for the attribute, return the
    #   regular person[ attribute ].
    if !hasHistory( person, tmpAttr )
        return person[ tmpAttr ]
    end  # if !hasHistory( person, tmpAttr )

    return person[ :history ][ tmpAttr ][ timestamp ]
end  # Base.getindex( person, attr, timestamp )


# This function sets the attribute for a personnel record, without needing to
#   access the dictionary directly (syntactic sugar). If the attribute does not
#   exist yet, it will be created.
function Base.setindex!( person::Personnel, data, attr::AttributeType )
    person.persData[ Symbol( attr ) ] = data
end  # Base.setindex!( person, data, attr )


# This function sets a historical value for the attribute for a personnel
#   record.
# If no history exists for this attribute, it will be created.
# If the history attribute already exists, but it is not of the correct type
#   (Dict{Symbol, History}), it will be overwritten.
function Base.setindex!( person::Personnel, data, attr::AttributeType,
    timestamp::T ) where T <: Real
    tmpAttr = Symbol( attr )

    # If the history attribute doesn't exist, or if it's the wrong type, create
    #   and (re)initialize it.
    if !hasAttribute( person, :history ) ||
        !isa( person[ :history ], Dict{Symbol, History} )
        person[ :history ] = Dict{Symbol, History}()
    end  # if !hasAttribute( person, :history ) || ...

    # If the history doesn't have an entry for the atrtibute, create it.
    if !haskey( person[ :history ], tmpAttr )
        person[ :history ][ tmpAttr ] = History( tmpAttr )
    end  # if !haskey( person[ :history ], tmpAttr )

    person[ :history ][ Symbol( attr ) ][ timestamp ] = data
end  # Base.setindex!( person, data, attr, timestamp )


function Base.show( io::IO, person::Personnel )
    displayPersonnel( io, person )
end  # Base.show( io, person )
