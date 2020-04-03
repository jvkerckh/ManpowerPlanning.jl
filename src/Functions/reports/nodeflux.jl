export  nodeFluxReport


"""
```
nodeFluxReport(
    mpSim::MPsim,
    timeGrid::Vector{Float64},
    fluxType::KeyType,
    nodes::String... )
```
This function generates reports for the flux into, out of, or within the valid nodes in `nodes` of the manpower simulation `mpSim`. The reports are generated on the grid of time points `timeGrid`, and the type of report is determined by `fluxType`:
* `:in`: flux into the node;
* `:out`: flux out of the node;
* `:within`: flux within different component nodes of the node. This creates no report for base nodes.

The nodes can be any base node, compound node, or `"active"`, signifying the entire population.

This function will issue a warning and not generate any report in the following three cases:
1. There are no positive time points in the time grid;
2. The flux type is unknown;
3. None of the entered nodes are actual nodes in the simulation.

This function returns a `Dict{String, DataFrame}`, where the keys are the valid nodes, and the value is the flux report for that node, where fluxes are broken down per specific transitions. In case the function issues a warning, its return value will be an empty dictionary.
"""
function nodeFluxReport( mpSim::MPsim, timeGrid::Vector{Float64},
    fluxType::KeyType, nodes::String... )::Dict{String, DataFrame}

    timeGrid = timeGrid[ 0.0 .<= timeGrid .<= now( mpSim ) ]
    timeGrid = unique( sort( timeGrid, rev = true ) )
    result = Dict{String, DataFrame}()
    fluxType = Symbol( fluxType )

    if isempty( timeGrid )
        @warn "No valid time points in time grid, cannot generate report."
        return result
    end  # if isempty( timeGrid )

    if timeGrid[ end ] > 0.0
        push!( timeGrid, 0.0 )
    end  # if timeGrid[ end ] > 0.0

    reverse!( timeGrid )

    if fluxType ∉ fluxTypes
        @warn "Unknown flux type requested, cannot generate report."
        return result
    end  # if fluxType ∉ fluxTypes

    nodes = filter( collect( nodes ) ) do nodeName
        return ( lowercase( nodeName ) ∈ [ "active", "" ] ) ||
            ( fluxType === :within ? false :
                haskey( mpSim.baseNodeList, nodeName ) ) ||
            haskey( mpSim.compoundNodeList, nodeName )
    end  # filter( nodes ) do nodeName

    if isempty( nodes )
        @warn "No valid nodes in node list, cannot generate report."
        return result
    end  # if isempty( nodes )

    nodes = unique( nodes )

    for nodeName in nodes
        result[ nodeName ] = generateNodeFluxReport( mpSim, timeGrid, fluxType,
            nodeName )
    end  # for nodeName in nodes

    return result

end  # nodeFluxReport( mpSim, timeGrid, fluxType, nodes )

"""
```
nodeFluxReport(
    mpSim::MPsim,
    timeRes::Real,
    fluxType::KeyType,
    nodes::String... )
```
This function generates reports for the flux into, out of, or within the valid nodes in `nodes` of the manpower simulation `mpSim`. The reports are generated on a grid of time points with resolution `timeRes`, and the type of report is determined by `fluxType`:
* `:in`: flux into the node;
* `:out`: flux out of the node;
* `:within`: flux within different component nodes of the node. This creates no report for base nodes.

The nodes can be any base node, compound node, or `"active"`, signifying the entire population.

This function will issue a warning and not generate any report in the following three cases:
1. The resolution of the time grid is ⩽ 0;
2. The flux type is unknown;
3. None of the entered nodes are actual nodes in the simulation.

This function returns a `Dict{String, DataFrame}`, where the keys are the valid nodes, and the value is the flux report for that node, where fluxes are broken down per specific transitions. In case the function issues a warning, its return value will be an empty dictionary.
"""
nodeFluxReport( mpSim::MPsim, timeRes::Real, fluxType::Symbol,
    nodes::String... )::Dict{String, DataFrame} = nodeFluxReport( mpSim,
    generateTimeGrid( mpSim, timeRes ), fluxType, nodes... )


include( joinpath( repPrivPath, "nodeflux.jl" ) )