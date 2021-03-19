function readIDs( xs::XLSX.Worksheet, idCol::Int, nRecords::Int, mpSim::MPsim )

    if idCol == 0
        return string.( "Init", 1:nRecords ), falses( nRecords )
    end  # if idCol == 0

    ids = xs[XLSX.CellRange( 2, idCol, nRecords + 1, idCol )][:]

    let
        isMissing = isa.( ids, Missing )
        nMissing = count( isMissing )

        if nMissing > 0
            ids[ isMissing ] = string.( "Init", 1:nMissing )

            if mpSim.showInfo
                @info string( "Generated ids for ", nMissing,
                    " record(s)." )
            end  # if mpSim.showInfo
        end  # if nMissing > 0
    end  # let

    ids = Vector{String}( strip.( string.( ids ) ) )
    isDuplicate = flagDuplicates( ids )
    nDuplicate = count( isDuplicate )

    if nDuplicate > 0
        ids = ids[.!isDuplicate]

        if mpSim.showInfo
            @info string( "Removed ", nDuplicate, " duplicate record(s)." )
        end  # if mpSim.showInfo
    end  # if nDuplicate > 0

    return ids, isDuplicate
    
end  # readIDs( xs, idCol, nRecords, mpSim )


function flagDuplicates( ids::Vector{String} )

    uniqueSet = Set{String}()
    duplicateSet = Set{String}()

    for id in ids
        if id ∉ uniqueSet
            push!( uniqueSet, id )
        elseif id ∉ duplicateSet
            push!( duplicateSet, id )
        end  # if id ∉ uniqueSet
    end  # for id in ids

    return map( id -> id ∈ duplicateSet, ids )

end  # flagDuplicates( ids )


function readTimes( xs::XLSX.Worksheet, timeCol::Int, refDate::Date,
    dateType::Symbol, nRecords::Int, isBad::Vector{Bool}, mpSim::MPsim,
    timeFactor::Float64=1.0 )

    if timeCol == 0
        return zeros( Float64, nRecords - count( isBad ) )
    end  # if tenureCol == 0

    times = xs[XLSX.CellRange( 2, timeCol, nRecords + 1, timeCol )][:]
    times = times[.!isBad]

    let
        isMissing = map( times ) do timeVal
            return ( timeVal isa Missing ) || (
                ( timeVal isa AbstractString ) &&
                ( tryparse( Float64, timeVal ) isa Nothing ) )
        end  # map( times ) do ltt

        nMissing = count( isMissing )

        if nMissing > 0
            times[ isMissing ] .= 0.0

            if mpSim.showInfo
                @info string( "Missing time values for ", nMissing,
                    " record(s), set them to 0.0." )
            end  # if mpSim.showInfo
        end  # if nMissing > 0

        computeTimes!( times, refDate, dateType )
        times = max.( times, 0.0 )
    end  # let

    return times * timeFactor

end  # readTimes( xs, timeCol, refDate, dateType, nRecords, isBad, mpSim,
     #   timeFactor )


function readNodes( xs::XLSX.Worksheet, nodeCol::Int, nRecords::Int,
    isBad::Vector{Bool}, mpSim::MPsim )

    if nodeCol == 0
        return fill( "NULL", nRecords - count( isBad ) )
    end  # if tenureCol == 0

    nodes = xs[XLSX.CellRange( 2, nodeCol, nRecords + 1, nodeCol )][:]
    nodes = nodes[.!isBad]

    let
        isMissing = isa.( nodes, Missing )
        nMissing = count( isMissing )

        if nMissing > 0
            nodes[ isMissing ] .= "NULL"

            if mpSim.showInfo
                @info string( "Missing initial nodes for ", nMissing,
                    " record(s), set them to NULL." )
            end  # if mpSim.showInfo
        end  # if nMissing > 0
    end  # let

    return Vector{String}( strip.( string.( nodes ) ) )

end # readNodes( xs, nodeCol, nRecords, isBad, mpSim )


function readData( xs::XLSX.Worksheet, ids::Vector{String},
    lastTransTimes::Vector{Float64}, tenures::Vector{Float64},
    ages::Vector{Float64}, nodes::Vector{String}, colsToImport::Vector{Int},
    nRecords::Int, isBad::Vector{Bool}, mpSim::MPsim )

    attributeNames = Vector{String}( strip.( string.( getindex.(
        Ref(xs), 1, colsToImport ) ) ) )
    personnelData = map( colNr -> xs[XLSX.CellRange( 2, colNr,
        nRecords + 1, colNr )][:], colsToImport )
    personnelData = hcat( personnelData... )[.!isBad, :]
    nRecords -= count( isBad )

    isBad = falses( nRecords )

    for ii in eachindex( colsToImport )
        isBad .|= isa.( personnelData[:, ii], Missing )
    end  # for ii in eachindex( personnelData )

    personnelData = Array{String}( strip.( string.(
        personnelData[.!isBad, :] ) ) )
    nBad = count( isBad )

    if nBad > 0
        ids = ids[.!isBad]
        lastTransTimes = lastTransTimes[.!isBad]
        tenures = tenures[.!isBad]
        ages = ages[.!isBad]
        nodes = nodes[.!isBad]

        if mpSim.showInfo
            @info string( "Removed ", nBad,
                " record(s) with missing data." )
        end  # # if mpSim.showInfo
    end  # if nBad > 0

    tenures = max.( tenures, lastTransTimes )
    ages = max.( ages, tenures )
    personnelData = hcat( personnelData, ids, lastTransTimes, tenures, ages,
        nodes )

    return personnelData, attributeNames

