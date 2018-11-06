# This file holds the definition of the functions pertaining to the HistoryEntry
#   type.

# The functions of the HistoryEntry type require no additional types.
requiredTypes = [ "historyEntry" ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( typePath, reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end  # for reqType in requiredTypes


function Base.:(==)( entryLeft::HistoryEntry, entryRight::HistoryEntry )
    return entryLeft.timestamp == entryRight.timestamp
end  # ==( entryLeft, entryRight )

function Base.:(==)( entry::HistoryEntry, num::T ) where T <: Real
    return entry.timestamp == num
end  # ==( entry, num )

function Base.:(==)( num::T, entry::HistoryEntry ) where T <: Real
    return num == entry.timestamp
end  # ==( num, entry )


# XXX The "<" operator must be defined by the Base.isless function. Otherwise
#   Julia generates an error.
function Base.isless( entryLeft::HistoryEntry, entryRight::HistoryEntry )
    return entryLeft.timestamp < entryRight.timestamp
end  # isless( entryLeft, entryRight )

function Base.isless( entry::HistoryEntry, num::T ) where T <: Real
    return entry.timestamp < num
end  # isless( entry, num )

function Base.isless( num::T, entry::HistoryEntry ) where T <: Real
    return num < entry.timestamp
end  # isless( num, entry )


function Base.show( io::IO, entry::HistoryEntry )
    print( io, "$(entry.timestamp): $(entry.newVal)")
end  # show( io, entry )
