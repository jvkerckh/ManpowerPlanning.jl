function SimJulia.run( mrs::MRS, showInfo::Bool=false; saveConfig::Bool=true,
    seed::Integer=-1, sysEnt::Bool=false )::Nothing
    if !verifySimulation!( mrs )
        error( "Simulation configuration is inconsistent, cannot run." )
        return
    elseif showInfo
        @info "Simulation configuration is consistent, initialising processes."
    end  # if !verifySimulation!( mrs )

    # Set the random seed of the seed generator.
    mrs.showInfo = showInfo
    mrs.seedRNG = seed < 0 ? MersenneTwister() : MersenneTwister( seed )

    # Initialise the database.
    initialiseMRSresultsDatabase!( mrs )

    # Create folder for tmp databases.
    tmpFolder = joinpath( dirname( mrs.resultsDB.file ), "tmps" )

    if !ispath( tmpFolder )
        mkpath( tmpFolder )
    end  # if !ispath( tmpFolder )

    nThreads = min( mrs.nRuns, mrs.maxThreads, Threads.nthreads() )
    hasSnapshot = mrs.mpSim.dbSize > 0

    if hasSnapshot
        # copySnapshots( mrs, tmpFolder )
        copySnapshots( mrs, tmpFolder, nThreads )
        GC.gc()
    end  # if hasSnapshot

    # Run the simulations.
    tStart = now()
    mrs.nComplete = 0
    currentSim = Channel{Int}( 1 )
    # resultsFree = Channel{Bool}( 1 )
    put!( currentSim, 1 )
    mrs.mpSim.sim = Simulation()
    # put!( resultsFree, true )
 
    Threads.@threads for threadnum in 1:nThreads
        # runsim( mrs, currentSim, resultsFree, tmpFolder )
        runsim( mrs, threadnum, hasSnapshot, currentSim, tmpFolder, nThreads )
    end  # Threads.@threads for threadnum in ...

    tElapsed = ( now() - tStart ).value / 1000.0
    mrs.showInfo && @info string( "Running ", mrs.nRuns, " replications on ",
        nThreads, " threads took ", tElapsed, " seconds." )

    # Clear tmp databases.
    copyResults( mrs, tmpFolder )
    run( mrs.mpSim )
    GC.gc();  # SQLite keeps files locked until their pointers have been
              #   scrubbed by the GC.
    rm( tmpFolder, recursive=true, force=true )
    return
end  #  run( mrs, showInfo, saveConfig, seed, sysEnt )


include( joinpath( simPrivPath, "multirunsimulation.jl" ) )