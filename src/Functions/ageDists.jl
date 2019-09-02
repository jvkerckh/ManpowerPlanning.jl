function generateAgeDistributionPlots( mpSim::ManpowerSimulation, timeRes::Real,
    ageRes::Real, ageType::Symbol, subpops::Subpopulation...;
    savePlots::Bool = false, timeFactor::Real = 12.0 )::Void

    # Issue warning if time or age resolution is negative.
    if ( timeRes <= 0.0 ) || ( ageRes <= 0.0 )
        warn( "Negative time or age resolution for grid. Resolutions must be > 0.0" )
        return
    end  # if ( timeRes <= 0.0 ) || ...

    # Issue warning if time factor is negative.
    if timeFactor <= 0.0
        warn( "Negative time compression factor. Factor must be > 0.0" )
        return
    end  # if timeFactor <= 0.0

    # Issue warning when trying to generate report of a simultation that hasn't
    #   started.
    if now( mpSim ) == 0.0
        warn( "Simulation hasn't started yet. Cannot generate report." )
        return
    end  # if now( mpSim ) == 0.0

    ageReport = generateAgeDistributionReport( mpSim, timeRes, ageRes, ageType,
        subpops... )
    subpopNames = map( subpop -> subpop.name, collect( subpops ) )
    filter!( subpop -> haskey( ageReport, subpop ), subpopNames )
    plotAgeDistData( mpSim, ageReport, subpopNames, ageType, savePlots,
        Float64( timeFactor ) )

    return

end  # generateAgeDistributionPlots( mpSim, timeRes, ageRes, ageType, subpops;
     #   fileName, savePlots, timeFactor )


function plotAgeDistData( mpSim::ManpowerSimulation,
    ageReport::Dict{String, DataFrame}, subpops::Vector{String},
    ageType::Symbol, savePlots::Bool, timeFactor::Float64 )::Void

    plotDirName = joinpath( mpSim.parFileName[ 1:(end - 5) ],
        "age distribution plots" )

    if savePlots && !ispath( plotDirName )
        mkpath( plotDirName )
    end  # if savePlots && !ispath( plotDirName )

    for subpop in subpops
        plotSingleAgeDist( ageReport[ subpop ], subpop, ageType, savePlots,
            timeFactor, plotDirName )
    end  # for subpop in keys( ageReport )

    return

end  # plotAgeDistData( mpSim, ageDistData, savePlots, timeFactor )


function plotSingleAgeDist( ageDist::DataFrame, subpop::String, ageType::Symbol,
    savePlot::Bool, timeFactor::Float64, plotDirName::String )::Void

    timeGrid = deepcopy( ageDist[ :timePoints ] ) ./ timeFactor
    timeRes = timeGrid[ 2 ] - timeGrid[ 1 ]
    ageGrid = parse.( Float64, string.( names( ageDist )[ 2:end ] ) ) ./
        timeFactor
    plt = nothing
    plotType = ageType === :age ? "Age" : ( ageType === :tenure ?
        "Tenure" : "Time in node" )

    if length( ageGrid ) == 1
        plotTitle = string( "Evolution of subpopulation ", subpop, " (res ",
            timeRes, ")" )
        plt = plot( timeGrid, ageDist[ 2 ], title = plotTitle, label = subpop,
            hover = ageDist[ 2 ], formatter = :plain, size = ( 960, 540 ) )
    else
        plotTitle = string( plotType, " distribution of subpopulation ",
            subpop )
        ylab = string( plotType, " (y)" )
        plt = surface( timeGrid * ones( 1, length( ageGrid ) ),
            ones( length( timeGrid ) ) * ageGrid', Array( ageDist[ 2:end ] ),
            title = plotTitle, formatter = :plain, size = ( 960, 540 ),
            xlabel = "Sim time (y)", ylabel = ylab )
    end  # if length( ageGrid ) == 1

    gui( plt )

    if savePlot
        plotFileName = joinpath( plotDirName, string( subpop, " - ", plotType,
            " (", timeRes, ").html" ) )
        savefig( plt, plotFileName )
    end  # if savePlot

    return

