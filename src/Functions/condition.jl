# This file holds the definition of the functions pertaining to the MPCondition
#   type.

function Base.show( io::IO, condition::MPCondition )::Nothing

    print( io, condition.attribute, " ", condition.operator, " " )

    if condition.value isa String
        print( io, "\"", condition.value, "\"" )
    elseif condition.value isa Vector{String}
        print( io, "{ \"", join( condition.value, "\", \"" ) ,"\" }" )
    else
        print( io, condition.value )
    end  # if condition.value isa String

    return

end  # show( io, condition )