end  # readData( xs, ids, lastTransTimes, tenures, ages, colsToImport,
     #   nRecords, isBad, mpSim )


function validateAttributeData( personnelData::Array{Any,2},
    attributeNames::Vector{String}, mpSim::MPsim )

    isBad = falses( size( personnelData, 1 ) )

    for ii in eachindex( attributeNames )
        # No need to validate anything if the attribute isn't defined.
        if !haskey( mpSim.attributeList, attributeNames[ii] )
            continue
        end  # if !haskey( mpSim.attributeList, attributeNames[ii] )

        attribute = mpSim.attributeList[attributeNames[ii]]
        isBad .|= map( val -> val ∉ attribute.possibleValues,
            personnelData[:, ii] )
    end  # for ii in eachindex( attributeNames )

    nBad = count( isBad )

    if nBad > 0
        personnelData = personnelData[.!isBad, :]

        if mpSim.showInfo
            @info string( "Removed ", nBad,
                " record(s) with inconsistent data." )
        end  # if mpSim.showInfo
    end  # if nBad > 0

    return personnelData

end  # validateAttributeData( personnelData, attributeNames, mpSim )


function generateSimAttributes!( mpSim::MPsim, personnelData::Array{Any,2}, attributeNames::Vector{String}, generateAttribute::BitArray{1} )

    attributes = Vector{Attribute}()

    for ii in filter( ii -> generateAttribute[ii],
        eachindex( generateAttribute ) )
        name = attributeNames[ii]
        attribute = Attribute( name )
        setPossibleAttributeValues!( attribute,
            Vector{String}( unique( personnelData[:, ii] ) ) )
        push!( attributes, attribute )
    end  # for ii in filter( ... )

    if isempty( attributes )
        return
    end  # if isempty( attributes )

    addSimulationAttribute!( mpSim, attributes... )

end  # generateSimAttributes!( mpSim, personnelData, attributeNames,
     #   generateAttribute )


function generateSimNodes!( mpSim::MPsim, personnelData::Array{Any,2},
    attributeNames::Vector{String} )

    nodes = personnelData[:, end]
    baseNodes = Vector{BaseNode}()
    
    for name in filter( name -> ( name != "NULL" ) &&
        ( !haskey( mpSim.baseNodeList, name ) ), unique( nodes ) )
        recordsOfNode = findall( nodes .== name )
        node = BaseNode( name )
        
        for ii in eachindex( attributeNames )
            attrName = attributeNames[ii]
            possibleVals =  unique( personnelData[recordsOfNode, ii] )
            
            if length( possibleVals ) == 1
                addNodeRequirement!( node, attrName, possibleVals[1] )
            end  # if length( possibleVals ) == 1
        end  # for ii in eachindex( attributeNames )

        push!( baseNodes, node )
    end  # for name in filter( ... )

    if isempty( baseNodes )
        return
    end  # if isempty( baseNodes )

    addSimulationBaseNode!( mpSim, baseNodes... )

end  # generateSimNodes!( mpSim, personnelData, attributeNames )


function inferBaseNodes( mpSim::MPsim, personnelData::Array{Any,2},
    attributeNames::Vector{String} )

    isNull = personnelData[:, end] .== "NULL"

    if !any( isNull )
        return
    end  # if !any( isNull )

    nodes = collect( keys( mpSim.baseNodeList ) )
    attributeVals = map( nodes ) do name
        node = mpSim.baseNodeList[name]
        attrVals = get.( Ref(node.requirements), attributeNames, nothing )
    end  # map( nodes ) do name

    for ii in findall( isNull )
        possibleNodes = map( eachindex( nodes ) ) do jj
            return all( isa.( attributeVals[jj], Nothing ) .|
                ( attributeVals[jj] .== personnelData[ii, 1:(end-5)] ) )
        end  # map( eachindex( nodes ) ) do jj

        possibleNodes = nodes[possibleNodes]
        
        if length( possibleNodes ) == 1
            personnelData[ii, end] = possibleNodes[1]
        end  # if length( possibleNodes ) == 1
    end  # for ii in findall( isNull )

end  # inferBaseNodes( mpSim, personnelData, attributeNames )