end  # plotSingleAgeDist( ageDist, subpop, ageType, savePlots, timeFactor,
     #   plotDirName )


function generateAgeDistExcelReport( mpSim::ManpowerSimulation, timeRes::Real,
    ageRes::Real, ageType::Symbol, subpops::Subpopulation...;
    fileName::String = "ageDistReport", overWrite::Bool = true,
    timeFactor::Real = 12.0 )::Void

    # Issue warning if time or age resolution is negative.
    if ( timeRes <= 0.0 ) || ( ageRes <= 0.0 )
        warn( "Negative time or age resolution for grid. Resolutions must be > 0.0" )
        return
    end  # if ( timeRes <= 0.0 ) || ...

    # Issue warning if time factor is negative.
    if timeFactor <= 0.0
        warn( "Negative time compression factor. Factor must be > 0.0" )
        return
    end  # if timeFactor <= 0.0

    # Issue warning when trying to generate report of a simultation that hasn't
    #   started.
    if now( mpSim ) == 0.0
        warn( "Simulation hasn't started yet. Cannot generate report." )
        return
    end  # if now( mpSim ) == 0.0

    tStart = now()
    ageReport = generateAgeDistributionReport( mpSim, timeRes, ageRes, ageType,
        subpops... )
    subpopNames = map( subpop -> subpop.name, collect( subpops ) )
    filter!( subpop -> haskey( ageReport, subpop ), subpopNames )
    tReport = ( now() - tStart ).value

    if !isempty( subpopNames )
        tmpFilename = string( fileName, endswith( fileName, ".xlsx" ) ? "" :
            ".xlsx" )
        dumpAgeDistData( mpSim, ageReport, subpopNames, tmpFilename,
            Float64( timeFactor ), tReport, overWrite )
    end  # if !isempty( subpopNames )

    return

end  # generateAgeDistExcelReport( mpSim, timeRes, ageRes, ageType, subpops,
     #   fileName, overWrite, timeFactor )


function dumpAgeDistData( mpSim::ManpowerSimulation,
    ageReport::Dict{String, DataFrame}, subpopNames::Vector{String},
    fileName::String, timeFactor::Float64, tReport::Int, overWrite::Bool )::Void

    if !ispath( dirname( fileName ) )
        mkpath( dirname( fileName ) )
    end  # if !ispath( dirname( fileName ) )

    tStart = now()
    tExcel = 0

    XLSX.openxlsx( fileName, mode = overWrite ? "w" : "rw" ) do xf
        timeGrid = deepcopy( ageReport[ subpopNames[ 1 ] ][ :timePoints ] ) ./
            timeFactor
        timeRes = timeGrid[ 2 ] - timeGrid[ 1 ]
        sheetName = "Summary"

        # Generate summary.
        if overWrite
            fSheet = xf[ 1 ]
            XLSX.rename!( fSheet, sheetName )
        else
            XLSX.addsheet!( xf, sheetName )
        end  # if overWrite

        fSheet = xf[ sheetName ]
        fSheet[ "A1" ] = "Simulation length"
        fSheet[ "B1" ] = timeGrid[ end ]
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

        for subpopName in subpopNames
            ageRep = deepcopy( ageReport[ subpopName ] )
            ageRep[ 1 ] = ageRep[ 1 ] ./ timeFactor
            fSheet = XLSX.addsheet!( xf, subpopName )

            fSheet[ "B1" ] = "Age"
            ageCats = names( ageRep )[ 2:end ]
            ageCats = parse.( Float64, string.( ageCats ) ) ./ timeFactor
            XLSX.writetable!( fSheet, ageRep, vcat( "Sim time", ageCats ),
                anchor_cell = XLSX.CellRef( "A2" ) )

            for jj in eachindex( ageCats )
                fSheet[ XLSX.CellRef( 2, jj + 1 ) ] = ageCats[ jj ]
            end  # for jj in eachindex( ageCats )

            fSheet[ XLSX.CellRef( 2, length( ageCats ) + 2 ) ] = "Total"

            for ii in eachindex( timeGrid )
                kk = ii + 2
                rangeRef = XLSX.CellRange( kk, 2, kk, length( ageCats ) + 1 )
                totalRef = XLSX.CellRef( kk, length( ageCats ) + 2 )
                fSheet[ totalRef ] = string( "=sum(", rangeRef, ")" )
                testCell = XLSX.getcell( fSheet, totalRef )
                testCell.formula = fSheet[ totalRef ]
            end  # for ii in eachindex( timeGrid )

            println()
        end  # for subpopName in subpopNames

        tExcel = ( now() - tStart ).value
        fSheet = xf[ sheetName ]
        fSheet[ "B5" ] = tExcel / 1000
    end  # XLSX.openxlsx( ... ) do xf

    return

