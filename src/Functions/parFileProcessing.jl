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
    sheets = [ "General",
               "Atributes",
               "States",
               "Transitions",
               "Recruitment",
               "Attrition",
               "Retirement" ]

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

    # Read attributes.
    s = getSheet( w, "Attributes" )
    readAttributes( mpSim, s )

    # Read states.
    s = getSheet( w, "States" )
    readStates( mpSim, s )

    # Read transitions.
    s = getSheet( w, "Transitions" )
    readTransitions( mpSim, s )

    # Read recruitment parameters.
    s = getSheet( w, "Recruitment" )
    readRecruitmentPars( mpSim, s )

    # Read attrition parameters.
    s = getSheet( w, "Attrition" )
    readAttritionPars( mpSim, s )

    # Read retirement parameters.
    s = getSheet( w, "Retirement" )
    readRetirementPars( mpSim, s )

    # Make sure the databases are okay.
    resetSimulation( mpSim )

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
    tmpTableList = SQLite.tables( mpSim.simDB )[ :name ]

    if ( mpSim.personnelDBname ∈ tmpTableList ) ||
            ( mpSim.historyDBname ∈ tmpTableList )
        warn( "Results for a simulation called \"$(mpSim.simName)\" already in database. These will be overwritten." )
    end  # if mpSim.personnelDBname ∈ tmpTableList

end  # readDBpars( mpSim, s )


function readGeneralPars( mpSim::ManpowerSimulation, s::Taro.Sheet )

    setPersonnelCap( mpSim, Int( s[ "B", 5 ] ) )
    setSimulationLength( mpSim, s[ "B", 7 ] * 12 )
    setDatabaseCommitTime( mpSim, s[ "B", 7 ] * 12 / s[ "B", 8 ] )

end  # readGeneralPars( mpSim, s )


function readAttributes( mpSim::ManpowerSimulation, s::Taro.Sheet )

    nAttrs = s[ "B", 3 ]
    clearAttributes!( mpSim )
    sLine = 5
    lastLine = numRows( s, "C" )
    ii = 1

    # Read every single attribute.
    while ( sLine <= lastLine ) && ( ii <= nAttrs )
        newAttr, sLine = readAttribute( s, sLine )
        addAttribute!( mpSim, newAttr )
        ii += 1
    end  # while ( sLine <= lastLine ) && ...

    return

end  # readAttributes( mpSim, s )


function readStates( mpSim::ManpowerSimulation, s::Taro.Sheet )

    nStates = s[ "B", 3 ]
    clearStates!( mpSim )
    sLine = 5
    lastLine = numRows( s, "C" )
    ii = 1

    while ( sLine <= lastLine ) && ( ii <= nStates )
        newState, isInitial, sLine = readState( s, sLine )
        addState!( mpSim, newState, isInitial )
        ii += 1
    end  # while ( sLine <= lastLine ) && ...

    return

end  # readStates( mpSim, s )


function readTransitions( mpSim::ManpowerSimulation, s::Taro.Sheet )

    nTransitions = s[ "B", 3 ]
    clearTransitions!( mpSim )
    sLine = 5
    lastLine = numRows( s, "C" )
    ii = 1
    stateList = collect( keys( merge( mpSim.initStateList,
        mpSim.otherStateList ) ) )

    while ( sLine <= lastLine ) && ( ii <= nTransitions )
        newTrans, startName, endName, sLine = readTransition( s, sLine )
        startInd = findfirst( state -> state.name == startName, stateList )
        endInd = findfirst( state -> state.name == endName, stateList )

        # If either of the states with the given name can't be found, throw an
        #   error.
        if startInd * endInd == 0
            error( "Start state or end state unknown." )
        end  # if startInd * endInd == 0

        setState( newTrans, stateList[ startInd ] )
        setState( newTrans, stateList[ endInd ], true )
        addTransition!( mpSim, newTrans )
        ii += 1
    end  # while ( sLine <= lastLine ) && ...

    return

end  # readTransitions( mpSim, s )


