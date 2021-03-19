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


setSimulationDBcommits!( mpSim::MPsim, nCommits::Integer ) =
    ( mpSim.nCommits = nCommits )


function wipeDatabase( mpSim::MPsim )

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
    DBInterface.execute( mpSim.simDB, sqliteCmd )

    sqliteCmd = string( "CREATE TABLE `", mpSim.transDBname, "`(",
        "\n    `", mpSim.idKey, "` TEXT,",
        "\n    timeIndex REAL,",
        "\n    transition TEXT,",
        "\n    sourceNode TEXT,",
        "\n    targetNode TEXT,",
        "\n    FOREIGN KEY (`", mpSim.idKey, "`) REFERENCES `",
        mpSim.persDBname, "`(`", mpSim.idKey, "`) )" )
    DBInterface.execute( mpSim.simDB, sqliteCmd )

    sqliteCmd = string( "CREATE TABLE `", mpSim.histDBname, "`(",
        "\n    `", mpSim.idKey, "` TEXT,",
        "\n    timeIndex REAL,",
        "\n    attribute TEXT,",
        "\n    value TEXT,",
        "\n    FOREIGN KEY (`", mpSim.idKey, "`) REFERENCES `",
        mpSim.persDBname, "`(`", mpSim.idKey, "`) )" )
    DBInterface.execute( mpSim.simDB, sqliteCmd )

end  # wipeDatabase( mpSim )

function wipeDatabase( mpSim::MPsim, snapshotIDs::Vector{String} )

    # Reset the population number of the simulation.
    mpSim.orgSize = length(snapshotIDs)
    mpSim.dbSize = length(snapshotIDs)
    mpSim.isVirgin = false

    # Reset the tables.
    sqliteCmd = string( "DELETE FROM `", mpSim.transDBname,
        "` WHERE transition IS NOT 'Init'" )
    DBInterface.execute( mpSim.simDB, sqliteCmd )

    sqliteCmd = string( "DELETE FROM `", mpSim.histDBname,
        "` WHERE timeIndex > 0 OR `", mpSim.idKey, "` NOT IN ('",
        join( snapshotIDs, "', '" ), "')" )
    DBInterface.execute( mpSim.simDB, sqliteCmd )

    sqliteCmd = string( "DELETE FROM `", mpSim.persDBname,
        "` WHERE `", mpSim.idKey, "` NOT IN ('", join( snapshotIDs, "', '" ),
        "')" )
    DBInterface.execute( mpSim.simDB, sqliteCmd )

    # Set the "inNodeSince" for every node.
    queryCmd = string( "SELECT `", mpSim.idKey,
        "`, timeIndex, targetNode FROM `", mpSim.transDBname, "`" )
    inNodeInfo = DataFrame(DBInterface.execute( mpSim.simDB, queryCmd ))

    for ii in 1:size( inNodeInfo, 1 )
        node = mpSim.baseNodeList[inNodeInfo[ii, "targetNode"]]
        node.inNodeSince[inNodeInfo[ii, mpSim.idKey]] =
            inNodeInfo[ii, "timeIndex"]
    end  # for ii in 1:size( inNodeInfo, 1 )

end  # wipeDatabase( mpSim, snapshotIDs )


function resetSimulation( mpSim::MPsim, keepSnap::Bool=true )

    mpSim.sim = Simulation()

    snapshotIDs = Vector{String}()
    dbtables = SQLite.tables(mpSim.simDB)

    if keepSnap && haskey( dbtables, :name ) &&
        ( [mpSim.persDBname, mpSim.histDBname, mpSim.transDBname] ⊆
            dbtables.name )
        queryCmd = string( "SELECT `", mpSim.idKey, "` FROM `",
            mpSim.transDBname, "` WHERE transition IS 'Init'" )
        snapshotIDs = DataFrame(DBInterface.execute( mpSim.simDB,
            queryCmd ))[!, 1]
    end  # if haskey( dbtables, :name ) && ...

    # Clear the "inNodeSince" from every node.
    for name in keys( mpSim.baseNodeList )
        node = mpSim.baseNodeList[name]
        empty!( node.inNodeSince )
    end  # for name in keys( mpSim.baseNodeList )

    isempty(snapshotIDs) ? wipeDatabase(mpSim) :
        wipeDatabase( mpSim, snapshotIDs )

    # Set database to new style.
    mpSim.isOldDB = false
    mpSim.sNode = "sourceNode"
    mpSim.tNode = "targetNode"
    mpSim.valName = "value"

    # Reset timers.
    mpSim.simExecTime = Millisecond( 0 )
    mpSim.attritionExecTime = Millisecond( 0 )

end  # resetSimulation( mpSim )