end  # dumpAgeDistData( mpSim, ageReport, subpopNames, fileName, timeFactor,
     #   tReport, overWrite )


function generateAgeDistributionReport( mpSim::ManpowerSimulation,
    timeRes::Real, ageRes::Real, ageType::Symbol,
    subpops::Subpopulation... )::Dict{String, DataFrame}

    results = Dict{String, DataFrame}()

    # Issue warning if time or age resolution is negative.
    if ( timeRes <= 0.0 ) || ( ageRes <= 0.0 )
        warn( "Negative time or age resolution for grid. Resolutions must be > 0.0" )
        return results
    end  # if ( timeRes <= 0.0 ) || ...

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

    # Find ages of all people in all subpopulations at each time point.
    timeGrid = MP.generateTimeGrid( mpSim, timeRes )
    agesPerTime = Vector( length( timeGrid ) )

    for ii in eachindex( timeGrid )
        tPoint = timeGrid[ ii ]
        agesPerTime[ ii ] = getAgesAtTime( mpSim, tPoint, tmpSubpops, ageType )
    end  # for ii in eachindex( timeGrid )
    # XXX using map generates an error, some times.

    # agesPerTime = map( tPoint -> getAgesAtTime( mpSim, tPoint,
    #     tmpSubpops, ageType ), timeGrid )  # Issue with regular vector broadcast
                                           #   Julia v0.6
    agesPerSubpop = Dict{String, Vector{Vector{Float64}}}()

    # Reorder the data by subpopulation.
    for ii in eachindex( tmpSubpops )
        subpopName = tmpSubpops[ ii ].name
        agesPerSubpop[ subpopName ] = Vector{Vector{Float64}}(
            length( timeGrid ) )

        for jj in eachindex( timeGrid )
            agesPerSubpop[ subpopName ][ jj ] = agesPerTime[ jj ][ ii ]
        end  # for jj in eachindex( timeGrid )

        agesOfSubpop = agesPerSubpop[ subpopName ]
        emptySubpop = isempty.( agesOfSubpop )

        if all( emptySubpop )
            results[ subpopName ] = DataFrame()
        else
            minAge = minimum( minimum.( agesOfSubpop[ .!emptySubpop ] ) )
            minAge = floor( minAge / ageRes ) * ageRes
            maxAge = maximum( maximum.( agesOfSubpop[ .!emptySubpop ] ) )
            maxAge = floor( maxAge / ageRes ) * ageRes
            ageGrid = collect( minAge:ageRes:maxAge )

            counts = zeros( Int, length( timeGrid ), length( ageGrid ) )

            for ii in eachindex( timeGrid )
                tmpCounts = map( age -> count( agesOfSubpop[ ii ] .>= age ),
                    ageGrid )
                tmpCounts -= vcat( tmpCounts[ 2:end ], 0 )
                counts[ ii, : ] = tmpCounts
            end  # for ii in eachindex( timeGrid )

            results[ subpopName ] = DataFrame( hcat( timeGrid, counts ),
                vcat( :timePoints, Symbol.( ageGrid ) ) )
        end  # if all( emptySubpop )
    end  # for ii in eachindex( tmpSubpops )

    return results

