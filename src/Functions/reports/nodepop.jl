export  nodePopReport,
        nodeEvolutionReport


"""
```
nodePopReport(
    mpSim::MPsim,
    timeGrid::Vector{Float64},
    nodes::String... )
```
This function generates reports for the evolution of the population of the valid nodes in `nodes` of the manpower simulation `mpSim`. The reports are generated on the grid of time points `timeGrid`.

The nodes can be any base node, compound node, or `"active"`, signifying the entire population.

This function will issue a warning and not generate any report in the following two cases:
1. There are no positive time points in the time grid;
2. None of the entered nodes are actual nodes in the simulation.

This function returns a `DataFrame`, with the first column the time points and the other columns corresponding to the population counts at each time point for each node. In case the function issues a warning, its return value will be an empty `DataFrame`.
"""
function nodePopReport( mpSim::MPsim, timeGrid::Vector{Float64},
    nodes::String... )::DataFrame

    result = DataFrame()

    if now( mpSim ) == 0
        @warn "Simulation hasn't started yet, can't make report."
        return result
    end  # if now( mpSim ) == 0

    timeGrid = cleanTimegrid( timeGrid, mpSim )

    if isempty( timeGrid )
        @warn "No valid time points in time grid, cannot generate report."
        return result
    end  # if isempty( timeGrid )

    nodes = filter( collect( nodes ) ) do nodeName
        return ( lowercase( nodeName ) ∈ ["active", ""] ) ||
            haskey( mpSim.baseNodeList, nodeName ) ||
            haskey( mpSim.compoundNodeList, nodeName )
    end  # filter( nodes ) do nodeName

    if isempty( nodes )
        @warn "No valid nodes in node list, cannot generate report."
        return result
    end  # if isempty( nodes )

    # Create reports.
    inFluxes = nodeFluxReport( mpSim, timeGrid, :in, nodes... )
    outFluxes = nodeFluxReport( mpSim, timeGrid, :out, nodes... )
    return createPopReport( nodes, timeGrid, inFluxes, outFluxes )

end  # nodePopReport( mpSim, timeGrid, nodes )

"""
```
nodePopReport(
    mpSim::MPsim,
    timeRes::Real,
    nodes::String... )
```
This function generates reports for the evolution of the population of the valid nodes in `nodes` of the manpower simulation `mpSim`. The reports are generated on a grid of time points with resolution `timeRes`.

The nodes can be any base node, compound node, or `"active"`, signifying the entire population.

This function will issue a warning and not generate any report in the following two cases:
1. The resolution of the time grid is ⩽ 0;
2. None of the entered nodes are actual nodes in the simulation.

This function returns a `DataFrame`, with the first column the time points and the other columns corresponding to the population counts at each time point for each node. In case the function issues a warning, its return value will be an empty `DataFrame`.
"""
nodePopReport( mpSim::MPsim, timeRes::Real, nodes::String... ) =
    nodePopReport( mpSim, generateTimeGrid( mpSim, timeRes ), nodes... )

function nodePopReport( mrs::MRS, timeGrid::Vector{Float64}, nodes::String... )
    result = MultirunReport()
    mpSim = mrs.mpSim

    if now(mpSim) == 0
        @warn "Simulation hasn't started yet, can't make report."
        return result
    end  # if now(mpSim) == 0

    timeGrid = cleanTimegrid( timeGrid, mpSim )

    if isempty( timeGrid )
        @warn "No valid time points in time grid, cannot generate report."
        return result
    end  # if isempty( timeGrid )

    nodes = cleanNodes( nodes, mpSim )

    if isempty( nodes )
        @warn "No valid nodes in node list, cannot generate report."
        return result
    end  # if isempty( nodes )

    # Get raw data.
    setSimulationDatabase!( mpSim, mrs.resultsDB.file )
    rawData = zeros( Real, length(timeGrid), length(nodes), mrs.nRuns )
    nThreads = min( mrs.nRuns, mrs.maxThreads, Threads.nthreads() )
    reportError = falses(mrs.nRuns)
    currentRun = Channel{Int}(1)
    put!( currentRun, 1 )

    Threads.@threads for threadnum in 1:nThreads  # To change
        generateRunReport( mpSim, timeGrid, collect(nodes), rawData,
            reportError, currentRun )
        # inFluxes = nodeFluxReport( mpSim, timeGrid, :in, nodes...; simRun=ii )
        # outFluxes = nodeFluxReport( mpSim, timeGrid, :out, nodes...; simRun=ii )
        # popReport = Array(createPopReport( nodes, timeGrid, inFluxes,
        #     outFluxes ))[:, 2:end]
        # rawData[:, :, ii] = popReport
    end  # for ii in 1:1

    for ii in findall(reportError)
        generateRunreport( mpSim, timeGrid, nodes, rawData, ii )
    end  # for ii in findall(reportError)

    setSimulationDatabase!( mpSim, "" )
    MultirunReport( rawData, timeGrid, nodes )
