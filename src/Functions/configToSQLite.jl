# This file holds all the functions necessary to save a system configuration to
#   the SQLite database.


export saveSimConfigToDatabase,
       readParFileToDatabase


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

    SQLite.execute!( configDB, "BEGIN TRANSACTION" )

    # try
        readGeneralParsFromSim( mpSim, configDB, configName )
        readAttributesFromSim( mpSim, configDB, configName )
        readAttritionFromSim( mpSim, configDB, configName )
        readStatesFromSim( mpSim, configDB, configName )
        readCompoundStatesFromSim( mpSim, configDB, configName )
        readTransTypesFromSim( mpSim, configDB, configName )
        readTransitionsFromSim( mpSim, configDB, configName )
        readRecruitmentFromSim( mpSim, configDB, configName )
    # catch errType
    #     command = "COMMIT"
    #     SQLite.execute!( configDB, command )
    #     error( errType )
    # end

    SQLite.execute!( configDB, "COMMIT" )

    return

end  # saveSimConfigToDatabase( mpSim, dbName, configName )


"""
```
readParFileToDatabase( fileName::String,
                       dbName::String,
                       configName::String = "config" )
```
This function reads the Excel file with filename `fileName`, processes the
parameters, and stores them in the `config` of the SQLite database with filename
`dbName`. If these filenames do not have the proper extension, `.xlsx` for the
Excel and `.sqlite` for the database, it will be apended to the name.

This function returns `nothing`. If the Excel file doesn't exist, this function
will throw an error.
"""
function readParFileToDatabase( fileName::String, dbName::String,
    configName::String = "config" )::Void

    newMPsim = ManpowerSimulation( fileName )
    saveSimConfigToDatabase( newMPsim, dbName, configName )
    return

end  # readParFileToDatabase( fileName, dbName )


# ==============================================================================
# Non-exported methods.
# ==============================================================================

relationEntries = Dict{Function, String}( Base.:(==) => "IS",
    Base.:(!=) => "IS NOT", Base.:∈ => "IN", Base.:∉ => "NOT IN",
    Base.:> => ">", Base.:(>=) => ">=", Base.:< => "<", Base.:(<=) => "<=" )


function createConfigTable( configName::String, configDB::SQLite.DB )::Void

    SQLite.drop!( configDB, configName, ifexists = true )
    command = "CREATE TABLE `$configName`(
        parName VARCHAR( 32 ),
        parType VARCHAR( 32 ),
        intPar MEDIUMINT,
        realPar FLOAT,
        boolPar VARCHAR( 5 ),
        strPar TEXT
    )"
    SQLite.execute!( configDB, command )

    return

end  # createConfigTable( configName, configDB )


function readGeneralParsFromSim( mpSim::ManpowerSimulation,
    configDB::SQLite.DB, configName::String )::Void

    dbCommits = Int( mpSim.simLength / mpSim.commitFrequency )
    command = "INSERT INTO `$configName`
        (parName, parType, intPar, realPar, strPar) VALUES
        ('Config file', 'General', NULL, NULL, '$(mpSim.parFileName)'),
        ('DB name', 'General', NULL, NULL, '$(mpSim.dbName)'),
        ('Catalogue name', 'General', NULL, NULL, '$(mpSim.catFileName)'),
        ('Sim name', 'General', NULL, NULL, '$(mpSim.simName)'),
        ('ID key', 'General', NULL, NULL, '$(mpSim.idKey)'),
        ('Personnel target', 'General', '$(mpSim.personnelTarget)', NULL, NULL),
        ('Start date', 'General', NULL, NULL, '$(mpSim.simStartDate)'),
        ('Sim length', 'General', NULL, '$(mpSim.simLength)', NULL),
        ('Sim time', 'General', NULL, $(min( now( mpSim ), mpSim.simLength)), NULL),
        ('DB commits', 'General', '$dbCommits', NULL, NULL)"
    SQLite.execute!( configDB, command )

    return

