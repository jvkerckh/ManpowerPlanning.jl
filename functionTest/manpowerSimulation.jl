if !isdefined( :ManpowerPlanning )
    ENV[ "PLOTS_USE_ATOM_PLOTPANE" ] = "false"  # To open plots in external window
    using Plots
    plotly()
    include( "../src/ManpowerPlanning.jl" )
    using ManpowerPlanning
    println( "Package loaded okay." )
end  # if isdefined( :ManpowerPlanning )


mpSim = ManpowerSimulation()

persCap = 5000
ManpowerPlanning.setPersonnelCap( mpSim, persCap )

recFreq, recOff = 2, 0
recCap = 500
recAge = 18
recScheme = Recruitment( recFreq, recOff )
ManpowerPlanning.setRecruitmentCap( recScheme, recCap )
ManpowerPlanning.setRecruitmentAge( recScheme, recAge )
ManpowerPlanning.addRecruitmentScheme!( mpSim, recScheme )

attrFreq = 3
attrRate = 0.03
attrScheme = Attrition( attrRate, attrFreq )
ManpowerPlanning.setAttrition( mpSim, attrScheme )

retAge = 60
retFreq, retOff = 1, 0
retScheme = Retirement( freq = retFreq, offset = retOff )
ManpowerPlanning.setRetirementAge( retScheme, retAge )
ManpowerPlanning.setRetirement( mpSim, retScheme )

simLength = 200
ManpowerPlanning.setSimulationLength( mpSim, simLength )

nTimes = 200
dbTime = max( 1, simLength / nTimes )
ManpowerPlanning.setDatabaseCommitTime( mpSim, dbTime )

# Simulation must be made ready to run.
ManpowerPlanning.initialise( mpSim )

tStart = now()
println( "Simulation start at $tStart" )
run( mpSim )
tStop = now()
println( "Simulation end at $tStop. Elapsed time: $(tStop - tStart)" )

tStart = now()
println( "Report generation start at $tStart" )
tDelta = 2
nRec = ManpowerPlanning.countRecords( mpSim, tDelta )
nFluxIn = ManpowerPlanning.countFluxIn( mpSim, tDelta )
nFluxOut = ManpowerPlanning.countFluxOut( mpSim, tDelta, true )
nNetFlux = nFluxIn[ 2 ] - nFluxOut[ 2 ]
tStop = now()
println( "Report generation end at $tStop. Elapsed time: $(tStop - tStart)" )

minNetFlux = minimum( nNetFlux )

plt = plot( nRec[ 1 ], nRec[ 2 ], w = 3, label = "Personnel", ylim = [
    - persCap * 0.01 + minNetFlux, persCap * 1.01 ] )
plot!( nFluxIn[ 1 ], nFluxIn[ 2 ], w = 2, label = "Flux In" )
plot!( nFluxOut[ 1 ], nFluxOut[ 2 ], w = 2, label = "Flux Out" )
plot!( nFluxIn[ 1 ], nNetFlux, w = 2, label = "Net Flux" )
gui( plt )

maxFlux = max( maximum( nFluxIn[ 2 ] ), maximum( nFluxOut[ 2 ] ) )

plt = plot( nFluxIn[ 1 ], nFluxIn[ 2 ], w = 2, label = "Flux In", ylim = [
    - recCap * 0.01 + minNetFlux, maxFlux * 1.01 ] )
plot!( nFluxOut[ 1 ], nFluxOut[ 2 ], w = 2, label = "Flux Out" )
plot!( nFluxIn[ 1 ], nNetFlux, w = 2, label = "Net Flux" )
plot!( nFluxOut[ 1 ], nFluxOut[ 3 ][ "resigned" ], label = "Resigned" )
plot!( nFluxOut[ 1 ], nFluxOut[ 3 ][ "retired" ], label = "Retired" )
gui( plt )

#println( mpSim )
#println( "\nPersonnel\n", SQLite.query( mpSim.simDB, "SELECT * FROM $(mpSim.personnelDBname)" ) )
#println( "\nHistory\n", SQLite.query( mpSim.simDB, "SELECT * FROM $(mpSim.historyDBname)" ) )
