# This file holds the functions to configure a manpower simulation from an
#   SQLite configuration database.

export configureSimFromDatabase


"""
```
configureSimFromDatabase( mpSim::ManpowerSimulation,
                          dbName::String,
                          overWriteResults:Bool = true;
                          configName::String = "config" )
```
This function configures the manpower simulation `mpSim` form the configuration
table with name `configName` in the SQLite database with filename `dbName`. If
the flag `overWriteResults` is set to `true`, the results of the previous
simulation, if any, will be wiped. If the database is missing the appropriate
extension, `.sqlite`, it will be appended to the name.

The function returns a `Bool`, indicating whether the configuration was
succesful or if the database was corrupted.
"""
function configureSimFromDatabase( mpSim::ManpowerSimulation, dbName::String,
    overwriteResults::Bool = true;
    configName::String = "config" )::Bool

    tmpDBname = dbName * ( endswith( dbName, ".sqlite" ) ? "" : ".sqlite" )

    # Check if the file exists.
    if !ispath( tmpDBname )
        error( "File '$tmpDBname' does not exist." )
    end  # if !ispath( tmpDBname )

    configDB = SQLite.DB( tmpDBname )

    # check if a configuration table exists.
    if configName ∉ SQLite.tables( configDB )[ :name ]
        error( "Database `$tmpDBname` does not contain a manpower simulation configuration." )
    end  # if configName ∉ SQLite.tables( configDB )[ :name ]

    # Get the general parameters
    try
        readGeneralParsFromDatabase( configDB, mpSim, configName )
        readAttributesFromDatabase( configDB, mpSim, configName )
        readAttritionFromDatabase( configDB, mpSim, configName )
        readStatesFromDatabase( configDB, mpSim, configName )
        readTransitionsFromDatabase( configDB, mpSim, configName )
        readRecruitmentFromDatabase( configDB, mpSim, configName )
        readRetirementFromDatabase( configDB, mpSim, configName )

        # Current sim time.
        queryCmd = "SELECT realPar FROM $configName WHERE parName IS 'Sim time'"
        currentTime = SQLite.query( configDB, queryCmd )[ 1, 1 ]

        # Wipe simulation results when requested, or advance the simulation to
        #   time in config file.
        if overwriteResults
            resetSimulation( mpSim )
        elseif currentTime < mpSim.simLength
            run( mpSim.sim, currentTime )
        else
            run( mpSim.sim )
        end  # if currentTime < simDB.simLength

        mpSim.isInitialised = true
        mpSim.isVirgin = now( mpSim ) == 0.0
    catch
        warn( "Configuration not properly read due to database corruption.\n" *
        "Simulation is not well configured and should not be executed." )
        return false
    end  # try

    return true

end  # configureSimFromDatabase( mpSim, dbName, configName )


# ==============================================================================
# Non-exported methods.
# ==============================================================================


