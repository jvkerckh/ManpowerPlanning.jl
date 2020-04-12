export  subpopulationAgeReport


"""
```
subpopulationAgeReport(
    mpSim::MPsim,
    timeGrid::Vector{Float64},
    ageRes::Real,
    ageType::Symbol,
    subpopulations::Subpopulation... )
```
This function generates reports for the distribution of the ages of the personnel members in the valid subpopulations in `subpopulations` of the manpower simulation `mpSim`. The reports are generated on the grid of time points `timeGrid` and on a grid of ages with resoluion `ageRes`.

The type of age that is reported is determined by `ageType`, which can take these valid values:
* `:age` for the actual age of the personnel members,
* `:tenure` for the tenure of the personnel members, and
* `:timeInNode` for the time the personnel members are in their current base node. If the subpopulation is based on the entire population, this reports the tenure instead.

This function will issue a warning and not generate any report in the following two cases:
1. There are no positive time points in the time grid;
2. None of the entered subpopulations are valid subpopulations in the simulation, where a subpopulation is invalid if its souce nodes doesn't exist in the simulation.
    
This function returns a `Dict` with the valid subpopulations as the keys (`String`), and a `DataFrame` (the age report for the subpopulation) as the value. In case the function issues a warning, its return value will be an empty dictionary.
"""
function subpopulationAgeReport( mpSim::MPsim, timeGrid::Vector{Float64},
    ageRes::Real, ageType::Symbol,
    subpopulations::Subpopulation... )::Dict{String,DataFrame}

    result = Dict{String,DataFrame}()
    timeGrid = timeGrid[0.0 .<= timeGrid .<= now( mpSim )]
    timeGrid = unique( sort( timeGrid, rev = true ) )

    if isempty( timeGrid )
        @warn "No valid time points in time grid, cannot generate report."
        return result
    end  # if isempty( timeGrid )

    if timeGrid[end] > 0.0
        push!( timeGrid, 0.0 )
    end  # if timeGrid[end] > 0.0

    reverse!( timeGrid )

    if ageRes <= 0
        @warn "Age resolution must be > 0, cannot generate report."
        return result
    end  # if ageRes <= 0

    if ageType ∉ [:age, :tenure, :timeInNode]
        @warn "Unknown type of data requested, cannot generate report."
        return result
    end  # if ageType ∉ [:age, :tenure, :timeInNode]

    subpopulations = filter( collect( subpopulations ) ) do subpopulation
        sourceNode = subpopulation.sourceNode
        return ( sourceNode == "active" ) ||
            haskey( mpSim.baseNodeList, sourceNode ) ||
            haskey( mpSim.compoundNodeList, sourceNode )
    end  # filter( ... ) do subpopulation

    if isempty( subpopulations )
        return result
    end  # if isempty( subpopulations )

    personnelAges = map( tPoint -> getAgesAtTime( mpSim, tPoint, subpopulations,
        ageType ), timeGrid )
    # ! Vector broadcast doesn't work properly for some reason.
    personnelAges = hcat( personnelAges... )
    result = processSubpopulationAges( personnelAges, subpopulations, timeGrid,
        Float64( ageRes ) )
    return result

end  # subpopulationAgeReport( mpSim, timeGrid, ageRes, ageType,
     #   subpopulations )

"""
```
subpopulationAgeReport(
    mpSim::MPsim,
    timeRes::Real,
    ageRes::Real,
    ageType::Symbol,
    subpopulations::Subpopulation... )
```
This function generates reports for the distribution of the ages of the personnel members in the valid subpopulations in `subpopulations` of the manpower simulation `mpSim`. The reports are generated on a grid of time points with resolution `timeRes` and on a grid of ages with resoluion `ageRes`.

The type of age that is reported is determined by `ageType`, which can take these valid values:
* `:age` for the actual age of the personnel members,
* `:tenure` for the tenure of the personnel members, and
* `:timeInNode` for the time the personnel members are in their current base node. If the subpopulation is based on the entire population, this reports the tenure instead.

This function will issue a warning and not generate any report in the following two cases:
1. There are no positive time points in the time grid;
2. None of the entered subpopulations are valid subpopulations in the simulation, where a subpopulation is invalid if its souce nodes doesn't exist in the simulation.
    
This function returns a `Dict` with the valid subpopulations as the keys (`String`), and a `DataFrame` (the age report for the subpopulation) as the value. In case the function issues a warning, its return value will be an empty dictionary.
"""
subpopulationAgeReport( mpSim::MPsim, timeRes::Real, ageRes::Real,
    ageType::Symbol,
    subpopulations::Subpopulation... )::Dict{String,DataFrame} =
    subpopulationAgeReport( mpSim, generateTimeGrid( mpSim, timeRes ), ageRes,
    ageType, subpopulations... )


include( joinpath( repPrivPath, "subpopulationage.jl" ) )