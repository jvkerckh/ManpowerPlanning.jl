# This file holds the function to upload the initial poulation snapshot.

export uploadSnapshot

function uploadSnapshot( mpSim::ManpowerSimulation, snapName::String,
    idCol::Int, colsToImport::Dict{Int,String} = Dict{Int, String}(),
    catalogueName::String = ""; recCol::Int = -1, isRecDate::Bool = true,
    ageCol::Int = -2, defaultRecAge::Float64 = 18.0, isBirthDate::Bool = true,
    stateCol::Int = -3 )::Void

    tmpSnapName = snapName
    tmpSnapName *= endswith( snapName, ".xlsx" ) ? "" : ".xlsx"

    if !ispath( tmpSnapName )
        warn( string( "The file '", tmpSnapName,
            "' does not exist. Cannot upload snapshot." ) )
        return
    end  # if !ispath( tmpSnapName )

    # Check if required columns (id, age, etc...) are all different.
    colsToIgnore = [ idCol, recCol, ageCol, stateCol ]

    if length( unique( colsToIgnore ) ) < length( colsToIgnore )
        warn( "Some of the required columns (id, age, tenure, state) are the same. Cannot upload snapshot." )
        return
    end  # if length( unique( colsToIgnore ) ) < length( colsToIgnore )

    verifyAttributes( colsToImport, colsToIgnore, mpSim )
    extraColsToImport = addSystemAttributes( mpSim, idCol, recCol, ageCol )
    dataColsToGrab = collect( keys( colsToImport ) )
    filter!( ii -> !haskey( extraColsToImport, ii ), dataColsToGrab )
    systemAttrs = [ mpSim.idKey, "timeEntered", "ageAtRecruitment" ]
    snapshotComp = Dict{String, Int}()

    XLSX.openxlsx( tmpSnapName ) do xf
        # Get the personnel data.
        dataSheet = xf[ 1 ]
        nEntries, nCols = XLSX.size( XLSX.get_dimension( dataSheet ) )
        nEntries -= 1
        excessCols = filter( ii -> ii > nCols, dataColsToGrab )

        if nEntries == 0
            warn( string( "Snapshot file '", snapName, "' is empty." ) )
            return
        end  # if nEffectiveEntries == 0

        # Purge non-existent columns.
        if !isempty( excessCols )
            filter!( ii -> ii <= nCols, dataColsToGrab )
            warn( string( "Column(s) ", join( excessCols, ", " ),
                " do(es) not exist in snapshot. ",
                "Not importing those columns." ) )
        end  # if !isempty( excessCols )

        contents = string.( XLSX.getdata( dataSheet )[ 2:end, dataColsToGrab ] )
        colNames = map( ii -> colsToImport[ ii ], dataColsToGrab )
        extraColsToGrab = collect( keys( extraColsToImport ) )
        contents = hcat( contents, XLSX.getdata( dataSheet )[ 2:end,
            extraColsToGrab ] )
        colNames = vcat( colNames, map( ii -> extraColsToImport[ ii ],
            extraColsToGrab ) )
        idColIndex = findfirst( extraColsToGrab .== idCol ) +
            length( dataColsToGrab )
        contents[ :, idColIndex ] = string.( contents[ :, idColIndex ] )

        # Retrieve time of last transition.
        lastTransTime = - 12.0 .* ones( nEntries )

        if 0 < stateCol <= nCols
            lastTransTime = map( transDate ->
            -( mpSim.simStartDate - transDate ).value,
                XLSX.getdata( dataSheet )[ 2:end, stateCol ] ) ./
                ( 365.0 / 12.0 )
        end  # if 0 < stateCol <= nCols

        # Add generated id if no ID column is present in the retrieved data, or
        #   if IDs are missing for some entries, and remove duplicates.
        if ( idCol <= 0 ) || ( idCol > nCols )
            contents = hcat( contents,
                "Sim" .* string.( collect( 1:nEntries ) ) )
            push!( colNames, mpSim.idKey )
        else
            # Fill in missing IDs
            isIDmissing = contents[ :, idColIndex ] .== "missing"

            if any( isIDmissing )
                existingIDs = sort( contents[ .!isIDmissing, idColIndex ] )
                generatedIDs = string.( "Sim", 1:sum( isIDmissing ) )
                contents[ isIDmissing, idColIndex ] = generatedIDs
            end  # if any( isIDmissing )

            # Filter out duplicates.
            uniqueIndices = indexin( unique( contents[ :, idColIndex ] ),
                contents[ :, idColIndex ] )
            contents = contents[ uniqueIndices, : ]
            lastTransTime = lastTransTime[ uniqueIndices ]
        end  # if ( idCol <= 0 ) || ...

        nEffectiveEntries = size( contents )[ 1 ]

        if nEntries > nEffectiveEntries
            warn( nEntries - nEffectiveEntries,
                " entry/ies with duplicate IDs. Retaining only one of each." )
            snapshotComp[ "Duplicates" ] = nEntries - nEffectiveEntries
        end  # if nEntries > nEffectiveEntries

        # Ensure the attribute values satisfy the catalogue, if present.
        if catalogueName != ""
            tmpCatalogueName = endswith( catalogueName, ".xlsx" ) ?
                catalogueName : catalogueName * ".xlsx"
            isEntryOkay = validateContents( contents,
                colNames[ eachindex( dataColsToGrab ) ], tmpCatalogueName )
            contents = contents[ isEntryOkay, : ]
            lastTransTime = lastTransTime[ isEntryOkay ]

            if !all( isEntryOkay )
                tmpEntries = nEffectiveEntries
                nEffectiveEntries = sum( isEntryOkay )
                snapshotComp[ "Invalid" ] = tmpEntries - nEffectiveEntries
            end  # if !all( isentryOkay )

            if nEffectiveEntries == 0
                warn( string( "No valid personnel entries left in snapshot ",
                    "file '", snapName, "'." ) )
                return
            end  # if nEffectiveEntries == 0
        end  # if catalogueName != ""

        recColIndex = length( colNames ) + 1

        # Adjust recruitment time information.
        if ( recCol <= 0 ) || ( recCol > nCols )
            contents = hcat( contents, zeros( Float64, nEffectiveEntries ) )
            push!( colNames, "timeEntered" )
        else
            recColIndex = findfirst( colName -> colName == "timeEntered",
                colNames )

            if isRecDate
                contents[ :, recColIndex ] = map( recDate ->
                    -( mpSim.simStartDate - recDate ).value,
                    contents[ :, recColIndex ] ) ./ ( 365.0 / 12.0 )
            else
                contents[ :, recColIndex ] *= -12.0
            end  # if isRecDate
        end  # if ( recCol <= 0 ) || ...

        ageColIndex = length( colNames ) + 1

        # Adjust recruitment age information.
        if ( ageCol <= 0 ) || ( ageCol > nCols )
            contents = hcat( contents, ones( Float64, nEffectiveEntries ) .*
                ( 12.0 * defaultRecAge ) )
            push!( colNames, "ageAtRecruitment" )
        else
            ageColIndex = findfirst( colName -> colName == "ageAtRecruitment",
                colNames )

            # Determine ages in months.
            if isBirthDate
                contents[ :, ageColIndex ] = map( birthDate ->
                    ( mpSim.simStartDate - birthDate ).value,
                    contents[ :, ageColIndex ] ) ./ ( 365.0 / 12.0 )
            else
                contents[ :, ageColIndex ] *= 12.0
            end  # if isBirthDate

            contents[ :, ageColIndex ] += contents[ :, recColIndex ]
        end  # if ( ageCol <= 0 ) || ...

        # Discover states of personnel members.
        attrList = filter( attrName -> attrName ∉ systemAttrs, colNames )
        attrIndices = map( attrName -> findfirst( attrName .== colNames ),
            attrList )
        attrVals = Dict{String, Any}()
        transCmd = "('" .* contents[ :, idColIndex ] .* "', " .*
            string.( contents[ :, recColIndex ] ) .* ", 'snapshot', 'active')"
        stateList = Dict{String, Vector{State}}()
        attritionSchemes = Vector{String}( nEffectiveEntries )
        attritionTimes = Vector{Union{String, Float64}}( nEffectiveEntries )

        for ii in 1:nEffectiveEntries
            for jj in attrIndices
                attrVals[ colNames[ jj ] ] = contents[ ii, jj ]
            end  # for jj in attrIndices

            # Identify all initial states the person belongs to and add entry info to
            #   each of those states.
            persStates = collect( Iterators.filter(
                state -> isPersonnelOfState( attrVals,
                    mpSim.stateList[ state ] ), keys( mpSim.stateList ) ) )
                # XXX Iterators.filter is needed to avoid deprecation warnings.

            id = contents[ ii, idColIndex ]

            if isempty( persStates )
                snapshotComp[ "No state" ] = 1 +
                    get( snapshotComp, "No state", 0 )
            elseif length( persStates ) > 1
                snapshotComp[ "Multiple states" ] = 1 +
                    get( snapshotComp, "Multiple states", 0 )
            else
                stateName = persStates[ 1 ]
                snapshotComp[ stateName ] = 1 +
                    get( snapshotComp, stateName, 0 )
            end  # if isempty( persStates )

            # Check if each person can be assigned to exactly one state.
            if mpSim.isWellDefined
                if isempty( persStates )
                    mpSim.isWellDefined = false
                    warn( "Person read that couldn't be assigned to any state. Please check if all required attributes to determine state have been read." )
                elseif length( persStates ) > 1
                    mpSim.isWellDefined = false
                    warn( "Person read that can be assigned to multiple states. Please check system configuration for consistency." )
                end  # if isempty( initPersStates )
            end  # if mpSim.isWellDefined

            # Determine person's expected time of attrition.
            attrScheme = mpSim.defaultAttritionScheme
            transTime = lastTransTime[ ii ]
            timeOfAttr = transTime

            # Add person to state list.
            for stateName in persStates
                state = mpSim.stateList[ stateName ]
                state.inStateSince[ id ] = transTime
                attrScheme = state.attrScheme
                push!( transCmd,
                    "('$id', $transTime, 'snapshot', '$stateName')" )
            end  # for state in persStates

            while isa( timeOfAttr, Real ) && ( timeOfAttr <= 0.0 )
                timeOfAttr = generateTimeOfAttrition( attrScheme,
                    transTime )
            end  # while isa( timeOfAttr, Real )

            attritionSchemes[ ii ] = attrScheme.name
            attritionTimes[ ii ] = timeOfAttr
        end  # for ii in 1:nEffectiveEntries

        map!( dataPoint -> isa( dataPoint, String ) ? "'" * dataPoint * "'" :
            dataPoint, contents, contents )

        contents = hcat( contents, attritionTimes,
            "'" .* attritionSchemes .* "'" )

        # Inject data into database.
        persCmd = map( ii -> "(" * join( contents[ ii, : ], ", " ) *
            ", 'active')", 1:nEffectiveEntries )
        persCmd = "INSERT INTO `$(mpSim.personnelDBname)`
            (`$(join( colNames, "`, `" ))`, expectedAttritionTime, attritionScheme, status)
            VALUES $(join( persCmd, ", " ))"
        SQLite.execute!( mpSim.simDB, persCmd )

        # Generate the history database.
        isAttrFixed = Dict{String, Bool}()
        fixedAttrList = filter( attr -> attr.isFixed,
            vcat( mpSim.initAttrList, mpSim.otherAttrList ) )
        fixedAttrList = vcat( map( attr -> attr.name, fixedAttrList ),
            systemAttrs )
        varColNames = filter( attrName -> attrName ∉ fixedAttrList, colNames )

        for attrName in varColNames
            attrIndex = findfirst( attrName .== colNames )
            histCmd = "(" .* contents[ :, idColIndex ] .* ", '" .* attrName .*
                "', " .* string.( lastTransTime ) .* ", " .*
                contents[ :, attrIndex ] .* ")"
                # XXX -12.0 is chosen since actual information on last attribute
                #   change isn't available, and for consistency when tenure
                #   information is missing.
            histCmd = "INSERT INTO `$(mpSim.historyDBname)`
                (`$(mpSim.idKey)`, attribute, timeIndex, strValue)
                VALUES $(join( histCmd, ", " ))"
            SQLite.execute!( mpSim.simDB, histCmd )
        end  # for attrName in varColNames

        # Generate transition database.
        transCmd = "INSERT INTO `$(mpSim.transitionDBname)`
            (`$(mpSim.idKey)`, timeIndex, transition, endState )
            VALUES $(join( transCmd, ", " ))"
        SQLite.execute!( mpSim.simDB, transCmd )
        mpSim.personnelSize = nEffectiveEntries
        mpSim.resultSize = nEffectiveEntries

        # Statistics of entered data.
        if mpSim.showOutput
            println( "Entered ", nEffectiveEntries, " of ", nEntries,
                " persons (", 100.0 * nEffectiveEntries / nEntries,
                "%) in snapshot into database." )
        end  # if mpSim.showOutput
    end  # XLSX.openxlsx( tmpSnapName ) do xf

    # Generate a pie chart of the composition of the snapshot.
    if mpSim.showOutput
        snapshotStates = collect( keys( snapshotComp ) )
        snapshotVals = get.( Ref( snapshotComp ), snapshotStates, 0 )
        gui( pie( string.( snapshotStates, ": ", snapshotVals ), snapshotVals,
            labels = "", title = "Composition of snapshot", lw = 2,
            size = ( 960, 540 ) ) )
    end

    return

