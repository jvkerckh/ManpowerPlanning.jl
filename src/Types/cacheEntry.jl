# This file defines the CacheEntry type. This type holds the cache of the count
#   and flux in/out reports for a single time resolution.

# The CacheEntry type requires no additional types.
requiredTypes = [ ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( dirname( Base.source_path() ), reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end  # for reqType in requiredTypes


export CacheEntry
type CacheEntry
    # The time resolution.
    resolution::Float64

    # The countRecords cache.
    countCache::Vector{Int}

    # The fluxIn cache.
    fluxInCache::Vector{Int}

    # The fluxOut cache.
    fluxOutCache::Vector{Int}

    # The fluxResigned cache.
    fluxResignedCache::Vector{Int}

    # The fluxRetired cache.
    fluxRetiredCache::Vector{Int}


    function CacheEntry( res::T ) where T <: Real

        if res <= 0.0
            error( "Time resolution must be > 0.0." )
        end  # if res <= 0.0

        newEntry = new()
        newEntry.resolution = res
        newEntry.countCache = Vector{Int}()
        newEntry.fluxInCache = Vector{Int}()
        newEntry.fluxOutCache = Vector{Int}()
        newEntry.fluxResignedCache = Vector{Int}()
        newEntry.fluxRetiredCache = Vector{Int}()
        return newEntry

    end  # CacheEntry( res )
end  # type CacheEntry
