"""
```
filterProperNodes( distNodes::Dict{T, Float64} ) where T <: Union{Int, Float64}
```
This function filters the bad nodes from the list of distribution nodes in `distNodes`. A bad node is a node with a negative node value or a negative weight.

The function returns a `Dict{T, Float64}`, the filtered list of distribution nodes.
"""
function filterProperNodes( distNodes::Dict{T,Float64} ) where T <: Union{Int, Float64}

    tmpNodes = deepcopy( distNodes )

    for node in keys( distNodes )
        if ( node < 0 ) || ( distNodes[node] < 0 )
            delete!( tmpNodes, node )
        end  # if ( node < 0 ) || ...
    end  # for node in keys( distNodes )

    return tmpNodes

end  # filterProperNodes( distNodes )


function setRecDist!( recruitment::Recruitment, distType::Symbol,
    distNodes::Dict{T,Float64} ) where T <: Union{Int, Float64}

    # Check if the distribution type is known.
    if !haskey( recruitmentDists, distType )
        @warn "Unknown distribution type, not making any changes."
        return false
    end  # if !haskey( recruitmentDists, distType )

    tmpDistNodes = filterProperNodes( distNodes )
    tmpNodes = sort( collect( keys( tmpDistNodes ) ) )

    # Check if there are sufficient nodes.
    if length( tmpNodes ) < recruitmentDists[distType][2]
        @warn "Not enough proper distribution nodes, not making any changes."
        return false
    end  # if length( tmpNodes ) < recruitmentDists[distType][2]
    
    # Check if the total probability mass is non-zero.
    pMass = sum( map( node -> tmpDistNodes[node], tmpNodes ) )

    if ( pMass == 0.0 ) || ( ( distType === :pUnif ) &&
        ( distNodes[tmpNodes[end]] == pMass ) )
        @warn "Proposed distribution has 0 probability mass, not making any changes."
        return false
    end  # if ( pMass == 0.0 ) || ...

    if T === Int
        recDist = recruitmentDists[distType][3]
        recruitment.isAdaptive = false
        recruitment.recruitmentDistType = distType
        recruitment.recruitmentDistNodes = tmpDistNodes
        recruitment.recruitmentDist = recDist( recruitment, tmpDistNodes,
            tmpNodes )
    else
        ageDist = recruitmentDists[distType][4]
        recruitment.ageDistType = distType
        recruitment.ageDistNodes = tmpDistNodes
        recruitment.ageDist = ageDist( recruitment, tmpDistNodes, tmpNodes )
    end  # if T === Int

    return true
    
end  # setRecDist!( recruitment, distType, distNodes )


function recDiscDist( recruitment::Recruitment, distNodes::Dict{Int,Float64},
    nodes::Vector{Int} )

    # No need to involve a distribution if there's only one node.
    if length( nodes ) == 1
        return function() return nodes[1] end
    end  # if length( nodes ) == 1

    # Get the point probabilities of the nodes.
    pNodes = map( node -> distNodes[node], nodes )
    pNodes /= sum( pNodes )

    return function()
        return nodes[rand( recruitment.recRNG, Categorical( pNodes ) )]
    end  # anonymous function()

end  # recDiscDist( recruitment, distNodes, nodes )


function recPUnifDist( recruitment::Recruitment, distNodes::Dict{Int,Float64},
    nodes::Vector{Int} )

    if length( nodes ) == 2
        intLength = nodes[2] - nodes[1]

        return function()
            return intLength == 1 ? nodes[1] :
                rand( recruitment.recRNG, nodes[1]:( nodes[2] - 1 ) )
        end  # anonymous function()
    end  # if length( nodes ) == 2

    # Get the point probabilities of the intervals.
    pInts = map( node -> distNodes[node], nodes[1:(end-1)] )
    pInts /= sum( pInts )

    return function()
        intInd = rand( recruitment.recRNG, Categorical( pInts ) )
        intLength = nodes[intInd + 1] - nodes[intInd]
        return intLength == 1 ? nodes[intInd] :
            rand( recruitment.recRNG, nodes[intInd]:( nodes[intInd + 1] - 1 ) )
    end  # anonymous function()

end  # recPUnifDist( recruitment, distNodes, nodes )


