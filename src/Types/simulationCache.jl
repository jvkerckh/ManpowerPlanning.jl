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
type SimulationCache
    # The simulation cache.
    cache::Dict{Float64, CacheEntry}


    function SimulationCache()
        newCache = new()
        newCache.cache = Dict{Float64, CacheEntry}()
        return newCache
    end  # SimulationCache()
end  # type SimulationCache
