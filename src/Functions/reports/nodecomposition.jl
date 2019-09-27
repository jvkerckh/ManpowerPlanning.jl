export  nodeCompositionReport


function nodeCompositionReport( mpSim::MPsim, timeGrid::Vector{Float64}, nodes::String... )::Dict{String, DataFrame}

    timeGrid = timeGrid[ 0.0 .<= timeGrid .<= now( mpSim ) ]
    timeGrid = unique( sort( timeGrid, rev = true ) )
    result = Dict{String, DataFrame}()

    if isempty( timeGrid )
        @warn "No valid time points in time grid, cannot generate report."
        return result
    end  # if isempty( timeGrid )

    if timeGrid[ end ] > 0.0
        push!( timeGrid, 0.0 )
    end  # if timeGrid[ end ] > 0.0

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
        baseNodeList = nodes[ isBaseNode ]
        result[ "Base nodes" ] = baseNodeReport[ :, vcat( :timePoint,
            Symbol.( baseNodeList ) ) ]
    end  # if any( isBaseNode )

    # Generate the report for the compound nodes.
    for node in nodes[ .!isBaseNode ]
        result[ node ] = generateCompositionReport(
            mpSim.compoundNodeList[ node ], baseNodeReport )
    end  # for node in nodes[ .!isBaseNode ]

    return result

end  # nodeCompositionReport( mpSim, timeGrid, nodes )

nodeCompositionReport( mpSim::MPsim, timeRes::Real, nodes::String... ) =
    nodeCompositionReport( mpSim, generateTimeGrid( mpSim, timeRes ), nodes... )


include( joinpath( repPrivPath, "nodecomposition.jl" ) )