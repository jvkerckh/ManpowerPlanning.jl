#=
This file holds all the functions that read and process an Excel parameter file
to initialise a manpower simulation.
=#


distTypes = Dict( "Pointwise" => :disc, "Piecewise Uniform" => :pUnif,
    "Piecewise Linear" => :pLin )


export initialiseFromExcel
"""
**Use**: `initialiseFromExcel( mpSim::ManpowerSimulation, fileName::String,
initDB::Bool = false )`

This function initalises the simulation `mpSim` from the Excel file with name
`fileName`. If the flag `initDB` is set to `true`, the database will be properly
initialised as well.

This function returns a `Bool`, indicating whether the simulation has been
succesfully initialised or not.
"""
function initialiseFromExcel( mpSim::ManpowerSimulation, fileName::String,
    initDB::Bool = true )::Bool

    # Do nothing if the file isn't an Excel file.
    if !endswith( fileName, ".xlsx" )
        warn( "File is not an Excel file. Not making any changes. Simulation setting should not be relied upon." )
        return false
    end  # if !endswith( fileName, ".xlsx" )

    configSource = "Excel"

    XLSX.openxlsx( fileName ) do xf
        # Check if the file has the required sheets.
        sheets = [ "General",
                   "Attributes",
                   "States",
                   "Compound States",
                   "Transitions",
                   "Recruitment",
                   "Retirement" ]

        if any( shName -> !XLSX.hassheet( xf, shName ), sheets )
            warn( "Improperly formatted Excel parameter file. Not making any changes." )
            return
        end  # if any( shName -> !XLSX.hassheet( xf, shName ), sheets )

        sheet = xf[ "General" ]

        # Read database parameters.
        configSource = readDBpars( mpSim, sheet )

        # Don't read Excel parameters if the source of the configuration is a
        #   database.
        if configSource != "Excel"
            return
        end  # if !isDBnew

        # Read general parameters.
        readGeneralPars( mpSim, sheet )

        XLSX.openxlsx( mpSim.catFileName ) do catXF
            # Read attrition schemes.
            readAttritionSchemes( mpSim, catXF )

            # Read attributes.
            sheet = xf[ "Attributes" ]
            catSheet = catXF[ "Attributes" ]
            readAttributes( mpSim, sheet, catSheet )

            # Read states.
            sheet = xf[ "States" ]
            catSheet = catXF[ "States" ]
            readStates( mpSim, sheet, catSheet )

            # Read compound states.
            sheet = xf[ "Compound States" ]
            readCompoundStates( mpSim, sheet, catSheet )

            # Read transition types.
            catSheet = catXF[ "General" ]
            nTypes = catSheet[ "B7" ]
            sheet = xf[ "Transitions" ]
            catSheet = catXF[ "Transition types" ]
            readTransitions( mpSim, sheet, catSheet, nTypes )
        end  # XLSX.openxlsx( mpSim.catFileName ) do catXF

        # Read recruitment parameters.
        sheet = xf[ "Recruitment" ]
        readRecruitmentPars( mpSim, sheet )

        # Read retirement parameters.
        sheet = xf[ "Retirement" ]
        readRetirementPars( mpSim, sheet )
    end  # XLSX.openxlsx( fileName ) do xf

    # Make sure the databases are okay, and save configuration to database.
    if configSource != "sameDB"
        initialise( mpSim )
        saveSimConfigToDatabase( mpSim )
    end  # if isDBuninitialised

    return true

end  # initialiseFromExcel( mpSim, fileName )


