# This file defines the Attrition type. This type represents an attrition scheme
#   to make it possible for personnel members to leave service before their
#   mandatory retirement.

# The attrition type requires no additional types. [ XXX true? ]
requiredTypes = [ ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( dirname( Base.source_path() ), reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end  # for reqType in requiredTypes


export Attrition
type Attrition
    # The attrition period.
    attrPeriod::Float64

    # The time points of the attrition curve. This curve is always sorted, and
    #   the first element is 0.0.
    attrCurvePoints::Vector{Float64}

    # The attrition rates at the points of the attrition curve.
    attrRates::Vector{Float64}


    function Attrition( rate::T1 = 0.0, period::T2 = 1.0 ) where T1 <: Real where T2 <: Real

        if ( rate < 0.0 ) || ( rate >= 1.0 )
            error( "Attrition rate must be between 0.0 and 1.0." )
        end  # if ( rate < 0.0 ) || ( rate > 100.0 )

        if period <= 0.0
            error( "Attrition period must be > 0.0." )
        end  # if period <= 0.0

        newAttr = new()
        # If there's no attrition, the period doesn't matter.
        newAttr.attrPeriod = rate == 0.0 ? 1.0 : period
        newAttr.attrCurvePoints = [ 0.0 ]
        newAttr.attrRates = [ rate ]
        return newAttr

    end  # Attrition( rate, period )

    function Attrition( curve::T1, period::T2 = 1.0 ) where T1 <: Union{Dict{Float64, Float64}, Array{Float64, 2}} where T2 <: Real

        if period <= 0.0
            error( "Attrition period must be > 0.0." )
        end  # if period <= 0.0

        newAttr = Attrition()
        setAttritionCurve( newAttr, curve )
        setAttritionPeriod( newAttr, period )
        return newAttr

    end  # Attrition( curve, period )

end  # type Attrition
