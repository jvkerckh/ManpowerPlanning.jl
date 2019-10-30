function wipeConfigTable( mpSim::MPsim )

    SQLite.execute!( mpSim.simDB, "DROP TABLE IF EXISTS config" )
    sqliteCmd = string( "CREATE TABLE config(",
        "\n    parName VARCHAR(32),",
        "\n    parType VARCHAR(32),",
        "\n    parValue TEXT )" )
    SQLite.execute!( mpSim.simDB, sqliteCmd )
    return

end  # wipeConfigTable( mpSim )


function storeGeneralPars( mpSim::MPsim )

    sqliteCmd = string( "INSERT INTO config ( parName, parType, parValue )",
        " VALUES",
        "\n    ('Sim name', 'General', '", mpSim.simName, "'),",
        "\n    ('ID key', 'General', '", mpSim.idKey, "'),",
        "\n    ('Personnel target', 'General', '", mpSim.personnelTarget, "'),",
        "\n    ('Sim length', 'General', '", mpSim.simLength, "'),",
        "\n    ('Current time', 'General', '", now( mpSim ), "'),",
        "\n    ('DB commits', 'General', '", mpSim.nCommits, "')" )
    SQLite.execute!( mpSim.simDB, sqliteCmd )
    return

end  # storeGeneralPars( mpSim )