"""
```
readGeneralParsFromDatabase( configDB::SQLite.DB,
                             mpSim::ManpowerSimulation,
                             configName::String )
```
This function reads the general simulation parameters from the SQLite database
`configDB`, looking in the table with name `configName`, and uses these
parameters to configure the manpower simulation `mpSim`.

This function returns `nothing`. If information is missing, the funuction will
issue warnings, or throw an error depending on the severity.
"""
function readGeneralParsFromDatabase( configDB::SQLite.DB,
    mpSim::ManpowerSimulation, configName::String )::Void

    queryCmd = "SELECT * FROM $configName
        WHERE parType IS 'General'"
    generalPars = SQLite.query( configDB, queryCmd )

    # Config file name.
    index = findfirst( generalPars[ :parName ], "Config file" )
    mpSim.parFileName = generalPars[ :strPar ][ index ]

    # Database name.
    index = findfirst( generalPars[ :parName ], "DB name" )
    mpSim.dbName = generalPars[ :strPar ][ index ]
    mpSim.simDB = SQLite.DB( mpSim.dbName )

    # This line ensures that foreign key logic works.
    SQLite.execute!( mpSim.simDB, "PRAGMA foreign_keys = ON" )

    # Catalogue name.
    index = findfirst( generalPars[ :parName ], "Catalogue name" )
    mpSim.catFileName = generalPars[ :strPar ][ index ]

    # Simulation name.
    index = findfirst( generalPars[ :parName ], "Sim name" )
    mpSim.simName = generalPars[ :strPar ][ index ]
    mpSim.personnelDBname = "Personnel_" * mpSim.simName
    mpSim.historyDBname = "History_" * mpSim.simName
    mpSim.transitionDBname = "Transitions_" * mpSim.simName

    # ID key.
    index = findfirst( generalPars[ :parName ], "ID key" )
    mpSim.idKey = generalPars[ :strPar ][ index ]

    # Personnel target.
    index = findfirst( generalPars[ :parName ], "Personnel target" )
    setPersonnelCap( mpSim, generalPars[ :intPar ][ index ] )

    # Start date.
    index = findfirst( generalPars[ :parName ], "Start date" )
    setSimStartDate( mpSim, Date( generalPars[ :strPar ][ index ] ) )

    # Sim length.
    index = findfirst( generalPars[ :parName ], "Sim length" )
    setSimulationLength( mpSim, generalPars[ :realPar ][ index ] )

    # Number of DB commits.
    index = findfirst( generalPars[ :parName ], "DB commits" )
    setDatabaseCommitTime( mpSim, mpSim.simLength /
        generalPars[ :intPar ][ index ] )

    return

end  # readGeneralParsFromDatabase( configDB, mpSim, configName )


"""
```
readAttributesFromDatabase( configDB::SQLite.DB,
                            mpSim::ManpowerSimulation,
                            configName::String )
```
This function reads the personnel attributes from the SQLite database
`configDB`, looking in the table with name `configName`, and uses these
parameters to configure the manpower simulation `mpSim`.

This function returns `nothing`. If information is missing, the funuction will
issue warnings, or throw an error depending on the severity.
"""
function readAttributesFromDatabase( configDB::SQLite.DB,
    mpSim::ManpowerSimulation, configName::String )::Void

    clearAttributes!( mpSim )
    queryCmd = "SELECT * FROM $configName
        WHERE parType IS 'Attribute'"
    attributes = SQLite.query( configDB, queryCmd )
    nAttrs = length( attributes[ :parName ] )

    for ii in 1:nAttrs
        newAttr = PersonnelAttribute( strip( attributes[ :parName ][ ii ] ) )

        # Is the attribute fixed?
        setFixed!( newAttr, parse( Bool, attributes[ :boolPar ][ ii ] ) )

        # Read the parameters stored as a string.
        attrPars = split( attributes[ :strPar ][ ii ], ";" )

        # Read the possible values the attribute can take.
        if attrPars[ 1 ] != "[]"
            possibleVals = map( val -> String( strip( val ) ),
                split( attrPars[ 1 ][ 2:(end - 1) ], "," ) )
            setPossibleValues!( newAttr, possibleVals )
        end  # if if attrPars[ 1 ] != "[]"

        # Read the initial values of the attribute with their respective
        #   generation probabilities.
        if attrPars[ 2 ] != "[]"
            initVals = split( attrPars[ 2 ][ 2:(end - 1) ], "," )
            initValDict = Dict{String, Float64}()

            for valPair in initVals
                valPair = split( valPair, ":" )
                initValDict[ strip( valPair[ 1 ] ) ] = parse( Float64,
                    valPair[ 2 ] )
            end  # for valPair in initVals

            setAttrValues!( newAttr, initValDict )
        end  # if attrPars[ 2 ] != "[]"

        addAttribute!( mpSim, newAttr )
    end  # for ii in 1:nAttrs

    return

end  # readAttributesFromDatabase( configDB, mpSim, configName )