end  # readGeneralParsFromSim( mpSim, configDB, configName )


function readAttributesFromSim( mpSim::ManpowerSimulation,
    configDB::SQLite.DB, configName::String )::Void

    # Don't read anything if there aren't any attributes defined.
    if isempty( mpSim.initAttrList ) && isempty( mpSim.otherAttrList )
        return
    end  # if isempty( mpSim.initAttrList ) && ...

    # Read every single attribute.
    attrInserts = map( attr -> saveAttributeToDatabase( attr ),
        vcat( mpSim.initAttrList, mpSim.otherAttrList ) )
    command = "INSERT INTO `$configName`
        (parName, parType, boolPar, strPar) VALUES
        $(join( attrInserts, ", " ))"
    SQLite.execute!( configDB, command )
    return

end  # readAttributesFromSim( mpSim, configDB, configName )


function saveAttributeToDatabase( attr::PersonnelAttribute )::String

    valueList = "[" * join( attr.possibleValues, "," ) * "];[" *
        join( map( val -> "$val:$(attr.values[ val ])", keys( attr.values ) ),
        "," ) * "]"
    return "('$(attr.name)', 'Attribute', '$(attr.isFixed)', '$valueList')"

end  # saveAttrToDatabase( attr )


function readAttritionFromSim( mpSim::ManpowerSimulation,
    configDB::SQLite.DB, configName::String )::Void

    attrInserts = map( attrName -> saveAttritionToDatabase(
        mpSim.attritionSchemes[ attrName ]), keys( mpSim.attritionSchemes ) )
    push!( attrInserts, saveAttritionToDatabase(
        mpSim.defaultAttritionScheme ) )
    command = "INSERT INTO `$configName`
        (parName, parType, realPar, strPar) VALUES
        $(join( attrInserts, ", " ))"
    SQLite.execute!( configDB, command )
    return

end  # readAttritionFromSim( mpSim, configDB, configName )


function saveAttritionToDatabase( attrScheme::Attrition )::String

    attrCurve = join( map( ii -> "$(attrScheme.attrCurvePoints[ ii ]):$(attrScheme.attrRates[ ii ])",
        eachindex( attrScheme.attrCurvePoints ) ), "," )
    return "('$(attrScheme.name)', 'Attrition', $(attrScheme.attrPeriod), '$attrCurve')"

end  # saveAttritionToDatabase( attrScheme )


