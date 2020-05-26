export  initPopReport,
        initPopAgeReport


function initPopReport( mpSim::MPsim )::DataFrame

    queryCmd = string( "SELECT targetNode, count( targetNode ) amount FROM `",
        mpSim.transDBname , "`",
        "\n    WHERE transition IS 'Init'",
        "\n    GROUP BY targetNode" )
    return DataFrame( DBInterface.execute( mpSim.simDB, queryCmd ) )

end  # function initPopReport( mpSim )


function initPopAgeReport( mpSim::MPsim, ageRes::Real,
    ageType::Symbol )::DataFrame

    if ageRes <= 0
        @warn "Age resolution must be > 0, cannot generate report."
        return DataFrame()
    end  # if ageRes <= 0

    if ageType ∉ [:age, :tenure, :timeInNode]
        @warn "Unknown type of data requested, cannot generate report."
        return DataFrame()
    end  # if ageType ∉ [:age, :tenure, :timeInNode]

    subpopulation = Subpopulation( "Init" )
    addSubpopulationCondition!( subpopulation,
        MPcondition( "had transition", ==, "Init" ) )
    ages = getAgesAtTime( mpSim, 0.0, [subpopulation], ageType )[1]

    if isempty( ages )
        return DataFrame()
    end  # if isempty( ages )

    return processInitPopAges( ages, Float64( ageRes ) )

end  # initPopAgeReport( mpSim, ageRes, ageType )


include( joinpath( repPrivPath, "initpop.jl" ) )