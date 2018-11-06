# This file defines the PrerequisiteGroup type, used to define a group of
#   prerequisites that all need to be satisfied.

# The PrerequisiteGroup type requires the Prerequisite type.
requiredTypes = [ "prerequisite" ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( typePath, reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end  # for reqType in requiredTypes


export PrerequisiteGroup
type PrerequisiteGroup
    # The list of prerequisites.
    prereqs::Vector{Prerequisite}

    # Constructor.
    function PrerequisiteGroup()
        prereqGroup = new()
        prereqGroup.prereqs = Vector{Prerequisite}()
        return prereqGroup
    end  # PrerequisiteGroup()
end  # type PrerequisiteGroup
