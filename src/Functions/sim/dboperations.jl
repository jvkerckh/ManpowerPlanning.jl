export  saveSimulationConfiguration


"""
```
saveSimulationConfiguration( mpSim::MPsim )
```
"""
function saveSimulationConfiguration( mpSim::MPsim )::Bool

    SQLite.execute!( mpSim.simDB, "BEGIN TRANSACTION" )
    wipeConfigTable( mpSim )
    storeGeneralPars( mpSim )
    storeAttributes( mpSim )
    storeAttrition( mpSim )
    storeNodes( mpSim )
    storeRecruitment( mpSim )
    storeTransitions( mpSim )
    storeRetirement( mpSim )
    SQLite.execute!( mpSim.simDB, "COMMIT" )

    return true

end  # saveSimulationConfiguration( mpSim )


include( joinpath( simPrivPath, "saveconfigtodb.jl" ) )