@resumable function recruitProcess( sim::Simulation, recruitment::Recruitment,
    mpSim::MPsim )

    # Timing of the process.
    processTime = Dates.Millisecond( 0 )
    tStart = now()
    recName = string( "Recruitment process '", recruitment.name, "' to node '",
        recruitment.targetNode, "' " )

    # Preparatory steps.
    timeToWait = recruitment.offset
    priority = typemin( Int8 ) + ( recruitment.isAdaptive ? zero( Int8 ) :
        one( Int8 ) )

    # Process loop.
    while now( sim ) + timeToWait <= mpSim.simLength
        processTime += now() - tStart
        @yield timeout( sim, timeToWait, priority = priority )
        tStart = now()
        recruitmentCycle( recruitment, mpSim )
        timeToWait = recruitment.freq
    end  # while now( sim ) + timeToWait <= mpSim.simLength

    # Timing of the process.
    processTime += now() - tStart

    if mpSim.showInfo
        println( recName, "took ", processTime.value / 1000, " seconds." )
    end  # if mpSim.showInfo

end  # @resumable recruitProcess( sim, recruitment, mpSim )


function recruitmentCycle( recruitment::Recruitment, mpSim::MPsim )

    targetNode = mpSim.baseNodeList[ recruitment.targetNode ]
    nToRecruit = generatePoolSize( recruitment, targetNode, mpSim )
    generatePersons( recruitment, nToRecruit, mpSim )

end  # recruitmentCycle( recruitment::Recruitment, mpSim::MPsim )


function generatePoolSize( recruitment::Recruitment, targetNode::BaseNode,
    mpSim::MPsim )

    # If the recruitment scheme isn't adaptive, draw from the distribution.
    if !recruitment.isAdaptive
        return recruitment.recruitmentDist()
    end  # if !recruitment.isAdaptive

    nToOrgTarget = mpSim.personnelTarget > 0 ? mpSim.personnelTarget -
        mpSim.orgSize : typemax( Int )
    nToNodeTarget = targetNode.target >= 0 ? targetNode.target -
        length( targetNode.inNodeSince ) : typemax( Int )
    return max( min( recruitment.maxRecruitment, nToOrgTarget, nToNodeTarget ),
        recruitment.minRecruitment )

end  # generatePoolSize( recruitment, targetNode, mpSim )


function generatePersons( recruitment::Recruitment, nToRecruit::Int,
    mpSim::MPsim )

    if nToRecruit == 0
        return
    end  # if nToRecruit == 0

    # Generate attribute values for the new personnel members.
    attributeNames = collect( keys( mpSim.attributeList ) )
    newPersons = DataFrame( fill( missing, nToRecruit,
        length( mpSim.attributeList ) ), Symbol.( attributeNames ) )
    
    for name in attributeNames
        attribute = mpSim.attributeList[ name ]

        if !isempty( attribute.initValues )
            newPersons[ :, Symbol( name ) ] = generateValues( attribute,
                nToRecruit )
        end  # if !isempty( attribute.initValues )
    end  # for name in attributeNames

    # Adjust initial values for target node.
    targetNode = mpSim.baseNodeList[ recruitment.targetNode ]

    for name in keys( targetNode.requirements )
        newPersons[ :, Symbol( name ) ] .= targetNode.requirements[ name ]
    end  # for name in keys( targetNode.requirements )

    # Add ID key and ages.
    ids = string.( "Sim", mpSim.dbSize .+ (1:nToRecruit) )
    insertcols!( newPersons, 1, Symbol( mpSim.idKey ) => ids )
    insertcols!( newPersons, 2, :recAge => recruitment.ageDist( nToRecruit ) )

    # Update target node populaton.
    currentTime = now( mpSim )

    for id in ids
        targetNode.inNodeSince[ id ] = currentTime
    end  # for id in ids

    # Entries into databases.
    attrition = mpSim.attritionSchemes[ targetNode.attrition ]
    timeOfAttrition = currentTime .+ generateTimeToAttrition( attrition,
        nToRecruit )
    insertcols!( newPersons, 3, :attrTime => timeOfAttrition )

    # Personnel database.
    attrCmd = map( attributeNames ) do name
        return string.( ", '", newPersons[ Symbol( name ) ], "'" )
    end  # map( attributeNames ) do name

    attrCmd = hcat( attrCmd... )
    attrCmd = map( ii -> join( attrCmd[ ii, : ] ), 1:nToRecruit )
    sqliteCmd = map( toa -> toa == +Inf ? "NULL" : toa, timeOfAttrition )
    sqliteCmd = string.( "\n    ('", newPersons[ :, Symbol( mpSim.idKey ) ],
        "', 'active', ", currentTime, ", ", newPersons[ :, :recAge ], ", ",
        sqliteCmd, ", '", targetNode.name, "'", attrCmd, ")" )
    sqliteCmd = string( "INSERT INTO `", mpSim.persDBname, "` (`", mpSim.idKey,
        "`, status, timeEntered, ageAtRecruitment, ",
        "expectedAttritionTime, currentNode",
        join( string.( ", `", attributeNames, "`" ) ), ") VALUES",
        join( sqliteCmd, "," ) )
    SQLite.execute!( mpSim.simDB, sqliteCmd )

    # Transition database.
    sqliteCmd = string.( "\n    ('", ids, "', ", currentTime, ", '",
        recruitment.name, "', '", recruitment.targetNode, "')" )
    sqliteCmd = string( "INSERT INTO `", mpSim.transDBname, "` (`", mpSim.idKey,
        "`, timeIndex, transition, targetNode) VALUES", join( sqliteCmd, "," ) )
    SQLite.execute!( mpSim.simDB, sqliteCmd )

    # History database.
    sqliteCmd = map( attributeNames ) do name
        return string.( "\n    ('", ids, "', ", currentTime, ", '", name,
            "', '", newPersons[ Symbol( name ) ], "')" )
    end  # map( attributeNames ) do name
    
    sqliteCmd = string( "INSERT INTO `", mpSim.histDBname, "` (`", mpSim.idKey,
        "`, timeIndex, attribute, value) VALUES",
        join( vcat( sqliteCmd... ), "," ) )
    SQLite.execute!( mpSim.simDB, sqliteCmd )

    mpSim.orgSize += nToRecruit
    mpSim.dbSize += nToRecruit

end  # generatePersons( recruitment, nToRecruit, mpSim )