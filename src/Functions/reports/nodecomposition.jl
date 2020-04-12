export  nodeCompositionReport


"""
```
nodeCompositionReport(
    mpSim::MPsim,
    timeGrid::Vector{Float64},
    nodes::String... )
```
This function generates a report on the composition of the nodes in `nodes` of the manpower simulation `mpSim`. The reports are generated on the grid of time points `timeGrid`, and the nodes can be any base or compound node.

This function will issue a warning and not generate any report in the following two cases:
1. There are no positive time points in the time grid;
2. None of the entered nodes are actual nodes in the simulation.

This function returns a `Dict{String, DataFrame}`, where the keys are the valid nodes, and the value is the composition report for that node. The base nodes are bundled in a single report with name `"Base nodes"`. In case the function issues a warning, its return value will be an empty dictionary.
"""
function nodeCompositionReport( mpSim::MPsim, timeGrid::Vector{Float64},
    nodes::String... )::Dict{String,DataFrame}

    timeGrid = timeGrid[0.0 .<= timeGrid .<= now( mpSim )]
    timeGrid = unique( sort( timeGrid, rev = true ) )
    result = Dict{String,DataFrame}()

    if isempty( timeGrid )
        @warn "No valid time points in time grid, cannot generate report."
        return result
    end  # if isempty( timeGrid )

    if timeGrid[end] > 0.0
        push!( timeGrid, 0.0 )
    end  # if timeGrid[end] > 0.0

    reverse!( timeGrid )

    nodes = filter( collect( nodes ) ) do nodeName
        return haskey( mpSim.baseNodeList, nodeName ) ||
            haskey( mpSim.compoundNodeList, nodeName )
    end  # filter( nodes ) do nodeName

    if isempty( nodes )
        @warn "No valid nodes in node list, cannot generate report."
        return result
    end  # if isempty( nodes )

    nodes = unique( nodes )

    # Get a population report on all the base nodes and component base nodes of
    #   the compound nodes.
    baseNodes = generateBaseNodeList( mpSim, nodes )
    baseNodeReport = nodePopReport( mpSim, timeGrid, baseNodes... )

    # Split off the report for the base nodes in the original list.
    isBaseNode = haskey.( Ref( mpSim.baseNodeList ), nodes )
    
    if any( isBaseNode )
        baseNodeList = nodes[isBaseNode]
        result["Base nodes"] = baseNodeReport[:, vcat( :timePoint,
            Symbol.( baseNodeList ) )]
    end  # if any( isBaseNode )

    # Generate the report for the compound nodes.
    for node in nodes[.!isBaseNode]
        result[node] = generateCompositionReport(
            mpSim.compoundNodeList[node], baseNodeReport )
    end  # for node in nodes[.!isBaseNode]

    return result

end  # nodeCompositionReport( mpSim, timeGrid, nodes )

"""
```
nodeCompositionReport(
    mpSim::MPsim,
    timeRes::Real,
    nodes::String... )
```
This function generates a report on the composition of the nodes in `nodes` of the manpower simulation `mpSim`. The reports are generated on a grid of time points with resolution `timeRes`, and the nodes can be any base or compound node.

This function will issue a warning and not generate any report in the following two cases:
1. The resolution of the time grid is ⩽ 0;
2. None of the entered nodes are actual nodes in the simulation.

This function returns a `Dict{String, DataFrame}`, where the keys are the valid nodes, and the value is the composition report for that node. The base nodes are bundled in a single report with name `"Base nodes"`. In case the function issues a warning, its return value will be an empty dictionary.
"""
nodeCompositionReport( mpSim::MPsim, timeRes::Real, nodes::String... ) =
    nodeCompositionReport( mpSim, generateTimeGrid( mpSim, timeRes ), nodes... )


include( joinpath( repPrivPath, "nodecomposition.jl" ) )