function addSnapshotAttrition( mpSim::MPsim, personnelData::Array{Any,2},
    nRecords::Int )

    attritionTimes = fill( +Inf, nRecords )

    for node in keys( mpSim.baseNodeList )
        nodeInds = personnelData[:, end] .== node
        attrition = mpSim.baseNodeList[node].attrition
        attritionTimes[nodeInds] = generateTimeToAttrition(
            mpSim.attritionSchemes[attrition],
            Vector{Float64}( personnelData[nodeInds, end-3] ) )
    end  # for node in keys( mpSim.baseNodeList )
    
    attritionTimes -= personnelData[:, end-3]

    return hcat( personnelData, attritionTimes )

end  # addSnapshotAttrition( mpSim, personnelData )


function saveSnapshotToDatabase( mpSim::MPsim, personnelData::Array{Any,2},
    attributeNames::Vector{String} )

    resetSimulation( mpSim, false )
    nRecords = size( personnelData, 1 )
    nAttributes = length( attributeNames )
    ageAtRecruitment = personnelData[:, end-2] - personnelData[:, end-3]
    nodes = personnelData[:, end-1]
    isValidNode = nodes .!= "NULL"
    DBInterface.execute( mpSim.simDB, "BEGIN TRANSACTION" )

    # The SQLite command that fills the personnel database.
    personnelCmd = map( 1:nRecords ) do ii
        node = nodes[ii]
        return string( "\n    ('",
            join( personnelData[ii, 1:(nAttributes + 1)], "', '" ), "', ",
            -personnelData[ii, end-3], ", ", ageAtRecruitment[ii], ", ",
            isValidNode[ii] ? string( "'", node, "'" ) : node, ", ",
            -personnelData[ii, end-4], ", ",
            personnelData[ii, end] == +Inf ? "NULL" : personnelData[ii, end],
            ", 'active')" )
    end  # map( 1:nRecords ) do ii

    personnelCmd = string( "INSERT INTO `", mpSim.persDBname, "` (`",
        join( attributeNames, "`, `" ), "`, `", mpSim.idKey,
        "`, timeEntered, ageAtRecruitment, currentNode, inNodeSince, expectedAttritionTime, status) VALUES",
        join( personnelCmd, "," ) )
    DBInterface.execute( mpSim.simDB, personnelCmd )

    # The SQLite command that fills the transition database.
    if any( isValidNode )
        transitionCmd = map( findall( isValidNode ) ) do ii
            return string( "\n    ('", personnelData[ii, end-5], "', ",
                - personnelData[ii, end-4], ", 'Init', '", nodes[ii], "')" )
        end  # map( findall( isValidNode ) ) do ii
    
        transitionCmd = string( "INSERT INTO `", mpSim.transDBname, "` (`",
            mpSim.idKey, "`, timeIndex, transition, targetNode) VALUES",
            join( transitionCmd, "," ) )
        DBInterface.execute( mpSim.simDB, transitionCmd )
    end  # if any( isValidNode )

    # The SQLite command that fills the attribute history database.
    historyCmd = map( eachindex( attributeNames ) ) do ii
        return join( string.( "\n    ('", personnelData[:, end-5], "', ",
            -personnelData[:, end-4], ", '", attributeNames[ii], "', '",
            personnelData[:, ii], "')" ), "," )
    end  # map( eachindex( attributeNames ) ) do ii

    historyCmd = string( "INSERT INTO `", mpSim.histDBname, "` (`", mpSim.idKey,
        "`, timeIndex, attribute, value) VALUES", join( historyCmd, "," ) )
    DBInterface.execute( mpSim.simDB, historyCmd )
    DBInterface.execute( mpSim.simDB, "COMMIT" )

end  # saveSnapshotToDatabase( mpSim, personnelData, attributeNames )


function saveNodeTime!( mpSim::MPsim, personnelData::Array{Any,2} )

    for node in keys( mpSim.baseNodeList )
        isIDinNode = personnelData[:, end-1] .== node
        setindex!.( Ref(mpSim.baseNodeList[node].inNodeSince),
            -personnelData[isIDinNode, end-4],
            personnelData[isIDinNode, end-5] )
    end  # for node in keys( mpSim.baseNodeList )

end  # saveNodeTime!( mpSim, personnelData )


function dateDiff( date1::Date, date2::Date, dateType::Symbol )
    dateType === :days && return (date1 - date2).value
    dateType === :years && return year(date1) - year(date2) +
        ( dayofyear(date1) - dayofyear(date2) ) / daysinyear(date1)

    ddiff = ( year(date1) - year(date2) ) * 12 + ( month(date1) - month(date2) )
    ddiff + ( day(date1) - day(date2) ) / daysinmonth(date1)
end  # dateDiff( date1, date2, dateType )


function computeTimes!( timeData::Vector, refDate::Date, dateType::Symbol )
    dateInds = findall(isa.( timeData, Date ))
    timeData[dateInds] = dateDiff.( refDate, timeData[dateInds],
        dateType )
end  # computeTimes!( timeData, refDate, dateType )
