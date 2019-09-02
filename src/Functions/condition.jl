# This file holds the definition of the functions pertaining to the Condition
#   type.

# The functions of the Transition type require no other types.
requiredTypes = [ "condition" ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( typePath, reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end  # for reqType in requiredTypes


function Base.show( io::IO, cond::Condition )

    print( io, cond.attr, " ", cond.rel, " " )

    if cond.val isa String
        print( io, "\"", cond.val, "\"" )
    elseif cond.val isa Vector{String}
        print( io, "{ \"", join( cond.val, "\", \"" ) ,"\" }" )
    else
        print( io, cond.val )
    end  # if cond.val isa String

    return

end  # show( io, cond )


# ==============================================================================
# Non-exported methods.
# ==============================================================================

relationFunctions = Dict{String, Function}( "IS" => ==, "IS NOT" => !=,
    "IN" => ∈, "NOT IN" => ∉, ">" => >, ">=" => >=, "<" => <, "<=" => <= )
timeAttrs = [ "age", "tenure", "time in node" ]
histAttrs = [ "had transition", "started as", "was" ]


function processCondition( attr::String, rel::String, val::Union{Real, String} )

    newCond = Condition{Int}( "", ==, 0 )
    relOp = get( relationFunctions, rel, nothing )

    # If the operator is unknown (shouldn't happen), do not process the
    #   condition.
    if isa( relOp, Void )
        warn( "Unknown operator. This warning should not appear!" )
        return newCond, false
    end  # if isa( relOp, Void )

    attrName = strip( attr )
    attrName = lowercase( attrName ) ∈ timeAttrs ? lowercase( attrName ) :
        attrName

    # If the condition is on the age, only process if the operator makes sense.
    if ( attrName ∈ timeAttrs ) && ( relOp ∉ [ ∈, ∉ ] )
        newCond = Condition{Float64}( attrName, relOp, val * 12.0 )
    else
        attrVal = val
        valType = typeof( val )

        if relOp ∈ [ ∈, ∉ ]
            attrVal = split( val, "," )
            attrVal = Vector{String}( map( opt -> strip( opt ), attrVal ) )
            valType = Vector{String}
        end  # if relOp ∈ [ ∈, ∉ ]

        newCond = Condition{valType}( attrName, relOp, attrVal )
    end  # if ( attrName ∈ timeAttrs ) && ...

    return newCond, true

end  # processCondition( attr::String, rel::String, val::T )


"""
```
conditionToSQLite( cond::Condition )
```
This function converts the condition `cond` to the appropriate SQLite statement.
If the condition is a history condition, that is with condition attribute
`had transition`, `started as`, or `was`, the correct requests will be generated
and prefaced with ` AND `.

This function returns a `String`, the SQLite statement equivalent to the
condition.
"""
function conditionToSQLite( cond::Condition )::String

    sqlVal = ""

    if cond.val isa Real
        sqlVal = string( cond.val )
    elseif cond.val isa String
        sqlVal = string( "'", cond.val, "'" )
    else
        sqlVal = string( "( '", join( cond.val, "', '" ), "' )" )
    end  # if cond.val isa Real

    sqlCond = ""

    if cond.attr == "had transition"
        sqlCond = string( " AND transition ", relationEntries[ cond.rel ], " ",
            sqlVal )
    elseif cond.attr == "started as"
        sqlCond = string( " AND startState IS NULL AND endState ",
            relationEntries[ cond.rel ], " ", sqlVal )
    elseif cond.attr == "was"
        sqlCond = string( " AND startState ", relationEntries[ cond.rel ], " ",
            sqlVal )
    else  # Regular conditions.
        sqlCond = string( "`", cond.attr, "` ", relationEntries[ cond.rel ],
            " ", sqlVal )
    end  # if cond.attr == "had transition"

    return sqlCond

end  # conditionToSQLite( cond )
