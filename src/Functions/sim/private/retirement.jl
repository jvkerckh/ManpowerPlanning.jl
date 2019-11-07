@resumable function retireProcess( sim::Simulation, mpSim::MPsim )

    retirement = mpSim.retirement

    if ( retirement.retirementAge == 0.0 ) &&
        ( retirement.maxCareerLength == 0.0 )
        return
    end  # if ( retirement.retirementAge == 0.0 ) && ...

    # Timing of the process.
    processTime = Dates.Millisecond( 0 )
    tStart = now()
    recName = string( "Default retirement process " )

    # Preparatory steps.
    timeToWait = retirement.offset
    priority = typemax( Int8 )
    
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
        println( string( recName, "took ", processTime.value / 1000,
            " seconds." ) )
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
    ids = DataFrame( SQLite.Query( mpSim.simDB, queryCmd ) )

    if isempty( ids )
        return
    end  # if isempty( ids )

    currentNodes = Vector{String}( ids[ :, :currentNode ] )
    ids = Vector{String}( ids[ :, Symbol( mpSim.idKey ) ] )
    removePersons( ids, currentNodes, "retirement", mpSim )

end  # retirementCycle( retirement, mpSim )


function removePersons( ids::Vector{String}, currentNodes::Vector{String},
    reason::String, mpSim::MPsim )

    # Add the retirement transition to the transition records.
    sqliteCmd = string.( "\n    ('", ids, "', ", now( mpSim ), ", '", reason,
        "', '", currentNodes, "')" )
    sqliteCmd = string( "INSERT INTO `", mpSim.transDBname, "` (`", mpSim.idKey,
        "`, timeIndex, transition, sourceNode) VALUES", join( sqliteCmd, "," ) )
    SQLite.execute!( mpSim.simDB, sqliteCmd )

    # Update the personnel records.
    sqliteCmd = string( "UPDATE `", mpSim.persDBname, "`",
        "\n    SET status = '", reason, "',",
        "\n        currentNode = NULL",
        "\n    WHERE `", mpSim.idKey, "` IN ('", join( ids, "', '" ), "')" )
    SQLite.execute!( mpSim.simDB, sqliteCmd )

end  # removePersons( ids, currentNodes, reason, mpSim )

removePersons( ids::Vector{String}, currentNode::String, reason::String,
    mpSim::MPsim ) = removePersons( ids, fill( currentNode, length( ids ) ),
    reason, mpSim )