end  # uploadSnapshot( mpSim, snapName, idCol, colsToImport, catalogueName,
    #    recCol, isRecDate, ageCol, defaultRecAge, isBirthDate, stateCol )


# ==============================================================================
# Non-exported methods.
# ==============================================================================

function verifyAttributes( colsToImport::Dict{Int, String},
    colsToIgnore::Vector{Int}, mpSim::ManpowerSimulation )::Void

    # Import only columns which have been defined as attributes.
    attrNameList = map( attr -> attr.name,
        vcat( mpSim.initAttrList, mpSim.otherAttrList ) )
    colsNotToImport = Vector{Int}()

    for ii in keys( colsToImport )
        if ( ii ∉ colsToIgnore ) && ( colsToImport[ ii ] ∉ attrNameList )
            push!( colsNotToImport, ii )
        end  # if ii != idcol
    end  # for ii in keys( colsToImport )

    for ii in colsNotToImport
        delete!( colsToImport, ii )
    end  # for ii in colsNotToImport

    return

end  # verifyAttributes( colsToImport, colsToIgnore, mpSim )


function addSystemAttributes( mpSim::ManpowerSimulation, idCol::Int,
    recCol::Int, ageCol::Int )::Dict{Int64, String}

    extraColsToImport = Dict{Int64,String}()

    # Make sure the name of the ID column is the one stored in the
    #   simulation configuration.
    if idCol > 0
        extraColsToImport[ idCol ] = mpSim.idKey
    end  # if idCol > 0

    # Add recruitment time information to the database.
    if recCol > 0
        extraColsToImport[ recCol ] = "timeEntered"
    end  # if recCol > 0

    # Add recruitment age information to the database.
    if ageCol > 0
        extraColsToImport[ ageCol ] = "ageAtRecruitment"
    end  # if ageCol > 0

    return extraColsToImport

