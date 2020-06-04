# This file defines the Attrition type. This type represents an attrition scheme
#   to make it possible for personnel members to leave service before their
#   mandatory retirement.

export Attrition

"""
The `Attrition` type represents an attrition scheme to make it possible for personnel members to leave service before their mandatory retirement. The reasons for leaving can be various, but are outside the organisation's control, such as voluntary resignation, medical discharge, etc. We assume that attrition has no memory so to speak. In other words, we assume that the distribution of the time to attrition is a (piecewise) exponential distribution.

An object of this type has the following fields:
* `name::String`: the name of the attrition scheme.
* `period::Float64`: the period which the attrition rate covers, e.g. percentage per month, quarter, or year. Default = 1.0
* `curvePoints::Vector{Float64}`: the time points of the attrition curve. This curve is always sorted, and the first element is always 0.0.
* `rates::Vector{Float64}`: the attrition rates in (average) percentage per period undergoing attrition for each time point of the attrition curve.

Additional fields of the type, which are computed based on the above fields, and used to compute the distribution of the time to attrition and sample from it:
* `lambdas::Vector{Float64}`: the average number of attrition events (λ) per period for each piece of the distribution.
* `gammas::Vector{Float64}`: the probabilities that the time to attrition exceeds each time node of the attrition curve.

Constructors:
```
Attrition( name::String = "default" )
```
This constructor generates an `Attrition` object with name `name` and a flat, zero-rate attrition curve.
```
"""
mutable struct Attrition

    name::String
    period::Float64
    curvePoints::Vector{Float64}
    rates::Vector{Float64}

    lambdas::Vector{Float64}
    gammas::Vector{Float64}
    timeRNG::MersenneTwister
    condtimeRNG::MersenneTwister


    function Attrition( name::String = "default" )::Attrition

        newAttr = new()
        newAttr.name = name
        newAttr.period = 1.0
        newAttr.curvePoints = [0.0]
        newAttr.rates = [0.0]
        newAttr.timeRNG = MersenneTwister()
        newAttr.condtimeRNG = MersenneTwister()
        computeDistPars( newAttr )
        return newAttr

    end  # Attrition( name )

end  # mutable struct Attrition