@resumable function recruitProcess( sim::Simulation, recruitment::Recruitment,
    mpSim::MPsim )

    # Timing of the process.
    processTime = Dates.Millisecond( 0 )
    tStart = now()
    recName = string( "Recruitment process '", recruitment.name, "' to node '",
        recruitment.targetNode, "' " )

    # Preparatory steps.
    priority = recruitment.priority -
        ( recruitment.isAdaptive ? 1 : 0 ) * mpSim.nPriorities
    timeToWait = recruitment.offset
        
    # If an initial population snapshot is uploaded, and it contains zero-time
    #   events, don't execute zero-time recruitment.
    if ( timeToWait == 0 ) && !mpSim.isVirgin
        timeToWait += recruitment.freq
    end  # if ( timeToWait == 0 ) && ...

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
    nToRecruit = generatePoolSize( recruitment,
        mpSim.baseNodeList[recruitment.targetNode], mpSim )
    generatePersons( recruitment, nToRecruit, mpSim )
end  # recruitmentCycle( recruitment, mpSim )


function generatePoolSize( recruitment::Recruitment, targetNode::BaseNode,
    mpSim::MPsim )
    # If the recruitment scheme isn't adaptive, draw from the distribution.
    !recruitment.isAdaptive && return recruitment.recruitmentDist()

    nToOrgTarget = mpSim.personnelTarget > 0 ? mpSim.personnelTarget -
        mpSim.orgSize : typemax( Int )
    nToNodeTarget = targetNode.target >= 0 ? targetNode.target -
        length( targetNode.inNodeSince ) : typemax( Int )
    return max( min( recruitment.maxRecruitment, nToOrgTarget, nToNodeTarget ),
        recruitment.minRecruitment )
end  # generatePoolSize( recruitment, targetNode, mpSim )


function generatePersons( recruitment::Recruitment, nToRecruit::Int,
    mpSim::MPsim )
    nToRecruit == 0 && return
    
    # Generate attribute values for the new personnel members.
    attributeNames = collect(keys(mpSim.attributeList))
    newPersons = DataFrame( fill( "", nToRecruit,
        length(mpSim.attributeList) ), Symbol.(attributeNames) )
    targetNode = mpSim.baseNodeList[recruitment.targetNode]
    
    for name in attributeNames
        attribute = mpSim.attributeList[name]

        if haskey( targetNode.requirements, name )
            newPersons[:, name] .= targetNode.requirements[name]
        elseif !isempty(attribute.initValues)
            newPersons[:, name] = generateValues( attribute, nToRecruit )
        end  # if !isempty(attribute.initValues)
    end  # for name in attributeNames
    
    # Add ID key and ages.
    ids = string.( "Sim", mpSim.dbSize .+ (1:nToRecruit) )
    insertcols!( newPersons, 1, Symbol(mpSim.idKey) => ids )
    insertcols!( newPersons, 2, :recAge => recruitment.ageDist(nToRecruit) )

    # Update target node populaton.
    setindex!.( Ref(targetNode.inNodeSince ), now(mpSim), ids )

    # Entries into databases.
    attrition = mpSim.attritionSchemes[targetNode.attrition]
    timeOfAttrition = now(mpSim) .+ generateTimeToAttrition( attrition,
        nToRecruit )
    insertcols!( newPersons, 3, :attrTime => timeOfAttrition )

    # Personnel database.
    attrCmd = ""

    if !isempty(attributeNames)
        attrCmd = map( attributeNames ) do name
            return string.( ", '", newPersons[:, Symbol( name )], "'" )
        end  # map( attributeNames ) do name

        attrCmd = hcat( attrCmd... )
        attrCmd = map( ii -> join(attrCmd[ii, :]), 1:nToRecruit )
    end  # if !isempty(attributeName)

    sqliteCmd = map( toa -> toa == +Inf ? "NULL" : toa, timeOfAttrition )
    # sqliteCmd = string.( "\n    ('", newPersons[:, Symbol(mpSim.idKey)],
    sqliteCmd = string.( "\n    ('", newPersons[:, mpSim.idKey],
        "', 'active', ", now(mpSim), ", ", newPersons[:, :recAge], ", ",
        sqliteCmd, ", '", targetNode.name, "', ", now(mpSim), attrCmd,
         ")" )
    sqliteCmd = string( "INSERT INTO `", mpSim.persDBname, "` (`", mpSim.idKey,
        "`, status, timeEntered, ageAtRecruitment, ",
        "expectedAttritionTime, currentNode, inNodeSince",
        join( string.( ", `", attributeNames, "`" ) ), ") VALUES",
        join( sqliteCmd, "," ) )
    # println(sqliteCmd)
    DBInterface.execute( mpSim.simDB, sqliteCmd )

    # Transition database.
    sqliteCmd = string.( "\n    ('", ids, "', ", now(mpSim), ", '",
        recruitment.name, "', '", recruitment.targetNode, "')" )
    sqliteCmd = string( "INSERT INTO `", mpSim.transDBname, "` (`", mpSim.idKey,
        "`, timeIndex, transition, targetNode) VALUES", join( sqliteCmd, "," ) )
    DBInterface.execute( mpSim.simDB, sqliteCmd )

    # History database.
    if !isempty(attributeNames)
        sqliteCmd = map(attributeNames) do name
            return string.( "\n    ('", ids, "', ", now(mpSim), ", '", name,
                "', '", newPersons[:, Symbol(name)], "')" )
        end  # map(attributeNames) do name
        
        sqliteCmd = string( "INSERT INTO `", mpSim.histDBname, "` (`",
            mpSim.idKey, "`, timeIndex, attribute, value) VALUES",
            join( vcat(sqliteCmd...), "," ) )
        DBInterface.execute( mpSim.simDB, sqliteCmd )
    end  # if !isempty(attributeNames)

    mpSim.orgSize += nToRecruit
    mpSim.dbSize += nToRecruit
end  # generatePersons( recruitment, nToRecruit, mpSim )