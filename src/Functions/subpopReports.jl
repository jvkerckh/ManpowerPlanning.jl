"""
```
generateSubpopExcelReport( mpSim::ManpowerSimulation,
                           timeRes::Real,
                           subpops::Subpopulation...;
                           fileName::String = "subpopReport",
                           overWrite::Bool = true,
                           timeFactor::Real = 12.0 )
```
This function generates an Excel report of the manpower simulation `mpSim`,
reporting on the evolution of the subpopulations in `subpops` on a time grid
with resolution `timesRes`. The name of the Excel file that the report is saved
to is `fileName`, with the `.xlsx` extension added when necessary. Times are
compressed by a factor `timeFactor` (e.g. 12 for sim in months, report in years)
and a new report is created if `overWrite` is `true`; otherwise, a new sheet is
added to the existing Excel file.

This function returns `nothing`.
"""
function generateSubpopExcelReport( mpSim::ManpowerSimulation, timeRes::Real,
    subpops::Subpopulation...; fileName::String = "subpopReport",
    overWrite::Bool = true, timeFactor::Real = 12.0 )::Void

    # Issue warning if time resolution is negative.
    if timeRes <= 0.0
        warn( "Negative time resolution for grid. Resolution must be > 0.0" )
        return results
    end  # if timeRes <= 0.0

    # Issue warning if time factor is negative.
    if timeFactor <= 0.0
        warn( "Negative time compression factor. Factor must be > 0.0" )
        return results
    end  # if timeFactor <= 0.0

    # Issue warning when trying to generate report of a simultation that hasn't
    #   started.
    if now( mpSim ) == 0.0
        warn( "Simulation hasn't started yet. Cannot generate report." )
        return results
    end  # if now( mpSim ) == 0.0

    tStart = now()
    subpopReport = generateSubpopulationReport( mpSim, timeRes, subpops... )
    tReport = ( now() - tStart ).value

    if isempty( subpopReport )
        return
    end  # if isempty( subpopReport )

    tmpFilename = string( fileName, endswith( fileName, ".xlsx" ) ? "" :
        ".xlsx" )
    dumpSubpopData( mpSim, subpopReport, tmpFilename, Float64( timeFactor ),
        tReport, overWrite )

    return

end  # generateSubpopExcelReport( mpSim, timeRes, subpops, fileName, overWrite,
     #    timeFactor )


"""
```
generateSubpopulationReport( mpSim::ManpowerSimulation,
                             timeRes::Real,
                             subpops::Subpopulation... )
```
This function generates a report on the size of the subpopulations in `subpop`
for the manpower simulation `mpSim` on a time grid with resolution `timeRes`.

This function returns a `DataFrame`, where the first column is the time grid,
and the other columns are the sizes of the valid subpopulations at each point of
the time grid.
"""
function generateSubpopulationReport( mpSim::ManpowerSimulation, timeRes::Real,
    subpops::Subpopulation... )::DataFrame

    results = Dict{String, DataFrame}()

    # Issue warning if time resolution is negative.
    if timeRes <= 0.0
        warn( "Negative time resolution for grid. Resolution must be > 0.0" )
        return results
    end  # if timeRes <= 0.0

    # Issue warning when trying to generate report of a simultation that hasn't
    #   started.
    if now( mpSim ) == 0.0
        warn( "Simulation hasn't started yet. Cannot generate report." )
        return results
    end  # if now( mpSim ) == 0.0

    # Filter the subpopulations on validity (existing source node).
    MP.generateRequiredCompounds( mpSim, map( subpop -> subpop.sourceNodeName,
        subpops )... )
    tmpSubpops = collect( subpops )
    filter!( subpop -> haskey( mpSim.stateList, subpop.sourceNodeName ) ||
        haskey( mpSim.compoundStateList, subpop.sourceNodeName ), tmpSubpops )

    if isempty( tmpSubpops )
        return results
    end  # if isempty( tmpSubpops )

    # Generate the report
    timeGrid = MP.generateTimeGrid( mpSim, timeRes )
    subpopCounts = zeros( Int, length( timeGrid ), length( tmpSubpops ) )

    for ii in eachindex( timeGrid )
        subpopCounts[ ii, : ] = length.( getSubpopAtTime( mpSim, timeGrid[ ii ],
            tmpSubpops ) )
    end  # for ii in eachindex( timeGrid )

    return DataFrame( hcat( timeGrid, subpopCounts ), vcat( :timePoints,
        map( subpop -> Symbol( subpop.name ), tmpSubpops ) ) )