end  # addSystemAttributes( mpSim, idCol, recCol, ageCol )


function retrieveLastTransitionTime( mpSim::ManpowerSimulation, nEntries::Int,
    stateCol::Int, nCols::Int, dataSheet::XLSX.Worksheet, contents::Array,
    snapshotComp::Dict{String, Int} )

    # Retrieve time of last transition.
    lastTransTime = - 12.0 .* ones( nEntries )

    if 0 < stateCol <= nCols
        lastTransDates = XLSX.getdata( dataSheet )[ 2:end, stateCol ]
        isDateMissing = isa.( lastTransDates, Missings.Missing )

        if any( isDateMissing )
            snapshotComp[ "Invalid" ] = sum( isDateMissing )
            nEntries -= sum( isDateMissing )
        end  # if any( isDateMissing )

        lastTransDates = lastTransDates[ .!isDateMissing ]
        contents = contents[ .!isDateMissing, : ]
        lastTransTime = map( transDate ->
        -( mpSim.simStartDate - transDate ).value, lastTransDates ) ./
            ( 365.0 / 12.0 )
    end  # if 0 < stateCol <= nCols

    return lastTransTime, contents

end  # retrieveLastTransitionTime( mpSim, nEntries, stateCol, nCols, dataSheet,
     #   contents, snapshotComp )