function recPLinDist( recruitment::Recruitment, distNodes::Dict{Int,Float64},
    nodes::Vector{Int} )

    # Get the point probabilities of the intervals.
    pointWeights = map( node -> distNodes[node], nodes )
    nodeDiffs = nodes[2:end] .- nodes[1:(end-1)] .- 1
    bracketWeights = map( eachindex( nodeDiffs ) ) do ii
        return pointWeights[ii] + nodeDiffs[ii] * ( pointWeights[ii] + pointWeights[ii + 1] ) / 2
    end  # map( eachindex( nodeDiffs ) ) do ii
    push!( bracketWeights, pointWeights[end] )
    bracketProbs = bracketWeights / sum( bracketWeights )

    return function()
        intInd = rand( recruitment.recRNG, Categorical( bracketProbs ) )

        if intInd == length( bracketProbs )
            return nodes[end]
        end  # if intInd == length( bracketProbs )

        posProbs = ( pointWeights[intInd + 1] - pointWeights[intInd] ) /
            ( nodeDiffs[intInd] + 1 )
        posProbs *= collect( 0:nodeDiffs[intInd] )
        posProbs = posProbs .+ pointWeights[intInd]
        posProbs /= bracketWeights[intInd]
        return nodes[intInd] + rand( recruitment.recRNG,
            Categorical( posProbs ) ) - 1
    end  # anonymous function()

end  # recPLinDist( recruitment, distNodes, nodes )


function ageDiscDist( recruitment::Recruitment,
    distNodes::Dict{Float64,Float64}, nodes::Vector{Float64} )

    # No need to involve a distribution if there's only one node.
    if length( nodes ) == 1
        return function( n::Integer ) return fill( nodes[1], n ) end
    end  # if length( nodes ) == 1

    # Get the point probabilities of the nodes.
    pNodes = map( node -> distNodes[node], nodes )
    pNodes /= sum( pNodes )

    return function( n::Integer )
        return nodes[rand( recruitment.ageRNG, Categorical( pNodes ), n )]
    end  # anonymous function( n )

end  # ageDiscDist( recruitment, distNodes, nodes )


function agePUnifDist( recruitment::Recruitment,
    distNodes::Dict{Float64,Float64}, nodes::Vector{Float64} )

    if length( nodes ) == 2
        intLength = nodes[2] - nodes[1]

        return function( n::Integer )
            return rand( recruitment.ageRNG, n ) * intLength .+ nodes[1]
        end  # anonymous function( n )
    end  # if length( nodes ) == 2

    # Get the point probabilities of the intervals.
    pInts = map( node -> distNodes[node], nodes[1:(end-1)] )
    pInts /= sum( pInts )

    return function( n::Integer )
        intInds = rand( recruitment.ageRNG, Categorical( pInts ), n )
        intLengths = nodes[intInds .+ 1] - nodes[intInds]
        return rand( recruitment.ageRNG, n ) .* intLengths + nodes[intInds]
    end  # anonymous function( n )

end  # agePUnifDist( recruitment, distNodes, nodes )


function agePLinDist( recruitment::Recruitment,
    distNodes::Dict{Float64,Float64}, nodes::Vector{Float64} )

    # Get the probabilities of each interval.
    pointWeights = map( node -> distNodes[node], nodes )
    bracketWeights = ( nodes[2:end] - nodes[1:(end - 1)] ) .*
        ( pointWeights[1:(end - 1)] + pointWeights[2:end] ) / 2
    bracketProbs = bracketWeights / sum( bracketWeights )

    return function( n::Integer )
        intInds = rand( recruitment.ageRNG, Categorical( bracketProbs ), n )
        isDiffWeights = pointWeights[intInds .+ 1] .!= pointWeights[intInds]
        diffInds = intInds[isDiffWeights]
        diffIndsP = diffInds .+ 1
        sameInds = intInds[.!isDiffWeights]
        result = rand( recruitment.ageRNG, n )

        # First, add the entries with equal weights in both endpoints of the
        #   containing interval.
        result[.!isDiffWeights] = nodes[sameInds] +
            result[.!isDiffWeights] .*
            ( nodes[sameInds .+ 1] - nodes[sameInds] )

        # Then, do the same for the other entries.
        a = ( pointWeights[diffIndsP] - pointWeights[diffInds] ) / 2
        b = pointWeights[diffInds] .* nodes[diffIndsP] -
            pointWeights[diffIndsP] .* nodes[diffInds]
        c = ( pointWeights[diffInds] + pointWeights[diffIndsP] ) .*
            nodes[diffInds].^2 / 2 - pointWeights[diffInds] .*
            nodes[diffInds] .* nodes[diffIndsP] -
            bracketWeights[diffInds] .* result[isDiffWeights] .*
            ( nodes[diffIndsP] - nodes[diffInds] )
        d = b.^2 - 4 * a .* c
        result[isDiffWeights] = ( sqrt.( d ) - b ) ./ ( 2 * a )

        return result
    end  # anonymous function( n )

end  # agePLinDist( recruitment, distNodes, nodes )


const recruitmentDists = Dict(
    :disc => ("discrete", 1, recDiscDist, ageDiscDist),
    :pUnif => ("piecewise uniform", 2, recPUnifDist, agePUnifDist),
    :pLin => ("piecewise linear", 2, recPLinDist, agePLinDist) )