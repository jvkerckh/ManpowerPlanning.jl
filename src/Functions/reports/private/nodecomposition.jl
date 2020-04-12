function generateBaseNodeList( mpSim::MPsim, nodes::Vector{String} )

    isBaseNode = haskey.( Ref( mpSim.baseNodeList ), nodes )
    nodeList = nodes[isBaseNode]

    for node in nodes[.!isBaseNode]
        append!( nodeList, mpSim.compoundNodeList[node].baseNodeList )
    end  # for node in nodes[.!isBaseNode]

    return unique( nodeList )

end  # generateBaseNodeList( mpSim, nodes )


function generateCompositionReport( node::CompoundNode,
    baseNodeReport::DataFrame )

    result = baseNodeReport[:, vcat( :timePoint,
        Symbol.( node.baseNodeList ) )]
    nRows = size( result, 1 )
    counts = zeros( Int, nRows )

    for baseNode in node.baseNodeList
        counts += result[:, Symbol( baseNode )]
    end  # for baseNode in node.baseNodeList

    insertcols!( result, 2, Symbol( node.name ) => counts )

    return result

end  # generateCompositionReport( node, baseNodeReport )