function validateContents( dataMatrix::Array, attrNames::Vector{String},
    catalogueName::String )::Vector{Bool}

    nEntries = size( dataMatrix )[ 1 ]
    isEntryOkay = trues( nEntries )

    XLSX.openxlsx( catalogueName ) do xf
        dataSheet = xf[ "General" ]
        nAttrs = dataSheet[ "B5" ]
        dataSheet = xf[ "Attributes" ]
        catalogueAttrNames = dataSheet[ "A2:A$(nAttrs + 1)" ]

        for ii in eachindex( attrNames )
            attrName = attrNames[ ii ]
            attrIndex = findfirst( catalogueAttrNames .== attrName )
            nVals = dataSheet[ "E$(attrIndex + 1)" ]
            vals = string.( dataSheet[ XLSX.CellRange( attrIndex + 1, 6,
                attrIndex + 1, 5 + nVals ) ] )
            isEntryOkay .&= map( val -> val ∈ vals, dataMatrix[ :, ii ] )
        end  # for attrName in attrNames
    end  # XLSX.openxlsx( catalogueName ) do xf

    if nEntries > sum( isEntryOkay )
        warn( nEntries - sum( isEntryOkay ),
            " entries contained attribute values not defined in the catalogue." )
    end  # if nEntries > sum( isEntryOkay )

    return isEntryOkay

