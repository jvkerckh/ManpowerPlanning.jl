# This file defines the SimulationCache type. This type holds the cache of all
#   the simulation reports created for a particular simulation.

# The SimulationCache type requires the CacheEntry type.
requiredTypes = [ "cacheEntry" ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( dirname( Base.source_path() ), reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end  # for reqType in requiredTypes


export SimulationCache
"""
This type defines a cache of processed results for a `ManpowerSimulation`. This
cache will always contain results relevant to the last run simulation, and if
the run was a partial run, up to the point where the run stopped.

The type contains one field:
* 'cache::Dict{Float64', CacheEntry}': The list of available entries in the
cache of results. For each entry, the `Float64` key is the time resolution of
the cache entry, and the `cacheEntry` object is the actual processed result for
that particular time resolution.
"""
type SimulationCache
    # The simulation cache.
    cache::Dict{Float64, CacheEntry}

    # The last time index of every cache.
    lastCacheTime::Float64


    """
    The constructor for the `SimulationCache` type.
    """
    function SimulationCache()

        newCache = new()
        newCache.cache = Dict{Float64, CacheEntry}()
        newCache.lastCacheTime = 0
        return newCache

    end  # SimulationCache()
end  # type SimulationCache
