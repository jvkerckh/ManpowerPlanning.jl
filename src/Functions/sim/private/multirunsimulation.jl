function initialiseMRSresultsDatabase!( mrs::MRS )
    # Clear database.
    if haskey( SQLite.tables( mrs.resultsDB ), :name )
        tablesToDelete = SQLite.tables( mrs.resultsDB ).name
        filter!( tname -> tname ∉ [mrs.mpSim.persDBname, mrs.mpSim.histDBname,
            mrs.mpSim.transDBname], tablesToDelete )
        DBInterface.execute( mrs.resultsDB, "BEGIN TRANSACTION" )
        sqliteCmd = string.( "DROP TABLE `", tablesToDelete, "`" )
        DBInterface.execute.( Ref(mrs.resultsDB), sqliteCmd )
        DBInterface.execute( mrs.resultsDB, "COMMIT" )
    end  # if !isempty( SQLite.tables( mrs.resultsDB ) )

    saveSimulationConfiguration( mrs.mpSim, mrs.resultsDB.file )

    sqliteCmd = string( "CREATE TABLE simokay(",
        "\n    simID TEXT )" )
    DBInterface.execute( mrs.resultsDB, sqliteCmd )
end  # initialiseMRSresultsDatabase!( mrs )


function copySnapshots( mrs::MRS, tmpFolder::String )
    tStart = now()

    for ii in 1:mrs.nRuns
        tmpname = joinpath( tmpFolder, string( "tmp", ii, ".sqlite" ) )
        cp( mrs.resultsDB.file, tmpname, force=true )
        newDB = SQLite.DB(tmpname)
        DBInterface.execute( newDB, "DROP TABLE config" )
        DBInterface.execute( newDB, "DROP TABLE simokay" )

        tablenames = SQLite.tables(newDB).name
        DBInterface.execute.( Ref(newDB), string.( "ALTER TABLE `", tablenames,
            "` RENAME TO ", tablenames, ii ) )
    end  # for ii in 1:mrs.nRuns

    tElapsed = ( now() - tStart ).value / 1000.0
    mrs.showInfo && @info string( "Initialising individual databases with start populations took ", tElapsed, " seconds." )
end  # copySnapshots( mrs, tmpFolder )

function copySnapshots( mrs::MRS, tmpFolder::String, nThreads::Int )
    tStart = now()

    for ii in 1:nThreads
        tmpname = joinpath( tmpFolder, string( "tmp", ii, ".sqlite" ) )
        cp( mrs.resultsDB.file, tmpname, force=true )
        newDB = SQLite.DB(tmpname)
        DBInterface.execute( newDB, "DROP TABLE config" )
        DBInterface.execute( newDB, "DROP TABLE simokay" )
    end  # for ii in 1:nThreads

    tElapsed = ( now() - tStart ).value / 1000.0
    mrs.showInfo && @info string( "Initialising temporary databases with start populations took ", tElapsed, " seconds." )
end  # copySnapshots( mrs, tmpFolder, nThreads )


function runsim( mrs::MRS, currentSim::Channel{Int},
    resultsFree::Channel{Bool}, tmpFolder::String )
    n = 0

    while ( ( n = take!( currentSim ) ) <= mrs.nRuns )
        tStart = now()
        put!( currentSim, n + 1 )

        tmpSim = deepcopy( mrs.mpSim )
        GC.gc()
        setSimulationName!( tmpSim, string( tmpSim.simName, n ) )
        setSimulationDatabase!( tmpSim,
            joinpath( tmpFolder, string( "tmp", n ) ) )
        run( tmpSim, saveConfig=false )

        # Copy the results to the main database right away.
        copyRunResult( mrs, tmpSim, resultsFree )
        mrs.nComplete += 1
        tElapsed = ( now() - tStart ).value / 1000.0
        mrs.showInfo && @info string( "Simulation ", mrs.nComplete, " of ",
            mrs.nRuns, " completed after ", tElapsed, " seconds." )
    end  # while ( ( n = take!( currentSim ) ) <= mrs.nRuns )

    put!( currentSim, n )
end  # runsim( mrs, currentSim, resultsFree, tmpFolder )

