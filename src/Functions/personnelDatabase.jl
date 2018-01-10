# This file holds the definition of the functions pertaining to the
#   PersonnelDatabase type.

# The functions of the PersonnelDatabase require the HistoryEntry, History, and
#   Personnel types.
requiredTypes = [ "historyEntry", "history", "personnel", "personnelDatabase" ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( dirname( Base.source_path() ), "..", "Types",
            reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end  # for reqType in requiredTypes


# Load in the type aliases.
include( joinpath( dirname( Base.source_path() ), "..", "Types",
    "typeAliases.jl" ) )


# This function tests if the database has the requested attribute.
export hasAttribute
function hasAttribute( dbase::PersonnelDatabase, attr::AttributeType )
    return Symbol( attr ) ∈ dbase.attrs
end  # hasAttribute( dbase, attr )


# This function adds the given attribute to the database, initializing the
#   attribute. If some personnel records have this attribute already, it will be
#   overwritten!
export addAttribute!
function addAttribute!( dbase::PersonnelDatabase, attr::AttributeType,
    initContent = nothing )
    tmpAttr = Symbol( attr )

    # Do nothing if the attribute exists in the database.
    if hasAttribute( dbase, tmpAttr )
        return
    end  # if hasAttribute( dbase, tmpAttr )

    push!( dbase.attrs, tmpAttr )

    # Update all personnel records to have this attribute.
    map( person -> person[ tmpAttr ] = initContent, dbase.dbase )
end  # addAttribute!( dbase, attr, initContent )


# This function adds the given attributes to the database.
export addAttributes!
function addAttributes!( dbase::PersonnelDatabase, attrs::Vector{Symbol} )
    map( attr -> addAttribute!( dbase, attr ), attrs )
end  # addAttributes!( dbase, attrs )

function addAttributes!( dbase::PersonnelDatabase, attrs::Vector{String} )
    map( attr -> addAttribute!( dbase, Symbol( attr ) ), attrs )
end  # addAttributes!( dbase, attrs )


# This function removes the given attribute from the database.
export removeAttribute!
function removeAttribute!( dbase::PersonnelDatabase, attr::AttributeType )
    tmpAttr = Symbol( attr )

    # If the attribute doesn't exist, or it is the ID key, do nothing.
    if !hasAttribute( dbase, tmpAttr ) || ( tmpAttr === dbase.idKey )
        return
    end  # if ( attr ∉ dbase.attrs ) || ...

    # Otherwise, remove attribute from list.
    index = find( x -> x == tmpAttr, dbase.attrs )
    deleteat!( dbase.attrs, index[ 1 ] )

    # Delete field from personnel records.
    map( person -> removeAttribute!( person, tmpAttr ), dbase.dbase )
end  # removeAttribute!( dbase, fiattreld )


# This function removes the given attributes from the database.
export removeAttributes!
function removeAttributes!( dbase::PersonnelDatabase, attrs::Vector{Symbol} )
    # Find all of the requested attributes that are present in the database, and
    #   which aren't the ID field.
    tmpAttrs = attrs[ unique( find( attr -> ( attr ∈ dbase.attrs ) &&
        ( attr !== dbase.idKey ), attrs ) ) ]

    if isempty( tmpAttrs )
        return
    end  # if isempty( tmpAttrs )

    # Find the indices of all the database attributes slated for removal and
    #   remove them.
    attrsIndex = find( attr -> attr ∈ tmpAttrs, dbase.attrs )
    deleteat!( dbase.attrs, sort( attrsIndex ) )

    # Remove the appropriate attributes from the personnel records.
    map( attr -> map( person -> removeAttribute!( person, attr ), dbase.dbase ),
        tmpAttrs )
end  # removeAttributes!( dbase, attrs )


# This function changes the key field of the database. The old key is kept to
#   make sure nothing gets broken.
export changeKey!
function changeKey!( dbase::PersonnelDatabase, key::AttributeType )
    tmpKey = Symbol( key )

    if !hasAttribute( dbase, tmpKey )
        warn( "Proposed ID \"$tmpKey\" is not a database attribute. ",
            "Ignoring request." )
        return
    end  # if tmpKey ∉ dbase.attrs

    # Stringify the contents of the propsed new ID key.
    map( person -> person[ tmpKey ] = string( person[ tmpKey ] ), dbase.dbase )

    # Check if the new key is unique.
    ids = dbase[ tmpKey ]

    if length( ids ) > length( unique( ids ) )
        warn( "Proposed ID \"$tmpKey\" does not have unique values." )
        return
    end  # if length( ids ) ...

    dbase.idKey = tmpKey
end  # changeKey!( dbase, key )


# This function adds an entry to the database.
export addPersonnel!
function addPersonnel!( dbase::PersonnelDatabase, person::Personnel )
    # Check if the person has the ID key of the database.
    if !hasAttribute( person, dbase.idKey )
        warn( "Person does not have the \"$(dbase.idKey)\" attribute. ",
            "Ignoring request." )
        return
    end  # if !hasAttribute( person, dbase.idKey )

    id = string( person[ dbase.idKey ] )

    # Check if the person's ID is not yet in the database.
    if exists( dbase, id )
        warn( "The database already contains an entry with ID \"$id\". ",
            "Ignoring request." )
        return
    end  # if exists( dbase, id )

    # Udate the database attribute list.
    addAttributes!( dbase, collect( keys( person.persData ) ) )

    # We create a new record here to make sure that we don't change the original
    #   personnel record.
    newPerson = person
    newPerson[ dbase.idKey ] = id

    # Add attributes that are in the database, but which aren't in the perosnnel
    #   record.
    newAttrs = dbase.attrs[ find( attr -> !hasAttribute( person, attr ),
        dbase.attrs ) ]
    map( attr -> newPerson[ attr ] = nothing, newAttrs )

    # Add the enriched copy of the personnel record to the database.
    push!( dbase.dbase, newPerson )
    dbase.persSize += 1
end  # addPersonnel!( dbase, person )


# This function adds a number of personnel records to the database.
function addPersonnel!( dbase::PersonnelDatabase, persons::Vector{Personnel} )
    map( person -> addPersonnel!( dbase, person ), persons )
end  # addPersonnel!( dbase, persons )


# This function adds a new personnel record with the given ID to the database.
function addPersonnel!( dbase::PersonnelDatabase, personID::String )
    # Check if the person's ID is not yet in the database.
    if exists( dbase, personID )
        warn( "The database already contains an entry with ID \"$personID\". ",
            "Ignoring request." )
        return
    end  # if exists( dbase, personID )

    # Create a new record with the requested ID.
    newPerson = Personnel( dbase.idKey, personID )

    # Add attributes that are in the database, but which aren't in the perosnnel
    #   record.
    newAttrs = dbase.attrs[ find( attr -> !hasAttribute( newPerson, attr ),
        dbase.attrs ) ]
    map( attr -> newPerson[ attr ] = nothing, newAttrs )

    # Add the enriched copy of the personnel record to the database.
    push!( dbase.dbase, newPerson )
    dbase.persSize += 1
end  # addPersonnel!( dbase, personID )


# This function adds new personnel records with the given IDs to the database.
function addPersonnel!( dbase::PersonnelDatabase, personIDs::Vector{String} )
    map( id -> addPersonnel!( dbase, id ), personIDs )
end  # addPersonnel!( dbase, personIDs )


# This function removes the personnel member with the requiested ID from the
#   database. If there is no personnel member with this ID, nothing happens.
export removePersonnel!
function removePersonnel!( dbase::PersonnelDatabase, id::String )
    index = getPosition( dbase, id )

    if index != 0
        removePersonnel!( dbase, index, false )
    end  # if index != 0
end  # removePersonnel!( dbase, id )

function removePersonnel!( dbase::PersonnelDatabase, ind::T,
    verifyIndex::Bool = true ) where T <: Integer
    if verifyIndex && ( ( ind <= 0 ) || ( ind > dbase.persSize ) )
        return
    end  # if verifyIndex && ...

    deleteat!( dbase.dbase, ind )
    dbase.persSize -= 1
end  # removePersonnel!( dbase, ind, verifyIndex )

function removePersonnel!( dbase::PersonnelDatabase, ids::Vector{String} )
    indices = Vector{Int}()

    for id in ids
        index = getPosition( dbase, id )

        if index != 0
            push!( indices, index )
        end  # if index != 0
    end  # for id in ids

    removePersonnel!( dbase, indices, false )
end  # removePersonnel!( dbase, ids )

function removePersonnel!( dbase::PersonnelDatabase, inds::Vector{Int},
    verifyIndices::Bool= true )
    indices = Vector{Int}()

    # Check which indices are valid.
    if verifyIndices
        for index in inds
            if ( index > 0 ) && ( index <= dbase.persSize )
                push!( indices, index )
            end  # if ( index > 0 ) && ...
        end  # for index ...
    else
        indices = inds
    end  # if verifyIndices

    # Delete the records with those indices.
    indices = unique( indices )
    deleteat!( dbase.dbase, sort( indices ) )
    dbase.persSize -= length( indices )
end  # removePersonnel!( dbase, inds, verifyIndices )


# This function tests if a personnel member with the requested ID exists in the
#   personnel database.
export exists
function exists( dbase::PersonnelDatabase, id::String )
    return getPosition( dbase, id ) != 0
end  # exists( dbase, id )


# This function returns the position of the person with the given ID in the
#   personnel database. If the ID doesn't exist, 0 is returned.
function getPosition( dbase::PersonnelDatabase, id::String )
    index = find( x -> x[ dbase.idKey ] == id, dbase.dbase )
    return isempty( index ) ? 0 : index[ 1 ]
end  # getPosition( dbase, id )


# This function selects all the records in the database with a specific value
#   for the given attribute.  (necessary?)
export selectRecords
function selectRecords( dbase::PersonnelDatabase, attr::AttributeType, val )
    tmpAttr = Symbol( attr )
    output = Vector{Personnel}()

    if !hasAttribute( dbase, tmpAttr )
        return output
    end # !hasAttribute( dbase, tmpAttr )

    map( person -> if ( person[ tmpAttr ] == val ) push!( output, person ) end,
        dbase.dbase )
    return output
end  # selectRecords( dbase, attr, val )


# This function adds a value to a vector attribute. If the attribute's value is
#   nothing, a vector will be created. If the attribute's value is not a vector,
#   nothing will happen.
export addValue
# The function using id as a String has to be written like this, because
#   otherwise a KeyError is thrown!
function addValue( dbase::PersonnelDatabase, id::String, attr::AttributeType,
    value::String )
    index = getPosition( dbase, id )
    addValue( dbase, index, attr, value )
end  # addValue( dbase, id, attr, value )

function addValue( dbase::PersonnelDatabase, ind::Int, attr::AttributeType,
    value::String )
    if ( ind <= 0 ) || ( ind > dbase.persSize )
        return
    end  # if ( ind <= 0 ) || ...

    addValue( dbase[ ind ], attr, value )
end  # addValue( dbase, id, key, value )


# This function gets the number of entries in the personnel database.
function Base.length( dbase::PersonnelDatabase )
    return dbase.persSize
end  # length( dbase )


# This function clears the database, and sets the key to the provided symbol.
export clearPDB!
function clearPDB!( dbase::PersonnelDatabase, key::Symbol = :id )
    empty!( dbase.attrs )
    empty!( dbase.dbase )
    dbase.persSize = 0
    addAttribute!( dbase, key )
    changeKey!( dbase, key )
end  # clearPDB!( dbase, key )

function clearPDB!( dbase::PersonnelDatabase, key::String )
    clearPDB!( dbase, Symbol( key ) )
end  # clearPDB!( dbase, key )


# This function retrieves the personnel member with the requested ID.
function Base.getindex( dbase::PersonnelDatabase, id::String )
    index = getPosition( dbase, id )

    # Throw an error if the personnel member with the requested ID doesn't
    #   exist.
    if index == 0
        error( "No personnel member with $(string( dbase.idKey )) \"$id\" on ",
            "record." )
    end # if index == 0

    return dbase.dbase[ index ]
end  # Base.getIndex( dbase, id )


# This function retrieves the personnel member with the requested index.
function Base.getindex( dbase::PersonnelDatabase, ind::T ) where T <: Integer
    if ( ind <= 0 ) || ( ind > dbase.persSize )
        error( "Cannot request personnel with index $ind: personnel database ",
            "size is only $(dbase.persSize)." )
    end  # if ind > dbase.persSize

    return dbase.dbase[ ind ]
end  # Base.getindex( dbase, ind )


# This function retrieves the personnel with the requested IDs.
function Base.getindex( dbase::PersonnelDatabase, indices::DbIndexArrayType )
    return map( index -> dbase[ index ], indices )
end  # Base.getindex( dbase, indices )


# This function retrieves the requested field from the personnel with the
#   requested ID.
function Base.getindex( dbase::PersonnelDatabase, index::DbIndexType,
    attr::AttributeType )
    return dbase[ index ][ Symbol( attr ) ]
end  # Base.getindex( dbase, index, attr )


# This function retrieves the requested attribute from the personnel with the
#   requested IDs.
function Base.getindex( dbase::PersonnelDatabase, indices::DbIndexArrayType,
    attr::AttributeType )
    tmpAttr = Symbol( attr )
    output = similar( indices, Any )
    map( ii -> output[ ii ] = dbase[ indices[ ii ], tmpAttr ],
        eachindex( indices ) )
    return output
end  # Base.getindex( dbase, indices, attr )


# This function retrieves the requested attribute at the given time from the
#   personnel record with the requested index.
function Base.getindex( dbase::PersonnelDatabase, index::DbIndexType,
    attr::AttributeType, timestamp::T ) where T <: Real
    person = dbase[ index ]
    return person[ attr, timestamp ]
end  # Base.getindex( dbase, index, attr, timestamp )


# This function retrieves the requested attribute from the entire database.
# XXX There is no overload of this function with a String as second argument
#   because such a function has been defined prior to retrieve the personnel
#   member with that value as ID.
function Base.getindex( dbase::PersonnelDatabase, field::Symbol )
    return dbase[ collect( 1:dbase.persSize ), field ]
end  # Base.getindex( dbase, field )


# This function sets the given attribute from the personnel with the requested
#   ID to the provided value. If the attribute does not exist, it gets created
#   first. If there is no personnel in the database with the provided ID, an
#   error gets generated.
function Base.setindex!( dbase::PersonnelDatabase, data, id::String,
    attr::AttributeType )
    index = getPosition( dbase, id )

    # Throw an error if the personnel member with the requested ID doesn't
    #   exist.
    if index == 0
        error( "No personnel member with $(string( dbase.idKey )) \"$id\" on ",
            "record." )
    end  # if index == 0

    # Make sure the database has the requested field, then fill it in as needed.
    tmpAttr = Symbol( attr )
    addAttribute!( dbase, tmpAttr )
    dbase[ index ][ tmpAttr ] = tmpAttr == dbase.idKey ? String( data ) : data
end  # Base.setindex!( dbase, data, id, attr )

function Base.setindex!( dbase::PersonnelDatabase, data, ind::T,
    attr::AttributeType ) where T <: Integer
    # Check if the index is in bounds.
    if ( ind <= 0 ) || ( ind > dbase.persSize )
        error( "Cannot request personnel with index $ind: personnel database ",
            "size is only $(dbase.persSize)." )
    end  # if ( ind <= 0 ) || ...

    # Make sure the database has the requested attribute, then fill it in as
    #   needed.
    tmpAttr = Symbol( attr )
    addAttribute!( dbase, tmpAttr )
    dbase[ ind ][ tmpAttr ] = data
end  # Base.setindex!( dbase, data, ind, attr )


# This function sets the given attribute at the given time from the personnel
#   with the requested ID to the provided value. If the attribute does not
#   exist, it gets created first. If there is no personnel in the database with
#   the provided ID, an error gets generated.
function Base.setindex!( dbase::PersonnelDatabase, data, index::DbIndexType,
    attr::AttributeType, timestamp::T ) where T <: Real
    tmpAttr = Symbol( attr )

    if !hasAttribute( dbase, tmpAttr )
        addAttribute!( dbase, tmpAttr, Dict{Symbol, History}() )
    end  # if !hasAttribute( dbase, tmpAttr )

    person = dbase[ index ]
    person[ attr, timestamp ] = data
end  # setindex!( dbase, data, index, attr, timestamp )


# This function prints the database.
function Base.show( io::IO, dbase::PersonnelDatabase )
    print( io, "ID key: $(dbase.idKey)" )
    print( io, "\nAttributes: $(dbase.attrs)" )

    if dbase.persSize == 0
        print( io, "\nNo persons in database." )
        return
    end  # if dbase.persSize == 0

    print( io, "\nPersonnel members" )
    map( person -> displayPersonnel( io, person, dbase.idKey ), dbase.dbase )
end  # Base.show( io, dbase )