end  # validateContents( dataMatrix, attrNames, catalogueName )


function readSnapshot( mpSim::ManpowerSimulation )::Void

    tStart = now()

    XLSX.openxlsx( mpSim.parFileName ) do xf
        if !XLSX.hassheet( xf, "Snapshot" )
            warn( string( "Configuration file has no sheet named 'Snapshot'. ",
                "Not uploading initial population." ) )
            return
        end  # if !hassheet( xf, "Snapshot" )

        snapSheet = xf[ "Snapshot" ]

        if snapSheet[ "B3" ] == "NO"
            return
        end  # if snapSheet[ "B3" ] == "NO"

        snapName = snapSheet[ "B4" ]
        snapName *= endswith( snapName, ".xlsx" ) ? "" : ".xlsx"
        snapName = joinpath( dirname( mpSim.parFileName ), snapName )

        if !ispath( snapName )
            warn( string( "Snapshot file '", snapName,
                "' does not exist. Not uploading initial population." ) )
            return
        end  # if !ispath( snapName )

        # Get special column parameters.
        idCol = snapSheet[ "B5" ]
        idCol = isa( idCol, Missings.Missing ) ? 0 : idCol
        recCol = snapSheet[ "B6" ]
        recCol = isa( recCol, Missings.Missing ) ? -1 : recCol
        ageCol = snapSheet[ "B8" ]
        ageCol = isa( ageCol, Missings.Missing ) ? -2 : ageCol
        stateCol = snapSheet[ "B10" ]
        stateCol = isa( stateCol, Missings.Missing ) ? -3 : stateCol
        isRecDate = snapSheet[ "B7" ] == "YES"
        isBirthDate = snapSheet[ "B9" ] == "YES"

        # Get columns to import.
        nCols = snapSheet[ "B13" ]
        colsToImport = Dict{Int, String}()
        foreach( ii -> colsToImport[ snapSheet[ "A$(ii+15)" ] ] =
            snapSheet[ "B$(ii+15)" ], 1:nCols )

        uploadSnapshot( mpSim, snapName, idCol, colsToImport, mpSim.catFileName,
            recCol = recCol, isRecDate = isRecDate, ageCol = ageCol,
            isBirthDate = isBirthDate, stateCol = stateCol )

        if mpSim.showOutput
            println( "Processing initial population snapshot took ",
                ( now() - tStart ).value / 1000, " seconds." )
        end  # if mpSim.showOutput
    end  # XLSX.openXLSX( mpSim.parFileName) do xf

    return

end  # readSnapshot( mpSim )