end  # generateAgeDistributionReport( mpSim, timeRes, ageRes, subpop, ageType )


function getAgesAtTime( mpSim::ManpowerSimulation, tPoint::Float64,
    subpops::Vector{Subpopulation},
    ageType::Symbol )::Vector{Vector{Float64}}

    # Get the ids in each subpop at the time point.
    results = Vector{Vector{Float64}}( length( subpops ) )
    idsInSubpop = getSubpopAtTime( mpSim, tPoint, subpops )

    if ageType === :timeInNode
        queryPre = string( "SELECT ", tPoint,
            " - max( timeIndex ) `time in node` FROM `", mpSim.transitionDBname,
            "`
            WHERE timeIndex <= ", tPoint, " AND `", mpSim.idKey, "` IN ( '" )
        querySuf = string( "' )
            GROUP BY `", mpSim.idKey, "`" )

        for ii in eachindex( subpops )
            if isempty( idsInSubpop[ ii ] )
                results[ ii ] = Vector{Float64}()
            else
                queryCmd = string( queryPre, join( idsInSubpop[ ii ], "', '" ),
                    querySuf )
                results[ ii ] = SQLite.query( mpSim.simDB, queryCmd )[ 1 ]
            end  # if isempty( idsInSubpop )[ ii ]
        end  # for ii in eachindex( subpops )

        return results
    end  # if ageType === :timeInNode

    queryPre = string( "SELECT ", tPoint, " - timeEntered",
        ageType === :age ? " + ageAtRecruitment age" : " tenure",
        " FROM `", mpSim.personnelDBname, "`
        WHERE `", mpSim.idKey, "` IN ( '" )

    for ii in eachindex( subpops )
        if isempty( idsInSubpop[ ii ] )
            results[ ii ] = Vector{Float64}()
        else
            queryCmd = string( queryPre, join( idsInSubpop[ ii ], "', '" ),
                "' )" )
            results[ ii ] = SQLite.query( mpSim.simDB, queryCmd )[ 1 ]
        end  # if isempty( idsInSubpop )[ ii ]
    end  # for ii in eachindex( subpops )

    return results

end  # getAgesAtTime( mpSim, tPoint, subpops, ageType )

#=
cond1 = MP.processCondition( "had transition", "IS", "Spec" )[ 1 ]
cond2 = MP.processCondition( "had transition", "NOT IN", "Spec" )[ 1 ]
cond3 = MP.processCondition( "started as", "IS", "Trainee" )[ 1 ]
cond4 = MP.processCondition( "was", "IS NOT", "Senior B" )[ 1 ]
cond5 = MP.processCondition( "tenure", ">=", 20 )[ 1 ]
cond6 = MP.processCondition( "gender", "IS", "F" )[ 1 ]

subpop1 = Subpopulation( "SP1", "Master A" )
addCondition!( subpop1, cond5, cond6 )
subpop2 = Subpopulation( "SP2", "Master Spec" )
addCondition!( subpop2, cond1, cond5, cond6 )
subpop3 = Subpopulation( "SP3", "Master Spec" )
addCondition!( subpop3, cond5, cond2, cond6 )
subpop4 = Subpopulation( "SP4", "Master A" )
addCondition!( subpop4, cond5, cond3, cond6 )
subpop5 = Subpopulation( "SP5", "Master Spec" )
addCondition!( subpop5, cond4, cond5, cond6 )
subpop6 = Subpopulation( "SP6", "Master Spec" )
addCondition!( subpop6, cond4, cond5, cond3, cond6 )
subpop7 = Subpopulation( "SP7", "Test" )

tRes = 12
aRes = 12
subpops = [ subpop1, subpop2, subpop3, subpop4, subpop5, subpop6, subpop7 ]
ageType = :age

@time generateAgeDistExcelReport( mpSim, tRes, aRes, ageType, subpops...,
    fileName = "agglomNode test 20190404/config1/ageDistReport.xlsx" )
println()
=#