"""
```
readAttritionFromDatabase( configDB::SQLite.DB,
                           mpSim::ManpowerSimulation,
                           configName::String )
```
This function reads the retirement parameters from the SQLite database
`configDB`, looking in the table with name `configName`, and uses these
parameters to configure the manpower simulation `mpSim`.

This function returns `nothing`. If information is missing, the funuction will
issue warnings, or throw an error depending on the severity.
"""
function readAttritionFromDatabase( configDB::SQLite.DB,
    mpSim::ManpowerSimulation, configName::String )::Void

    clearAttritionSchemes!( mpSim )
    queryCmd = "SELECT * FROM $configName
        WHERE parType IS 'Attrition'"
    attrList = SQLite.query( configDB, queryCmd )
    nSchemes = length( attrList[ :parName ] )
    isDefaultFound = false

    # If no attrition is in the database, set the attrition scheme to nothing
    #   and finish.
    if nSchemes == 0
        setAttrition( mpSim )
        return
    end  # if length( retirement ) == 0

    # Process attrition schemes.
    for ii in 1:nSchemes
        attrName = strip( attrList[ :parName ][ ii ] )
        newAttrScheme = Attrition( attrName )

        # Read attrition period.
        setAttritionPeriod( newAttrScheme, attrList[ :realPar ][ ii ] )

        # Read attrition curve.
        attrCurve = split( attrList[ :strPar ][ ii ], ";" )
        attrCurveDict = Dict{Float64, Float64}()

        for attrPair in attrCurve
            attrPair = split( attrPair, ":" )
            attrCurveDict[ parse( Float64, attrPair[ 1 ] ) ] = parse( Float64,
                attrPair[ 2 ] )
        end  # for attrPair in attrCurve

        setAttritionCurve( newAttrScheme, attrCurveDict )

        if attrName == "default"
            setAttrition( mpSim, newAttrScheme )
            isDefaultFound = true
        else
            addAttritionScheme!( newAttrScheme, mpSim )
        end  # if attrName == "default"
    end  # for ii in 1:nSchemes

    # Add a default attrition rate of 0% if there's no default in the database.
    if !isDefaultFound
        setAttrition( mpSim )
    end

    return

end  # readAttritionFromDatabase( configDB, mpSim, configName )


"""
```
readStatesFromDatabase( configDB::SQLite.DB,
                        mpSim::ManpowerSimulation,
                        configName::String )
```
This function reads the personnel states from the SQLite database `configDB`,
looking in the table with name `configName`, and uses these parameters to
configure the manpower simulation `mpSim`.

This function returns `nothing`. If information is missing, the function will
issue warnings, or throw an error depending on the severity.
"""
function readStatesFromDatabase( configDB::SQLite.DB,
    mpSim::ManpowerSimulation, configName::String )::Void

    clearStates!( mpSim )
    queryCmd = "SELECT * FROM $configName
        WHERE parType IS 'State'"
    states = SQLite.query( configDB, queryCmd )
    nStates = length( states[ :parName ] )

    for ii in 1:nStates
        newState = State( strip( states[ :parName ][ ii ] ) )
        setInitial!( newState, parse( Bool, states[ :boolPar ][ ii ] ) )
        setStateTarget!( newState, states[ :intPar ][ ii ] )
        setStateRetirementAge!( newState, states[ :realPar ][ ii ] )

        # Read all the parameters stored as string.
        statePars = split( states[ :strPar ][ ii ], ";" )

        # Read the state requirements.
        if statePars[ 1 ] != "[]"
            stateReqs = split( statePars[ 1 ][ 2:(end - 1) ], "," )

            for stateReq in stateReqs
                stateReq = split( stateReq, ":" )
                addRequirement!( newState, String( strip( stateReq[ 1 ] ) ),
                    map( val -> String( strip( val ) ),
                    split( stateReq[ 2 ], "//" ) ) )
            end  # for stateReq in stateReqs
        end  # if statePars[ 1 ] != "[]"

        # Read the state attrition regime.
        stateAttr = split( statePars[ 2 ], ":" )

        if length( stateAttr ) == 1
            schemeName = strip( stateAttr[ 1 ] )
            attrScheme = schemeName == "default" ?
                mpSim.defaultAttritionScheme :
                mpSim.attritionSchemes[ schemeName ]
            setStateAttritionScheme!( newState, attrScheme )
        elseif stateAttr[ 1 ] == "Attrition"
            # This one is necessary because generated attrition schemes start
            #   with "Attrition:".
            schemeName = join( stateAttr, ":" )
            attrScheme = mpSim.attritionSchemes[ schemeName ]
            setStateAttritionScheme!( newState, attrScheme )
        else
            setStateAttritionScheme!( newState,
                parse( Float64, stateAttr[ 2 ] ),
                parse( Float64, stateAttr[ 1 ] ), mpSim )
        end  # if length( stateAttr ) == 1

        addState!( mpSim, newState, newState.isInitial )
    end  # for ii in 1:nAttrs

    return

