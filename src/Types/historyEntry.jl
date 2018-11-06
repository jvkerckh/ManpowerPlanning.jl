# This file defines the HistoryEntry type. This type marks when a change in the
#   status of a personnel member occurred.
# Note that the entry does NOT contain the parameter that is changed, because
#   that information is already contained in the representation of the personnel
#   member.

# The HistoryEntry type requires no additional types.
requiredTypes = [ ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( typePath, reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end  # for reqType in requiredTypes


export HistoryEntry
type HistoryEntry
    # The timestamp of the entry.
    timestamp::Float64

    # The new value of the parameter.
    newVal

    function HistoryEntry( t::T, val ) where T <: Real
        newEntry = new()
        newEntry.timestamp = t
        newEntry.newVal = val
        return newEntry
    end  # HistoryEntry( t, par, newVal )
end  # type HistoryEntry
