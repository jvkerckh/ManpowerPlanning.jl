# This file holds the definition of the Recruitment type. This type is used to
#   describe a recruitment scheme for a specific part of the organisation and
#   defines which attributes need to be initialised and what the distributions
#   of those attributes are.

# The Recruitment type requires no additional types.
requiredTypes = [ ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( typePath, reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end  # for reqType in requiredTypes


export Recruitment
type Recruitment

    # The name of this recruitment type.
    name::String

    # The time between two recruitment drives.
    recruitFreq::Float64

    # The offset of the recruitment cycle.
    recruitOffset::Float64

    # Vary recruitment according to needs.
    isAdaptive::Bool

    # The min/max number of personnel members to recruit.
    minRecruit::Int
    maxRecruit::Int

    # The state to recruit into.
    recState::String

    # The type of the recruitment distribution.
    recDistType::Symbol

    # The nodes of the recruitment distribution, if applicable.
    recDistNodes::Dict{Float64, Float64}

    # This is the type of the age distribution.
    ageDistType::Symbol

    # The distribution function of the number of recruits in a single cycle.
    recDist::Function

    # These are the nodes (with probability weights) of the age distribution.
    ageDistNodes::Dict{Float64, Float64}

    # The distribution function of the age of a single recruit.
    ageDist::Function

    #___________________________________________________________________________
    # This section is used by the optimizer
    # We define a recruitment flow and age for each year

    # The recruitment flow is defined by the RecFlowArray
    UseRecFlowArray::Bool

    # Recruitment flow array
    RecFlowArray::Array{Int}

    # The recruitment age is defined by the RecAgeArray
    UseRecAgeArray::Bool

    # Recruitment age array
    RecAgeArray::Array{Int}
    #___________________________________________________________________________

    function Recruitment( name::String, freq::T1, offset::T2 = 0.0 ) where T1 <: Real where T2 <: Real

        if freq <= 0.0
            error( "Recruitment frequency must be > 0.0." )
        end  # if freq <= 0.0

        newRec = new()
        newRec.name = name
        newRec.recruitFreq = freq
        newRec.recruitOffset = offset % freq + ( offset < 0.0 ? freq : 0.0 )
        newRec.isAdaptive = true
        newRec.minRecruit = 0
        newRec.maxRecruit = typemax( Int )
        newRec.recState = ""
        newRec.recDistType = :disc
        newRec.recDistNodes = Dict{Float64, Float64}()
        newRec.recDist = function() return 0 end
        newRec.ageDistType = :disc
        newRec.ageDistNodes = Dict( 0.0 => 1.0 )
        newRec.ageDist = function() return 0.0 end
        newRec.UseRecFlowArray = false
        newRec.UseRecAgeArray = false
        return newRec

    end  # Recruitment( freq, offset )

end  # type Recruitment
