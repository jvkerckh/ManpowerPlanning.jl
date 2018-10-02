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
        warn( "The file `$tmpSnapName` does not exist. Cannot upload snapshot." )
        return
    end  # if !ispath( tmpSnapName )

    # Check if required columns (id, age, etc...) are all different
    colsToIgnore = [ idCol, recCol, ageCol, stateCol ]

    if length( unique( colsToIgnore ) ) < length( colsToIgnore )
        warn( "Some of the required columns (id, age, tenure, state) are the same. Cannot upload snapshot." )
        return
    end  # if length( unique( colsToIgnore ) ) < length( colsToIgnore )

    verifyAttributes( colsToImport, colsToIgnore, mpSim )

    # Make sure the name of the ID column is the one stored in the
    #   simulation configuration.
    if idCol > 0
        colsToImport[ idCol ] = mpSim.idKey
    end  # if idCol > 0

    # Add recruitment time information to the database.
    if recCol > 0
        colsToImport[ recCol ] = "timeEntered"
    end  # if recCol > 0

    # Add recruitment age information to the database.
    if ageCol > 0
        colsToImport[ ageCol ] = "ageAtRecruitment"
    end  # if ageCol > 0

    dataColsToGrab = collect( keys( colsToImport ) )
    systemAttrs = [ mpSim.idKey, "timeEntered", "ageAtRecruitment",
        "expectedRetirementTime" ]

    XLSX.openxlsx( tmpSnapName ) do xf
        # Get the personnel data.
        dataSheet = xf[ 1 ]
        nEntries, nCols = XLSX.size( XLSX.get_dimension( dataSheet ) )
        nEntries -= 1
        excessCols = filter( ii -> ii > nCols, dataColsToGrab )

        if nEntries == 0
            warn( "Snapeshot file '$snapName' empty." )
            return
        end  # if nEffectiveEntries == 0

        # Purge non-existent columns.
        if !isempty( excessCols )
            filter!( ii -> ii <= nCols, dataColsToGrab )
            warn( "Column(s) $(join( excessCols, ", " )) do(es) not exist in snapshot. Not importing those columns." )
        end  # if !isempty( excessCols )

        contents = XLSX.getdata( dataSheet )[ 2:end, dataColsToGrab ]
        colNames = map( ii -> colsToImport[ ii ], dataColsToGrab )
        idColIndex = findfirst( dataColsToGrab .== idCol )

        # Add generated id if no ID column is present in the retrieved data.
        if ( idCol <= 0 ) || ( idCol > nCols )
            contents = hcat( contents,
                "Sim" .* string.( collect( 1:nEntries ) ) )
            push!( colNames, mpSim.idKey )
        else
            uniqueIndices = indexin( unique( contents[ :, idColIndex ] ),
                contents[ :, idColIndex ] )
            contents = contents[ uniqueIndices, : ]
        end  # if ( idCol <= 0 ) || ...

        nEffectiveEntries = size( contents )[ 1 ]
        println( nEntries - nEffectiveEntries,
            " entry/ies with duplicate IDs. Retaining only one of each." )

        if catalogueName != ""
            tmpCatalogueName = endswith( catalogueName, ".xlsx" ) ?
                catalogueName : catalogueName * ".xlsx"
            isEntryOkay = validateContents( contents,
                colNames[ vcat( 1:(idColIndex-1), (idColIndex+1):end ) ],
                mpSim.idKey, tmpCatalogueName )
            contents = contents[ isEntryOkay, : ]
            nEffectiveEntries = sum( isEntryOkay )

            if nEffectiveEntries == 0
                warn( "No valid personnel entries left in snapshot file '$snapName'." )
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

        # Determine retirement ages/times.
        push!( colNames, "expectedRetirementTime" )
        contents = hcat( contents, map( ii -> computeExpectedRetirementTime(
            mpSim, mpSim.retirementScheme, contents[ ii, ageColIndex ],
            contents[ ii, recColIndex ] ), 1:nEffectiveEntries ) )

        # Retrieve time of last transition.
        lastTransTime = - 12.0 .* ones( nEntries )

        if 0 < stateCol <= nCols
            lastTransTime = map( transDate ->
            -( mpSim.simStartDate - transDate ).value,
                XLSX.getdata( dataSheet )[ 2:end, stateCol ] ) ./
                ( 365.0 / 12.0 )
        end  # if 0 < stateCol <= nCols


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

            # Add person to state list.
            for stateName in persStates
                state = mpSim.stateList[ stateName ]
                transTime = lastTransTime[ ii ]
                state.inStateSince[ id ] = transTime
                state.isLockedForTransition[ id ] = false
                attrScheme = state.attrScheme
                timeOfAttr = transTime

                while isa( timeOfAttr, Real ) && ( timeOfAttr <= 0.0 )
                    timeOfAttr = generateTimeOfAttrition( attrScheme,
                        transTime )
                end  # while isa( timeOfAttr, Real )

                attritionSchemes[ ii ] = attrScheme.name
                attritionTimes[ ii ] = timeOfAttr
                push!( transCmd,
                    "('$id', $transTime, 'snapshot', '$stateName')" )
            end  # for state in persStates
        end  # for ii in 1:nEffectiveEntries

        map!( dataPoint -> isa( dataPoint, String ) ? "'" * dataPoint * "'" :
            dataPoint, contents, contents )

        contents = hcat( contents, attritionTimes,
            "'" .* attritionSchemes .* "'" )

        # Inject data into database.
        persCmd = map( ii -> "(" * join( contents[ ii, : ], ", " ) *
            ", 'active')", 1:nEffectiveEntries )
        persCmd = "INSERT INTO $(mpSim.personnelDBname)
            ('$(join( colNames, "', '" ))', expectedAttritionTime, attritionScheme, status)
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
            histCmd = "INSERT INTO $(mpSim.historyDBname)
                ($(mpSim.idKey), attribute, timeIndex, strValue)
                VALUES $(join( histCmd, ", " ))"
            SQLite.execute!( mpSim.simDB, histCmd )
        end  # for attrName in varColNames

        # Generate transition database.
        transCmd = "INSERT INTO $(mpSim.transitionDBname)
            ($(mpSim.idKey), timeIndex, transition, endState )
            VALUES $(join( transCmd, ", " ))"
        SQLite.execute!( mpSim.simDB, transCmd )
        mpSim.personnelSize = nEffectiveEntries
        mpSim.resultSize = nEffectiveEntries

        # Statistics of entered data.
        println( "Entered $nEffectiveEntries of $nEntries persons ($(100.0 * nEffectiveEntries / nEntries)%) in snapshot into database." )

        # for ii in eachindex( colNames )
        #     if colNames[ ii ] ∉ systemAttrs
        #         counts = StatsBase.countmap( contents[ :, ii ] )
        #         println( "Attribute '$(colNames[ ii ])':" )
        #         foreach( val -> println( "   $val: $(counts[ val ])  ($(100.0 * counts[ val ] / nEffectiveEntries )%)" ), keys( counts ) )
        #     end  # if colNames( ii ) ∉ [ mpSim.idKey, ...
        # end  # for ii in eachindex( colNames )
    end  # XLSX.openxlsx( tmpSnapName ) do xf

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


