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
    initDB::Bool = false )

    # Do nothing if the file isn't an Excel file.
    if !endswith( fileName, ".xlsx" )
        warn( "File is not an Excel file. Not making any changes." )
        return
    end  # if !endswith( fileName, ".xlsx" )

    # Check if the file has the required sheets.
    w = Workbook( fileName )
    sheets = [ "General",
               "Attributes",
               "States",
               "Transitions",
               "Recruitment",
               "Attrition",
               "Retirement" ]

    if any( shName -> getSheet( w, shName ).ptr === Ptr{Void}( 0 ), sheets )
        warn( "Improperly formatted Excel parameter file. Not making any changes." )
        return
    end  # if any( shName -> getSheet( w, shName ).ptr === ...

    # Read general parameters.
    s = getSheet( w, "General" )

    if initDB
        readDBpars( mpSim, s )
    end  # if initDB

    readGeneralPars( mpSim, s )

    # Read attrition parameters.
    s = getSheet( w, "Attrition" )
    readAttritionPars( mpSim, s )

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
        newState, isInitial, attrName, sLine = readState( s, sLine )
        setStateAttritionScheme( newState, attrName, mpSim )
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
        isExtraCondsOkay = true

        # Test if all the extra conditions deal with attributes (or age)
        for cond in newTrans.extraConditions
            if isExtraCondsOkay
                isExtraCondsOkay = ( cond.attr == "age" ) ||
                    any( attr -> attr.name == cond.attr,
                    vcat( mpSim.initAttrList, mpSim.otherAttrList ) )
            end  # if isExtraCondsOkay
        end  # for cond in newTrans.extraConditions

        for attr in newTrans.extraChanges
            if isExtraCondsOkay
                isExtraCondsOkay = any( tmpAttr -> tmpAttr.name == attr.name,
                    vcat( mpSim.initAttrList, mpSim.otherAttrList ) )
            end  # if isExtraCondsOkay
        end  # for attr in newTrans.extraChanges

        # If either of the states with the given name can't be found, throw an
        #   error.
        if startInd * endInd == 0
            error( "Start state or end state unknown." )
        elseif !isExtraCondsOkay
            error( "Extra transition conditions/changes on unknown attribute." )
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

    dataColNr = ii * 5 - 3
    name = s[ dataColNr, 5 ]
    recScheme = Recruitment( name, s[ dataColNr, 6 ], s[ dataColNr, 7 ] )
    isAdaptive = s[ dataColNr, 10 ] == 1
    isRandom = s[ dataColNr, 11 ] == 1
    nRow = 17

    if isAdaptive
        minRec = s[ dataColNr, 8 ] === nothing ? 0 : Int( s[ dataColNr, 8 ] )
        setRecruitmentLimits( recScheme, minRec, Int( s[ dataColNr, 9 ] ) )
    elseif isRandom
        distType = distTypes[ s[ dataColNr, 15 ] ]
        numNodes = Int( s[ dataColNr, 16 ] )
        minNodes = distType == "Pointwise" ? 1 : 2
        recDist = Dict{Int, Float64}()

        for jj in 1:numNodes
            node = s[ dataColNr, nRow + jj ]
            weight = s[ dataColNr + 1, nRow + jj ]

            if isa( node, Float64 ) && !haskey( recDist, node ) &&
                ( node >= 0 ) && isa( weight, Float64 ) && ( weight >= 0 )
                recDist[ floor( Int, node ) ] = weight
            end  # if isa( node, Float64 ) && ...
        end  # for ii in 1:numNodes

        if length( recDist ) < minNodes
            error( "Recruitment type $name has an insufficient number of valid nodes defined for its population size distribution." )
        end  # if numNodes < ( distType == "Pointwise" ? 1 : 2 )

        setRecruitmentDistribution( recScheme, recDist, distType )
    else
        setRecruitmentFixed( recScheme, Int( s[ dataColNr, 9 ] ) )
    end  # if isAdaptive

    isFixedAge = s[ dataColNr, 12 ] == 1

    # Add the age distribution.
    if isFixedAge
        setRecruitmentAge( recScheme, s[ dataColNr, 13 ] * 12 )
    else
        # Get to the start of the age distribution
        nRow += 1

        while isa( s[ dataColNr - 1, nRow ], Void )
            nRow += 1
        end  # while isa( s[ dataColNr - 1, nRow ], Void )

        distType = distTypes[ s[ dataColNr, nRow ] ]
        numNodes = Int( s[ dataColNr, nRow + 1 ] )
        minNodes = distType == "Pointwise" ? 1 : 2
        nRow += 2
        ageDist = Dict{Float64, Float64}()

        for jj in 1:numNodes
            age = s[ dataColNr, nRow + jj ] * 12
            pMass = s[ dataColNr + 1, nRow + jj ]

            # Only add the entry if it makes sense.
            if isa( age, Float64 ) && !haskey( ageDist, age ) && ( age >= 0 ) &&
                isa( pMass, Float64 ) && ( pMass >= 0 )
                ageDist[ age ] = pMass
            end  # if isa( age, Float64 ) && ...
        end  # for jj in (rowNrOfDist + 2):rowNrOfDistEnd

        if length( ageDist ) < minNodes
            error( "Recruitment type $name has an insufficient number of valid nodes defined for its recruitment age distribution." )
        end  # if numNodes < ( distType == "Pointwise" ? 1 : 2 )

        setAgeDistribution( recScheme, ageDist, distType )
    end  # if isFixedAge

    return recScheme

end  # function generateRecruitmentScheme( s, ii )


function readAttritionPars( mpSim::ManpowerSimulation, s::Taro.Sheet )

    attrScheme = readAttrition( s, 2, true )
    setAttrition( mpSim, attrScheme )
    colNr = 5
    clearAttritionSchemes!( mpSim )

    # Read all other attrition schemes.
    while !isa( s[ colNr, 5 ], Void )
        attrScheme = readAttrition( s, colNr )
        addAttritionScheme!( attrScheme, mpSim )
        colNr += 3
    end  # while !isa( s[ colNr, 5 ], Void )

end  # readAttritionPars( mpSim, s )


function readRetirementPars( mpSim::ManpowerSimulation, s::Taro.Sheet )

    maxTenure = s[ "B", 5 ] * 12
    maxAge = s[ "B", 6 ] * 12
    isEither = s[ "B", 7 ] == "EITHER"
    retScheme = Retirement( freq = s[ "B", 3 ], offset = s[ "B", 4 ],
        maxCareer = maxTenure, retireAge = maxAge, isEither = isEither )
    setRetirement( mpSim, retScheme )

end  # readRetirementPars( mpSim, s )
