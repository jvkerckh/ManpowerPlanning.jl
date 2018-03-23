# Initalise ManpowerPlanning module
if !isdefined( :ManpowerSimulation )
    include( joinpath( dirname( Base.source_path() ), "..", "src",
        "ManpowerPlanning.jl" ) )
    using ManpowerPlanning
    isUpToDate = true
    println( "ManpowerPlanning module initialised." )
end

configurationFileName = joinpath( dirname( Base.source_path() ),
    configurationFileName )

# Initialise the simulation.
if !isdefined( :isSimInitialised )
    mpSim = ManpowerSimulation( configurationFileName )
    isSimInitialised = true
    # println( "Manpower simulation mpSim initialised and ready for configuration." )
    # println( mpSim )
end  #  if !isdefined( :isSimInitialised )

# Reset simulation if necessary.
if isdefined( :isSimulationFinished ) && isSimulationFinished && rerunSimulation
    resetSimulation( mpSim )
    initialiseFromExcel( mpSim, configurationFileName )
    println( "Manpower simulation mpSim reset." )
end

if !isdefined( :isSimulationFinished ) || rerunSimulation

isSimulationFinished = false
monthFactor = 12 # isSimTimeInMonths ? 12 : 1

println( "\nPersonnel cap set at $(mpSim.personnelCap) personnel members." )
println( "Length of the simulation set at $(mpSim.simLength / monthFactor) years." )
println( "Time between two database commits set at $(mpSim.commitFrequency) months." )


println( "Recruitment schemes added to the simulation." )


# Attrition scheme.
println( "\nAttrition" )
isAttrSchemeAvailable = mpSim.attritionScheme !== nothing

if isAttrSchemeAvailable
    println( mpSim.attritionScheme )
else
    println( "No attrition acheme in the simulation." )
end  # if attrRate > 0


# Retirement scheme.
println( "\nRetirement" )
isRetSchemeAvailable = mpSim.retirementScheme !== nothing
maxTenure = isRetSchemeAvailable ? mpSim.retirementScheme.maxCareerLength : 0
maxAge = isRetSchemeAvailable ? mpSim.retirementScheme.retireAge : 0

if maxTenure > 0
    println( "Mandatory retirement after $(maxTenure / monthFactor) years of service." )
end  # if maxTenure > 0

if maxAge > 0
    println( "Mandatory retirement at the age of $(maxAge / monthFactor) years." )
end  # if maxAge > 0

if ( maxTenure > 0 ) || ( maxAge > 0 )
    println( "Time between two retirement cycles is $(mpSim.retirementScheme.retireFreq) months." )
    println( "First retirement cycle starts after $(mpSim.retirementScheme.retireOffset) months." )
else
    println( "No retirement occurring." )
end  # if ( maxTenure > 0 ) || ...


println( "\nSimulation is now ready to run." )


# Run simulation.
tStart = now()
println( "\nSimulation start at $tStart" )
run( mpSim )
tStop = now()
println( "Simulation end at $tStop. Elapsed time: $(tStop - tStart)" )
isSimulationFinished = true

end  # if rerunSimulation


# Process results.

tStart = now()
println( "\nReport generation start at $tStart" )
timeResolution = graphTimeResolutionInMonths

nRec = countRecords( mpSim, timeResolution )
nFluxIn = countFluxIn( mpSim, timeResolution )
nFluxOut = countFluxOut( mpSim, timeResolution, true )
nNetFlux = ( nFluxIn[ 1 ], nFluxIn[ 2 ] - nFluxOut[ 2 ] )
simAgeDist = getAgeDistEvolution( mpSim, timeResolution, monthFactor )
simAgeStats = getAgeStatistics( mpSim, timeResolution )
tStop = now()
println( "Report generation completed at $tStop. Elapsed time: $(tStop - tStart)" )


#=
tStart = now()
println( "Excel file generation start at $tStart" )
generateReport( mpSim, timeResolution, "testReport" )
tStop = now()
println( "Excel file generation completed at $tStop. Elapsed time: $(tStop - tStart)" )
=#


