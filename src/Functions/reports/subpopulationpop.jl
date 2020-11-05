export  subpopulationPopReport


"""
```
subpopulationPopReport(
    mpSim::MPsim,
    timeGrid::Vector{Float64},
    subpopulations::Subpopulation... )
```
This function generates reports for the evolution of the population of the valid subpopulations in `subpopulations` of the manpower simulation `mpSim`. The reports are generated on the grid of time points `timeGrid`.
    
This function will issue a warning and not generate any report in the following two cases:
1. There are no positive time points in the time grid;
2. None of the entered subpopulations are valid subpopulations in the simulation, where a subpopulation is invalid if its souce nodes doesn't exist in the simulation.
    
This function returns a `DataFrame`, with the first column the time points and the other columns corresponding to the population counts at each time point for each subpopulation. In case the function issues a warning, its return value will be an empty `DataFrame`.
"""
function subpopulationPopReport( mpSim::MPsim, timeGrid::Vector{Float64},
    subpopulations::Subpopulation... )::DataFrame

    result = DataFrame()

    if now( mpSim ) == 0
        @warn "Simulation hasn't started yet, can't make report."
        return result
    end  # if now( mpSim ) == 0

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

    subpopulations = filter( collect( subpopulations ) ) do subpopulation
        sourceNode = subpopulation.sourceNode
        return ( sourceNode == "active" ) ||
            haskey( mpSim.baseNodeList, sourceNode ) ||
            haskey( mpSim.compoundNodeList, sourceNode )
    end  # filter( ... ) do subpopulation

    if isempty( subpopulations )
        return result
    end  # if isempty( subpopulations )

    counts = zeros( Int, length( timeGrid ), length( subpopulations ) )

    for ii in eachindex( timeGrid )
        counts[ii, :] = length.( getSubpopulationAtTime( mpSim,
            timeGrid[ii], subpopulations ) )
    end  # for ii in eachindex( timeGrid )

    return DataFrame( hcat( timeGrid, counts ), vcat( :timePoint,
        map( subpopulation -> Symbol( subpopulation.name ), subpopulations ) ) )

end  # subpopulationPopReport( mpSim, timeGrid, subpopulations )

"""
```
subpopulationPopReport(
    mpSim::MPsim,
    timeRes::Real,
    subpopulations::Subpopulation... )
```
This function generates reports for the evolution of the population of the valid subpopulations in `subpopulations` of the manpower simulation `mpSim`.  The reports are generated on a grid of time points with resolution `timeRes`.
    
This function will issue a warning and not generate any report in the following two cases:
1. There are no positive time points in the time grid;
2. None of the entered subpopulations are valid subpopulations in the simulation, where a subpopulation is invalid if its souce nodes doesn't exist in the simulation.
    
This function returns a `DataFrame`, with the first column the time points and the other columns corresponding to the population counts at each time point for each subpopulation. In case the function issues a warning, its return value will be an empty `DataFrame`.
"""
subpopulationPopReport( mpSim::MPsim, timeRes::Real,
    subpopulations::Subpopulation... )::DataFrame =
    subpopulationPopReport( mpSim, generateTimeGrid( mpSim, timeRes ),
    subpopulations... )


include( joinpath( repPrivPath, "subpopulationpop.jl" ) )