function SimJulia.run( mpSim::MPsim, showInfo::Bool = false;
    saveConfig::Bool = true )::Nothing

    if !verifySimulation!( mpSim )
        error( "Simulation configuration is inconsistent, cannot run." )
    elseif showInfo
        @info "Simulation configuration is consistent, initialising processes."
    end  # if !verifySimulation!( mpSim )

    mpSim.showInfo = showInfo
    SQLite.execute!( mpSim.simDB, "BEGIN TRANSACTION" )
    resetSimulation( mpSim )

    # Initialise the recruitment processes.
    for name in keys( mpSim.recruitmentByName )
        for recruitment in mpSim.recruitmentByName[ name ]
            @process recruitProcess( mpSim.sim, recruitment, mpSim )
        end  # for recruitment in mpSim.recruitmentByName[ name ]
    end  # for name in keys( mpSim.recruitmentByName )

    # Execute the simulation.
    try
        run( mpSim.sim )
    catch err
        SQLite.execute!( mpSim.simDB, "COMMIT" )
        rethrow( err )
    end  # try

    SQLite.execute!( mpSim.simDB, "COMMIT" )

    # Save the configuration if needed.
    if saveConfig
        saveSimulationConfiguration( mpSim )
    end  # if saveConfig

    return

end  # run( mpSim, showInfo, saveConfig )


include( joinpath( simPath, "dboperations.jl" ) )
include( joinpath( simPrivPath, "attrition.jl" ) )
include( joinpath( simPrivPath, "attribute.jl" ) )
include( joinpath( simPrivPath, "recruitment.jl" ) )
include( joinpath( simPrivPath, "manpowersimulation.jl" ) )