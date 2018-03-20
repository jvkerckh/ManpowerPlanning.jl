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


# export isCached
"""
This function tests if the simulation cache `simCache` contains an entry for
the information requested by `cacheType` and time resolution `res`, and returns
`true` or `false` accordingly.

If the user asks for a cacheType which is not one of `:count`, `:fluxIn`,
`:fluxOut`, `:resigned`, or `:retired` the function throws an error.
"""
function isCached( simCache::SimulationCache, res::T, cacheType::Symbol ) where T <: Real

    # If the cache type is wrong, throw an error.
    if cacheType ∉ [ :count, :fluxIn, :fluxOut, :resigned, :retired ]
        error( "Unknown cache entry field." )
    end  # if cacheType ∉ [ :count, :fluxIn, :fluxOut ]

    # If the time resolution is unknown in the cache, it obviously doesn't
    #   exist.
    if !haskey( simCache.cache, res )
        return false
    end  # if !haskey( simCache.cache, res )

    return simCache.cache[ res ][ cacheType ] !== nothing

end  # isCached( simCache::SimulationCache, res::T, cacheType::Symbol )


"""
This function sets the time index of the last entries in each cache of the
simulation cache `simCache` to `maxT` and wipes all the caches that are present.

This function returns `nothing`. If `maxT` is smaller than 0, this function
throws an error, and if it is equal to the current maximum time, nothing
happens and the caches do not get wiped.
"""
function setCacheMaxTime( simCache::SimulationCache, maxT::T ) where T <: Real

    # Test if the proposed max time is valid.
    if maxT < 0
        error( "Maximum cache time must be ⩾ 0." )
    end  # if maxT < 0

    # Do nothing if the proposed time is the same as the existing time.
    if maxT == simCache.lastCacheTime
        return
    end  # if maxT == simCache.lastCacheTime

    simCache.lastCacheTime = maxT
    empty!( simCache )

end  # setCacheMaxTime( simCache, maxT )


# export getCachedResolutions
"""
This function returns a sorted list of all the time resolutions for which the
simulation cache `simCache` has entries.
"""
function getCachedResolutions( simCache::SimulationCache )

    return sort( collect( keys( simCache.cache ) ) )

end


# This function aggregates a count report from one cached time resolution to a
#   coarser time resolution.
export aggregateCountReport
"""
This function tries to create a cache of a record count report for a new time
resolution in the simulation cache `simCache`. In particular, this function
tries to distill the report for time resolution `toRes` from the cache with time
resolution `fromRes`.

If this distillation is successful, the new report is put in the cache, and
`nothing` is returned. If there is no cache with resolution `fromCache`, this
function throws an error. If a cache with resolution `toCache` exists already,
nothing happens.
"""
function aggregateCountReport( simCache::SimulationCache, fromRes::T1,
    toRes::T2 ) where T1 <: Real where T2 <: Real

    # Check if there exists a report with the target time resolution.
    if isCached( simCache, toRes, :count )
        return
    end  # if isCached( simCache, toRes, :count )

    # Check if the source report is cached!
    if !isCached( simCache, fromRes, :count )
        error( "Cannot aggregate. Source report has no cache." )
    end  # if !isCached( simCache, T1, :count )

    # Check if the target time resolution is a positive multiple of the source
    #   resolution.
    if ( toRes <= 0 ) || ( toRes % fromRes != 0 )
        error( "Target time resolution is not a positive multiple of source time resolution." )
    end  # if ( toRes <= 0 ) || ...

    sourceCache = simCache[ fromRes, :count ]
    numCoarse = floor( Int, simCache.lastCacheTime / toRes )
    ratio = floor( Int, toRes / fromRes )
    coarseCache = sourceCache[ 1 + ratio * ( 0:numCoarse ) ]

    if numCoarse * toRes < simCache.lastCacheTime
        push!( coarseCache, sourceCache[ end ] )
    end  # if numCoarse * toRes < simCache.lastCacheTime

    addToCache( simCache, toRes, :count, cache )

end  # aggregateCountReport( simCache, fromRes, toRes )


#=
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
=#


function addToCache( simCache::SimulationCache, res::T, cacheType::Symbol,
    cache::Vector{Int} ) where T <: Real

    # If the cache type is wrong, throw an error.
    if cacheType ∉ [ :count, :fluxIn, :fluxOut, :resigned, :retired ]
        error( "Unknown cache entry field." )
    end  # if cacheType ∉ [ :count, :fluxIn, :fluxOut, :resigned, :retired ]

    # If the resolution is non-positive, do nothing.
    if res <= 0.0
        return
    end  # if res <= 0.0

    # Next, check if the cache has the correct number of elements in it.
    numCache = floor( Int, simCache.lastCacheTime / res )

    if length( cache ) != numCache +
        ( numCache * res == simCache.lastCacheTime ? 0 : 1 ) +
        ( cacheType === :count ? 1 : 0 )
        error( "Cache does not have the correct number of elements." )
    end  # if length( cache ) != numCache + ...

    # Add an entry for the resolution if the cache doesn't have it yet.
    if !haskey( simCache.cache, res )
        simCache.cache[ res ] = CacheEntry( res )
    end  # if !haskey( simCache.cache, res )

    setCache( simCache.cache[ res ], cacheType, cache )

end  # addToCache( simCache, res, cacheType, cache )


# This function clears the cache.
function Base.empty!( simCache::SimulationCache )

    empty!( simCache.cache )

end  # Base.empty!( simCache )


# This function returns the requested cache at the specified time resolution.
# If the requested cache has not been created yet, it will return nothing.
# If the wrong type of information is requested, it will throw an error.
# Accepted types are :count, :fluxIn, :fluxOut, :resigned, :retired.
function Base.getindex( simCache::SimulationCache, res::T, cacheType::Symbol ) where T <: Real

    return haskey( simCache.cache, res ) ? simCache.cache[ res ][ cacheType ] :
        nothing

end  # Base.getIndex( entry, res, cacheType )

#=
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
=#