function validateContents( dataMatrix::Array, attrNames::Vector{String},
    idKey::String, catalogueName::String )::Vector{Bool}

    nEntries = size( dataMatrix )[ 1 ]
    isEntryOkay = trues( nEntries )

    XLSX.openxlsx( catalogueName ) do xf
        dataSheet = xf[ "General" ]
        nAttrs = dataSheet[ "B5" ]
        dataSheet = xf[ "Attributes" ]
        catalogueAttrNames = dataSheet[ "A2:A$(nAttrs + 1)" ]

        for ii in eachindex( attrNames )
            attrName = attrNames[ ii ]

            if attrName ∉ [ idKey, "timeEntered", "ageAtRecruitment" ]
                attrIndex = findfirst( catalogueAttrNames .== attrName )
                nVals = dataSheet[ "E$(attrIndex + 1)" ]
                vals = dataSheet[ XLSX.CellRange( attrIndex + 1, 6,
                    attrIndex + 1, 5 + nVals ) ]
                isEntryOkay .&= map( val -> val ∈ vals, dataMatrix[ :, ii ] )
            end  # if attrName != idKey
        end  # for attrName in attrNames
    end  # XLSX.openxlsx( catalogueName ) do xf

    println( nEntries - sum( isEntryOkay ), " entries contained attribute values not defined in the catalogue." )

    return isEntryOkay

end  # validateContents( dataMatrix, attrNames, idKey, catalogueName )


function readSnapshot( mpSim::ManpowerSimulation )::Void

    tStart = now()

    XLSX.openxlsx( mpSim.parFileName ) do xf
        if !XLSX.hassheet( xf, "Snapshot" )
            warn( "Configuration file has no sheet named 'Snapshot'. Not uploading initial population." )
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
            warn( "Snapshot file '$snapName' does not exist. Not uploading initial population." )
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
    end  # XLSX.openXLSX( mpSim.parFileName) do xf

    println( "Processing initial population snapshot took ",
        ( now() - tStart ).value / 1000, " seconds." )

    return

end  # readSnapshot( mpSim )
