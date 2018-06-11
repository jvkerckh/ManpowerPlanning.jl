# This file holds the definition of the functions pertaining to the State type.

# The functions of the State type require no additional types.
requiredTypes = [ "state" ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( dirname( Base.source_path() ), "..", "Types",
            reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end  # for reqType in requiredTypes


export setName,
       addRequirement!,
       removeRequirement!,
       clearRequirements!


"""
```
setName( state::State,
         name::String )
```
This function sets the name of the state `state` to `name`.

This function returns `nothing`.
"""
function setName( state::State, name::String )::Void

    state.name = name
    return

end  # setName( state, name )


"""
```
addRequirement!( state::State,
                 attribute::String,
                 value::String )
```
This function adds a requirement to the state `state`, requiring that the
attribute `attribute` has the value `value`. The spaces in the attribute are
replaced with underscores (`_`). If there is already a requirement on the
attribute, the function overwrites the requirement.

This function returns `nothing`.
"""
function addRequirement!( state::State, attribute::String, value::String )::Void

    state.requirements[ replace( attribute, " ", "_" ) ] = [ value ]
    return

end  # addRequirement!( state, attribute, value )


"""
```
addRequirement!( state::State,
                 attribute::String,
                 values::Vector{String} )
```
This function adds a requirement to the state `state`, requiring that the
attribute `attribute` has a value in `values`. The spaces in the attribute are
replaced with underscores (`_`). If there is already a requirement on the
attribute, the function overwrites the requirement.

This function returns `nothing`.
"""
function addRequirement!( state::State, attribute::String,
    values::Vector{String} )::Void

    state.requirements[ replace( attribute, " ", "_" ) ] = values
    return

end  # addRequirement!( state, attribute, values )


"""
```
removeRequirement!( state::State,
                    attribute::String )
```
This function removes the requirement for state `state` on attribute
`attribute`. If the attribute had no requirement on it, nothing happens.

This function returns `nothing`.
"""
function removeRequirement!( state::State, attribute::String )::Void

    delete!( state.requirements, attribute )
    return

end  # removeRequirement!( state, attribute )


"""
```
clearRequirements!( state::State )
```
This function clears all the requirements for state `state`.

This function returns `nothing`.
"""
function clearRequirements!( state::State )::Void

    empty!( state.requirements )
    return

end  # clearRequirements!( state )


"""
```
setInitial( state::State,
            isInitial::Bool )
```
This function sets the flag of `state` which indicates the state is an initial
state to `isInitial`.

This function returns `nothing`.
"""
function setInitial( state::State, isInitial::Bool )::Void

    state.isInitial = isInitial
    return

end  # setInitial( state, isInitial )


function Base.show( io::IO, state::State )

    print( io, "  State: $(state.name)" )

    if isempty( state.requirements )
        print( io, "\n    State '$(state.name)' has no requirements" )
        return
    end  # if isempty( state.requirements )

    print( io, "\n    Requirements" )

    for attr in keys( state.requirements )
        print( io, "\n      $attr " )
        vals = state.requirements[ attr ]
        multival = length( vals ) != 1
        print( io, multival ? "∈ { " : "= " )
        print( io, join( map( val -> "'$val'", vals ), ", " ) )
        print( io, multival ? " }" : "" )
    end  # for attr in keys( state.requirements )

end  # show( io, state )


# ==============================================================================
# Non-exported methods.
# ==============================================================================


"""
```
readState( s::Taro.Sheet,
           sLine::T )
```
This function reads the Excel sheet `s`, starting from line `sLine` and
extracts the parameters of a single state from it.

This function returns a `Tuple{State, Bool, Int}`. The first element is the
state object as it is described in the Excel sheet, the second element is `true`
if the state is a possible initial state, and the last element is the start line
of the next state in the sheet.
"""
function readState( s::Taro.Sheet, sLine::T ) where T <: Integer

    isInitial = s[ "B", sLine + 1 ] == 1
    newState = State( s[ "B", sLine ], isInitial )
    nReqs = Int( s[ "B", sLine + 2 ] )

    for ii in 1:nReqs
        attr = s[ "B", sLine + 2 + ii ]
        values = processStateOptions( s[ "C", sLine + 2 + ii ] )
        addRequirement!( newState, attr, values )
    end  # for ii in 1:nReqs

    return newState, isInitial, sLine + 4 + nReqs

end  # readState( s, sLine )


"""
```
processStateOptions( opts::String )
```
This function processes the list of options given in `opts`.

This function returns either a `String` if there was only one option, or a
`Vector{String}` if there were multiple, comma separated options.
"""
function processStateOptions( opts::String )

    vals = split( opts, "," )
    vals = map( val -> String( strip( val ) ), vals )
    return length( vals ) == 1 ? vals[ 1 ] : vals

end  # processStateOptions( opts )


"""
```
isPersonnelOfState( persAttrs::Array{Any,2},
                    state::State )
```
This function tests if the personnel members with initialised attributes
`persAttrs` satisfies the requirements of state `state`.

This function returns a `Bool` with the result of the test.
"""
function isPersonnelOfState( persAttrs::Array{Any,2}, state::State )::Bool

    for attr in keys( state.requirements )
        attrInd = findfirst( persAttrs[ 1, : ] .== attr )

        # If the attribute isn't initialised for the personnel member, the
        #   personnel doesn't satisfy it, and isn't in the state.
        if attrInd == 0
            return false
        end  # if attrInd == 0

        toMatch = state.requirements[ attr ]

        if persAttrs[ 2, attrInd ] ∉ toMatch
            return false
        end  # if persAttrs[ 2, attrInd ] ∉ toMatch
    end  # for attr in keys( state.requirements )

    return true

end  # isPersonnelOfState( persAttrs, state )
