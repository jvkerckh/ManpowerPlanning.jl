# This file defines the History type. This type holds all the changes in a
#   specific attribute of a specific person.
# The history also contains the attribute of which it is the history, for
#   validation purposes.

# The History type requires the HistoryEntry type.
requiredTypes = [ ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( typePath, reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end  # for reqType in requiredTypes


export History
type History
    # The attribute of which this is the history.
    attribute::Symbol

    # The list of events.
    history::Vector{HistoryEntry}

    function History( attr::Symbol )
        newHist = new()
        newHist.attribute = attr
        newHist.history = Vector{HistoryEntry}()
        return newHist
    end  # History( attr )
end  # type History
