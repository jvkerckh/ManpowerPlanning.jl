function SimJulia.run( mpSim::MPsim, showInfo::Bool = false )::Nothing

    if !verifySimulation!( mpSim )
        error( "Simulation configuration is inconsistent, cannot run." )
    elseif showInfo
        @info "Simulation configuration is consistent, initialising processes."
    end  # if !verifySimulation!( mpSim )

    mpSim.showInfo = showInfo

    # Execute the simulation.
    SQLite.execute!( mpSim.simDB, "BEGIN TRANSACTION" )

    try
        run( mpSim.sim )
    catch err
        SQLite.execute!( mpSim.simDB, "COMMIT" )
        rethrow( err )
    end  # try

    SQLite.execute!( mpSim.simDB, "COMMIT" )

    saveSimulationConfiguration( mpSim )

    return

end  # run( mpSim, showInfo )


include( joinpath( simPath, "dboperations.jl" ) )