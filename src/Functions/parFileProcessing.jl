#=
This file holds all the functions that read and process an Excel parameter file
to initialise a manpower simulation.
=#


export initialiseFromExcel
"""
**Use**: `initialiseFromExcel( mpSim::ManpowerSimulation, fileName::String,
initDB::Bool = false )`

This function initalises the simulation `mpSim` from the Excel file with name
`fileName`. If the flag `initDB` is set to `true`, the database will be properly
initialised as well.
"""
function initialiseFromExcel( mpSim::ManpowerSimulation, fileName::String,
    initDB::Bool = false )

    # Do nothing if the file isn't an Excel file.
    if !endswith( fileName, ".xlsx" )
        warn( "File is not an Excel file. Not making any changes." )
        return
    end  # if !endswith( fileName, ".xlsx" )

    # Check if the file has the required sheets.
    w = Workbook( fileName )
    sheets = [ "General", "Recruitment", "Attrition", "Retirement" ]

    if any( shName -> getSheet( w, shName ) === Ptr{Void}( 0 ), sheets )
        warn( "Improperly formatted Excel parameter file. Not making any changes." )
        return
    end  # if any( shName -> getSheet( w, shName ) === ...

    # Read general parameters.
    s = getSheet( w, "General" )

    if initDB
        readDBpars( mpSim, s )
    end  # if initDB

    readGeneralPars( mpSim, s )

    # Read recruitment parameters.
    s = getSheet( w, "Recruitment" )
    readRecruitmentPars( mpSim, s )

    # Read attrition parameters.
    s = getSheet( w, "Attrition" )
    readAttritionPars( mpSim, s )

    # Read retirement parameters.
    s = getSheet( w, "Retirement" )
    readRetirementPars( mpSim, s )

end  # initialiseFromExcel( mpSim, fileName )


function readDBpars( mpSim::ManpowerSimulation, s::Taro.Sheet )

    # This block creates the database file if necessary and opens a link to
    #   it.  XXX Persistent??
    tmpDBname = s[ "B", 3 ] * ".sqlite"
    println( "Database file \"$tmpDBname\" ",
        isfile( tmpDBname ) ? "exists" : "does not exist", "." )
    mpSim.simDB = SQLite.DB( tmpDBname )

    # This line ensures that foreign key logic works.
    SQLite.execute!( mpSim.simDB, "PRAGMA foreign_keys = ON" )

    mpSim.personnelDBname = "Personnel_" * s[ "B", 4 ]
    mpSim.historyDBname = "History_" * s[ "B", 4 ]

    # Check if databases are present and issue a warning if so.
    tmpTableList = SQLite.tables( mpSim.simDB )[ :name ].values

    if ( mpSim.personnelDBname ∈ tmpTableList ) ||
            ( mpSim.historyDBname ∈ tmpTableList )
        warn( "Results for a simulation called \"$(mpSim.simName)\" already in database. These will be overwritten." )
    end  # if mpSim.personnelDBname ∈ tmpTableList

end  # readDBpars( mpSim, s )


function readGeneralPars( mpSim::ManpowerSimulation, s::Taro.Sheet )

    setPersonnelCap( mpSim, Int( s[ "B", 5 ] ) )
    setSimulationLength( mpSim, s[ "B", 8 ] * 12 )
    setDatabaseCommitTime( mpSim, s[ "B", 8 ] * 12 / s[ "B", 9 ] )

end  # readGeneralPars( mpSim, s )


function readRecruitmentPars( mpSim::ManpowerSimulation, s::Taro.Sheet )

    clearRecruitmentSchemes!( mpSim )
    numSchemes = Int( s[ "B", 3 ] )

    for ii in 1:numSchemes
        addRecruitmentScheme!( mpSim, s, ii - 1 )
    end  # for ii in 1:numSchemes

end  # readRecruitmentPars( mpSim, s )


function readAttritionPars( mpSim::ManpowerSimulation, s::Taro.Sheet )

    if s[ "B", 4 ] > 0
        attrScheme = Attrition( s[ "B", 4 ], s[ "B", 3 ] )
        setAttrition( mpSim, attrScheme )
    else
        setAttrition( mpSim )
    end  # if s[ "B", 4 ] > 0

end  # readAttritionPars( mpSim, s )


function readRetirementPars( mpSim::ManpowerSimulation, s::Taro.Sheet )

    maxTenure = s[ "B", 5 ] * 12
    maxAge = s[ "B", 6 ] * 12

    if ( maxTenure > 0 ) || ( maxAge > 0 )
        retScheme = Retirement( freq = s[ "B", 3 ], offset = s[ "B", 4 ],
            maxCareer = maxTenure, retireAge = maxAge )
        setRetirement( mpSim, retScheme )
    else
        setRetirement( mpSim )
    end  # if ( maxTenure > 0 ) || ...

end  # readRetirementPars( mpSim, s )
