function SimJulia.run( mpSim::MPsim, showInfo::Bool=false;
    saveConfig::Bool=true, seed::Integer=-1, sysEnt::Bool=false )::Nothing

    if !verifySimulation!( mpSim )
        error( "Simulation configuration is inconsistent, cannot run." )
        return
    elseif showInfo
        @info "Simulation configuration is consistent, initialising processes."
    end  # if !verifySimulation!( mpSim )

    mpSim.showInfo = showInfo
    seedSimulation!( mpSim, seed, sysEnt )
    DBInterface.execute( mpSim.simDB, "BEGIN TRANSACTION" )

    try
        if ( now( mpSim ) != 0 ) || ( mpSim.orgSize == 0 )
            resetSimulation( mpSim )
        end  # if ( now( mpSim ) != 0 ) || ...

        # Initialise the recruitment processes.
        for name in keys( mpSim.recruitmentByName )
            for recruitment in mpSim.recruitmentByName[name]
                @process recruitProcess( mpSim.sim, recruitment, mpSim )
            end  # for recruitment in mpSim.recruitmentByName[name]
        end  # for name in keys( mpSim.recruitmentByName )

        # Initialise the default retirement process.
        @process retireProcess( mpSim.sim, mpSim )

        # Initalise the attrition process.
        @process checkAttritionProcess( mpSim.sim, mpSim )

        # Initialise the transition processes.
        orderTransitions!( mpSim )

        for name in keys( mpSim.transitionsByName )
            for transition in mpSim.transitionsByName[name]
                @process transitionProcess( mpSim.sim, transition, mpSim )
            end  # for transition in mpSim.transitionsByName[name]
        end  # for name in keys( mpSim.transitionsByName )

        # Execute the simulation.
        run( mpSim.sim )
    catch err
        DBInterface.execute( mpSim.simDB, "COMMIT" )
        rethrow( err )
    end  # try

    DBInterface.execute( mpSim.simDB, "COMMIT" )

    if mpSim.showInfo
        println( "Attrition execution processes took ",
            mpSim.attritionExecTime.value / 1000, " seconds." )
    end  # if mpSim.showInfo

    # Save the configuration if needed.
    if saveConfig
        saveSimulationConfiguration( mpSim )
    end  # if saveConfig

    mpSim.isVirgin = true
    return

end  # run( mpSim, showInfo, saveConfig, seed, sysEnt )


include( joinpath( simPath, "dboperations.jl" ) )
include( joinpath( simPath, "snapshot.jl" ) )
include( joinpath( simPrivPath, "attrition.jl" ) )
include( joinpath( simPrivPath, "attribute.jl" ) )
include( joinpath( simPrivPath, "recruitment.jl" ) )
include( joinpath( simPrivPath, "retirement.jl" ) )
include( joinpath( simPrivPath, "transition.jl" ) )
include( joinpath( simPrivPath, "manpowersimulation.jl" ) )