end  # generateSubpopulationReport( mpSim, timeRes, subpops )


"""
```
dumpSubpopData( mpSim::ManpowerSimulation,
                subpopReport::DataFrame,
                fileName::String,
                timeFactor::Float64,
                tReport::Int,
                overWrite::Bool )
```
This function writes the generated subpopulation report `subpopReport` of the
manpower simulation `mpSim` to an Excel file with name `fileName`. The
simulation times are compressed by a factor `timeFactor` (e.g. 12 for months to
years), and it also includes the time needed to generate the report `tReport`.
If `overWrite` is `true`, the existing file (if any) gets overwritten, otherwise
a new tab is added.

This function returns `nothing`.
"""
function dumpSubpopData( mpSim::ManpowerSimulation, subpopReport::DataFrame,
    fileName::String, timeFactor::Float64, tReport::Int, overWrite::Bool )::Void

    if !ispath( dirname( fileName ) )
        mkpath( dirname( fileName ) )
    end  # if !ispath( dirname( fileName ) )

    tStart = now()
    tExcel = 0

    XLSX.openxlsx( fileName, mode = overWrite ? "w" : "rw" ) do xf
        tmpReport = deepcopy( subpopReport )
        tmpReport[ :timePoints ] ./= timeFactor
        timeRes = tmpReport[ :timePoints ][ 2 ] - tmpReport[ :timePoints ][ 1 ]
        subpopNames = string.( names( subpopReport ) )
        subpopNames[ 1 ] = "Sim time"
        sheetName = string( "Subpop report, res (", timeRes, ")" )

        if overWrite
            fSheet = xf[ 1 ]
            XLSX.rename!( fSheet, sheetName )
        else
            XLSX.addsheet!( xf, sheetName )
        end  # if overWrite

        fSheet = xf[ sheetName ]

        # Generate summary.
        fSheet[ "A1" ] = "Simulation length"
        fSheet[ "B1" ] = tmpReport[ :timePoints ][ end ]
        fSheet[ "C1" ] = "years"
        fSheet[ "A2" ] = "Simulation length"
        fSheet[ "B2" ] = timeRes
        fSheet[ "C2" ] = "years"
        fSheet[ "A3" ] = "Report timestamp"
        fSheet[ "B3" ] = now()
        fSheet[ "A4" ] = "Data generation time"
        fSheet[ "B4" ] = tReport / 1000
        fSheet[ "C4" ] = "seconds"
        fSheet[ "A5" ] = "Excel generation time"
        fSheet[ "C5" ] = "seconds"

        XLSX.writetable!( fSheet, tmpReport, subpopNames,
            anchor_cell = XLSX.CellRef( "A7" ) )
        tExcel = ( now() - tStart ).value
        fSheet[ "B5" ] = tExcel / 1000
    end  # XLSX.openxlsx( ... ) do xf

    return

end  # dumpSubpopData( mpSim, subpopReport, fileName, timeFactor, tReport )