function readStatesFromSim( mpSim::ManpowerSimulation,
    configDB::SQLite.DB, configName::String )::Void

    # Don't read anything if there aren't any states defined.
    if isempty( mpSim.stateList )
        return
    end  # if isempty( mpSim.stateList )

    # Read every single state.
    stateInserts = map( state -> saveStateToDatabase( mpSim.stateList[ state ],
        mpSim ), keys( mpSim.stateList ) )
    command = "INSERT INTO `$configName`
        (parName, parType, intPar, boolPar, strPar) VALUES
        $(join( stateInserts, ", " ))"
    SQLite.execute!( configDB, command )

    # Read preferred state order.
    if !isempty( mpSim.preferredStateOrder )
        command = string( "INSERT INTO '", configName, "'
            (parName, parType, strPar) VALUES
            ('Preferred Order', 'State Order', '",
            join( mpSim.preferredStateOrder, ";" ), "')" )
        SQLite.execute!( configDB, command )
    end  # if !isempty( mpSim.preferredStateOrder )

    return

end  # readStatesFromSim( mpSim, configDB, configName )


function saveStateToDatabase( state::State, mpSim::ManpowerSimulation )::String

    reqList = collect( keys( state.requirements ) )
    map!( attr -> string( attr, ':', join( state.requirements[ attr ], "//" ) ),
        reqList, reqList )
    stateEntry = string( "('", state.name, "', 'State', ", state.stateTarget,
        ", '", state.isInitial, "', '[", join( reqList, "," ), "];" )
    attrName = "default"

    if state.attrScheme != mpSim.defaultAttritionScheme
        if haskey( mpSim.attritionSchemes, state.attrScheme.name )
            attrName = state.attrScheme.name
        else
            warn( "Unknown attrition scheme." )
            attrScheme = state.attrScheme
            attrName = string( attrScheme.attrPeriod, ':',
                attrScheme.attrRates[ 1 ] )
        end  # if haskey( mpSim.attritionSchemes, state.attrScheme.name )
    end  # if state.attrScheme != mpSim.defaultAttritionScheme )

    stateEntry = string( stateEntry, attrName, "')" )

    return stateEntry

end  # saveStateToDatabase( state, attrName, configDB, configName )


function readCompoundStatesFromSim( mpSim::ManpowerSimulation,
    configDB::SQLite.DB, configName::String )::Void

    # Don't read anything if there aren't any compound states defined.
    if isempty( mpSim.compoundStatesCat ) &&
        isempty( mpSim.compoundStatesCustom )
        return
    end  # if isempty( mpSim.stateList )

    # Read every single compound state.
    compStateInserts = vcat( map( compState -> saveCompStateToDatabase(
        mpSim.compoundStatesCat[ compState ], mpSim ),
        keys( mpSim.compoundStatesCat ) ), map(
        compState -> saveCompStateToDatabase(
        mpSim.compoundStatesCustom[ compState ], mpSim ),
        keys( mpSim.compoundStatesCustom ) ) )
    command = "INSERT INTO `$configName`
        (parName, parType, intPar, boolPar, strPar) VALUES
        $(join( compStateInserts, ", " ))"
    SQLite.execute!( configDB, command )
    return

end  # readCompoundStatesFromSim( mpSim, configDB, configName )


function saveCompStateToDatabase( state::State,
    mpSim::ManpowerSimulation )::String

    reqList = collect( keys( state.requirements ) )
    map!( attr -> "$attr:$(state.requirements[ attr ][ 1 ])", reqList, reqList )
    stateEntry = "('$(state.name)', 'Compound state', $(state.stateTarget), "
    stateEntry *= "'false', '" * join( reqList, ";" ) * "')"
    return stateEntry

end  # saveCompStateToDatabase( state, mpSim )


function saveCompStateToDatabase( compState::CompoundState,
    mpSim::ManpowerSimulation )::String

    stateEntry = "('$(compState.name)', 'Compound state', "
    stateEntry *= "$(compState.stateTarget), 'true', '"
    stateEntry *= join( compState.stateList, ";" ) * "')"
    return stateEntry

end  # saveCompStateToDatabase( state, mpSim )



function readTransTypesFromSim( mpSim::ManpowerSimulation,
    configDB::SQLite.DB, configName::String )::Void

    # Don't do anything if there aren't any transition types defined.
    if isempty( mpSim.transList )
        return
    end  # if isempty( transInserts )

    transTypeInserts = map( keys( mpSim.transList ) ) do trans
        return "('$trans', 'Transition type', $(mpSim.transList[ trans ]))"
    end  # map( keys( transList ) ) do

    command = "INSERT INTO `$configName`
        (parName, parType, intPar) VALUES
        $(join( transTypeInserts, ", " ))"
    SQLite.execute!( configDB, command )

    return

end  # readTransTypesFromSim( mpSim, configDB, configName )


function readTransitionsFromSim( mpSim::ManpowerSimulation,
    configDB::SQLite.DB, configName::String )::Void

    transInserts = Vector{String}()
    stateList = merge( mpSim.initStateList, mpSim.otherStateList )

    for state in keys( stateList )
        for trans in stateList[ state ]
            push!( transInserts, saveTransitionToDatabase( trans ) )
        end  # for trans in stateList[ state ]
    end  # for state in keys( stateList )

    # Don't do anything if there aren't any transitions defined.
    if isempty( transInserts )
        return
    end  # if isempty( transInserts )

    command = "INSERT INTO `$configName`
        (parName, parType, strPar) VALUES
        $(join( transInserts, ", " ))"
    SQLite.execute!( configDB, command )

    return

end  # readTransitionsFromSim( mpSim, configDB, configName )


function saveTransitionToDatabase( trans::Transition )::String

    transEntry = string( "('", trans.name, "', 'Transition', '",
        trans.startState.name, ';', trans.isOutTrans ? "" : trans.endState.name,
        ';', trans.freq, ';', trans.offset, ";[" )
    condList = Vector{String}( length( trans.extraConditions ) )

    for ii in eachindex( trans.extraConditions )
        cond = trans.extraConditions[ ii ]
        condRel = relationEntries[ cond.rel ]
        condList[ ii ] = "$(cond.attr):$condRel:"

        if isa( cond.val, Vector )
            condList[ ii ] *= join( cond.val, "//" )
        else
            condList[ ii ] *= string( cond.val )
        end  # if isa( cond.val, Vector )
    end  # for cond in trans.extraConditions

    transEntry = string( transEntry, join( condList, "," ), "];[" )

    if !trans.isOutTrans
        changeList = Vector{String}( length( trans.extraChanges ) )

        for ii in eachindex( trans.extraChanges )
            attr = trans.extraChanges[ ii ]
            changeList[ ii ] = string( "$(attr.name):",
                collect( keys( attr.values ) )[ 1 ] )
        end  # for ii in eachindex( trans.extraChanges )
    end  # if !trans.isOutTrans

    transEntry = string( transEntry, trans.isOutTrans ? "" :
        join( changeList, "," ), "];[", join( trans.probabilityList, "," ),
        "];", trans.maxAttempts, ';', trans.isOutTrans, ';', trans.maxFlux, ';',
        trans.hasPriority, "')" )
    return transEntry

end  # saveTransitionToDatabase( trans::Transition )


function readRecruitmentFromSim( mpSim::ManpowerSimulation,
    configDB::SQLite.DB, configName::String )::Void

    # Don't do anything if there aren't any recruitment schemes defined.
    if isempty( mpSim.recruitmentSchemes )
        return
    end  # if isempty( mpSim.recruitmentSchemes )

    # Read every single recruitment scheme.
    recInserts = map( recScheme -> saveRecruitmentToDatabase( recScheme ),
        mpSim.recruitmentSchemes )
    command = "INSERT INTO `$configName`
        (parName, parType, boolPar, strPar) VALUES
        $(join( recInserts, ", " ))"
    SQLite.execute!( configDB, command )
    return

end  # readRecruitmentFromSim( mpSim, configDB, configName )


function saveRecruitmentToDatabase( recScheme::Recruitment )::String

    recEntry = "('$(recScheme.name)', 'Recruitment', '$(recScheme.isAdaptive)',"
    recEntry *= "'$(recScheme.recruitFreq);$(recScheme.recruitOffset);"
    recEntry *= "$(recScheme.recState);"

    if recScheme.isAdaptive
        recEntry *= "$(recScheme.minRecruit);$(recScheme.maxRecruit);"
    else
        recEntry *= "$(recScheme.recDistType);["
        recDistList = Vector{Any}( collect( keys( recScheme.recDistNodes ) ) )

        for ii in eachindex( recDistList )
            node = recDistList[ ii ]
            recDistList[ ii ] = "$node:$(recScheme.recDistNodes[ node ])"
        end  # for ii in eachindex( recDistList )

        recEntry *= join( recDistList, "," ) * "];"
    end  # if recScheme.isAdpative

    recEntry *= "$(recScheme.ageDistType);["
    ageDistList = Vector{Any}( collect( keys( recScheme.ageDistNodes ) ) )

    for ii in eachindex( ageDistList )
        node = ageDistList[ ii ]
        ageDistList[ ii ] = "$(node):$(recScheme.ageDistNodes[ node ])"
    end  # for ii in eachindex( ageDistList )

    recEntry *= join( ageDistList, "," ) * "]')"
    return recEntry

end  # saveAttrToDatabase( attr, configDB, configName )
