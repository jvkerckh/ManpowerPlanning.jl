# This file defines the MultiRunSimulation type. This type bundles all the
#   information of a simulation that runs multiple times.

export MultiRunSimulation, MRS
mutable struct MultiRunSimulation

    mpSim::MPsim
    nRuns::Int
    resultsDBname::String
    maxThreads::Int

    seedRNG::MersenneTwister
    resultsDB::SQLite.DB


    function MultiRunSimulation( mpSim::MPsim )::MRS

        newMRS = new()
        newMRS.mpSim = deepcopy( mpSim )
        newMRS.nRuns = 1
        newMRS.resultsDBname = ""
        newMRS.maxThreads = Threads.nthreads()
        newMRS.seedRNG = MersenneTwister()
        newMRS.resultsDB = SQLite.DB( "" )
        return newMRS

    end  # MultiRunSimulation( mpSim )

    MultiRunSimulation( name::String="sim" )::MRS = MRS( MPsim( name ) )

end  # MultiRunSimulation


const MRS = MultiRunSimulation