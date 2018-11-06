# This file defines the Attrition type. This type represents an attrition scheme
#   to make it possible for personnel members to leave service before their
#   mandatory retirement.

# The attrition type requires no additional types. [ XXX true? ]
requiredTypes = [ ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( typePath, reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end  # for reqType in requiredTypes


export Attrition
type Attrition
    # The name of the attrition scheme.
    name::String

    # The attrition period.
    attrPeriod::Float64

    # The time points of the attrition curve. This curve is always sorted, and
    #   the first element is 0.0.
    attrCurvePoints::Vector{Float64}

    # The attrition rates at the points of the attrition curve.
    attrRates::Vector{Float64}

    # The lambdas of each part of the attrition time distribution.
    lambdas::Vector{Float64}

    # An auxiliary vector of parameters.
    betas::Vector{Float64}

    # The exceeding probabilities for each time node of the attrition time
    #   distribution.
    gammas::Vector{Float64}


    function Attrition( name::String, rate::T1 = 0.0, period::T2 = 1.0 ) where T1 <: Real where T2 <: Real

        if ( rate < 0.0 ) || ( rate >= 1.0 )
            error( "Attrition rate must be between 0.0 and 1.0." )
        end  # if ( rate < 0.0 ) || ( rate > 100.0 )

        if period <= 0.0
            error( "Attrition period must be > 0.0." )
        end  # if period <= 0.0

        newAttr = new()
        newAttr.name = name
        # If there's no attrition, the period doesn't matter.
        newAttr.attrPeriod = rate == 0.0 ? 1.0 : period
        newAttr.attrCurvePoints = [ 0.0 ]
        newAttr.attrRates = [ rate ]
        computeDistPars( newAttr )
        return newAttr

    end  # Attrition( name, rate, period )

    function Attrition( rate::T1 = 0.0, period::T2 = 1.0 ) where T1 <: Real where T2 <: Real

        newAttr = Attrition( "default", rate, period )
        return newAttr

    end  # Attrition( rate, period )

    function Attrition( name::String, curve::T1, period::T2 = 1.0 ) where T1 <: Union{Dict{Float64, Float64}, Array{Float64, 2}} where T2 <: Real

        if period <= 0.0
            error( "Attrition period must be > 0.0." )
        end  # if period <= 0.0

        newAttr = Attrition( name )
        setAttritionCurve( newAttr, curve )
        setAttritionPeriod( newAttr, period )
        return newAttr

    end  # Attrition( name, curve, period )

    function Attrition( curve::T1, period::T2 = 1.0 ) where T1 <: Union{Dict{Float64, Float64}, Array{Float64, 2}} where T2 <: Real

        if period <= 0.0
            error( "Attrition period must be > 0.0." )
        end  # if period <= 0.0

        newAttr = Attrition( "default" )
        setAttritionCurve( newAttr, curve )
        setAttritionPeriod( newAttr, period )
        return newAttr

    end  # Attrition( curve, period )

end  # type Attrition
