export uploadSnapshot


"""
```
uploadSnapshot(
    mpSim::MPsim,
    snapname::AbstractString,
    sheetname::AbstractString,
    colsToImport::Union{Vector{ColIndex}, Vector{String}, Vector{Int}},
    specialCols::NTuple{5,ColIndex},
    refDate::Date = Date(now());
    validateData::Bool=true,
    generateSimData::Bool=false )
```
This function uploads the Excel snapshot in tab `sheetname` of file `snapname` to the manpower simulation `mpSim`. The function imports the columns in `colsToImport`, which can be given as a mix of column number or column refererence. The columns in `specialCols` will also be imported, and these are, in order,
1. the unique ID
2. the time since the last transition
3. the tenure
4. the current age
5. the current node

Duplicate IDs get ignored, and missing IDs or times get generated with a best guess. The optional parameters are `validateData`, which flags records and attributes containing values that haven't been defined in the simulation if `true`, and `generateSimData`, which tries to generate new attributes and values based on the snapshot.
"""
function uploadSnapshot( mpSim::MPsim, snapname::AbstractString,
    sheetname::AbstractString,
    colsToImport::Union{Vector{ColIndex}, Vector{String}, Vector{Int}},
    specialCols::NTuple{5,ColIndex}; refDate::Date=Date(now()),
    dateType::Symbol=:month, validateData::Bool=true,
    generateSimData::Bool=false )

    snapname = string( snapname, endswith( snapname, ".xlsx" ) ? "" : ".xlsx" )

    if !ispath( snapname )
        @warn string( "File with name '", snapname,
            "' doesn't exist, cannot upload initial population." )
        return
    end  # if !ispath( snapname )

    # Check if the special columns are all different.
    specialCols = map( specialCols ) do colNr
        colNr isa AbstractString ? XLSX.decode_column_number( colNr ) : colNr
    end  # map( ... ) do colNr

    if length( unique( specialCols ) ) < length( specialCols )
        @warn "Some of the required columns (id, tenure) are the same, cannot upload initial population."
        return
    end  # if length( unique( specialCols ) ) < length( specialCols )

    colsToImport = map( colRef -> colRef isa Int ? colRef :
        XLSX.decode_column_number( colRef ), colsToImport )
    colsToImport = unique( sort( vcat( colsToImport, specialCols... ) ) )
    isSnapshotBad = false
    nRecords = 0
    personnelData = nothing
    attributeNames = nothing

    XLSX.openxlsx( snapname ) do xf
        if !XLSX.hassheet( xf, sheetname )
            @warn string( "File doesn't have a sheet '", sheetname,
                "', cannot upload initial population." )
            isSnapshotBad = true
            return
        end  # if !XLSX.hassheet( xf, sheetname )

        xs = xf[sheetname]
        nCols, nRecords = getfield.( Ref(xs.dimension.stop),
            (:column_number, :row_number) )
        nRecords -= 1

        if nRecords == 0
            @info "No records in snapshot."
            isSnapshotBad = true
            return
        elseif mpSim.showInfo
            @info string( "The file has ", nRecords, " records." )
        end  # if nRecords == 0

        # Read the special columns.
        filter!( ii -> 0 < ii <= nCols, colsToImport )
        specialCols = map( colNr -> colNr ∈ colsToImport ? colNr : 0,
            specialCols )
        setSimulationKey!( mpSim, specialCols[1] == 0 ?
            string( xs[1, specialCols[1]] ) : "id" )

        ids, isBad = readIDs( xs, specialCols[1], nRecords, mpSim )
        lastTransTimes = readTimes( xs, specialCols[2], refDate, dateType,
            nRecords, isBad, mpSim )
        tenures = readTimes( xs, specialCols[3], refDate, dateType, nRecords,
            isBad, mpSim )
        ages = readTimes( xs, specialCols[4], refDate, dateType, nRecords,
            isBad, mpSim )
        startNodes = readNodes( xs, specialCols[5], nRecords, isBad, mpSim )

        # for timeData in [lastTransTimes, tenures, ages]
        #     any(isa.( timeData, Date )) &&
        #         computeTimes!( timeData, refDate, dateType )
        # end  # for timeData in [lastTransTimes, tenures, ages]

        # Read attribute data.
        filter!( ii -> ii ∉ specialCols, colsToImport )        
        personnelData, attributeNames = readData( xs, ids, lastTransTimes,
            tenures, ages, startNodes, colsToImport, nRecords, isBad, mpSim )
        
        if size( personnelData, 1 ) == 0
            @warn "No valid entries in the initial population file."
            isSnapshotBad = true
            return
        end  # if size( personnelData, 1 ) == 0

        # If attributes aren't validated, they have to be generated from the
        #   data.
        generateSimData |= !validateData
        
        if validateData
            personnelData = validateAttributeData( personnelData,
                attributeNames, mpSim )
        end  # if validateData

        isValidAttribute = validateData ?
            map( name -> haskey( mpSim.attributeList, name ), attributeNames ) :
            falses( length( attributeNames ) )

        if !generateSimData
            # The latter ensures that the extra columns are included.
            attributeNames = attributeNames[isValidAttribute]
            personnelData = personnelData[:,
                vcat( isValidAttribute, trues( 5 ) )]
        else
            if !all( isValidAttribute )
                generateSimAttributes!( mpSim, personnelData, attributeNames,
                    .!isValidAttribute )
            end  # if !all( isValidAttribute )

            generateSimNodes!( mpSim, personnelData, attributeNames )
            inferBaseNodes( mpSim, personnelData, attributeNames )
        end  # if !generateSimData

        if size( personnelData, 2 ) == 5
            @warn "No valid attributes in the initial population file."
            isSnapshotBad = true
            return
        end  # if size( personnelData, 2 ) == 5

        nRecords = size( personnelData, 1 )
        personnelData = addSnapshotAttrition( mpSim, personnelData, nRecords )
    end  # XLSX.openxlsx( snapname ) do xf

    if isSnapshotBad
        return
    end  # if isSnapshotBad

    saveSnapshotToDatabase( mpSim, personnelData, attributeNames )
    saveNodeTime!( mpSim, personnelData )
    mpSim.orgSize = mpSim.dbSize = nRecords
    mpSim.isVirgin = false
    return

