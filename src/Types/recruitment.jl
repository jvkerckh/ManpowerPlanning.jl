# This file holds the definition of the Recruitment type. This type is used to
#   describe a recruitment scheme for a specific part of the organisation and
#   defines which attributes need to be initialised and what the distributions
#   of those attributes are.

# The Recruitment type requires no additional types.
requiredTypes = [ ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( dirname( Base.source_path() ), reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end  # for reqType in requiredTypes


export Recruitment
type Recruitment
    # The time between two recruitment drives.
    recruitFreq::Float64

    # The offset of the recruitment cycle.
    recruitOffset::Float64

    # The distribution of the number of recruits per cycle.
    # We model this as a Categorical distribution + a map from 1:K to the
    #   actual values.
    recruitDist::Categorical
    recruitMap::Vector{Int}

    # The distribution of the age of a single recruit.
    ageDist::Function


    function Recruitment( freq::T1, offset::T2 = 0.0 ) where T1 <: Real where T2 <: Real

        if freq <= 0.0
            error( "Recruitment frequency must be > 0.0." )
        end  # if freq <= 0.0

        newRec = new()
        newRec.recruitFreq = freq
        newRec.recruitOffset = offset % freq + ( offset < 0.0 ? freq : 0.0 )
        newRec.recruitDist = Categorical( 1 )
        newRec.recruitMap = [ 0 ]
        newRec.ageDist = function() return 0.0 end
        return newRec

    end  # Recruitment( freq, offset )
end  # type Recruitment
