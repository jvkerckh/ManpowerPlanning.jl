@resumable function dbCommitProcess( sim::Simulation, mpSim::MPsim )

    timeToWait = mpSim.simLength / mpSim.nCommits

    while now( sim ) + timeToWait < mpSim.simLength
        @yield timeout( sim, timeToWait )
        DBInterface.execute( mpSim.simDB, "COMMIT" )
        DBInterface.execute( mpSim.simDB, "BEGIN TRANSACTION" )
    end  # while now( sim ) + timeToWait < mpSim.simLength

end  # dbCommitProcess( sim, mpSim )