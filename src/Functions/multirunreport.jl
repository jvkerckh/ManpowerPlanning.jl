function Base.getindex( mr::MultirunReport, ii::Int, isRep::Bool=true )
    slice = isRep ? hcat( mr.timeGrid, mr.rawData[:, :, ii] ) :
        transpose(mr.rawData[ii, :, :])
    sliceNames = isRep ? vcat( :timePoint, mr.dataCols ) : mr.dataCols
    DataFrame( slice, sliceNames )
end  # getindex( mr, ii, isRep ) AKA mr[ii, isRep]

function Base.getindex( mr::MultirunReport, dataCol::Symbol )
    ii = findfirst( dataCol .=== mr.dataCols )
    ii isa Nothing && @error string( "Unknown column '", dataCol,
        "' requested in MultirunReport" )
    mr.rawData[:, ii, :]
end  # getindex( mr, dataCol ) AKA mr[dataCol]

Base.getindex( mr::MultirunReport, dataCol::String ) = mr[Symbol(dataCol)]


function StatsBase.mean( mr::MultirunReport )
    statData = mean( mr.rawData, dims=3 )[:,:,1]
    DataFrame( hcat( mr.timeGrid, statData ), vcat( :timePoint, mr.dataCols ) )
end  # mean( mr )

function StatsBase.var( mr::MultirunReport )
    statData = var( mr.rawData, dims=3 )[:,:,1]
    DataFrame( hcat( mr.timeGrid, statData ), vcat( :timePoint, mr.dataCols ) )
end  # var( mr )

function StatsBase.std( mr::MultirunReport )
    statData = std( mr.rawData, dims=3 )[:,:,1]
    DataFrame( hcat( mr.timeGrid, statData ), vcat( :timePoint, mr.dataCols ) )
end  # std( mr )

function StatsBase.median( mr::MultirunReport )
    statData = median( mr.rawData, dims=3 )[:,:,1]
    DataFrame( hcat( mr.timeGrid, statData ), vcat( :timePoint, mr.dataCols ) )
end  # median( mr )

function Base.minimum( mr::MultirunReport )
    statData = minimum( mr.rawData, dims=3 )[:,:,1]
    DataFrame( hcat( mr.timeGrid, statData ), vcat( :timePoint, mr.dataCols ) )
end  # minimum( mr, prob )

function Base.maximum( mr::MultirunReport )
    statData = maximum( mr.rawData, dims=3 )[:,:,1]
    DataFrame( hcat( mr.timeGrid, statData ), vcat( :timePoint, mr.dataCols ) )
end  # maximum( mr, prob )

function StatsBase.quantile( mr::MultirunReport, prob::Real )
    statData = map( eachindex(view( mr.rawData, 1:length(mr.timeGrid),
        1:length(mr.dataCols), 1 )) ) do ii
        quantile( mr.rawData[ii,:], prob )
    end  # map( ... ) do ii
    DataFrame( hcat( mr.timeGrid, statData ), vcat( :timePoint, mr.dataCols ) )
end  # quantile( mr, prob )

function Base.show( io::IO, mr::MultirunReport )
    print( io, "Report for ", size( mr.rawData, 3 ), " runs and ",
        length(mr.timeGrid), " time points." )
    print( io, "\n  Data columns: ", join( mr.dataCols, ", " ) )
end  # show( io, mr )
