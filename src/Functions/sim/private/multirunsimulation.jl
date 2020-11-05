function initialiseMRSresultsDatabase!( mrs::MRS )
    # Clear database.
    if !isempty( SQLite.tables( mrs.resultsDB ) )
        DBInterface.execute( mrs.resultsDB, "BEGIN TRANSACTION" )
        sqliteCmd = string.( "DROP TABLE `",
            SQLite.tables( mrs.resultsDB ).name, "`" )
        DBInterface.execute.( Ref(mrs.resultsDB), sqliteCmd )
        DBInterface.execute( mrs.resultsDB, "COMMIT" )
    end  # if !isempty( SQLite.tables( mrs.resultsDB ) )

    saveSimulationConfiguration( mrs.mpSim, mrs.resultsDB.file )

    sqliteCmd = string( "CREATE TABLE simokay (",
        "\n    simID VARCHAR(32)",
        ")" )
    DBInterface.execute( mrs.resultsDB, sqliteCmd )
end  # initialiseMRSresultsDatabase!( mrs )


function runsim( mrs::MRS, currentSim::Channel{Int},
    resultsFree::Channel{Bool}, tmpFolder::String )
    n = 0

    while ( ( n = take!( currentSim ) ) <= mrs.nRuns )
        put!( currentSim, n + 1 )

        tmpSim = deepcopy( mrs.mpSim )
        setSimulationName!( tmpSim, string( tmpSim.simName, n ) )
        setSimulationDatabase!( tmpSim,
            joinpath( tmpFolder, string( "tmp", n ) ) )
        run( tmpSim, saveConfig=false )

        # Copy the results to the main database right away.
        copyRunResult( mrs, tmpSim, resultsFree )
    end  # while ( ( n = take!( currentSim ) ) <= mrs.nRuns )

    put!( currentSim, n )
end  # runsim( mrs, currentSim, resultsFree, tmpFolder )


function copyRunResult( mrs::MRS, mpSim::MPsim, resultsFree::Channel{Bool} )
    take!( resultsFree )
    tmpDBname = mpSim.simDB.file
    setSimulationDatabase!( mpSim, mrs.resultsDB.file )

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

    # Link simulation result database.
    sqliteCmd = string( "ATTACH '", tmpDBname, "' AS origin" )
    DBInterface.execute( mpSim.simDB, sqliteCmd )

    # Copy results to main database.
    sqliteCmd = string( "INSERT INTO `", mpSim.persDBname, "`",
        "\n    SELECT * FROM origin.`", mpSim.persDBname, "`" )
    DBInterface.execute( mpSim.simDB, sqliteCmd )

    sqliteCmd = string( "INSERT INTO `", mpSim.transDBname, "`",
        "\n    SELECT * FROM origin.`", mpSim.transDBname, "`" )
    DBInterface.execute( mpSim.simDB, sqliteCmd )

    sqliteCmd = string( "INSERT INTO `", mpSim.histDBname, "`",
        "\n    SELECT * FROM origin.`", mpSim.histDBname, "`" )
    DBInterface.execute( mpSim.simDB, sqliteCmd )

    # Unlink simulation result database.
    DBInterface.execute( mpSim.simDB, "DETACH origin" )

    # Checking off sim completion.
    sqliteCmd = string( "INSERT INTO simokay VALUES ('", mpSim.simName, "')" )
    DBInterface.execute( mpSim.simDB, sqliteCmd )
    put!( resultsFree, true )
end  # copyRunResult( mrs, mpSim )


function copyRunResult( mrs::MRS, ii::Integer, tmpFolder::String )
    mpSim = mrs.mpSim
    persDBname = string( mpSim.persDBname, ii )
    transDBname = string( mpSim.transDBname, ii )
    histDBname = string( mpSim.histDBname, ii )

    # Create the tables.
    sqliteCmd = string( "CREATE TABLE `", persDBname, "`(",
        "\n    `", mpSim.idKey, "` VARCHAR(32) NOT NULL PRIMARY KEY,",
        "\n    timeEntered FLOAT,",
        "\n    timeExited FLOAT,",
        "\n    ageAtRecruitment FLOAT,",
        "\n    expectedAttritionTime FLOAT,",
        "\n    currentNode VARCHAR(64),",
        join( string.( "\n    `", collect( keys( mpSim.attributeList ) )
            , "` VARCHAR(64)," ) ),
        "\n    status VARCHAR(16) )" )
    DBInterface.execute( mrs.resultsDB, sqliteCmd )

    sqliteCmd = string( "CREATE TABLE `", transDBname, "`(",
        "\n    `", mpSim.idKey, "` VARCHAR(32),",
        "\n    timeIndex FLOAT,",
        "\n    transition VARCHAR(64),",
        "\n    sourceNode VARCHAR(64),",
        "\n    targetNode VARCHAR(64),",
        "\n    FOREIGN KEY (`", mpSim.idKey, "`) REFERENCES `",
        mpSim.persDBname, "`(`", mpSim.idKey, "`) )" )
    DBInterface.execute( mrs.resultsDB, sqliteCmd )

    sqliteCmd = string( "CREATE TABLE `", histDBname, "`(",
        "\n    `", mpSim.idKey, "` VARCHAR(32),",
        "\n    timeIndex FLOAT,",
        "\n    attribute VARCHAR(64),",
        "\n    value VARCHAR(64),",
        "\n    FOREIGN KEY (`", mpSim.idKey, "`) REFERENCES `",
        mpSim.persDBname, "`(`", mpSim.idKey, "`) )" )
    DBInterface.execute( mrs.resultsDB, sqliteCmd )

    # Link simulation result database.
    sqliteCmd = string( "ATTACH '", tmpFolder, "/tmp", ii,
        ".sqlite' AS origin" )
    DBInterface.execute( mrs.resultsDB, sqliteCmd )

    # Copy results to main database.
    sqliteCmd = string( "INSERT INTO `", persDBname, "`",
        "\n    SELECT * FROM origin.`", persDBname, "`" )
    DBInterface.execute( mrs.resultsDB, sqliteCmd )

    sqliteCmd = string( "INSERT INTO `", transDBname, "`",
        "\n    SELECT * FROM origin.`", transDBname, "`" )
    DBInterface.execute( mrs.resultsDB, sqliteCmd )

    sqliteCmd = string( "INSERT INTO `", histDBname, "`",
        "\n    SELECT * FROM origin.`", histDBname, "`" )
    DBInterface.execute( mrs.resultsDB, sqliteCmd )

    # Unlink simulation result database.
    DBInterface.execute( mrs.resultsDB, "DETACH origin" )
end  # copyRunResult( mrs, ii )