"""
```
getSubpopAtTime( mpSim::ManpowerSimulation,
                 tPoint::Float64,
                 subpops::Vector{Subpopulation} )
```
This function finds the ids of the personnel members in each subpopulation
defined in `subpops` of the manpower simulation `mpSim` at time `tPoint`.

This function returns a `Vector{Vector{String}}`.
"""
function getSubpopAtTime( mpSim::ManpowerSimulation, tPoint::Float64,
    subpops::Vector{Subpopulation} )::Vector{Vector{String}}

    results = Vector{Vector{String}}( length( subpops ) )
    hasAttribConds = map( subpop -> !isempty( subpop.attribConds ), subpops )

    # First, find the personnel members satisfying the node and time conditions
    #   for each request.
    for ii in eachindex( results )
        subpop = subpops[ ii ]

        results[ ii ] = subpop.sourceNodeName ∈ [ "active", "" ] ?
            getActiveAtTime( mpSim, tPoint, subpop.timeConds, subpop.histConds,
                true ) :
            getActiveAtTime( mpSim, subpop.sourceNodeName, tPoint,
                subpop.timeConds, subpop.histConds, true )

        if isempty( results[ ii ] )
            hasAttribConds[ ii ] = false
        end  # if isempty( results[ ii ] )
    end  # for ii in eachindex( results )

    if !any( hasAttribConds )
        return results
    end  # if !any( hasAttribConds )

    # Get the personnel database snapshot of the personnel members for whom a
    #   database state reconstruction is required.
    idsToReconstruct = vcat( results[ hasAttribConds ]... )
    queryCmd = string( "SELECT * FROM `", mpSim.personnelDBname, "`
        WHERE `", mpSim.idKey, "` IN ( '" , join( idsToReconstruct, "', '" ),
        "' )" )
    activeAtTime = SQLite.query( mpSim.simDB, queryCmd )
    getSubpopStateAtTime!( activeAtTime, mpSim, tPoint )

    # For each request, filter out personnel members satisfying the conditions
    #   of the request.
    for ii in filter( ii -> hasAttribConds[ ii ], eachindex( results ) )
        subpop = subpops[ ii ]
        satisfyConds = map( id -> id ∈ results[ ii ],
            activeAtTime[ Symbol( mpSim.idKey ) ] )

        for cond in subpop.attribConds
            satisfyConds = satisfyConds .&
                map( val -> cond.rel( val, cond.val ),
                activeAtTime[ Symbol( cond.attr ) ] )
        end  # for cond in attribConds

        results[ ii ] = activeAtTime[ satisfyConds, Symbol( mpSim.idKey ) ]
    end  # for ii in filter( ... )

    return results

end  # getSubpopAtTime( mpSim, tPoint, dataRequests )


"""
```
getSubpopStateAtTime!( activeAtTime::DataFrame,
                       mpSim::ManpowerSimulation,
                       tPoint::Float64 )
```
This function reworks the database snippet `activeAtTime` from the manpower
simulation `mpSim` such that the snippet is in the state it was at simulation
time `tPoint`.

This function returns a `DataFrame`, the reworked database snippet.
"""
function getSubpopStateAtTime!( activeAtTime::DataFrame,
    mpSim::ManpowerSimulation, tPoint::Float64 )::DataFrame

    # Get the value of the attributes at time tPoint.
    activeIDs = activeAtTime[ Symbol( mpSim.idKey ) ]
    queryCmd = string( "SELECT `", mpSim.idKey, "`, attribute, strValue FROM `",
        mpSim.historyDBname, "`
        WHERE timeIndex <= ", tPoint, " AND `", mpSim.idKey, "` IN ( '",
        join( activeIDs, "', '" ) , "')
        GROUP BY `", mpSim.idKey, "`, attribute
        ORDER BY attribute, `", mpSim.idKey, "`" )
    currentAttribVals = SQLite.query( mpSim.simDB, queryCmd )

    # Reconstruct the state of the personnel members satisfying the node and
    #   time conditions.
    attribs = unique( currentAttribVals[ :attribute ] )
    filter!( attrib -> attrib != "status", attribs )

    for attrib in attribs
        attribInds = currentAttribVals[ :attribute ] .== attrib
        ids = currentAttribVals[ attribInds, Symbol( mpSim.idKey ) ]
        vals = currentAttribVals[ attribInds, :strValue ]

        if length( ids ) == length( activeIDs )
            activeAtTime[ Symbol( attrib ) ] = vals
        else
            changeAttrib = zeros( Int, size( ids ) )
            jj = 1

            for ii in eachindex( ids )
                while activeIDs[ jj ] != ids[ ii ]
                    jj += 1
                end  # while activeIDs[ jj ] != ids[ ii ]

                changeAttrib[ ii ] = jj
                jj += 1
            end  # for ii in eachindex( ids )

            activeAtTime[ changeAttrib, Symbol( attrib ) ] = vals
        end  # if length( ids ) == length( activeIDs )

    end  # for attrib in attribshelp

    return activeAtTime

end  # getSubpopStateAtTime!( activeAtTime, mpSim, tPoint )


"""
```
getActiveAtTime( mpSim::ManpowerSimulation,
                 tPoint::Float64,
                 timeConds::Vector{MP.Condition},
                 histConds::Vector{MP.Condition},
                 getIDsOnly::Bool )
```
This function gets the slice of the database of the manpower simulation `mpSim`
of personnel members satisfying all the following conditions.
1. They are active personnel members at time `tPoint`,
2. They satisfy all time related conditions (age, tenure, time in node) given in
   `timeConds`.
3. Their history satisfies all conditions in `histConds`. Valid attributes here
   are `had transition` for checking if a personnel member did (or did not do)
   the given transition before the time point; `started as` for checking if a
   personnel member entered the system in the given node(s); `was` for checking
   if the personnel member was (not) in the given node(s) at any time.
If the flag `getIDsOnly` is `true`, only the IDs are returned, otherwise the
entire database. Note that in the latter case, it does NOT return the database
in the state it was at the given time point. For that, it needs to be post-
processed.

This function returns either a `Vector{String}`, the list of IDs, or a
`DataFrame`, the slice of the database.
"""
function getActiveAtTime( mpSim::ManpowerSimulation, tPoint::Float64,
    timeConds::Vector{MP.Condition}, histConds::Vector{MP.Condition},
    getIDsOnly::Bool )

    # Generate the SQLite query.
    queryCmd = string( "SELECT *,
        ", tPoint, " - timeEntered tenure,
        ", tPoint, " - timeEntered + ageAtRecruitment age FROM `",
        mpSim.personnelDBname, "`
        WHERE timeEntered <= ", tPoint, " AND ( timeExited > ", tPoint,
        " OR timeExited IS NULL )" )

    if !isempty( timeConds )
        condSQLite = MP.conditionToSQLite.( timeConds )

        # Replace "time in node" by "tenure"
        for ii in eachindex( condSQLite )
            if startswith( condSQLite[ ii ], "`time in node`" )
                condSQLite[ ii ] = replace( condSQLite[ ii ], "`time in node`",
                    "`tenure`" )
            end  # if startswith( condSQLite[ ii ], "`time in node`" )
        end  # for ii in eachindex( condSQLite )

        queryCmd = string( queryCmd, " AND ", join( condSQLite, " AND " ) )
    end  # if !isempty( timeConds )

    if !isempty( histConds )
        # Identify which history conditions are negatives and adjust for them.
        isNegHistCond = map( cond -> cond.rel ∈ [ !=, ∉ ], histConds )
        tmpHistConds = deepcopy( histConds )

        for cond in tmpHistConds[ isNegHistCond ]
            cond.rel = cond.rel == Base.:∉ ? Base.:∈ : Base.:(==)
        end  # for cond in histConds[ isNegHistCond ]

        # Generate history condition queries.
        condSQLite = MP.conditionToSQLite.( tmpHistConds )
        condSQLite = string.( "`", mpSim.idKey, "`",
            map( bVal -> bVal ? " NOT" : "", isNegHistCond ), " IN ( SELECT `",
            mpSim.idKey, "` FROM `" , mpSim.transitionDBname, "`
                WHERE timeIndex <= ", tPoint, condSQLite,
            " )" )
        queryCmd = string( queryCmd, " AND ", join( condSQLite, " AND " ) )
    end  # if !isempty( histConds )

    queryCmd = string( queryCmd, "
        ORDER BY `", mpSim.idKey, "`" )

    result = SQLite.query( mpSim.simDB, queryCmd )

    # Note, this means the type is a Vector{String} or a DataFrame.
    return getIDsOnly ? string.( result[ Symbol( mpSim.idKey ) ] ) : result

end  # getActiveAtTime( mpSim, tPoint, timeConds, histConds, getIDsOnly )

"""
```
getActiveAtTime( mpSim::ManpowerSimulation,
                 nodeName::String,
                 tPoint::Float64,
                 timeConds::Vector{MP.Condition},
                 histConds::Vector{MP.Condition},
                 getIDsOnly::Bool )
```
This function gets the slice of the database of the manpower simulation `mpSim`
of personnel members satisfying all the following conditions.
1. They are active in (compound) node `nodeName` at time `tPoint`,
2. They satisfy all time related conditions (age, tenure, time in node) given in
   `timeConds`.
3. Their history satisfies all conditions in `histConds`. Valid attributes here
   are `had transition` for checking if a personnel member did (or did not do)
   the given transition before the time point; `started as` for checking if a
   personnel member entered the system in the given node(s); `was` for checking
   if the personnel member was (not) in the given node(s) at any time.
If the flag `getIDsOnly` is `true`, only the IDs are returned, otherwise the
entire database. Note that in the latter case, it does NOT return the database
in the state it was at the given time point. For that, it needs to be post-
processed.

This function returns either a `Vector{String}`, the list of IDs, or a
`DataFrame`, the slice of the database.
"""
function getActiveAtTime( mpSim::ManpowerSimulation, nodeName::String,
    tPoint::Float64, timeConds::Vector{MP.Condition},
    histConds::Vector{MP.Condition}, getIDsOnly::Bool )

    # Identify which history conditions are negatives and adjust for them.
    isNegHistCond = map( cond -> cond.rel ∈ [ !=, ∉ ], histConds )
    tmpHistConds = deepcopy( histConds )

    for cond in tmpHistConds[ isNegHistCond ]
        cond.rel = cond.rel == Base.:∉ ? Base.:∈ : Base.:(==)
    end  # for cond in histConds[ isNegHistCond ]

    # Generate history condition queries.
    queryCmd = MP.conditionToSQLite.( tmpHistConds )
    queryCmd = string.( "`", mpSim.idKey, "`",
        map( bVal -> bVal ? " NOT" : "", isNegHistCond ), " IN ( SELECT `",
        mpSim.idKey, "` FROM `" , mpSim.transitionDBname, "`
            WHERE timeIndex <= ", tPoint, queryCmd,
        " )" )

    # Generate subquery.
    stateCond = haskey( mpSim.stateList, nodeName ) ? nodeName :
        join( mpSim.compoundStateList[ nodeName ].stateList, "', '" )
    queryCmd = string( "SELECT `", mpSim.idKey, "`, timeIndex FROM `",
        mpSim.transitionDBname, "`
        WHERE timeIndex <= ", tPoint,
        isempty( queryCmd ) ? "" : " AND ", join( queryCmd, " AND " ), "
        GROUP BY `", mpSim.idKey, "`
        HAVING endState IN ( '", stateCond, "' )" )

    # Generate full query.
    queryCmd = string( "SELECT *,
        ", tPoint, " - timeEntered tenure,
        ", tPoint, " - timeEntered + ageAtRecruitment age,
        ", tPoint, " - timeIndex `time in node` FROM `", mpSim.personnelDBname,
        "`
        INNER JOIN ( ", queryCmd, " ) tmpList ON `",
        mpSim.personnelDBname, "`.`", mpSim.idKey,"` IS tmpList.`", mpSim.idKey,
        "`" )

    if !isempty( timeConds )
        condSQLite = MP.conditionToSQLite.( timeConds )
        queryCmd = string( queryCmd, "
            WHERE ", join( condSQLite, " AND " ) )
    end  # if !isempty( timeConds )

    queryCmd = string( queryCmd, "
        ORDER BY `", mpSim.idKey, "`" )

    result = SQLite.query( mpSim.simDB, queryCmd )

    # Note, this means the type is a Vector{String} or a DataFrame.
    return getIDsOnly ? string.( result[ Symbol( mpSim.idKey ) ] ) : result

end  # getActiveAtTime( mpSim, nodeName, tPoint, timeConds, histconds,
     #   getIDsOnly )
