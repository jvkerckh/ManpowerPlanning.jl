const timeAttributes = ["age", "tenure", "time in node"]
const histAttributes = ["had transition", "started as", "was"]
const relationEntries = Dict{Function, String}( Base.:(==) => "IS",
    Base.:(!=) => "IS NOT", Base.:∈ => "IN", Base.:∉ => "NOT IN",
    Base.:> => ">", Base.:(>=) => ">=", Base.:< => "<", Base.:(<=) => "<=" )


function conditionToSQLite( condition::MPcondition, mpSim::MPsim )

    sqlValue = ""

    if condition.value isa Real
        sqlValue = string( condition.value )
    elseif condition.value isa String
        sqlValue = string( "'", condition.value, "'" )
    else
        sqlValue = string( "( '", join( condition.value, "', '" ), "' )" )
    end  # if condition.value isa Real

    sqlCond = ""

    if condition.attribute == "had transition"
        sqlCond = string( " AND transition ",
            relationEntries[condition.operator], " ", sqlValue )
    elseif condition.attribute == "started as"
        sqlCond = string( " AND ", mpSim.sNode, " IS NULL AND ", mpSim.tNode,
            " ", relationEntries[condition.operator], " ", sqlValue )
    elseif condition.attribute == "was"
        sqlCond = string( " AND ", mpSim.sNode, " ",
            relationEntries[condition.operator], " ", sqlValue )
    else  # Regular conditions.
        sqlCond = string( "`", condition.attribute, "` ",
            relationEntries[condition.operator], " ", sqlValue )
    end  # if condition.attribute == "had transition"

    return sqlCond

end  # conditionToSQLite( condition, mpSim )