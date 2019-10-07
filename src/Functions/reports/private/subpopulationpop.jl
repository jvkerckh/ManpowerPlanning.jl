function getSubpopulationAtTime( mpSim::MPsim, timePoint::Float64, subpopulations::Vector{Subpopulation} )

    result = fill( Vector{String}(), length( subpopulations ) )
    hasAttributeConds = map( subpopulation -> !isempty(
        subpopulation.attributeConds ), subpopulations )

    # Find all personnel members that satisfy the source node, the history
    #   conditions, and the time conditions.
    for ii in eachindex( subpopulations )
        subpopulation = subpopulations[ ii ]
        result[ ii ] = subpopulation.sourceNode == "active" ?
            getActiveAtTime( mpSim, timePoint, subpopulation ) :
            getActiveAtTime( mpSim, timePoint, subpopulation, false )  # ! To change
    end  # for ii in eachindex( subpopulations )

    if !any( hasAttributeConds )
        return result
    end  # if !any( hasAttributeConds )

    # Get the personnel database snapshot of the personnel members for whom a
    #   database state reconstruction is required.
    idsToReconstruct = vcat( result[ hasAttributeConds ]... )
    queryCmd = string( "SELECT * FROM `", mpSim.persDBname, "` WHERE",
        "\n    `", mpSim.idKey, "` IN ( '" , join( idsToReconstruct, "', '" ),
        "' )" )
    activeAtTime = DataFrame( SQLite.Query( mpSim.simDB, queryCmd ) )
    getSubpopulationStateAtTime!( activeAtTime, mpSim, timePoint )
    idSymbol = Symbol( mpSim.idKey )

    # For each request, filter out personnel members satisfying the conditions
    #   of the request.
    for ii in filter( ii -> hasAttributeConds[ ii ], eachindex( result ) )
        subpopulation = subpopulations[ ii ]
        satisfyConds = map( id -> id ∈ result[ ii ],
            activeAtTime[ :, idSymbol ] )

        for condition in subpopulation.attributeConds
            satisfyConds .&= map(  activeAtTime[ :,
                Symbol( condition.attribute ) ] ) do val
                return condition.operator( val, condition.value )
            end  # map( ... )
        end  # for cond in attribConds
    
        result[ ii ] = activeAtTime[ satisfyConds, idSymbol ]
    end  # for ii in filter( ..., eachindex( result ) )

    return result

end  # getSubpopulationAtTime( mpSim, timePoint, subpopulations )


function getActiveAtTime( mpSim::MPsim, timePoint::Float64,
    subpopulation::Subpopulation )

    # Generate the SQLite query.
    queryCmd = string( "SELECT *, ",
        timePoint, " - timeEntered tenure, ", 
        timePoint, " - timeEntered + ageAtRecruitment age FROM `",
        mpSim.persDBname, "` WHERE",
        "\n    timeEntered <= ", timePoint, " AND ( timeExited > ", timePoint,
        " OR timeExited IS NULL )" )

    if !isempty( subpopulation.timeConds )
        condSQLite = conditionToSQLite.( subpopulation.timeConds )

        # Replace "time in node" by "tenure"
        for ii in eachindex( condSQLite )
            if startswith( condSQLite[ ii ], "`time in node`" )
                condSQLite[ ii ] = replace( condSQLite[ ii ],
                    "`time in node`" => "tenure" )
            end  # if startswith( condSQLite[ ii ], "`time in node`" )
        end  # for ii in eachindex( condSQLite )

        queryCmd = string( queryCmd, " AND ", join( condSQLite, " AND " ) )
    end  # if !isempty( timeConds )
    
    if !isempty( subpopulation.historyConds )
        # Identify which history conditions are negatives and adjust for them.
        histConds = deepcopy( subpopulation.historyConds )
        isNegHistCond = map( cond -> cond.operator ∈ [ !=, ∉ ], histConds )

        for ii in eachindex( histConds )
            if isNegHistCond[ ii ]
                condition = histConds[ ii ]
                histConds[ ii ] = MPcondition( condition.attribute,
                    condition.operator == Base.:∈ ? Base.:∈ : Base.:(==),
                    condition.value )
            end  # if isNegHistCond[ ii ]
        end  # for ii in eachindex( histConds )
    
        # Generate history condition queries.
        condSQLite = conditionToSQLite.( histConds )
        condSQLite = string.( "`", mpSim.idKey, "`",
            map( bVal -> bVal ? " NOT" : "", isNegHistCond ), " IN ( SELECT `",
            mpSim.idKey, "` FROM `" , mpSim.transDBname, "`
                WHERE timeIndex <= ", timePoint, condSQLite,
            " )" )
        queryCmd = string( queryCmd, " AND ", join( condSQLite, " AND " ) )
    end  # if !isempty( subpopulation.historyConds )

    queryCmd = string( queryCmd, "\n    ORDER BY `", mpSim.idKey, "`" )
    result = DataFrame( SQLite.Query( mpSim.simDB, queryCmd ) )
    return string.( result[ :, Symbol( mpSim.idKey ) ] )

