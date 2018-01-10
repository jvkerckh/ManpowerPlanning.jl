# This file holds the definition of the functions pertaining to the History
#   type.

# The functions of the History type require the HistoryEntry type.
requiredTypes = [ "historyEntry", "history" ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( dirname( Base.source_path() ), "..", "Types",
            reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end  # for reqType in requiredTypes


# This function adds an entry to the history.
export addEntry!
function addEntry!( hist::History, timestamp::T, newState ) where T <: Real
    # Check if there's no entry with this timestamp already.
    ii = searchsortedlast( hist.history, timestamp )

    if ( ii > 0 ) && ( hist.history[ ii ] == timestamp )
        hist.history[ ii ].newVal = newState
        return
    end  # if ( ii <= length( hist.history ) ) ...

    # Add the new entry at the end.
    ii = length( hist.history )
    push!( hist.history, HistoryEntry( timestamp, newState ) )

    # Place the entry where it belongs.
    while ( ii >= 1 ) && ( hist.history[ ii ] > hist.history[ ii + 1 ] )
        hist.history[ ii ], hist.history[ ii + 1 ] =
            hist.history[ ii + 1 ], hist.history[ ii ]
        ii -= 1
    end  # while ( ii >= 1 ) ...
end  # addEntry!( hist, timestamp, newState )


# This function returns the value of the attribute at the requested timestamp.
# If the timestamp is earlier than the first time in the history, or if the
#   history is empty, nothing gets returned.
function Base.getindex( hist::History, timestamp::T ) where T <: Real
    ii = searchsortedlast( hist.history, timestamp )

    return ii == 0 ? nothing : hist.history[ ii ].newVal
end  # getindex( hist, timestamp )


function Base.setindex!( hist::History, data, timestamp::T ) where T <: Real
    addEntry!( hist, timestamp, data )
end


function Base.show( io::IO, hist::History )
    print( io, "Attribute: $(hist.attribute)" )

    for entry in hist.history
        print( io, "\n$entry" )
    end  # for entry in hist.history
end  # show( io, hist )
