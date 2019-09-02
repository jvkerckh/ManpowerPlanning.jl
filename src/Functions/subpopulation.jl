# This file holds the definition of the functions pertaining to the
#   Subpopulation type.

# The functions of the Subpopulation type require the Attrition type.
requiredTypes = [ "condition", "state" ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( typePath, reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end  # for reqType in requiredTypes


export  setName!,
        addCondition!,
        clearConditions!


"""
```
setName!( subpop::Subpopulation,
          name::String )
```
This function sets the name of the subpopulation `subpop` to `name`.

This function returns `nothing`.
"""
function setName!( subpop::Subpopulation, name::String )::Void

    subpop.name = name
    return

end  # setName!( subpop, name )


"""
```
addCondition!( subpop::Subpopulation,
               condList::Condition... )
```
This function adds the conditions in `condList` to the subpopulation `subpop`.

This function returns `nothing`.
"""
function addCondition!( subpop::Subpopulation, condList::Condition... )::Void

    for cond in condList
        if cond.attr ∈ timeAttrs
            push!( subpop.timeConds, cond )
        elseif cond.attr ∈ histAttrs
            push!( subpop.histConds, cond )
        else
            push!( subpop.attribConds, cond )
        end  # if cond.attr ∈ timeAttrs
    end  # for cond in condList

    return

end  # addCondition!( subpop, condList )


"""
```
clearConditions!( subpop::Subpopulation )
```
This function clears all the requirements for subpopulation `subpop`.

This function returns `nothing`.
"""
function clearConditions!( subpop::Subpopulation )::Void

    empty!( state.requirements )
    return

end  # clearConditions!( subpop )


function Base.show( io::IO, subpop::Subpopulation )

    print( io, "  Subpopulation: $(subpop.name)" )
    print( io, "\n    Root node: $(subpop.sourceNodeName)" )

    if !isempty( subpop.timeConds ) || !isempty( subpop.histConds ) ||
        !isempty( subpop.attribConds )
        print( io, "\n    Conditions\n      ", join( vcat( subpop.timeConds,
            subpop.histConds, subpop.attribConds ), "\n      " ) )
    end  # if !isempty( subpop.timeConds ) || ...

    return

end  # show( io, state )
