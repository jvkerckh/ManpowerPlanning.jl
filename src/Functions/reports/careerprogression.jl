export  generateCareerProgression


"""
```
generateCareerProgression(
    mpSim::MPsim,
    idList::String... )
```
This function generates a report of the careers that the personnel members with IDs in `idList` had in the manpower simulation `mpSim`.

This function returns a `Dict{String, Tuple}` where the keys are the IDs that are in the simulation. The value associated with each IDs is a `Tuple{Float64, Dict}`, where the number is the age of the person at recruitment, and the dictionary consists of time stamps (`Float64` key) and a transition/source node/target node `NTuple{3, String}`.
"""
function generateCareerProgression( mpSim::MPsim,
    idList::String... )::Dict{String,Tuple{Float64,DataFrame}}

    result = Dict{String,Tuple{Float64,DataFrame}}()

    if now( mpSim ) == 0
        @warn "Simulation hasn't started yet, can't make report."
        return result
    end  # if now( mpSim ) == 0

    queryCmd = string( "SELECT `", mpSim.idKey, "`, ageAtRecruitment FROM `", mpSim.persDBname, "` WHERE `",
        mpSim.idKey, "` IN ('", join( idList, "', '" ), "')" )
    recruitmentAges = DataFrame( DBInterface.execute( mpSim.simDB, queryCmd ) )

    if isempty( recruitmentAges )
        return result
    end  # if isempty( recruitmentAges )

    idSymbol = Symbol( mpSim.idKey )
    queryCmd = string( "SELECT * FROM `", mpSim.transDBname, "` WHERE",
        "\n    `", mpSim.idKey, "` IN ('",
        join( recruitmentAges[:, idSymbol], "', '" ), "')",
        "\n    ORDER BY `", mpSim.idKey, "`, timeIndex" )
    careerPaths = DataFrame( DBInterface.execute( mpSim.simDB, queryCmd ) )

    for ii in 1:size( recruitmentAges, 1 )
        id = recruitmentAges[ii, idSymbol]
        careerPath = careerPaths[careerPaths[:, idSymbol] .== id, :]
        result[id] = (recruitmentAges[ii, :ageAtRecruitment], careerPath)
    end  # for ii in 1:size( recruitmentAges, 1 )

    return result

end  # generateCareerProgression( mpSim, idList )