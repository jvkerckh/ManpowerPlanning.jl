function seedSimulation!( mpSim::MPsim, seed::Integer, sysEnt::Bool )

    # Seed the simulation.
    mpSim.seedRNG = seed < 0 ? MersenneTwister() : MersenneTwister( seed )

    for name in sort( collect( keys( mpSim.recruitmentByName ) ) )
        for recruitment in mpSim.recruitmentByName[name]
            recSeed = sysEnt ? nothing : rand( mpSim.seedRNG, UInt64 )
            recruitment.recRNG = MersenneTwister( recSeed )
            recDist = recruitmentDists[recruitment.recruitmentDistType][3]
            recDistNodes = recruitment.recruitmentDistNodes
            recruitment.recruitmentDist = recDist( recruitment, recDistNodes,
                sort( collect( keys( recDistNodes ) ) ) )

            ageSeed = sysEnt ? nothing : rand( mpSim.seedRNG, UInt64 )
            recruitment.ageRNG = MersenneTwister( ageSeed )
            ageDist = recruitmentDists[recruitment.ageDistType][4]
            ageDistNodes = recruitment.ageDistNodes
            recruitment.ageDist = ageDist( recruitment, ageDistNodes,
                sort( collect( keys( ageDistNodes ) ) ) )
        end  # for recruitment in mpSim.recruitmentByName[name]
    end  # for name in keys( mpSim.recruitmentByName )

    # Seed the attributes.
    for name in sort( collect( keys( mpSim.attributeList ) ) )
        attSeed = sysEnt ? nothing : rand( mpSim.seedRNG, UInt64 )
        attribute = mpSim.attributeList[name]
        attribute.initRNG = MersenneTwister( attSeed )
    end  # for name in keys( mpSim.attributeList )

    # Seed the attrition times.
    for name in sort( collect( keys( mpSim.attritionSchemes ) ) )
        attSeed = sysEnt ? nothing : rand( mpSim.seedRNG, UInt64 )
        attrition = mpSim.attritionSchemes[name]
        attrition.timeRNG = MersenneTwister( attSeed )
    end  # for name in keys( mpSim.attritionSchemes )

    # Seed the transitions.
    for name in sort( collect( keys( mpSim.transitionsByName ) ) )
        for transition in mpSim.transitionsByName[name]
            transSeed = sysEnt ? nothing : rand( mpSim.seedRNG, UInt64 )
            transition.probRNG = MersenneTwister( transSeed )
        end  # for transition in mpSim.transitionsByName[name]
    end  # for name in keys( mpSim.transitionsByName )

end  # seedSimulation!( mpSim, seed, sysEnt )
^

setSimulationDBcommits!( mpSim::MPsim, nCommits::Integer ) =
    ( mpSim.nCommits = nCommits )


function resetSimulation( mpSim::MPsim )

    mpSim.sim = Simulation()

    # Clear the "inNodeSince" from every node.
    for name in keys( mpSim.baseNodeList )
        node = mpSim.baseNodeList[name]
        empty!( node.inNodeSince )
    end

    # Wipe the tables if needed.
    DBInterface.execute( mpSim.simDB, string( "DROP TABLE IF EXISTS `",
        mpSim.histDBname, "`" ) )
    DBInterface.execute( mpSim.simDB, string( "DROP TABLE IF EXISTS `",
        mpSim.transDBname, "`" ) )
    DBInterface.execute( mpSim.simDB, string( "DROP TABLE IF EXISTS `",
        mpSim.persDBname, "`" ) )

    # Reset the population number of the simulation.
    mpSim.orgSize = 0
    mpSim.dbSize = 0
    mpSim.isVirgin = true
    
    # Create the tables.
    sqliteCmd = string( "CREATE TABLE `", mpSim.persDBname, "`(",
        "\n    `", mpSim.idKey, "` VARCHAR(32) NOT NULL PRIMARY KEY,",
        "\n    timeEntered FLOAT,",
        "\n    timeExited FLOAT,",
        "\n    ageAtRecruitment FLOAT,",
        "\n    expectedAttritionTime FLOAT,",
        "\n    currentNode VARCHAR(64),",
        join( string.( "\n    `", collect( keys( mpSim.attributeList ) )
            , "` VARCHAR(64)," ) ),
        "\n    status VARCHAR(16) )" )
    DBInterface.execute( mpSim.simDB, sqliteCmd )

    sqliteCmd = string( "CREATE TABLE `", mpSim.transDBname, "`(",
        "\n    `", mpSim.idKey, "` VARCHAR(32),",
        "\n    timeIndex FLOAT,",
        "\n    transition VARCHAR(64),",
        "\n    sourceNode VARCHAR(64),",
        "\n    targetNode VARCHAR(64),",
        "\n    FOREIGN KEY (`", mpSim.idKey, "`) REFERENCES `",
        mpSim.persDBname, "`(`", mpSim.idKey, "`) )" )
    DBInterface.execute( mpSim.simDB, sqliteCmd )

    sqliteCmd = string( "CREATE TABLE `", mpSim.histDBname, "`(",
        "\n    `", mpSim.idKey, "` VARCHAR(32),",
        "\n    timeIndex FLOAT,",
        "\n    attribute VARCHAR(64),",
        "\n    value VARCHAR(64),",
        "\n    FOREIGN KEY (`", mpSim.idKey, "`) REFERENCES `",
        mpSim.persDBname, "`(`", mpSim.idKey, "`) )" )
    DBInterface.execute( mpSim.simDB, sqliteCmd )

    # Set database to new style.
    mpSim.isOldDB = false
    mpSim.sNode = "sourceNode"
    mpSim.tNode = "targetNode"
    mpSim.valName = "value"

    # Reset timers.
    mpSim.simExecTime = Millisecond( 0 )
    mpSim.attritionExecTime = Millisecond( 0 )

end  # resetSimulation( mpSim )