end  # uploadSnapshot( mpSim, snapname, sheetname, colsToImport, specialCols,
     #   refDate, validateData, generateSimData )

function uploadSnapshot( mrs::MRS, snapname::AbstractString,
    sheetname::AbstractString,
    colsToImport::Union{Vector{ColIndex}, Vector{String}, Vector{Int}},
    specialCols::NTuple{5,ColIndex}; refDate::Date = Date(now()),
    validateData::Bool=true, generateSimData::Bool=false )

    mpSim = mrs.mpSim
    uploadSnapshot( mpSim, snapname, sheetname, colsToImport, specialCols,
        refDate=refDate, validateData=validateData,
        generateSimData=generateSimData )

    # Wipe the snapshot tables if needed.
    DBInterface.execute( mrs.resultsDB, string( "DROP TABLE IF EXISTS `",
        mpSim.histDBname, "`" ) )
    DBInterface.execute( mrs.resultsDB, string( "DROP TABLE IF EXISTS `",
        mpSim.transDBname, "`" ) )
    DBInterface.execute( mrs.resultsDB, string( "DROP TABLE IF EXISTS `",
        mpSim.persDBname, "`" ) )
        
    # Create snapshot tables.
    sqliteCmd = string( "CREATE TABLE `", mpSim.persDBname, "`(",
        "\n    `", mpSim.idKey, "` TEXT NOT NULL PRIMARY KEY,",
        "\n    timeEntered REAL,",
        "\n    timeExited REAL,",
        "\n    ageAtRecruitment REAL,",
        "\n    expectedAttritionTime REAL,",
        "\n    currentNode TEXT,",
        "\n    inNodeSince REAL,",
        join( string.( "\n    `", collect( keys( mpSim.attributeList ) )
            , "` TEXT," ) ),
        "\n    status TEXT )" )
    DBInterface.execute( mrs.resultsDB, sqliteCmd )

    sqliteCmd = string( "CREATE TABLE `", mpSim.transDBname, "`(",
        "\n    `", mpSim.idKey, "` TEXT,",
        "\n    timeIndex REAL,",
        "\n    transition TEXT,",
        "\n    sourceNode TEXT,",
        "\n    targetNode TEXT,",
        "\n    FOREIGN KEY (`", mpSim.idKey, "`) REFERENCES `",
        mpSim.persDBname, "`(`", mpSim.idKey, "`) )" )
    DBInterface.execute( mrs.resultsDB, sqliteCmd )

    sqliteCmd = string( "CREATE TABLE `", mpSim.histDBname, "`(",
        "\n    `", mpSim.idKey, "` TEXT,",
        "\n    timeIndex REAL,",
        "\n    attribute TEXT,",
        "\n    value TEXT,",
        "\n    FOREIGN KEY (`", mpSim.idKey, "`) REFERENCES `",
        mpSim.persDBname, "`(`", mpSim.idKey, "`) )" )
    DBInterface.execute( mrs.resultsDB, sqliteCmd )

    # Copy snapshot into results database.
    sqliteCmd = string( "ATTACH '", mrs.resultsDB.file, "' AS target" )
    DBInterface.execute( mpSim.simDB, sqliteCmd )
 
    sqliteCmd = string( "INSERT INTO target.`", mpSim.persDBname, "`",
        "\n    SELECT * FROM `", mpSim.persDBname, "`" )
    DBInterface.execute( mpSim.simDB, sqliteCmd )

    sqliteCmd = string( "INSERT INTO target.`", mpSim.histDBname, "`",
        "\n    SELECT * FROM `", mpSim.histDBname, "`" )
    DBInterface.execute( mpSim.simDB, sqliteCmd )

    sqliteCmd = string( "INSERT INTO target.`", mpSim.transDBname, "`",
        "\n    SELECT * FROM `", mpSim.transDBname, "`" )
    DBInterface.execute( mpSim.simDB, sqliteCmd )

    DBInterface.execute( mpSim.simDB, "DETACH target" )

end  # uploadSnapshot( mps, snapname, sheetname, colsToImport, specialCols,
     #   refDate, validateData, generateSimData )

include( "private/snapshot.jl" )