end  # readStatesFromDatabase( configDB, mpSim, configName )


"""
```
readTransitionsFromDatabase( configDB::SQLite.DB,
                             mpSim::ManpowerSimulation,
                             configName::String )
```
This function reads the state transitions from the SQLite database `configDB`,
looking in the table with name `configName`, and uses these parameters to
configure the manpower simulation `mpSim`.

This function returns `nothing`. If information is missing, the function will
issue warnings, or throw an error depending on the severity.
"""
function readTransitionsFromDatabase( configDB::SQLite.DB,
    mpSim::ManpowerSimulation, configName::String )::Void

    clearTransitions!( mpSim )
    queryCmd = "SELECT * FROM $configName
        WHERE parType IS 'Transition'"
    transitions = SQLite.query( configDB, queryCmd )
    nTrans = length( transitions[ :parName ] )
    stateList = collect( keys( merge( mpSim.initStateList,
        mpSim.otherStateList ) ) )

    for ii in 1:nTrans
        transPars = split( transitions[ :strPar ][ ii ], ";" )
        newTrans = Transition( strip( transitions[ :parName ][ ii ] ),
            mpSim.stateList[ strip( transPars[ 1 ] ) ],
            mpSim.stateList[ strip( transPars[ 2 ] ) ] )
        setFireAfterFail( newTrans, parse( Bool,
            transitions[ :boolPar ][ ii ] ) )
        setSchedule( newTrans, parse( Float64, transPars[ 3 ] ),
            parse( Float64, transPars[ 4 ] ) )

        # Read the extra conditions on the transition.
        if transPars[ 5 ] != "[]"
            conds = split( transPars[ 5 ][ 2:(end - 1) ], "," )

            for cond in conds
                condParts = split( cond, ":" )
                condVal = tryparse( Float64, condParts[ 3 ] )

                if condVal.hasvalue
                    condVal = condVal.value / 12.0
                else
                    condVal = replace( strip( String( condParts[ 3 ] ) ), "//",
                        "," )
                end  # if condVal.hasvalue

                newCond = processCondition( strip( String( condParts[ 1 ] ) ),
                    strip( String( condParts[ 2 ] ) ), condVal )
                addCondition!( newTrans, newCond[ 1 ] )
            end  # for cond in conds
        end  # if transPars[ 5 ] != "[]"

        # Read the extra changes of the transition.
        if transPars[ 6 ] != "[]"
            changes = split( transPars[ 6 ][ 2:(end - 1) ], "," )

            for change in changes
                change = split( change, ":" )
                addAttributeChange!( newTrans, String( change[ 1 ] ),
                    String( change[ 2 ] ) )
            end  # for change in changes
        end  # if transPars[ 6 ] != "[]"

        # Read the final parameters.
        probList = map( prob -> parse( Float64, prob ),
            split( transPars[ 7 ][ 2:(end - 1) ], "," ) )
        setTransProbabilities( newTrans, probList )
        setMaxAttempts( newTrans, parse( Int, transPars[ 8 ] ) )
        setMaxFlux( newTrans, parse( Int, transPars[ 9 ] ) )
        addTransition!( mpSim, newTrans )
    end  # for ii in 1:nTrans

    return

end  # readTransitionsFromDatabase( configDB, mpSim, configName )