end  # getActiveAtTime( MPsim, timePoint, subpopulation )


function getActiveAtTime( mpSim::MPsim, timePoint::Float64,
    subpopulation::Subpopulation, fullPop::Bool )

    # Only for safety.
    if fullPop
        return getActiveAtTime( mpSim, timePoint, subpopulation )
    end  # if fullPop

    # Identify which history conditions are negatives and adjust for them.
    histConds = deepcopy( subpopulation.historyConds )
    isNegHistCond = map( cond -> cond.operator ∈ [ !=, ∉ ], histConds )

    for ii in eachindex( histConds )
        if isNegHistCond[ ii ]
            condition = histConds[ ii ]
            histConds[ ii ] = MPcondition( condition.attribute,
                condition.operator == Base.:∈ ? Base.:∈ : Base.:(==),
                condition.value )
        end  # if isNegHistCond[ ii ]
    end  # for ii in eachindex( histConds )

    # Generate history condition queries.
    queryCmd = conditionToSQLite.( histConds )
    queryCmd = string.( "`", mpSim.idKey, "`",
        map( bVal -> bVal ? " NOT" : "", isNegHistCond ), " IN ( SELECT `",
        mpSim.idKey, "` FROM `" , mpSim.transDBname, "` WHERE",
            "\n    timeIndex <= ", timePoint, queryCmd, " )" )
    
    # Generate subquery.
    nodeName = subpopulation.sourceNode
    nodeCond = haskey( mpSim.baseNodeList, nodeName ) ? nodeName :
        join( mpSim.compoundNodeList[ nodeName ].baseNodeList, "', '" )
    queryCmd = string( "SELECT `", mpSim.idKey, "` tmpID, timeIndex FROM `",
        mpSim.transDBname, "` WHERE",
        "\n    timeIndex <= ", timePoint, isempty( queryCmd ) ? "" : " AND ", join( queryCmd, " AND " ), "\n    GROUP BY `", mpSim.idKey, "`",
        "\n    HAVING endState IN ( '", nodeCond, "' )" )

    # Generate full query.
    queryCmd = string( "SELECT *, ",
        timePoint, " - timeEntered tenure, ",
        timePoint, " - timeEntered + ageAtRecruitment age, ",
        timePoint, " - timeIndex `time in node` FROM `", mpSim.persDBname, "`",
        "\n    INNER JOIN ( ", queryCmd, " ) tmpList ON `", mpSim.idKey,
        "` IS tmpID" )

    if !isempty( subpopulation.timeConds )
        condSQLite = conditionToSQLite.( subpopulation.timeConds )
        queryCmd = string( queryCmd, "\n    WHERE ",
            join( condSQLite, " AND " ) )
    end  # if !isempty( timeConds )

    queryCmd = string( queryCmd, "\n    ORDER BY `", mpSim.persDBname, "`.`",
        mpSim.idKey, "`" )
    result = DataFrame( SQLite.Query( mpSim.simDB, queryCmd ) )
    return string.( result[ :, Symbol( mpSim.idKey ) ] )

end  # getActiveAtTime( mpSim, timePoint, subpopulation, fullPop )


function getSubpopulationStateAtTime!( activeAtTime::DataFrame, mpSim::MPsim,
    timePoint::Float64 )

    # Get the value of the attributes at time tPoint.
    activeIDs = activeAtTime[ :, Symbol( mpSim.idKey ) ]
    queryCmd = string( "SELECT `", mpSim.idKey, "`, attribute, strValue FROM `",
        mpSim.histDBname, "` WHERE", 
        "\n    timeIndex <= ", timePoint, " AND ",
        "\n    attribute IS NOT 'status' AND ",
        "\n   `", mpSim.idKey, "` IN ( '",
        join( activeIDs, "', '" ) , "')",
        "\n    GROUP BY `", mpSim.idKey, "`, attribute",
        "\n    ORDER BY attribute, `", mpSim.idKey, "`" )
        currentAttributeVals = DataFrame( SQLite.Query( mpSim.simDB,
            queryCmd ) )

    # Reconstruct the state of the personnel members satisfying the node and
    #   time conditions.
    attributes = unique( currentAttributeVals[ :, :attribute ] )

    for attribute in attributes
        attributeInds = currentAttributeVals[ :, :attribute ] .== attribute

        # activeAtTime[ !, Symbol( attribute ) ] =
        #     currentAttributeVals[ attributeInds, :strValue ]
        # ! This formation is best for DataFrames v0.19+
        activeAtTime[ :, Symbol( attribute ) ] =
            currentAttributeVals[ attributeInds, :strValue ]
        # ! This formulation gives a deprecation warning for DataFrames v0.19+
    end  # for attrib in attribshelp

end  # getSubpopulationStateAtTime!( activeAtTime, mpSim, timePoint )