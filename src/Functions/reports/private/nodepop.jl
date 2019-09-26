function createPopReport( nodes::Vector{String}, timeGrid::Vector{Float64}, inFluxes::Dict{String, DataFrame}, outFluxes::Dict{String, DataFrame} )

    result = zeros( Int, length( timeGrid ), length( nodes ) )

    for ii in eachindex( nodes )
        nodeName = nodes[ ii ]
        tmpResult = inFluxes[ nodeName ][ 3 ]
        tmpResult -= outFluxes[ nodeName ][ 3 ]
        result[ :, ii ] = cumsum( tmpResult )
    end  # for ii in eachindex( nodes )

    return DataFrame( hcat( timeGrid, result ), vcat( :timePoint,
        Symbol.( nodes ) ) )

end  # createPopReport( nodes, timeGrid, inFluxes, outFluxes )