end  # nodePopReport( mrs, timeGrid, nodes )

nodePopReport( mrs::MRS, timeRes::Real, nodes::String... ) =
    nodePopReport( mrs, generateTimeGrid( mrs.mpSim, timeRes ), nodes... ) 


"""
```
nodeEvolutionReport(
    mpSim::MPsim,
    timeGrid::Vector{Float64},
    nodes::String... )
```
This function generates reports for the evolution of the population of the valid nodes in `nodes` of the manpower simulation `mpSim`, as well as the in and out fluxes into those nodes. The reports are generated on the grid of time points `timeGrid`.

The nodes can be any base node, compound node, or `"active"`, signifying the entire population.

This function will issue a warning and not generate any report in the following two cases:
1. There are no positive time points in the time grid;
2. None of the entered nodes are actual nodes in the simulation.

This function returns a `Tuple` consisting of a `DataFrame` and a dictionary. the `DataFrame`is the population report for all the valid nodes, and the dictionary is a `Dict{String,Tuple}`. The keys of the dictionary are the names of the nodes, and the corresponding value is the report on the in and out fluxes for the node if the node is a base node. If the report is a compound node, it also adds a report on the transitions within the compound node, and a composition report. In case the function issues a warning, its return value will be a `Tuple` with empty objects of the correct type.
"""
function nodeEvolutionReport( mpSim::MPsim, timeGrid::Vector{Float64},
    nodes::String... )::Tuple{DataFrame, Dict{String,Tuple}}

    timeGrid = timeGrid[0.0 .<= timeGrid .<= now( mpSim )]
    timeGrid = unique( sort( timeGrid, rev = true ) )
    fluxReport = Dict{String,Tuple}()

    if isempty( timeGrid )
        @warn "No valid time points in time grid, cannot generate report."
        return (DataFrame(), fluxReport)
    end  # if isempty( timeGrid )

    if timeGrid[end] > 0.0
        push!( timeGrid, 0.0 )
    end  # if timeGrid[end] > 0.0

    reverse!( timeGrid )

    nodes = filter( collect( nodes ) ) do nodeName
        return ( lowercase( nodeName ) == "active" ) ||
            haskey( mpSim.baseNodeList, nodeName ) ||
            haskey( mpSim.compoundNodeList, nodeName )
    end  # filter( nodes ) do nodeName

    if isempty( nodes )
        @warn "No valid nodes in node list, cannot generate report."
        return (DataFrame(), fluxReport)
    end  # if isempty( nodes )

    nodes = unique( nodes )
    compoundNodes = filter( node -> haskey( mpSim.compoundNodeList, node ),
        nodes )

    # Create reports.
    inFluxes = nodeFluxReport( mpSim, timeGrid, :in, nodes... )
    outFluxes = nodeFluxReport( mpSim, timeGrid, :out, nodes... )
    popReport = createPopReport( nodes, timeGrid, inFluxes, outFluxes )

    withinFluxes = nothing
    compReport = nothing

    if !isempty( compoundNodes )
        withinFluxes = nodeFluxReport( mpSim, timeGrid, :within,
            compoundNodes... )
        compReport = nodeCompositionReport( mpSim, timeGrid, compoundNodes... )
    end  # if !isempty( compoundNodes )

    for node in nodes
        if haskey( mpSim.compoundNodeList, node )
            fluxReport[node] = (inFluxes[node], outFluxes[node],
                withinFluxes[node], compReport[node])
        else
            fluxReport[node] = (inFluxes[node], outFluxes[node])
        end  # if haskey( mpSim.compoundNodeList, node )
    end  # for node in nodes

    return (popReport, fluxReport)
    
end  # nodeEvolutionReport( mpSim, timeRes, nodes )

"""
```
nodeEvolutionReport(
    mpSim::MPsim,
    timeRes::Real,
    nodes::String... )
```
This function generates reports for the evolution of the population of the valid nodes in `nodes` of the manpower simulation `mpSim`, as well as the in and out fluxes into those nodes. The reports are generated on a grid of time points with resolution `timeRes`.

The nodes can be any base node, compound node, or `"active"`, signifying the entire population.

This function will issue a warning and not generate any report in the following two cases:
1. The resolution of the time grid is ⩽ 0;
2. None of the entered nodes are actual nodes in the simulation.

This function returns a `Tuple` consisting of a `DataFrame` and a dictionary. the `DataFrame`is the population report for all the valid nodes, and the dictionary is a `Dict{String,NTuple{2,DataFrame}}`. The keys of the dictionary are the names of the nodes, and the corresponding value is the report on the in and out fluxes for the node. In case the function issues a warning, its return value will be a `Tuple` with empty objects of the correct type.
"""
nodeEvolutionReport( mpSim::MPsim, timeRes::Real, nodes::String... ) =
    nodeEvolutionReport( mpSim, generateTimeGrid( mpSim, timeRes ), nodes... )


include( joinpath( repPrivPath, "nodepop.jl" ) )