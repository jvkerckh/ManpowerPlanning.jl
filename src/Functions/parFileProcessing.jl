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
"""
function initialiseFromExcel( mpSim::ManpowerSimulation, fileName::String,
    initDB::Bool = true )::Void

    # Do nothing if the file isn't an Excel file.
    if !endswith( fileName, ".xlsx" )
        warn( "File is not an Excel file. Not making any changes." )
        return
    end  # if !endswith( fileName, ".xlsx" )

    XLSX.openxlsx( fileName ) do xf
        # Check if the file has the required sheets.
        sheets = [ "General",
                   "Attributes",
                   "States",
                   "Transitions",
                   "Recruitment",
                   "Retirement" ]

        if any( shName -> !XLSX.hassheet( xf, shName ), sheets )
            warn( "Improperly formatted Excel parameter file. Not making any changes." )
            return
        end  # if any( shName -> !XLSX.hassheet( xf, shName ), sheets )

        sheet = xf[ "General" ]

        # Read database parameters.
        if initDB
            readDBpars( mpSim, sheet )
        end  # if initDB

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
        end  # XLSX.openxlsx( mpSim.catFileName ) do catXF

        # Read transitions.
        sheet = xf[ "Transitions" ]
        readTransitions( mpSim, sheet )

        # Read recruitment parameters.
        sheet = xf[ "Recruitment" ]
        readRecruitmentPars( mpSim, sheet )

        # Read retirement parameters.
        sheet = xf[ "Retirement" ]
        readRetirementPars( mpSim, sheet )
    end  # XLSX.openxlsx( fileName ) do xf

    # Make sure the databases are okay.
    resetSimulation( mpSim )

    return

end  # initialiseFromExcel( mpSim, fileName )


function readDBpars( mpSim::ManpowerSimulation, sheet::XLSX.Worksheet )::Void

    # This block creates the database file if necessary and opens a link to it.
    try
        mkdir( mpSim.parFileName[ 1:(end-5) ] )
    catch
    end

    tmpDBname = joinpath( mpSim.parFileName[ 1:(end-5) ],
        sheet[ "B4" ] * ".sqlite" )
    println( "Database file \"$tmpDBname\" ",
        isfile( tmpDBname ) ? "exists" : "does not exist", "." )
    mpSim.simDB = SQLite.DB( tmpDBname )

    # This line ensures that foreign key logic works.
    SQLite.execute!( mpSim.simDB, "PRAGMA foreign_keys = ON" )

    simName = sheet[ "B5" ]
    mpSim.personnelDBname = "Personnel_" * simName
    mpSim.historyDBname = "History_" * simName

    # Check if databases are present and issue a warning if so.
    tmpTableList = SQLite.tables( mpSim.simDB )[ :name ]

    if ( mpSim.personnelDBname ∈ tmpTableList ) ||
            ( mpSim.historyDBname ∈ tmpTableList )
        warn( "Results for a simulation called \"$(mpSim.simName)\" already in database. These will be overwritten." )
    end  # if mpSim.personnelDBname ∈ tmpTableList

    return

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
    stateCat::XLSX.Worksheet )::Void

    nStates = sheet[ "B4" ]
    clearStates!( mpSim )
    # listOfStates = Vector{String}()

    for ii in 1:nStates
        newState, attrPar = readState( sheet, stateCat, 6 + ii )

        if isa( attrPar, String )
            setStateAttritionScheme!( newState, attrPar, mpSim )
        else
            setStateAttritionScheme!( newState, attrPar[ 2 ], attrPar[ 1 ],
                mpSim )
        end  # if isa( attrPar, String )

        addState!( mpSim, newState, newState.isInitial )
    end  # for ii in 1:nStates

    return

end  # readStates( mpSim, s )


function readTransitions( mpSim::ManpowerSimulation,
    sheet::XLSX.Worksheet )::Void

    nTransitions = Int( sheet[ "B4" ] )
    clearTransitions!( mpSim )
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