function runsim( mrs::MRS, threadnum::Int, hasSnapshot::Bool,
    currentSim::Channel{Int}, tmpFolder::String, nThreads::Int )
    tmpSim = deepcopy(mrs.mpSim)
    setSimulationDatabase!( tmpSim,
        joinpath( tmpFolder, string( "tmp", threadnum ) ) )
    DBInterface.execute( tmpSim.simDB,
        "CREATE TABLE inventory( repnr INTEGER )" )

    baseName = tmpSim.simName
    baseNames = (tmpSim.persDBname, tmpSim.transDBname, tmpSim.histDBname)
    n = 0

    while ( ( n = take!(currentSim) ) <= mrs.nRuns )
        tStart = now()
        put!( currentSim, n + 1 )

        setSimulationName!( tmpSim, string( baseName, n ) )
        hasSnapshot && copySnapshot( tmpSim, baseNames )
        run( tmpSim, saveConfig=false, nCommits=nThreads )
        sqliteCmd = string( "INSERT INTO inventory( repnr ) VALUES (", n, ")" )
        DBInterface.execute( tmpSim.simDB, sqliteCmd )

        # Copy the results to the main database right away.
        mrs.nComplete += 1
        tElapsed = ( now() - tStart ).value / 1000.0
        mrs.showInfo && @info string( "Simulation ", mrs.nComplete, " of ",
            mrs.nRuns, " completed after ", tElapsed, " seconds." )
        # GC.gc()
    end  # while ( ( n = take!(currentSim) ) <= mrs.nRuns )

    put!( currentSim, n )
end  # runsim( mrs, threadnum, hasSnapshot, currentSim, tmpFolder, nThreads )


function copySnapshot( mpSim::MPsim, baseNames::NTuple{3,String} )
    newNames = (mpSim.persDBname, mpSim.transDBname, mpSim.histDBname)

    # sqliteCmds = string.( "CREATE TABLE `", newNames, "` LIKE `",
    #     baseNames, "`" )
    DBInterface.execute.( Ref(mpSim.simDB), generateTable.( newNames,
        Ref(newNames[1]), Ref(mpSim), (:pers, :trans, :hist) ) )

    sqliteCmds = string.( "INSERT INTO `", newNames, "` SELECT * FROM `",
        baseNames, "`" )
    DBInterface.execute.( Ref(mpSim.simDB), sqliteCmds )
end  # copySnapshot( sim, baseNames )


function copyResults( mrs::MRS, tmpFolder::String )
    tmpDBs = joinpath.( tmpFolder, readdir(tmpFolder) )
    
    for tmpDBname in tmpDBs
        tmpDB = SQLite.DB(tmpDBname)

        # Attach temporary database.
        sqliteCmd = string( "ATTACH '", tmpDBname, "' AS origin" )
        DBInterface.execute( mrs.resultsDB, sqliteCmd )
        DBInterface.execute( mrs.resultsDB, "BEGIN TRANSACTION" )

        simNrs = DataFrame(DBInterface.execute( tmpDB,
            "SELECT repnr FROM inventory"))[!, :repnr]
        tableNames = (mrs.mpSim.persDBname, mrs.mpSim.transDBname,
            mrs.mpSim.histDBname)
        copyResults.( Ref(mrs), simNrs, Ref(tableNames) )

        # Detach temporary database.
        DBInterface.execute( mrs.resultsDB, "COMMIT" )
        DBInterface.execute( mrs.resultsDB, "DETACH origin" )

    end  # for tmpDB in tmpDBs
end  # copyResults( mrs, tmpFolder )

function copyResults( mrs::MRS, simNr::Int, tableNames::NTuple{3,String} )
    mpSim = mrs.mpSim
    tmpNames = string.( tableNames, simNr )

    # Remove tables if needed.
    # sqliteCmds = string.( "DROP TABLE IF EXISTS `", tmpNames, "`" )
    # DBInterface.execute.( Ref(mrs.resultsDB), sqliteCmds )

    # Create tables.
    DBInterface.execute.( Ref(mrs.resultsDB), generateTable.( tmpNames,
        Ref(tmpNames[1]), Ref(mpSim), (:pers, :trans, :hist) ) )
