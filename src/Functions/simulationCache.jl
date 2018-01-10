# This file holds the definition of the functions pertaining to the
#   SimulationCache type.

# The functions of the SimulationCache type require the CacheEntry type.
requiredTypes = [ "cacheEntry", "simulationCache" ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( dirname( Base.source_path() ), "..", "Types",
            reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end  # for reqType in requiredTypes


# This function tests if the requested cache exists.
# If the wrong type of information is requested, it will throw an error.
# Accepted types are :count, :fluxIn, :fluxOut.
export isCached
function isCached( simCache::SimulationCache, res::T, cacheType::Symbol ) where T <: Real
    # If the cache type is wrong, throw an error.
    if cacheType ∉ [ :count, :fluxIn, :fluxOut ]
        error( "Unknown cache entry field." )
    end  # if cacheType ∉ [ :count, :fluxIn, :fluxOut ]

    # If the time resolution is unknown in the cache, it obviously doesn't
    #   exist.
    if !haskey( simCache.cache, res )
        return false
    end  # if !haskey( simCache.cache, res )

    return simCache.cache[ res ][ cacheType ] !== nothing
end  # isCached( simCache::SimulationCache, res::T, cacheType::Symbol )


# This function returns the list of cached time resolutions.
export getCachedResolutions
function getCachedResolutions( simCache::SimulationCache )
    return collect( keys( simCache.cache ) )
end


# This function aggregates a count report from one cached time resolution to a
#   coarser time resolution.
export aggregateCountReport
function aggregateCountReport( simCache::SimulationCache, fromRes::T1,
    toRes::T2 ) where T1 <: Real where T2 <: Real

    # Check if the source report is cached!
    if !isCached( simCache, fromRes, :count )
        error( "Cannot aggregate. Source report has no cache." )
    end  # if !isCached( simCache, T1, :count )

    sourceCache = simCache[ fromRes, :count ]
    ratio = Int( floor( toRes / fromRes ) )
    simCache[ toRes, :count ] = sourceCache[ 1:ratio:length( sourceCache ) ]
end  # aggregateCountReport( simCache, fromRes, toRes )


# This function aggregates a flux report from one cached time resolution to a
#   coarser time resolution.
export aggregateFluxReport
function aggregateFluxReport( simCache::SimulationCache, fromRes::T1,
    toRes::T2, isIn::Bool = true ) where T1 <: Real where T2 <: Real

    fluxType = isIn ? :fluxIn : :fluxOut

    # Check if the source report is cached!
    if !isCached( simCache, fromRes, fluxType )
        error( "Cannot aggregate. Source report has no cache." )
    end  # if !isCached( simCache, T1, :count )

    sourceCache = simCache[ fromRes, fluxType ]
    ratio = Int( floor( toRes / fromRes ) )
    targetSize = Int( floor( length( sourceCache ) / ratio ) )
    targetCache = map( ii -> sum( sourceCache[ ratio * (ii - 1) + (1:ratio) ] ),
        1:targetSize )

    # Final aggregation if necessary.
    if length( sourceCache ) % ratio != 0
        push!( targetCache, sum( sourceCache[ (ratio * targetSize + 1):end ] ) )
    end  # if length( sourceCache ) % ratio != 0

    simCache[ toRes, fluxType ] = targetCache
end  # aggregateFluxReport( simCache, fromRes, toRes, isIn = true )

# This function clears the cache.
function Base.empty!( simCache::SimulationCache )
    empty!( simCache.cache )
end  # Base.empty!( simCache )


# This function returns the requested cache at the specified time resolution.
# If the requested cache has not been created yet, it will return nothing.
# If the wrong type of information is requested, it will throw an error.
# Accepted types are :count, :fluxIn, :fluxOut.
function Base.getindex( simCache::SimulationCache, res::T, cacheType::Symbol ) where T <: Real
    if cacheType ∉ [ :count, :fluxIn, :fluxOut ]
        error( "Unknown cache entry field." )
    end  # if infoType ∉ [ :count, :fluxIn, :fluxOut ]

    return haskey( simCache.cache, res ) ? simCache.cache[ res ][ cacheType ] :
        nothing
end  # Base.getIndex( entry, res, cacheType )


# This function sets the specified cache at the given time resolution.
# If the wrong type of information is requested, it will throw an error.
# Accepted types are :count, :fluxIn, :fluxOut.
function Base.setindex!( simCache::SimulationCache, cache::Vector{Int}, res::T,
    cacheType::Symbol ) where T <: Real

    # If the cache type is wrong, throw an error.
    if cacheType ∉ [ :count, :fluxIn, :fluxOut ]
        error( "Unknown cache entry field." )
    end  # if cacheType ∉ [ :count, :fluxIn, :fluxOut ]

    # If the resolution is non-positive, do nothing.
    if res <= 0.0
        return
    end  # if res <= 0.0

    # If there is no cache yet for this time resolution, create an empty cache.
    if !haskey( simCache.cache, res )
        simCache.cache[ res ] = CacheEntry( res )
    end  # if !haskey( simCache.cache, res )

    simCache.cache[ res ][ cacheType ] = cache
end  # Base.setindex!( simCache, cache, res, cacheType )
