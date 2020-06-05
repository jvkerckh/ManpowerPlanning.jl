# This file holds the definition of the Recruitment type. This type is used to
#   describe a recruitment scheme for a specific part of the organisation and
#   defines which attributes need to be initialised and what the distributions
#   of those attributes are.

export Recruitment
"""
The `Recruitment` type described a recruitment scheme, allowing new personnel members to enter the organisation into a specific nodes.

The type contains the following fields:
* `name::String`: the name of the recruitment scheme.
* `freq::Float64`: the period of the recruitment cycle. Default = 1.0
* `offset::Float64`: the offset of the recruitment cycle w.r.t. the start of the simulation. Default = 0.0
* `targetNode::BaseNode`: the target node of the recruitment scheme.
* `minRecruitment::Int`: the minimum number of personnel members to recruit during a single recruitment step. This is only used for adaptive recruitment schemes. Default = 0
* `maxRecruitment::Int`: the maximum number of personnel members to recruit during a single recruitment step, where -1 stands for no upper limit. This is only used for adaptive recruitment schemes. Default = -1
* `recruitmentDistType::Symbol`: the type of the distribution of the number of people to recruit. Supported types are `:disc` (pointwise), `:pUnif` (piecewise uniform), and `:pLin` (piecewise linear). This is only used for non-adaptive recruitment schemes. Default = `:disc`
* `recruitmentDistNodes::Dict{Int,Float64}`: the nodes of the distribution of the number of people to recruit. These are given as number/weight pairs. Default: Dict( 0 => 1.0 )
* `ageDistType::Symbol`: the type of the distribution of the ages of the recruited people. Supported types are `:disc` (pointwise), `:pUnif` (piecewise uniform), and `:pLin` (piecewise linear). This is only used for non-adaptive recruitment schemes. Default = `:disc`
* `ageDistNodes::Dict{Float64,Float64}`: the nodes of the distribution of the ages of the recruited people. These are given as age/weight pairs. Default: Dict( 0.0 => 1.0 )

Several additional fields are used to speed up computations:
* `isAdaptive::Bool`: a flag indicating whether the recruitment scheme is adaptive or not.
* `recruitmentDist::Function`: the function that draws a sample from the distribution of the number of people to recruit.
* `ageDist::Function`: the function that draws a sample from the distrubiton of the recruitment age.
* `priority::Int`: the priority of the SimJulia process of this recruitment scheme.
* `recRNG::MersenneTwister`: the random stream that generates the number of people to recruit during each recruitment cycle.
* `ageRNG::MersenneTwister`: the random stream that generates the ages of the newly recruited personnel members.

Constructor:
```
Recruitment( name::String )
```
This constructor creates a `Recruitment` object with name `name`, and zero recruitment defined.
"""
mutable struct Recruitment

    name::String
    freq::Float64
    offset::Float64
    targetNode::String
    minRecruitment::Int
    maxRecruitment::Int
    recruitmentDistType::Symbol
    recruitmentDistNodes::Dict{Int,Float64}
    ageDistType::Symbol
    ageDistNodes::Dict{Float64,Float64}

    isAdaptive::Bool
    recruitmentDist::Function
    ageDist::Function
    priority::Int
    recRNG::MersenneTwister
    ageRNG::MersenneTwister


    function Recruitment( name::String )

        newRec = new()
        newRec.name = name
        newRec.freq = 1.0
        newRec.offset = 0.0
        newRec.targetNode = "dummy"
        newRec.minRecruitment = 0
        newRec.maxRecruitment = -1
        newRec.recruitmentDistType = :disc
        newRec.recruitmentDistNodes = Dict( 0 => 1.0 )
        newRec.ageDistType = :disc
        newRec.ageDistNodes = Dict( 0.0 => 1.0 )

        newRec.isAdaptive = false
        newRec.recruitmentDist = function() return 0 end
        newRec.ageDist = function( n::Integer ) return zeros( Float64, n ) end
        newRec.priority = 1
        newRec.recRNG = MersenneTwister()
        newRec.ageRNG = MersenneTwister()
        return newRec

    end  # Recruitment( name )

end  # mutable struct Recruitment