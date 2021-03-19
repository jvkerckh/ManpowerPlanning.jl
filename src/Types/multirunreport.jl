export MultirunReport
mutable struct MultirunReport
    rawData::Array{Real,3}
    timeGrid::Vector{Float64}
    dataCols::Vector{Symbol}

    MultirunReport() = new( zeros( Real, 0, 0, 0 ), Vector{Float64}(),
        Vector{Symbol}() )

    MultirunReport( rawData::Array{T,3}, timeGrid::Vector{Float64},
        dataCols::Vector{Symbol} ) where T <: Real =
        new( deepcopy(rawData), deepcopy(timeGrid), deepcopy(dataCols) )

    MultirunReport( rawData::Array{T,3}, timeGrid::Vector{Float64},
        dataCols::Vector{String} ) where T <: Real =
        MultirunReport( rawData, timeGrid, Symbol.(dataCols) )
end  # mutable struct MultirunReport
