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

"""
```
saveSimulationConfiguration(
    mpSim::MPsim
    dbName::AbstractString )
```
This function saves the configuration of the manpower simulation `mpSim` to the database with name `dbName`.

This function returns `true`, indicating that the configuration has been saved successfully.
"""
function saveSimulationConfiguration( mpSim::MPsim,
    dbName::AbstractString )::Bool
    # Generate required path if it doesn't exist.
    if !ispath( dirname( dbName ) )
        mkpath( dirname( dbName ) )
    end  # if !ispath( dirname( dbName ) )

    currentDBname = mpSim.simDB.file
    setSimulationDatabase!( mpSim, dbName )
    saveSimulationConfiguration( mpSim )
    setSimulationDatabase!( mpSim, currentDBname )
    return true
end  # saveSimulationConfiguration( mpSim, dbName )


include( joinpath( simPrivPath, "saveconfigtodb.jl" ) )