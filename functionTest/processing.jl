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

println( "\nPersonnel target set at $(mpSim.personnelTarget) personnel members." )
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
println( "Simulation end at $tStop. Elapsed time: $(mpSim.simTimeElapsed.value / 1000) seconds" )
isSimulationFinished = true

end  # if rerunSimulation


# Process results.

tStart = now()
println( "\nReport generation start at $tStart" )
timeResolution = graphTimeResolutionInMonths
generateReports( mpSim, timeResolution, monthFactor )
tStop = now()
println( "Report generation completed at $tStop. Elapsed time: $(tStop - tStart)" )
