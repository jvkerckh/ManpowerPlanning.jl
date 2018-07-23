# This file holds the definition of the functions pertaining to the Condition
#   type.

# The functions of the Transition type require the State type.
requiredTypes = [ "condition" ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( dirname( Base.source_path() ), "..", "Types",
            reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end  # for reqType in requiredTypes


# ==============================================================================
# Non-exported methods.
# ==============================================================================


relationFunctions = Dict( "IS" => ==, "IS NOT" => !=, "IN" => ∈, "NOT IN" => ∉,
    ">" => >, ">=" => >=, "<" => <, "<=" => <= )


function processCondition( attr::String, rel::String, val::T ) where T <: Union{Real, String}

    newCond = Condition{Int}( "", ==, 0 )
    relOp = get( relationFunctions, rel, nothing )

    # If the operator is unknown (shouldn't happen), do not process the
    #   condition.
    if isa( relOp, Void )
        warn( "Unknown operator. This warning should not appear!" )
        return newCond, false
    end  # if isa( relOp, Void )

    attrName = strip( attr )
    attrName = lowercase( attrName ) == "age" ? "age" :
        replace( attrName, " ", "_" )

    # If the condition is on the age, only process if the operator makes sense.
    if ( attrName == "age" ) && ( relOp ∉ [ ∈, ∉ ] )
        newCond = Condition{T}( attrName, relOp, val * 12.0 )
    else
        attrVal = val
        valType = T

        if relOp ∈ [ ∈, ∉ ]
            attrVal = split( val, "," )
            attrVal = Vector{String}( map( opt -> strip( opt ), attrVal ) )
            valType = Vector{String}
        end  # if relOp ∈ [ ∈, ∉ ]

        newCond = Condition{valType}( attrName, relOp, attrVal )
    end  # if ( attrName == "age" ) &&

    return newCond, true

end  # processCondition( attr::String, rel::String, val::T )
