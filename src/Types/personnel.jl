# This file holds the definition of the Personnel type. This type is used to
#   define members of a military organisation, in this case, the Belgian Army.

# The Personnel type requires no additional types.
requiredTypes = [ ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( dirname( Base.source_path() ), reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end  # for reqType in requiredTypes


export Personnel
type Personnel
    # Information about the personnel member.
    persData::Dict{Symbol, Any}

    function Personnel( id::String = "-----" )
        newPers = new()
        newPers.persData = Dict{Symbol, Any}( :id => id )

        return newPers
    end  # Personnel( id )

    function Personnel( idKey::Symbol, id::String = "-----" )
        newPers = new()
        newPers.persData = Dict{Symbol, Any}( idKey => id )

        return newPers
    end  # Personnel( idKey, id )

    function Personnel( idKey::String, id::String )
        newPers = new()
        newPers.persData = Dict{Symbol, Any}( Symbol( idKey ) => id )

        return newPers
    end  # Personnel( idKey, id )
end  # type Personnel
