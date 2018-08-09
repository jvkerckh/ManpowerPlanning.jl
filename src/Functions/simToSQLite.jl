# This file holds the functions to save the configuration of a manpower
#   simulation to an SQLite database.

export saveSimConfigToDatabase


"""
```
saveSimConfigToDatabase( mpSim::ManpowerSimulation,
                         dbName::String,
                         configName::String = "config" )
```
This function stores the configuration parameters of the manpower simulation
`mpSim` in the database with filename `dbName`, in the table with name
`configName`. If the database filename doesn't have the proper extension,
`.sqlite`, it will be appended to the name.

This function returns `nothing`.
"""
function saveSimConfigToDatabase( mpSim::ManpowerSimulation, dbName::String,
    configName::String = "config" )::Void

    tmpDBname = ( dbName == "" ) || endswith( dbName, ".sqlite" ) ?
        dbName : dbName * ".sqlite"
    configDB = SQLite.DB( tmpDBname )

    createConfigTable( configName, configDB )

    command = "BEGIN TRANSACTION"
    SQLite.execute!( configDB, command )

    readGeneralParsFromSim( mpSim, configDB, configName )
    readAttributesFromSim( mpSim, configDB, configName )
    readStatesFromSim( mpSim, configDB, configName )
    readTransitionsFromSim( mpSim, configDB, configName )
    readRecruitmentFromSim( mpSim, configDB, configName )
    readAttritionFromSim( mpSim, configDB, configName )
    readRetirementFromSim( mpSim, configDB, configName )

    command = "COMMIT"
    SQLite.execute!( configDB, command )

    return

end  # saveSimConfigToDatabase( mpSim, dbName, configName )

"""
```
saveSimConfigToDatabase( mpSim::ManpowerSimulation )
```
This function stores the configuration parameters of the manpower simulation
`mpSim` in table `config` of the database defined in the simulation.

This function returns `nothing`.
"""
function saveSimConfigToDatabase( mpSim::ManpowerSimulation )::Void

    saveSimConfigToDatabase( mpSim, mpSim.dbName )

end  # saveSimConfigToDatabase( mpSim::ManpowerSimulation )


# ==============================================================================
# Non-exported methods.
# ==============================================================================


"""
```
readGeneralParsFromSim( mpSim::ManpowerSimulation,
                        configDB::SQLite.DB,
                        configName::String )
```
This function reads the general simulation parameters from the manpower
simulation `mpSim` and writes them to the SQLite database `configDB` in the
table with name `configName`.

This function returns `nothing`.
"""
function readGeneralParsFromSim( mpSim::ManpowerSimulation,
    configDB::SQLite.DB, configName::String )::Void

    # Name of the simulation database file.
    command = "INSERT INTO config
        (parName, parType, strPar1) VALUES
        ('dbName', 'General', '$(mpSim.dbName)')"
    SQLite.execute!( configDB, command )

    # Name of the simulation.
    simName = replace( mpSim.personnelDBname, "Personnel_", "", 1 )
    command = "INSERT INTO config
        (parName, parType, strPar1) VALUES
        ('simName', 'General', '$simName')"
    SQLite.execute!( configDB, command )

    # Personnel cap.
    command = "INSERT INTO config
        (parName, parType, intPar1) VALUES
        ('dbName', 'General', '$(mpSim.personnelTarget)')"
    SQLite.execute!( configDB, command )

    # Simulation length.
    simLength = mpSim.simLength / 12
    command = "INSERT INTO config
        (parName, parType, realPar1) VALUES
        ('dbName', 'General', '$simLength')"
    SQLite.execute!( configDB, command )

    # Database commits.
    dbCommits = Int( mpSim.simLength / mpSim.commitFrequency )
    command = "INSERT INTO config
        (parName, parType, intPar1) VALUES
        ('dbName', 'General', '$dbCommits')"
    SQLite.execute!( configDB, command )

    return

end  # readGeneralParsFromSim( mpSim, configDB, configName )


"""
```
readAttributesFromSim( mpSim::ManpowerSimulation,
                       configDB::SQLite.DB,
                       configName::String )
```
This function reads the personnel attributes from the manpower simulation
`mpSim` and writes them to the SQLite database `configDB` in the table with name
`configName`.

This function returns `nothing`.
"""
function readAttributesFromSim( mpSim::ManpowerSimulation,
    configDB::SQLite.DB, configName::String )::Void

    # Read every single attribute.
    foreach( attr -> saveAttrToDatabase( attr, configDB, configName ),
        vcat( mpSim.initAttrList, mpSim.otherAttrList ) )

    return

