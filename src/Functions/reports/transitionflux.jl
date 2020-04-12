export  transitionFluxReport


"""
```
transitionFluxReport(
    mpSim::MPsim,
    timeGrid::Vector{Float64},
    transitions::TransitionType... )
```
This function generates reports for the flux of the unique transitions in `transitions` of the manpower simulation `mpSim`. The reports are generated on the grid of time points `timeGrid`.

The transitions are given either as:
* a `String`: the name of the transition, where `"attrition"` (personnel attrition) and `"retirement"` (default retirement scheme) are valid names,
* a `Tuple{String, String}`: the source and target nodes of the transition, where `""`, `"out"`, and `"external"` refer to "not in the system", or
* a `Tuple{String, String, String}`: the name and the source and target nodes of the transition.

If multiple transitions have the same name, the fluxes will be summed together.

This function will issue a warning and not generate any report in the following two cases:
1. There are no positive time points in the time grid;
2. None of the entered transitions exist in the simulation.

The function returns a `DataFrame` holding the flux report. The first column are the time points, and each other column corresponds to one of the valid transitions. In case the function issues a warning, its return value will be an empty `DataFrame`.
"""
function transitionFluxReport( mpSim::MPsim, timeGrid::Vector{Float64},
    transitions::TransitionType... )::DataFrame

    timeGrid = timeGrid[0.0 .<= timeGrid .<= now( mpSim )]
    timeGrid = unique( sort( timeGrid, rev = true ) )

    if isempty( timeGrid )
        @warn "No valid time points in time grid, cannot generate report."
        return DataFrame()
    end  # if isempty( timeGrid )

    if timeGrid[end] > 0.0
        push!( timeGrid, 0.0 )
    end  # if timeGrid[end] > 0.0

    reverse!( timeGrid )

    transitions = filter( transition -> validateTransition( mpSim, transition ),
        collect( transitions ) )

    if isempty( transitions )
        @warn "No valid transitions in list, cannot generate report."
        return DataFrame()
    end  # if isempty( transitions )

    unique!( transitions )
    results = zeros( Int, length( timeGrid ), length( transitions ) )

    for ii in eachindex( transitions )
        results[:, ii] = createTransitionFluxReport( mpSim, timeGrid,
            transitions[ii] )
    end  # for transition in transitions

    transitionNames = vcat( "timeStart", "timePoint",
        generateTransitionName.( transitions ) )

    return DataFrame( hcat( vcat( 0, timeGrid[1:(end - 1)] ), timeGrid,
        results ), Symbol.( transitionNames ) )

end  # transitionFluxReport( mpSim, timeGrid, transitions )


"""
```
transitionFluxReport(
    mpSim::MPsim,
    timeRes::Real,
    transitions::TransitionType... )
```
This function generates reports for the flux of the unique transitions in `transitions` of the manpower simulation `mpSim`. The reports are generated on a grid of time points with resolution `timeRes`.

The transitions are given either as:
* a `String`: the name of the transition, where `"attrition"` (personnel attrition) and `"retirement"` (default retirement scheme) are valid names,
* a `Tuple{String, String}`: the source and target nodes of the transition, where `""`, `"out"`, and `"external"` refer to "not in the system", or
* a `Tuple{String, String, String}`: the name and the source and target nodes of the transition.

If multiple transitions have the same name, the fluxes will be summed together.

This function will issue a warning and not generate any report in the following two cases:
1. The resolution of the time grid is ⩽ 0;
2. None of the entered transitions exist in the simulation.

The function returns a `DataFrame` holding the flux report. The first column are the time points, and each other column corresponds to one of the valid transitions. In case the function issues a warning, its return value will be an empty `DataFrame`.
"""
transitionFluxReport( mpSim::MPsim, timeRes::Real,
    transitions::TransitionType... )::DataFrame = transitionFluxReport( mpSim,
    generateTimeGrid( mpSim, timeRes ), transitions... )


include( joinpath( repPrivPath, "transitionflux.jl" ) )