# This file holds the definition of the functions pertaining to the CacheEntry
#   type.

# The functions of the CacheEntry type require no additional types.
requiredTypes = [ "cacheEntry" ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( dirname( Base.source_path() ), "..", "Types",
            reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end  # for reqType in requiredTypes


# This function sets the time resolution of the cache entry.
export setCacheResolution
function setCacheResolution( entry::CacheEntry, res::T ) where T <: Real
    if res <= 0.0
        error( "Time resolution must be > 0.0." )
    end  # if res <= 0.0

    entry.resolution = res
end  # setCacheResolution( entry, res )


# This function returns the time resolution of this cache entry, or the
#   requested cache.
# If the cache has not been created yet, it will return nothing.
# If the wrong type of information is requested, it will throw an error.
# Accepted types are :resolution, :count, :fluxIn, :fluxOut.
function Base.getindex( entry::CacheEntry, infoType::Symbol )
    if infoType ∉ [ :resolution, :count, :fluxIn, :fluxOut ]
        error( "Unknown cache entry field." )
    end  # if infoType ∉ [ :resolution, :count, :fluxIn, :fluxOut ]

    if infoType === :count
        out = entry.countCache
    elseif infoType === :fluxIn
        out = entry.fluxInCache
    elseif infoType === :fluxOut
        out = entry.fluxOutCache
    else
        return entry.resolution
    end  # if infoType === :count

    return isempty( out ) ? nothing : out
end  # Base.getIndex( entry, infoType )


# This function sets the specified cache.
# If the wrong type of information is requested, it will throw an error.
# Accepted types are :count, :fluxIn, :fluxOut.
function Base.setindex!( entry::CacheEntry, cache::Vector{Int},
    cacheType::Symbol )

    if cacheType ∉ [ :count, :fluxIn, :fluxOut ]
        error( "Unknown cache entry field." )
    end  # if cacheType ∉ [ :count, :fluxIn, :fluxOut ]

    if cacheType === :count
        entry.countCache = cache
    elseif cacheType === :fluxIn
        entry.fluxInCache = cache
    else
        entry.fluxOutCache = cache
    end  # if cacheType === :count
end  # Base.setindex!( entry, cache, cacheType )
