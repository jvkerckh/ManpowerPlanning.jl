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

    # Throw an error if the time resolution is negative.
    if res <= 0.0
        error( "Time resolution must be > 0.0." )
    end  # if res <= 0.0

    entry.resolution = res

end  # setCacheResolution( entry, res )


"""
This function changes the cache entry `entry` for the type  `cacheType` to
`cache`.

This function returns `nothing` upon successful completion. If the given cache
type is invalid, the function throws an error. Valid types are `:count`,
`:fluxIn`, `:fluxOut`, `:resigned`, `:retired`.
"""
function setCache( entry::CacheEntry, cacheType::Symbol, cache::Vector{Int} )

    if cacheType ∉ [ :count, :fluxIn, :fluxOut, :resigned, :retired ]
        error( "Unknown cache entry field." )
    end  # if cacheType ∉ [ :count, :fluxIn, :fluxOut ]

    if cacheType === :count
        entry.countCache = cache
    elseif cacheType === :fluxIn
        entry.fluxInCache = cache
    elseif cacheType === :fluxOut
        entry.fluxOutCache = cache
    elseif cacheType === :resigned
        entry.fluxResignedCache = cache
    else
        entry.fluxRetiredCache = cache
    end  # if cacheType === :count

end  # addCache( entry, cacheType, cache )



# This function returns the time resolution of this cache entry, or the
#   requested cache.
# If the cache has not been created yet, it will return nothing.
# If the wrong type of information is requested, it will throw an error.
# Accepted types are :resolution, :count, :fluxIn, :fluxOut.
function Base.getindex( entry::CacheEntry, infoType::Symbol )

    if infoType ∉ [ :resolution, :count, :fluxIn, :fluxOut, :resigned,
        :retired ]
        error( "Unknown cache entry field." )
    end  # if infoType ∉ ...

    if infoType === :count
        out = entry.countCache
    elseif infoType === :fluxIn
        out = entry.fluxInCache
    elseif infoType === :fluxOut
        out = entry.fluxOutCache
    elseif infoType === :resigned
        out = entry.fluxResignedCache
    elseif infoType === :retired
        out = entry.fluxRetiredCache
    else
        return entry.resolution
    end  # if infoType === :count

    return isempty( out ) ? nothing : out

end  # Base.getIndex( entry, infoType )


#=
# This function sets the specified cache.
# If the wrong type of information is requested, it will throw an error.
# Accepted types are :count, :fluxIn, :fluxOut.
function Base.setindex!( entry::CacheEntry, cache::Vector{Int},
    cacheType::Symbol )

    if cacheType ∉ [ :count, :fluxIn, :fluxOut, :resigned, :retired ]
        error( "Unknown cache entry field." )
    end  # if cacheType ∉ [ :count, :fluxIn, :fluxOut ]

    if cacheType === :count
        entry.countCache = cache
    elseif cacheType === :fluxIn
        entry.fluxInCache = cache
    elseif cacheType === :fluxOut
        entry.fluxOutCache = cache
    elseif cacheType === :resigned
        entry.fluxResignedCache = cache
    else
        entry.fluxRetiredCache = cache
    end  # if cacheType === :count

end  # Base.setindex!( entry, cache, cacheType )
=#