function readDBpars( mpSim::ManpowerSimulation, sheet::XLSX.Worksheet )::String

    isConfigFromDB = sheet[ "B11" ] == "YES"
    configDBname = Base.source_path()
    configDBname = configDBname isa Void ? "" : dirname( configDBname )
    tmpDBname = sheet[ "B4" ]

    if tmpDBname isa Missings.Missing
        tmpDBname = ""
    else
        tmpDBname = joinpath( mpSim.parFileName[ 1:(end-5) ], sheet[ "B4" ] )
        tmpDBname *= endswith( tmpDBname, ".sqlite" ) ? "" : ".sqlite"
    end  # if tmpDBname isa Missings.Missing

    if isConfigFromDB
        tmpConfigName = sheet[ "B12" ]

        if isa( tmpConfigName, Missings.Missing )
            warn( "No database entered to get configuration from. Configuring simulation from Excel sheet." )
            isConfigFromDB = false
        else
            configDBname = joinpath( configDBname, tmpConfigName )
            configDBname *= endswith( configDBname, ".sqlite" ) ? "" : ".sqlite"

            if ispath( configDBname )
                isRerun = ( configDBname == tmpDBname ) &&
                    ( sheet[ "B14" ] == "YES" )
                configureSimFromDatabase( mpSim, configDBname, isRerun )

                # Don't make any further changes if the database is the same.
                if configDBname == tmpDBname
                    return "sameDB"
                end  # if configDBname == tmpDBname
            else
                warn( "Database '$configDBname' does not exist. Configuring simulation from Excel sheet." )
                isConfigFromDB = false
            end  # if ispath( configDBname )
        end  # if isa( tmpDBname, Missings.Missing )
    end  # if isConfigFromDB

    # This block creates the database file if necessary and opens a link to it.
    try
        mkdir( mpSim.parFileName[ 1:(end-5) ] )
    catch
    end

    println( "Database file \"$tmpDBname\" ",
        isfile( tmpDBname ) ? "exists" : "does not exist", "." )
    mpSim.dbName = tmpDBname
    mpSim.simDB = SQLite.DB( tmpDBname )

    # This line ensures that foreign key logic works.
    SQLite.execute!( mpSim.simDB, "PRAGMA foreign_keys = ON" )

    simName = sheet[ "B5" ]
    mpSim.personnelDBname = "Personnel_" * simName
    mpSim.historyDBname = "History_" * simName
    mpSim.transitionDBname = "Transitions_" * simName

    # Check if databases are present and issue a warning if so.
    tmpTableList = SQLite.tables( mpSim.simDB )[ :name ]

    if ( mpSim.personnelDBname ∈ tmpTableList ) ||
            ( mpSim.historyDBname ∈ tmpTableList )
            ( mpSim.transitionDBname ∈ tmpTableList )
        warn( "Results for a simulation called \"$(mpSim.simName)\" already in database. These will be overwritten." )
    end  # if mpSim.personnelDBname ∈ tmpTableList

    return isConfigFromDB ? "otherDB" : "Excel"

end  # readDBpars( mpSim, sheet )


function readGeneralPars( mpSim::ManpowerSimulation,
    sheet::XLSX.Worksheet )::Void

    # Read the name of the catalogue file.
    catalogueName = joinpath( dirname( mpSim.parFileName ),
        sheet[ "B3" ] * ".xlsx" )

    if !ispath( catalogueName )
        error( "Catalogue file '$catalogueName' does not exist." )
    end  # if !ispath( catalogueName )

    mpSim.catFileName = catalogueName

    # Set general simulation parameters.
    setPersonnelCap( mpSim, sheet[ "B6" ] )

    if !isa( sheet[ "B7" ], Missings.Missing )
        setSimStartDate( mpSim, sheet[ "B7" ] )
    end  # if !isa( sheet[ "B7" ], Missings.Missing )

    setSimulationLength( mpSim, sheet[ "B8" ] * 12.0 )
    setDatabaseCommitTime( mpSim, sheet[ "B8" ] * 12.0 / sheet[ "B9" ] )
    return

end  # readGeneralPars( mpSim, sheet )


function readAttritionSchemes( mpSim::ManpowerSimulation,
    catXF::XLSX.XLSXFile )::Void

    catSheet = catXF[ "General" ]
    nSchemes = catSheet[ "B4" ]
    catSheet = catXF[ "Attrition" ]
    isDefaultDefined = false
    clearAttritionSchemes!( mpSim )

    for sLine in (1:nSchemes) + 1
        newAttrScheme = readAttrition( catSheet, sLine )

        if newAttrScheme.name == "default"
            isDefaultDefined = true
            setAttrition( mpSim, newAttrScheme )
        else
            addAttritionScheme!( newAttrScheme, mpSim )
        end  # if newAttrScheme.name == "default"
    end  # for ii in (1:nSchemes) + 1

    return

end  # readAttritionSchemes( mpSim, catXF )


function readAttributes( mpSim::ManpowerSimulation, sheet::XLSX.Worksheet,
    attrCat::XLSX.Worksheet )::Void

    nAttrs = sheet[ "B4" ]
    clearAttributes!( mpSim )

    for sLine in 4 + 3 * ( 1:nAttrs )
        newAttr = readAttribute( sheet, attrCat, sLine )
        addAttribute!( mpSim, newAttr )
    end  # for sLine in 4 + 3 * ( 1::nAttrs )

    return