#=
    sqliteCmd = string( "CREATE TABLE `", tmpNames[1], "`(",
        "\n    `", mpSim.idKey, "` TEXT NOT NULL PRIMARY KEY,",
        "\n    timeEntered REAL,",
        "\n    timeExited REAL,",
        "\n    ageAtRecruitment REAL,",
        "\n    expectedAttritionTime REAL,",
        "\n    currentNode TEXT,",
        join( string.( "\n    `", collect( keys( mpSim.attributeList ) )
            , "` TEXT," ) ),
        "\n    status TEXT )" )
    DBInterface.execute( mrs.resultsDB, sqliteCmd )

    sqliteCmd = string( "CREATE TABLE `", tmpNames[2], "`(",
        "\n    `", mpSim.idKey, "` TEXT,",
        "\n    timeIndex REAL,",
        "\n    transition TEXT,",
        "\n    sourceNode TEXT,",
        "\n    targetNode TEXT,",
        "\n    FOREIGN KEY (`", mpSim.idKey, "`) REFERENCES `",
        mpSim.persDBname, "`(`", mpSim.idKey, "`) )" )
    DBInterface.execute( mrs.resultsDB, sqliteCmd )

    sqliteCmd = string( "CREATE TABLE `", tmpNames[3], "`(",
        "\n    `", mpSim.idKey, "` TEXT,",
        "\n    timeIndex REAL,",
        "\n    attribute TEXT,",
        "\n    value TEXT,",
        "\n    FOREIGN KEY (`", mpSim.idKey, "`) REFERENCES `",
        mpSim.persDBname, "`(`", mpSim.idKey, "`) )" )
    DBInterface.execute( mrs.resultsDB, sqliteCmd )
=#
    # Copy results to main database.
    sqliteCmds = string.( "INSERT INTO `", tmpNames, "`",
        "\n    SELECT * FROM origin.`", tmpNames, "`" )
    DBInterface.execute.( Ref(mrs.resultsDB), sqliteCmds )
end  # copyResults( mrs, simNr, tableNames )


function copyRunResult( mrs::MRS, mpSim::MPsim, resultsFree::Channel{Bool} )
    take!( resultsFree )

    # Link simulation result database.
    sqliteCmd = string( "ATTACH '", mpSim.simDB.file, "' AS origin" )
    DBInterface.execute( mrs.resultsDB, sqliteCmd )

    # Create the tables.
    tableNames = (mpSim.persDBname, mpSim.transDBname, mpSim.histDBname)
    DBInterface.execute.( Ref(mrs.resultsDB), generateTable.( tableNames,
        Ref(tableNames[1]), Ref(mpSim), (:pers, :trans, :hist) ) )

    # Copy results to main database.
    sqliteCmds = string.( "INSERT INTO `", tableNames, "`",
        "\n    SELECT * FROM origin.`", tableNames, "`" )
    DBInterface.execute.( Ref(mrs.resultsDB), sqliteCmds )

    # Unlink simulation result database.
    DBInterface.execute( mrs.resultsDB, "DETACH origin" )

    # Checking off sim completion.
    sqliteCmd = string( "INSERT INTO simokay VALUES ('", mpSim.simName, "')" )
    DBInterface.execute( mrs.resultsDB, sqliteCmd )
    put!( resultsFree, true )
end  # copyRunResult( mrs, mpSim, resultsFree )

function generateTable( tableName::String, persName::String, mpSim::MPsim,
    type::Symbol )
    if type === :pers
        sqliteCmd = string( "CREATE TABLE `", tableName, "`(",
            "\n    `", mpSim.idKey, "` TEXT NOT NULL PRIMARY KEY,",
            "\n    timeEntered REAL,",
            "\n    timeExited REAL,",
            "\n    ageAtRecruitment REAL,",
            "\n    expectedAttritionTime REAL,",
            "\n    currentNode TEXT,",
            "\n    inNodeSince REAL,",
            join( string.( "\n    `", collect( keys( mpSim.attributeList ) )
                , "` TEXT," ) ),
            "\n    status TEXT )" )
    elseif type === :trans
        sqliteCmd = string( "CREATE TABLE `", tableName, "`(",
            "\n    `", mpSim.idKey, "` TEXT,",
            "\n    timeIndex REAL,",
            "\n    transition TEXT,",
            "\n    sourceNode TEXT,",
            "\n    targetNode TEXT,",
            "\n    FOREIGN KEY (`", mpSim.idKey, "`) REFERENCES `",
            persName, "`(`", mpSim.idKey, "`) )" )
    elseif type === :hist
        sqliteCmd = string( "CREATE TABLE `", tableName, "`(",
            "\n    `", mpSim.idKey, "` TEXT,",
            "\n    timeIndex REAL,",
            "\n    attribute TEXT,",
            "\n    value TEXT,",
            "\n    FOREIGN KEY (`", mpSim.idKey, "`) REFERENCES `",
            persName, "`(`", mpSim.idKey, "`) )" )
    end

    sqliteCmd
end  # generateTable( tableName, persName, type, mpSim )