end  # readAttributesFromSim( mpSim, configDB, configName )


"""
```
readStatesFromSim( mpSim::ManpowerSimulation,
                   configDB::SQLite.DB,
                   configName::String )
```
This function reads the personnel states from the manpower simulation `mpSim`
and writes them to the SQLite database `configDB` in the table with name
`configName`.

This function returns `nothing`.
"""
function readStatesFromSim( mpSim::ManpowerSimulation,
    configDB::SQLite.DB, configName::String )::Void

    # Read every single state.
    foreach( state -> saveStateToDatabase( state, configDB, configName ),
        keys( mpSim.initStateList ) )
    foreach( state -> saveStateToDatabase( state, configDB, configName ),
        keys( mpSim.otherStateList ) )

    return

end  # readStatesFromSim( mpSim, configDB, configName )


"""
```
readTransitionsFromSim( mpSim::ManpowerSimulation,
                        configDB::SQLite.DB,
                        configName::String )
```
This function reads the state transitions from the manpower simulation `mpSim`
and writes them to the SQLite database `configDB` in the table with name
`configName`.

This function returns `nothing`.
"""
function readTransitionsFromSim( mpSim::ManpowerSimulation,
    configDB::SQLite.DB, configName::String )::Void

    # Read every single transition.
    for state in keys( mpSim.initStateList )
        foreach( trans -> saveTransitionToDatabase( trans, state.name,
            trans.endState.name, configDB, configName ),
            mpSim.initStateList[ state ] )
    end  # for state in keys( mpSim.initStateList )

    for state in keys( mpSim.otherStateList )
        foreach( trans -> saveTransitionToDatabase( trans, state.name,
            trans.endState.name, configDB, configName ),
            mpSim.otherStateList[ state ] )
    end  # for state in keys( mpSim.otherStateList )

    return

end  # readStatesFromSim( mpSim, configDB, configName )


"""
```
readRecruitmentFromSim( mpSim::ManpowerSimulation,
                        configDB::SQLite.DB,
                        configName::String )
```
This function reads the recruitment schemes from the manpower simulation
`mpSim` and writes them to the SQLite database `configDB` in the table with name
`configName`.

This function returns `nothing`.
"""
function readRecruitmentFromSim( mpSim::ManpowerSimulation,
    configDB::SQLite.DB, configName::String )::Void

    # Read every single recruitment scheme.
    foreach( recScheme -> saveRecruitmentToDatabase( recScheme, configDB,
        configName ), mpSim.recruitmentSchemes )

    return

end  # readRecruitmentFromSim( mpSim, configDB, configName )


"""
```
readAttritionFromSim( mpSim::ManpowerSimulation,
                      configDB::SQLite.DB,
                      configName::String )
```
This function reads the attrition parameters from the manpower simulation
`mpSim` and writes them to the SQLite database `configDB` in the table with name
`configName`.

This function returns `nothing`.
"""
function readAttritionFromSim( mpSim::ManpowerSimulation,
    configDB::SQLite.DB, configName::String )::Void

    # Only process if there is an attrition scheme.
    if mpSim.attritionScheme === nothing
        return
    end  # if mpSim.attritionScheme === nothing

    attrScheme = mpSim.attritionScheme
    saveAttritionToDatabase( attrScheme, configDB, configName )

    return

end  # readAttritionFromSim( mpSim, configDB, configName )


"""
```
readRetirementFromSim( mpSim::ManpowerSimulation,
                       configDB::SQLite.DB,
                       configName::String )
```
This function reads the retirement parameters from the manpower simulation
`mpSim` and writes them to the SQLite database `configDB` in the table with name
`configName`.

This function returns `nothing`.
"""
function readRetirementFromSim( mpSim::ManpowerSimulation,
    configDB::SQLite.DB, configName::String )::Void

    # Only process if there is a retirement scheme.
    if mpSim.retirementScheme === nothing
        return
    end  # if mpSim.retirementScheme === nothing

    retScheme = mpSim.retirementScheme

    command = "INSERT INTO $configName
        (parName, parType, boolPar1, strPar1) VALUES
        ('Retirement', 'Retirement', '$(retScheme.isEither)',
            '$(retScheme.maxCareerLength),$(retScheme.retireAge),$(retScheme.retireFreq),$(retScheme.retireOffset)')"
    SQLite.execute!( configDB, command )

    return

end  # readRetirementFromSim( mpSim, configDB, configName )
