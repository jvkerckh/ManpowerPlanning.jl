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

    # The rate of attrition over a single period.
    attrRate::Float64


    function Attrition( rate::T1 = 0.0, period::T2 = 1.0 ) where T1 <: Real where T2 <: Real
        if ( rate < 0.0 ) || ( rate >= 1.0 )
            error( "Attrition rate must be between 0.0 and 1.0." )
        end  # if ( rate < 0.0 ) || ( rate > 100.0 )

        if period <= 0.0
            error( "Attrition period must be > 0.0." )
        end  # if period <= 0.0

        newAttr = new()
        newAttr.attrRate = rate
        # If there's no attrition, the period doesn't matter.
        newAttr.attrPeriod = rate == 0.0 ? 1.0 : period
        return newAttr
    end  # Attrition( rate, period )
end  # type Attrition