"""
```
readRecruitmentFromDatabase( configDB::SQLite.DB,
                             mpSim::ManpowerSimulation,
                             configName::String )
```
This function reads the recruitment schemes from the SQLite database
`configDB`, looking in the table with name `configName`, and uses these
parameters to configure the manpower simulation `mpSim`.

This function returns `nothing`. If information is missing, the function will
issue warnings, or throw an error depending on the severity.
"""
function readRecruitmentFromDatabase( configDB::SQLite.DB,
    mpSim::ManpowerSimulation, configName::String )::Void

    clearRecruitmentSchemes!( mpSim )
    queryCmd = "SELECT * FROM $configName
        WHERE parType IS 'Recruitment'"
    recruitment = SQLite.query( configDB, queryCmd )
    numSchemes = length( recruitment[ :parName ] )

    # If no recruitment schemes are in the database, do nothing.
    if numSchemes == 0
        return
    end  # if numSchemes == 0

    for ii in 1:numSchemes
        recScheme = Recruitment( recruitment[ :parName ][ ii ], 1 )
        recPars = split( recruitment[ :strPar ][ ii ], ";" )
        setRecruitmentSchedule( recScheme, parse( Float64, recPars[ 1 ] ),
            parse( Float64, recPars[ 2 ] ) )
        setRecruitState( recScheme, String( strip( recPars[ 3 ] ) ) )

        # Read the distribution of the number of people to recruit.
        if parse( Bool, recruitment[ :boolPar ][ ii ] )
            setRecruitmentLimits( recScheme, parse( Int, recPars[ 4 ] ),
                parse( Int, recPars[ 5 ] ) )
        else
            distType = Symbol( strip( recPars[ 4 ] ) )
            distNodes = split( recPars[ 5 ][ 2:(end - 1) ], "," )
            distNodesDict = Dict{Int, Float64}()

            for node in distNodes
                node = split( node, ":" )
                distNodesDict[ parse( Float64, node[ 1 ] ) ] =
                    parse( Float64, node[ 2 ] )
            end  # for node in distNodes

            setRecruitmentDistribution( recScheme, distNodesDict, distType )
        end  # if isAdaptive

        ageDistType = Symbol( strip( recPars[ 6 ] ) )
        ageDistNodes = split( recPars[ 7 ][ 2:(end - 1) ], "," )
        ageDistNodesDict = Dict{Float64, Float64}()

        for node in ageDistNodes
            node = split( node, ":" )
            ageDistNodesDict[ parse( Float64, node[ 1 ] ) ] =
                parse( Float64, node[ 2 ] )
        end  # for node in distNodes

        setAgeDistribution( recScheme, ageDistNodesDict, ageDistType )
        addRecruitmentScheme!( mpSim, recScheme )
    end  # for ii in 1:numSchemes

    return

end  # readRecruitmentFromDatabase( configDB, mpSim, configName )


"""
```
readRetirementFromDatabase( configDB::SQLite.DB,
                            mpSim::ManpowerSimulation,
                            configName::String )
```
This function reads the retirement parameters from the SQLite database
`configDB`, looking in the table with name `configName`, and uses these
parameters to configure the manpower simulation `mpSim`.

This function returns `nothing`. If information is missing, the funuction will
issue warnings, or throw an error depending on the severity.
"""
function readRetirementFromDatabase( configDB::SQLite.DB,
    mpSim::ManpowerSimulation, configName::String )::Void

    queryCmd = "SELECT * FROM $configName
        WHERE parType IS 'Retirement' AND parName IS 'Retirement'"
    retirement = SQLite.query( configDB, queryCmd )

    # If no retirement is in the database, set the retirement scheme to nothing
    #   and finish.
    if length( retirement ) == 0
        setRetirement( mpSim )
        return
    end  # if length( retirement ) == 0

    retScheme = Retirement( isEither = parse( Bool,
        retirement[ :boolPar ][ 1 ] ) )

    retPars = split( retirement[ :strPar ][ 1 ], ";" )
    setCareerLength( retScheme, parse( Float64, retPars[ 1 ] ) )
    setRetirementAge( retScheme, parse( Float64, retPars[ 2 ] ) )
    setRetirementSchedule( retScheme, parse( Float64, retPars[ 3 ] ),
        parse( Float64, retPars[ 4 ] ) )
    setRetirement( mpSim, retScheme )

    return

end  # readRetirementFromDatabase( configDB, mpSim, configName )
