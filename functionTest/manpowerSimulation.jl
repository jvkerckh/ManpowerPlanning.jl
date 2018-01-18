if !isdefined( :ManpowerPlanning )
    include( "../src/ManpowerPlanning.jl" )
    println( "Package loaded okay." )
end  # if isdefined( :ManpowerPlanning )


mpSim = ManpowerSimulation( "mpSim" )

persCap = 10
ManpowerPlanning.setPersonnelCap( mpSim, persCap )

recFreq, recOff = 3, 0
recCap = 1
recAge = 18
recScheme = Recruitment( recFreq, recOff )
ManpowerPlanning.setRecruitmentCap( recScheme, recCap )
ManpowerPlanning.setRecruitmentAge( recScheme, recAge )
ManpowerPlanning.addRecruitmentScheme!( mpSim, recScheme )

attrFreq = 1
attrRate = 1
attrScheme = Attrition( attrRate, attrFreq )
ManpowerPlanning.setAttrition( mpSim, attrScheme )

retAge = 60
retFreq, retOff = 2, 0
retScheme = Retirement( freq = retFreq, offset = retOff )
ManpowerPlanning.setRetirementAge( retScheme, retAge )
ManpowerPlanning.setRetirement( mpSim, retScheme )

simLength = 500
ManpowerPlanning.setSimulationLength( mpSim, simLength )

# Simulation must be made ready to run.
ManpowerPlanning.initialise( mpSim )

tic()
run( mpSim )
toc()

println( mpSim )
#println( "Personnel\n", SQLite.query( mpSim.simDB, "SELECT * FROM $(mpSim.personnelDBname)" ) )
#println( "\nHistory\n", SQLite.query( mpSim.simDB, "SELECT * FROM $(mpSim.historyDBname)" ) )