# Initialise plotting.
allowedVars = Dict{String, Any}(
    "personnel" => nRec,
    "flux in" => nFluxIn,
    "flux out" => nFluxOut,
    "net flux" => nNetFlux,
    "resigned" => nFluxOut,
    "retired" => nFluxOut
)

if !isdefined( :varLabels )
    const varLabels = Dict{String, String}(
        "personnel" => "Personnel",
        "flux in" => "Flux In",
        "flux out" => "Flux Out",
        "net flux" => "Net Flux",
        "resigned" => "Resigned",
        "retired" => "Retired"
    )
end

if !isdefined( :plotSim )
    function plotSim!( mpSim::ManpowerSimulation, arg::String, ym::Int,
        yM::Int )

        series = allowedVars[ arg ]
        xVals = series[ 1 ] / monthFactor

        if ( arg ∈ [ "retired", "resigned" ] ) && !haskey( series[ 3 ], arg )
            yVals = zeros( Int, length( xVals ), 1 )
        else
            yVals = arg ∈ [ "retired", "resigned" ] ?
                series[ 3 ][ arg ] : series[ 2 ]
        end
        yMin = min( minimum( yVals ), ym )
        yMax = max( maximum( yVals ), yM )
        plot!( xVals, yVals, label = varLabels[ arg ], w = 2,
            ylim = [ yMin, yMax ] + 0.01 * ( yMax - yMin ) * [ -1, 1 ] )
        return (yMin, yMax)

    end

    function plotSim( mpSim::ManpowerSimulation, firstArg::String,
        varArgs::String... )

        if ( firstArg ∉ keys( varLabels ) ) ||
            any( arg -> arg ∉ keys( varLabels ), varArgs )
            error( "Plot of unknown variable requested." )
        end

        tStart = now()
        println( "Plot generation started at $tStart" )

        firstSeries = allowedVars[ firstArg ]
        xVals = firstSeries[ 1 ] / monthFactor

        if ( firstArg ∈ [ "retired", "resigned" ] ) &&
            !haskey( firstSeries[ 3 ] )
            yVals = zeros( Int, length( xVals ), 1 )
        else
            yVals = firstArg ∈ [ "retired", "resigned" ] ?
                firstSeries[ 3 ][ firstArg ] : firstSeries[ 2 ]
        end

        yMin = minimum( yVals )
        yMax = maximum( yVals )
        plt = plot( xVals, yVals, label = varLabels[ firstArg ], w = 2,
            ylim = [ yMin, yMax ] + 0.01 * ( yMax - yMin ) * [ -1, 1 ],
            size = ( 800, 600 ), xlabel = "Simulation time (y)",
            ylabel = "Amount" )

        otherArgs = Vector{String}()
        map( arg -> if arg != firstArg push!( otherArgs, arg ) end, varArgs )
        otherArgs = unique( otherArgs )
        map( arg -> begin yMin, yMax = plotSim!( mpSim, arg, yMin, yMax ) end,
            otherArgs )
        gui( plt )

        tStop = now()
        println( "Plot generation completed at $tStop. Elapsed time: $(tStop - tStart)" )

    end

    function plotAgeStats( mpSim::ManpowerSimulation, timeRes::T ) where T <: Real

        ageStats = getAgeStatistics( mpSim, timeRes )
        minAge = minimum( ageStats[ 2 ][ :, 4 ] ) / 12
        maxAge = maximum( ageStats[ 2 ][ :, 5 ] ) / 12
        plt = plot( ageStats[ 1 ] / 12, ageStats[ 2 ][ :, 1 ] / 12,
            label = "Mean age", lw = 2, color = :blue,
            ylim = [ minAge, maxAge ] + 0.01 * ( maxAge - minAge ) * [ -1, 1 ] )
        plot!( ageStats[ 1 ] / 12, ageStats[ 2 ][ :, 3 ] / 12, lw = 2,
            color = :red, label = "Median age" )
        plot!( ageStats[ 1 ] / 12, ageStats[ 2 ][ :, 4 ] / 12, color = :black,
            label = "Minimum age" )
        plot!( ageStats[ 1 ] / 12, ageStats[ 2 ][ :, 5 ] / 12, color = :black,
            label = "Maximum age" )
        gui( plt )

    end  # plotAgeStats( mpSim, timeRes )
end
