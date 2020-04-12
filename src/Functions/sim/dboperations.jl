export  saveSimulationConfiguration


"""
```
saveSimulationConfiguration( mpSim::MPsim )
```
This function saves the configuration of the manpower simulation `mpSim` to the database with the name defined in the simulation object.

This function returns `true`, indicating that the configuration has been saved successfully.
"""
function saveSimulationConfiguration( mpSim::MPsim )::Bool

    DBInterface.execute( mpSim.simDB, "BEGIN TRANSACTION" )
    wipeConfigTable( mpSim )
    storeGeneralPars( mpSim )
    storeAttributes( mpSim )
    storeAttrition( mpSim )
    storeNodes( mpSim )
    storeRecruitment( mpSim )
    storeTransitions( mpSim )
    storeRetirement( mpSim )
    DBInterface.execute( mpSim.simDB, "COMMIT" )

    return true

end  # saveSimulationConfiguration( mpSim )


include( joinpath( simPrivPath, "saveconfigtodb.jl" ) )