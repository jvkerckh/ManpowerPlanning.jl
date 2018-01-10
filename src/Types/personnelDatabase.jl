# This file holds the definition of the PersonnelDatabase type. This type holds
#   the database of all personnel members in the military organisation.

# The PersonnelDatabase type requires the Personnel type.
requiredTypes = [ "personnel" ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( dirname( Base.source_path() ), reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end  # for reqType in requiredTypes


export PersonnelDatabase
type PersonnelDatabase
    # The unique id key field.
    idKey::Symbol

    # The list of attributes.
    attrs::Vector{Symbol}

    # The database.
    dbase::Vector{Personnel}

    # The number of entries.
    persSize::Int

    # This constructor creates a new database.
    function PersonnelDatabase( id::Symbol = :id,
        attrList::Vector{Symbol} = Vector{Symbol}() )
        # Make sure the ID field is in the list of fields.
        push!( attrList, id )

        newBase = new()
        newBase.idKey = id
        newBase.attrs = unique( attrList )
        newBase.dbase = Vector{Personnel}()
        newBase.persSize = 0

        return newBase
    end  # PersonnelDatabase( id, attrdList )

    function PersonnelDatabase( id::String,
        attrList::Vector{Symbol} = Vector{Symbol}() )
        return PersonnelDatabase( Symbol( id ), attrlist )
    end  # PersonnelDatabase( id, fieldList )
end  # PersonnelDatabase
