# This file holds the process that controls access to the SQLite database.

@resumable function dbCommitProcess( sim::Simulation, toTime::Float64,
    mpSim::ManpowerSimulation )

    while now( sim ) + mpSim.commitFrequency < toTime
        @yield timeout( sim, mpSim.commitFrequency )
        SQLite.execute!( mpSim.simDB, "COMMIT" )
        SQLite.execute!( mpSim.simDB, "BEGIN TRANSACTION" )
    end  # while now( sim ) + mpSim.commitFrequency < toTime

end  # dbCommitProcess( sim, toTime, mpSim )