end  # readAttributes( mpSim, sheet, attrCat )


function readStates( mpSim::ManpowerSimulation, sheet::XLSX.Worksheet,
    catSheet::XLSX.Worksheet )::Void

    nStates = sheet[ "B4" ]
    clearStates!( mpSim )
    # listOfStates = Vector{String}()

    for ii in 1:nStates
        newState, attrPar = readState( sheet, catSheet, 6 + ii )

        if isa( attrPar, String )
            setStateAttritionScheme!( newState, attrPar, mpSim )
        else
            setStateAttritionScheme!( newState, attrPar[ 2 ], attrPar[ 1 ],
                mpSim )
        end  # if isa( attrPar, String )

        addState!( mpSim, newState, newState.isInitial )
    end  # for ii in 1:nStates

    return

end  # readStates( mpSim, sheet, catSheet )


function readCompoundStates( mpSim::ManpowerSimulation, sheet::XLSX.Worksheet,
    catSheet::XLSX.Worksheet )::Void

    clearCompoundStates!( mpSim )
    readHierarchy( sheet, mpSim )

    # Catalogue based compound states.
    nCompStates = sheet[ "B4" ]

    for ii in 1:nCompStates
        compState = readState( sheet, catSheet, ii + 6 )[ 1 ]
        mpSim.compoundStatesCat[ compState.name ] = compState
    end  # for ii in 1:nCompStates

    # Custom compound states.
    nCompStates = sheet[ "I4" ]

    for ii in 1:nCompStates
        compState = readCompoundState( sheet, ii + 6 )
        mpSim.compoundStatesCustom[ compState.name ] = compState
    end  # or ii in 1:nCompStates

    return

end  # readCompoundStates( mpSim, sheet, catSheet )


function readTransitions( mpSim::ManpowerSimulation,
    sheet::XLSX.Worksheet, catSheet::XLSX.Worksheet, nTypes::Int )::Void

    nTransitions = Int( sheet[ "B4" ] )
    clearTransitions!( mpSim )

    # Read the transition types first.
    for sLine in ( 1:nTypes ) + 1
        tType = catSheet[ "A$sLine" ]
        tPrio = catSheet[ "B$sLine" ]
        tPrio = isa( tPrio, Int ) ? tPrio : 0
        mpSim.transList[ tType ] = tPrio
    end  # for sLine in ( 1:nTypes ) + 1

    stateList = collect( keys( merge( mpSim.initStateList,
        mpSim.otherStateList ) ) )

    for sLine in 3 + 4 * ( 1:nTransitions )
        newTrans, startName, endName = readTransition( sheet, sLine )
        startInd = findfirst( state -> state.name == startName, stateList )
        endInd = findfirst( state -> state.name == endName, stateList )
        setState( newTrans, stateList[ startInd ] )
        setState( newTrans, stateList[ endInd ], true )
        # purgeRedundantExtraChanges( newTrans )
        addTransition!( mpSim, newTrans )
    end  # for sLine in 3 + 4 * ( 1:nTransitions )

    return

end  # readTransitions( mpSim, sheet )


function readRecruitmentPars( mpSim::ManpowerSimulation,
    sheet::XLSX.Worksheet )::Void

    clearRecruitmentSchemes!( mpSim )
    numSchemes = sheet[ "B3" ]

    for ii in 1:numSchemes
        recScheme = readRecruitmentScheme( sheet, ii )
        addRecruitmentScheme!( mpSim, recScheme )
    end  # for ii in 1:numSchemes

    return

end  # readRecruitmentPars( mpSim, sheet )


function readRetirementPars( mpSim::ManpowerSimulation,
    sheet::XLSX.Worksheet )::Void

    maxTenure = sheet[ "B5" ] * 12.0
    maxAge = sheet[ "B6" ] * 12.0
    isEither = sheet[ "B7" ] == "EITHER"
    retScheme = Retirement( freq = sheet[ "B3" ], offset = sheet[ "B4" ],
        maxCareer = maxTenure, retireAge = maxAge, isEither = isEither )
    setRetirement( mpSim, retScheme )

    return

end  # readRetirementPars( mpSim, sheet )


include( "simplifiedParFileProcessing.jl" )
