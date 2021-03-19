function cleanTimegrid( timeGrid::Vector{Float64}, mpSim::MPsim )
    timeGrid = timeGrid[0.0 .<= timeGrid .<= now(mpSim)]
    isempty(timeGrid) && return timeGrid

    timeGrid = unique(sort( timeGrid, rev=true ))
    timeGrid[end] > 0.0 && push!( timeGrid, 0.0 )
    reverse!(timeGrid)
end  # cleanTimegrid( timeGrid, mpSim )


function cleanNodes( nodes::Tuple, mpSim::MPsim )
    nodes = filter(collect(nodes)) do nodeName
        return ( lowercase(nodeName) ∈ ["active", ""] ) ||
            haskey( mpSim.baseNodeList, nodeName ) ||
            haskey( mpSim.compoundNodeList, nodeName )
    end  # filter(nodes) do nodeName

    isempty(nodes) && return nodes
    nodes[lowercase.(nodes) .== "active"] .= "active"
    nodes[nodes .== ""] .= "active"
    unique(nodes)
end  # cleanNodes( nodes, mpSim )


function createPopReport( nodes::Vector{String}, timeGrid::Vector{Float64},
    inFluxes::Dict{String,DataFrame}, outFluxes::Dict{String,DataFrame} )

    result = zeros( Int, length( timeGrid ), length( nodes ) )

    for ii in eachindex( nodes )
        nodeName = nodes[ii]
        tmpResult = inFluxes[nodeName][:, 3]
        tmpResult -= outFluxes[nodeName][:, 3]
        result[:, ii] = cumsum( tmpResult )
    end  # for ii in eachindex( nodes )

    return DataFrame( hcat( timeGrid, result ), vcat( :timePoint,
        Symbol.( nodes ) ) )

end  # createPopReport( nodes, timeGrid, inFluxes, outFluxes )


function generateRunReport( mpSim::MPsim, timeGrid::Vector{Float64},
    nodes::Vector{String}, rawData::Array{Real,3}, reportError::BitArray{1},
    currentRun::Channel{Int} )
    while (ii = take!(currentRun)) <= size( rawData, 3 )
        put!( currentRun, ii + 1 )

        try
            generateRunreport( mpSim, timeGrid, nodes, rawData, ii )
        catch
            reportError[ii] = true
        end
    end  # while (ii = take!(currentRun)) <= size( rawData, 3 )

    put!( currentRun, ii )
end  # generateRunReport( mpSim, timeGrid, nodes, rawData, reportError, 
     #   currentRun )

function generateRunreport( mpSim::MPsim, timeGrid::Vector{Float64},
    nodes::Vector{String}, rawData::Array{Real,3}, runNr::Int )
    inFluxes = nodeFluxReport( mpSim, timeGrid, :in, nodes...; simRun=runNr )
    outFluxes = nodeFluxReport( mpSim, timeGrid, :out, nodes...; simRun=runNr )
    popReport = Array(createPopReport( nodes, timeGrid, inFluxes,
        outFluxes ))[:, 2:end]
    rawData[:, :, runNr] = popReport
end  # generateRunreport( mpSim, timeGrid, nodes, rawData, runNr )