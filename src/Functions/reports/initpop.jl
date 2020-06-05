export  initPopReport,
        initPopAgeReport


"""
```
initPopReport( mpSim::MPsim )
```
This function creates a composition report on the initial population of the manpower simulation `mpSim`.

This function returns a `DataFrame`, with the nodes to which the members of the initial belong and the number in each node. If there is no population, this function returns an empty `DataFrame`.
"""
function initPopReport( mpSim::MPsim )::DataFrame

    queryCmd = string( "SELECT targetNode, count( targetNode ) amount FROM `",
        mpSim.transDBname , "`",
        "\n    WHERE transition IS 'Init'",
        "\n    GROUP BY targetNode" )
    return DataFrame( DBInterface.execute( mpSim.simDB, queryCmd ) )

end  # function initPopReport( mpSim )


"""
```
initPopAgeReport(
    mpSim::MPsim,
    ageRes::Real,
    ageType::Symbol )
```
This function creates an age distribution report on the initial population of the manpower simulation `mpSim`. The report is generated on a grid of ages with resoluion `ageRes`.

The type of age that is reported is determined by `ageType`, which can take these valid values:
* `:age` for the actual age of the personnel members,
* `:tenure` for the tenure of the personnel members, and
* `:timeInNode` for the time the personnel members are in their current base node.

This function returns a `DataFrame`, with the number of personnel members in each age bracket. The last 5 entries in the `DataFrame` are the summary statistics (mean, median, standard deviation, minimum, and maximum) of the ages.
"""
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