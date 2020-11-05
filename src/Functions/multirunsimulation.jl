export  setMRSconfiguration!,
        setMRSruns!,
        setMRSdatabaseName!,
        setMRSmaxThreads!


function setMRSconfiguration!( mrs::MRS, mpSim::MPsim )::Bool
    mrs.mpSim = deepcopy( mpSim )
    return true
end  # setMRSconfiguration!( mrs, sim )


function setMRSruns!( mrs::MRS, nRuns::Integer )::Bool
    if nRuns < 0
        return false
    end  # if nRuns < 0

    mrs.nRuns = nRuns
    return true
end  # setMRSruns!( mrs, nruns )


function setMRSdatabaseName!( mrs::MRS, dbName::AbstractString="" )::Bool
    if dbName == ""
        mrs.resultsDBname = ""
        mrs.resultsDB = SQLite.DB()
        return true
    end  # if dbName == ""

    # Ensure the folder exists.
    if !ispath( dirname( dbName ) )
        mkpath( dirname( dbName ) )
    end  # if !ispath( dirname( dbName ) )

    mrs.resultsDBname = string( dbName )
    mrs.resultsDB = SQLite.DB( mrs.resultsDBname )
    return true
end  # setMRSdatabaseName!( mrs, dbName )


function setMRSmaxThreads!( mrs::MRS, maxThreads::Integer )::Bool
    if maxThreads <= 0
        return false
    end  # if maxThreads <= 0

    mrs.maxThreads = maxThreads
    return true
end  # setMRSmaxThreads!( mrs, maxThreads )


verifySimulation!( mrs::MRS )::Bool = verifySimulation!( mrs.mpSim )