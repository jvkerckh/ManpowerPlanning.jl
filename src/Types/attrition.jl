# This file defines the Attrition type. This type represents an attrition scheme
#   to make it possible for personnel members to leave service before their
#   mandatory retirement.

export Attrition

"""
The `Attrition` type represents an attrition scheme to make it possible for personnel members to leave service before their mandatory retirement. The reasons for leaving can be various, but are outside the organisation's control, such as voluntary resignation, medical discharge, etc. We assume that attrition has no memory so to speak. In other words, we assume that the distribution of the time to attrition is a (piecewise) exponential distribution.

An object of this type has the following fields:
* `name::String`: the name of the attrition scheme.
* `period::Float64`: the period which the attrition rate covers, e.g. percentage per month, quarter, or year.
* `curvePoints::Vector{Float64}`: the time points, in periods, of the attrition curve. This curve is always sorted, and the first element is always 0.0.
* `rates::Vector{Float64}`: the attrition rates in (average) percentage per period undergoing attrition for each time point of the attrition curve.

Additional fields of the type, which are computed based on the above fields, and used to compute the distribution of the time to attrition and sample from it:
* `lambdas::Vector{Float64}`: the average number of attrition events (λ) per period for each piece of the distribution.
* `gammas::Vector{Float64}`: the probabilities that the time to attrition exceeds each time node of the attrition curve.

Constructors:
```
Attrition(
    name::String = "default",
    rate::Real = 0.0,
    period::Real = 1.0 )
```
This constructor generates an `Attrition` object with name `name`, and an attrition rate of `rate` per period of length `period`. The attrition rate must be in the interval [0, 1), and the period must be > 0.
```
Attrition(
    name::String,
    curve::Union{Dict{Float64, Float64}, Array{Float64, 2}},
    period::Real = 1.0 )

Attrition(
    curve::Union{Dict{Float64, Float64}, Array{Float64, 2}},
    period::Real = 1.0 )
```
This constructor generates an `Attrition` object with name `name`, and an attrition curve `curve` where the attrition rates are given per period of length `period`. Nodes with a time point ⩽ 0 are ignored, except the one closest to 0, which is used to determine the attrition rate at time 0. If no such node exists, the initial attrition rate is set to 0. Nodes with a negative attrition rate are ignored.

The second version of this constructor creates an `Attrition` object with name `default`.
"""
mutable struct Attrition

    name::String
    period::Float64
    curvePoints::Vector{Float64}
    rates::Vector{Float64}

    lambdas::Vector{Float64}
    gammas::Vector{Float64}


    function Attrition( name::String = "default", rate::Real = 0.0,
        period::Real = 1.0 )::Attrition

        if !( 0.0 <= rate < 1.0 )
            error( "Attrition rate must be in the range [0.0, 1.0)." )
        end  # if !( 0.0 <= rate < 1.0 )

        if period <= 0.0
            error( "Attrition period must be > 0.0." )
        end  # if period <= 0.0

        newAttr = new()
        newAttr.name = name
        newAttr.period = period
        newAttr.curvePoints = [ 0.0 ]
        newAttr.rates = [ rate ]
        computeDistPars( newAttr )
        return newAttr

    end  # Attrition( name, rate, period )

    function Attrition( name::String, curve::Union{Dict{T1, T2}, Array{T3, 2}},
        period::Real = 1.0 )::Attrition where T1 <: Real where T2 <: Real where T3 <: Real

        if period <= 0.0
            error( "Attrition period must be > 0.0." )
        end  # if period <= 0.0

        newAttr = Attrition( name )
        newAttr.period = period
        setAttritionCurve!( newAttr, curve )
        return newAttr

    end  # Attrition( name, curve, period )

    # TODO: make sure this constructor covers all bases.
    Attrition( curve::Union{Dict{Float64, Float64}, Array{Float64, 2}},
        period::Real = 1.0 )::Attrition = Attrition( "default", curve, period )

end  # mutable struct Attrition