function readRecruitmentPars( mpSim::ManpowerSimulation, s::Taro.Sheet )

    clearRecruitmentSchemes!( mpSim )
    numSchemes = Int( s[ "B", 3 ] )

    for ii in 1:numSchemes
        recScheme = generateRecruitmentScheme( s, ii )
        addRecruitmentScheme!( mpSim, recScheme )
    end  # for ii in 1:numSchemes

end  # readRecruitmentPars( mpSim, s )


function generateRecruitmentScheme( s::Taro.Sheet, ii::T ) where T <: Integer

    dataColNr = ii * 4 - 2
    recScheme = Recruitment( s[ dataColNr, 5 ], s[ dataColNr, 6 ],
        s[ dataColNr, 7 ] )
    isAdaptive = s[ dataColNr, 10 ] == 1
    isRandom = s[ dataColNr, 11 ] == 1

    if isAdaptive
        minRec = s[ dataColNr, 8 ] === nothing ? 0 : Int( s[ dataColNr, 8 ] )
        setRecruitmentLimits( recScheme, minRec, Int( s[ dataColNr, 9 ] ) )
    elseif isRandom
        distTypes = Dict( "Pointwise" => :disc, "Uniform" => :pUnif,
            "Piecewise Linear" => :pLin )
        distType = distTypes[ s[ dataColNr, 15 ] ]
        recDist = Dict{Int, Float64}()
        jj = 17

        while s[ dataColNr, jj ] !== nothing
            node = s[ dataColNr, jj ]
            weight = s[ dataColNr + 1, jj ]

            if isa( node, Float64 ) && ( node == floor( node ) ) &&
                isa( weight, Float64 )
                recDist[ Int( node ) ] = weight
            end  # if isa( node, Float64 ) &&

            jj += 1
        end  # while s[ "B", jj ] !== nothing

        setRecruitmentDistribution( recScheme, recDist, distType )
    else
        setRecruitmentFixed( recScheme, Int( s[ dataColNr, 9 ] ) )
    end  # if isAdaptive

    isFixedAge = s[ dataColNr, 12 ] == 1

    # Add the age distribution.
    if isFixedAge
        setRecruitmentAge( recScheme, s[ dataColNr, 13 ] * 12 )
    else
        rowNrOfDist = numRows( s, dataColNr - 1, dataColNr - 1 )
        distType = s[ dataColNr, rowNrOfDist ] == "Pointwise" ? :disc : :pUnif
        rowNrOfDistEnd = numRows( s, dataColNr, dataColNr )

        if rowNrOfDist + 2 > rowNrOfDistEnd
            warn( "Improper recruitment age distribution. Ignoring recruitment scheme." )
            return
        end

        ageDist = Dict{Float64, Float64}()

        for jj in (rowNrOfDist + 2):rowNrOfDistEnd
            age = s[ dataColNr, jj ] * 12
            pMass = s[ dataColNr + 1, jj ]

            # Only add the entry if it makes sense.
            if isa( age, Float64 ) && isa( pMass, Float64 ) &&
                !haskey( ageDist, age )
                ageDist[ age ] = pMass
            end  # if isa( age, Float64 ) && ...
        end  # for jj in (rowNrOfDist + 2):rowNrOfDistEnd

        setAgeDistribution( recScheme, ageDist, distType )
    end  # if isFixedAge

    return recScheme

end  # function generateRecruitmentScheme( s, ii )


function readAttritionPars( mpSim::ManpowerSimulation, s::Taro.Sheet )

    if s[ "B", 4 ] == 1
        if s[ "B", 5 ] > 0
            attrScheme = Attrition( s[ "B", 5 ], s[ "B", 3 ] )
            setAttrition( mpSim, attrScheme )
        else
            setAttrition( mpSim )
        end  # if s[ "B", 5 ] > 0
    else
        lastRow = numRows( s, "C" )
        nAttrEntries = lastRow - 7  # 7 is the header row of the attrition curve
        attrCurve = zeros( Float64, nAttrEntries, 2 )
        foreach( ii -> attrCurve[ ii, : ] = [ s[ "B", ii + 7 ] * 12,
            s[ "C", ii + 7 ] ], 1:nAttrEntries )
        attrScheme = Attrition( attrCurve, s[ "B", 3 ] )
        setAttrition( mpSim, attrScheme )
    end  # if s[ "B", 4 ] == 1

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
