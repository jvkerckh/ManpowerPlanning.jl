@resumable function retireProcess( sim::Simulation, mpSim::MPsim )

    retirement = mpSim.retirement

    if ( retirement.retirementAge == 0.0 ) &&
        ( retirement.maxCareerLength == 0.0 )
        return
    end  # if ( retirement.retirementAge == 0.0 ) && ...

    # Timing of the process.
    processTime = Dates.Millisecond( 0 )
    tStart = now()
    retName = string( "Default retirement process " )

    # Preparatory steps.
    priority = typemax( Int )
    timeToWait = retirement.offset

    # If an initial population snapshot is uploaded, and it contains zero-time
    #   events, don't execute zero-time retirement.
    if ( timeToWait == 0 ) && !mpSim.isVirgin
        timeToWait += retirement.freq
    end  # if ( timeToWait == 0 ) && ...

    # Process loop.
    while now( sim ) + timeToWait <= mpSim.simLength
        processTime += now() - tStart
        @yield timeout( sim, timeToWait, priority = priority )
        tStart = now()
        retirementCycle( retirement, mpSim )
        timeToWait = retirement.freq
    end  # while now( sim ) + timeToWait <= mpSim.simLength

    # Timing of the process.
    processTime += now() - tStart

    if mpSim.showInfo
        println( retName, "took ", processTime.value / 1000, " seconds." )
    end  # if mpSim.showInfo

end  # @resumable function retireProcess( sim, mpSim )


function retirementCycle( retirement::Retirement, mpSim::MPsim )

    currentTime = now( mpSim )
    queryCmd = string( "SELECT id, currentNode FROM `", mpSim.persDBname,
        "` WHERE",
        "\n    status IS 'active' AND" )

    if retirement.retirementAge == 0.0
        queryCmd = string( queryCmd,
            "\n    ", currentTime, " - timeEntered >= ",
            retirement.maxCareerLength )
    elseif retirement.maxCareerLength == 0.0
        queryCmd = string( queryCmd,
            "\n    ", currentTime, " - timeEntered + ageAtRecruitment >= ",
            retirement.retirementAge )
    else
        queryCmd = string( queryCmd,
            "\n    (", currentTime, " - timeEntered >= ",
            retirement.maxCareerLength, retirement.isEither ? " OR " : " AND ",
            "\n        ", currentTime, " - timeEntered + ageAtRecruitment >= ",
            retirement.retirementAge, ")" )
    end  # if retirement.retirementAge == 0.0

    queryCmd = string( queryCmd,
        "\n    ORDER BY currentNode" )
    ids = DataFrame( DBInterface.execute( mpSim.simDB, queryCmd ) )

    if isempty( ids )
        return
    end  # if isempty( ids )

    currentNodes = Vector{String}( ids[:, :currentNode] )
    ids = Vector{String}( ids[:, Symbol( mpSim.idKey )] )
    removePersons( ids, currentNodes, "retirement", mpSim )

end  # retirementCycle( retirement, mpSim )


function removePersons( ids::Vector{String}, currentNodes::Vector{String},
    simTimes::Union{Float64, Vector{Float64}}, reason::String, mpSim::MPsim )

    # Add the retirement transition to the transition records.
    sqliteCmd = string.( "\n    ('", ids, "', ", simTimes, ", '", reason,
        "', '", currentNodes, "')" )
    sqliteCmd = string( "INSERT INTO `", mpSim.transDBname, "` (`", mpSim.idKey,
        "`, timeIndex, transition, sourceNode) VALUES", join( sqliteCmd, "," ) )
    DBInterface.execute( mpSim.simDB, sqliteCmd )

    # Clear the ids from the inNodeSince field of their current node.
    for name in unique( currentNodes )
        currentNode = mpSim.baseNodeList[name]
        delete!.( Ref( currentNode.inNodeSince ), ids[currentNodes .== name] )
    end  # for name in unique( currentNodes )

    # Update the personnel records.
    sqliteCmd = string.( "UPDATE `", Ref(mpSim.persDBname), "`",
        "\n    SET status = '", Ref(reason), "',",
        "\n        timeExited = ", simTimes, ",",
        "\n        currentNode = NULL,",
        "\n        inNodeSince = NULL",
        "\n    WHERE `", mpSim.idKey, "` IS '", ids, "'" )
    DBInterface.execute.( Ref(mpSim.simDB), sqliteCmd )

end  # removePersons( ids, currentNodes, reason, mpSim )

removePersons( ids::Vector{String}, currentNode::String,
    simTimes::Union{Float64, Vector{Float64}}, reason::String, mpSim::MPsim ) =
    removePersons( ids, fill( currentNode, length(ids) ), simTimes, reason,
    mpSim )

removePersons( ids::Vector{String},
    currentNodes::Union{String, Vector{String}}, reason::String,
    mpSim::MPsim ) = removePersons( ids, currentNodes, now(mpSim), reason, mpSim )

    
removePerson( id::String, currentNode::String, reason::String, mpSim::MPsim ) =
    removePersons( [id], currentNode, reason, mpSim )