function resetSimulation( mpSim::MPsim )

    mpSim.sim = Simulation()

    # Clear the "inNodeSince" from every node.
    for name in keys( mpSim.baseNodeList )
        node = mpSim.baseNodeList[ name ]
        empty!( node.inNodeSince )
    end

    # Wipe the tables if needed.
    SQLite.execute!( mpSim.simDB, string( "DROP TABLE IF EXISTS `",
        mpSim.histDBname, "`" ) )
    SQLite.execute!( mpSim.simDB, string( "DROP TABLE IF EXISTS `",
        mpSim.transDBname, "`" ) )
    SQLite.execute!( mpSim.simDB, string( "DROP TABLE IF EXISTS `",
        mpSim.persDBname, "`" ) )

    # Reset the population number of the simulation.
    mpSim.orgSize = 0
    mpSim.dbSize = 0
    
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
    SQLite.execute!( mpSim.simDB, sqliteCmd )

    sqliteCmd = string( "CREATE TABLE `", mpSim.transDBname, "`(",
        "\n    `", mpSim.idKey, "` VARCHAR(32),",
        "\n    timeIndex FLOAT,",
        "\n    transition VARCHAR(64),",
        "\n    sourceNode VARCHAR(64),",
        "\n    targetNode VARCHAR(64),",
        "\n    FOREIGN KEY (`", mpSim.idKey, "`) REFERENCES `",
        mpSim.persDBname, "`(`", mpSim.idKey, "`) )" )
    SQLite.execute!( mpSim.simDB, sqliteCmd )

    sqliteCmd = string( "CREATE TABLE `", mpSim.histDBname, "`(",
        "\n    `", mpSim.idKey, "` VARCHAR(32),",
        "\n    timeIndex FLOAT,",
        "\n    attribute VARCHAR(64),",
        "\n    value VARCHAR(64),",
        "\n    FOREIGN KEY (`", mpSim.idKey, "`) REFERENCES `",
        mpSim.persDBname, "`(`", mpSim.idKey, "`) )" )
    SQLite.execute!( mpSim.simDB, sqliteCmd )

    # Set database to new style.
    mpSim.isOldDB = false
    mpSim.sNode = "sourceNode"
    mpSim.tNode = "targetNode"

    # Reset timers.
    mpSim.simExecTime = Millisecond( 0 )
    mpSim.attritionExecTime = Millisecond( 0 )

end  # resetSimulation( mpSim )