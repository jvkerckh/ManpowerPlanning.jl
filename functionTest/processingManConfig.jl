# Initalise ManpowerPlanning module
if !isdefined( :ManpowerSimulation )
    # include( joinpath( dirname( Base.source_path() ), "..", "src",
    #     "ManpowerPlanning.jl" ) )
    using ManpowerPlanning
    isUpToDate = true
    println( "ManpowerPlanning module initialised." )
end


# Initialise the simulation.
if !isdefined( :isSimInitialised )
    mpSim = ManpowerSimulation()
    # println( mpSim )
# end

# if !isdefined( :isSimInitialised )
    initialise( mpSim )
    isSimInitialised = true
    println( "Manpower simulation mpSim initialised and ready for configuration." )
    # println( mpSim )
end

# Reset simulation if necessary.
if isdefined( :isSimulationFinished ) && isSimulationFinished && rerunSimulation
    resetSimulation( mpSim )
    isRecruitmentOkay = false
    isAttritionOkay = false
    isRetirementOkay = false
    println( "Manpower simulation mpSim reset." )
end

if !isdefined( :isSimulationFinished ) || rerunSimulation

isSimulationFinished = false

# Set cap of simulation.
setPersonnelCap( mpSim, pars[ "maxPersonnelMembers" ] )
println( "Personnel cap set at $(pars[ "maxPersonnelMembers" ]) personnel members." )

# Set length of simulation.
monthFactor = isSimTimeInMonths ? 12 : 1
simLength = pars[ "simulationLengthInYears" ] * monthFactor
setDatabaseCommitTime( mpSim, simLength / pars[ "numDBupdates" ] )
setSimulationLength( mpSim, simLength )
println( "Length of the simulation set at $(pars[ "simulationLengthInYears" ]) years." )

# Set up recruitment scheme.
recFreq = pars[ "timeBetweenRecruitmentCyclesInMonths" ] * monthFactor / 12
recOffset = pars[ "offsetOfRecruitmentCycleInMonths" ] * monthFactor / 12
recAge = pars[ "ageAtRecruitmentInYears" ] * monthFactor
recOff = ( recOffset % recFreq ) * 12 / monthFactor
recOff += recOff < 0 ? 12 : 0
recScheme = Recruitment( recFreq, recOffset )
setRecruitmentCap( recScheme, pars[ "maxNumberToRecruitEachCycle" ] )
println( "\nRecruitment scheme" )
println( "Time between two recruitment cycles is $(pars[ "timeBetweenRecruitmentCyclesInMonths" ]) months." )
println( "First recruitment cycle starts after $recOff months." )
println( "At most $(pars[ "maxNumberToRecruitEachCycle" ]) persons recruited every cycle." )

if isRecruitmentAgeFixed
    setRecruitmentAge( recScheme, recAge )
    println( "Recruits are $(pars[ "ageAtRecruitmentInYears" ]) years old." )
else
    recAgeDist = Dict{Float64, Float64}()
    map( ii -> recAgeDist[ pars[ "ageAtRecruitmentDistributionInYears" ][ ii ][ 1 ] * monthFactor ] =
        pars[ "ageAtRecruitmentDistributionInYears" ][ ii ][ 2 ],
        eachindex( pars[ "ageAtRecruitmentDistributionInYears" ] ) )
    minAge = minimum( keys( recAgeDist ) )
    maxAge = maximum( keys( recAgeDist ) )
    setAgeDistribution( recScheme, recAgeDist,
        pars[ "recruitmentAgeDistributionType" ] )
    println( "Recruits are between $minAge and $maxAge years old." )
end

if !isdefined( :isRecruitmentOkay ) || !isRecruitmentOkay
    clearRecruitmentSchemes!( mpSim )
    addRecruitmentScheme!( mpSim, recScheme )
    # println( mpSim )
    isRecruitmentOkay = true
end

println( "Recruitment scheme configured and added to the simulation." )

# Set up attrition scheme.
attrPeriod = pars[ "lengthOfAttritionPeriodInMonths" ] * monthFactor / 12
attrProb = pars[ "probabilityOfAttritionPerPeriod" ] /
    ( isProbabilityInPercent ? 100 : 1 )
attrScheme = Attrition( attrProb, attrPeriod )
println( "\nAttrition" )
println( "Attrition rate of $(attrProb * 100)% every $(pars[ "lengthOfAttritionPeriodInMonths" ]) months." )

if !isdefined( :isAttritionOkay ) || !isAttritionOkay
    setAttrition( mpSim, attrScheme )
    isAttritionOkay = true
end

println( "Attrition configured and added to the simulation." )

# Set up retirement scheme.
maxTenure = pars[ "maxCareerLengthInYears" ] * monthFactor
maxAge = pars[ "mandatoryRetirementAgeInYears" ] * monthFactor
retFreq = pars[ "timeBetweenRetirementCyclesInMonths" ] * monthFactor / 12
retOffset = pars[ "offsetOfRetiretmentCycleInMonths" ] * monthFactor / 12
println( "\nRetirement" )

if ( maxTenure > 0 )
    println( "Mandatory retirement after $(pars[ "maxCareerLengthInYears" ]) years of service." )
end

if ( maxAge > 0 )
    println( "Mandatory retirement at the age of $(pars[ "mandatoryRetirementAgeInYears" ]) years." )
end

if ( maxTenure > 0 ) || ( maxAge > 0 )
    retScheme = Retirement( freq = retFreq, offset = retOffset, maxCareer = maxTenure, retireAge = maxAge )
    println( "Time between two retirement cycles is $(pars[ "timeBetweenRetirementCyclesInMonths" ]) months." )
    println( "First retirement cycle starts after $recOff months." )
else
    retScheme = nothing
    println( "No retirement occurring." )
end

if !isdefined( :isRetirementOkay ) || !isRetirementOkay
    setRetirement( mpSim, retScheme )
    # println( mpSim )
    isRetirementOkay = true
end

println( "Retirement scheme configured and added to the simulation." )
println( "Simulation is now ready to run." )

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
timeResolution = pars[ "graphTimeResolutionInMonths" ] * monthFactor / 12

nRec = countRecords( mpSim, timeResolution )
nFluxIn = countFluxIn( mpSim, timeResolution )
nFluxOut = countFluxOut( mpSim, timeResolution, true )
nNetFlux = ( nFluxIn[ 1 ], nFluxIn[ 2 ] - nFluxOut[ 2 ] )
simAgeDist = getAgeDistEvolution( mpSim, timeResolution, 12 )
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
        minAge = minimum( ageStats[ 2 ][ :, 4 ] )
        maxAge = maximum( ageStats[ 2 ][ :, 5 ] )
        plt = plot( ageStats[ 1 ], ageStats[ 2 ][ :, 1 ], label = "Mean age",
            ylim = [ minAge, maxAge ] + 0.01 * ( maxAge - minAge ) * [ -1, 1 ] )
        plot!( ageStats[ 1 ], ageStats[ 2 ][ :, 2 ], label = "Median age" )
        plot!( ageStats[ 1 ], ageStats[ 2 ][ :, 4 ], label = "Minimum age" )
        plot!( ageStats[ 1 ], ageStats[ 2 ][ :, 5 ], label = "Maximum age" )
        gui( plt )

    end  # plotAgeStats( mpSim, timeRes )
end
