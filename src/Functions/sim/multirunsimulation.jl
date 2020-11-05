function SimJulia.run( mrs::MRS, showInfo::Bool=false; saveConfig::Bool=true,
    seed::Integer=-1, sysEnt::Bool=false )::Nothing
    if !verifySimulation!( mrs )
        error( "Simulation configuration is inconsistent, cannot run." )
        return
    elseif showInfo
        @info "Simulation configuration is consistent, initialising processes."
    end  # if !verifySimulation!( mrs )

    # Set the random seed of the seed generator.
    mrs.seedRNG = seed < 0 ? MersenneTwister() : MersenneTwister( seed )

    # Initialise the database.
    initialiseMRSresultsDatabase!( mrs )

    # Create folder for tmp databases.
    tmpFolder = joinpath( dirname( mrs.resultsDB.file ), "tmps" )

    if !ispath( tmpFolder )
        mkpath( tmpFolder )
    end  # if !ispath( tmpFolder )

    # Run the simulations.
    nThreads = min( mrs.nRuns, mrs.maxThreads, Threads.nthreads() )
    currentSim = Channel{Int}( 1 )
    resultsFree = Channel{Bool}( 1 )
    put!( currentSim, 1 )
    put!( resultsFree, true )
 
    Threads.@threads for ii in 1:nThreads
        runsim( mrs, currentSim, resultsFree, tmpFolder )
    end  # Threads.@threads for ii in ...

    # Clear tmp databases.
    GC.gc()  # SQLite keeps files locked until their pointers have been
             #   scrubbed by the GC.
    rm( tmpFolder, recursive=true, force=true )
    return
end  #  run( mrs, showInfo, saveConfig, seed, sysEnt )


include( joinpath( simPrivPath, "multirunsimulation.jl" ) )