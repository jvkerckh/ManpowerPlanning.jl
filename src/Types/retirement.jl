# This file holds the definition of the Retirement type. This type is used to
#   describe the particulars of retirement due to age/end of career.

# The Retirement type requires no additional types.
requiredTypes = [ ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( dirname( Base.source_path() ), reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end  # for reqType in requiredTypes


export Retirement
"""
This type defines a retirement scheme for mandatory retirement of personnel
members based on age or tenure.

The type contains the following fields:
* `maxCareerLength::Float64`: the maximum length of a personnel member's career.
  Set this to 0 to ignore this criterion.
* `retireAge::Float64`: the mandatory retirement age. Set this to 0 to ignore
  this criterion.
* `retireFreq::Float64`: the length of the time interval between two retirement
  checks.
* `retireOffset::Float64`: the offset of the retirement schedule with respect to
  the start of the simulation.
* 'isEither::Bool': a flag indicating whether either of the criteria (age or
  tenure) must be satisfied for retirement, or both.
"""
type Retirement

    maxCareerLength::Float64
    retireAge::Float64
    retireFreq::Float64
    retireOffset::Float64
    isEither::Bool

    function Retirement( ; freq::T1 = 1.0, offset::T2 = 0.0,
        maxCareer::T3 = 0.0, retireAge::T4 = 0.0, isEither::Bool = true ) where T1 <: Real where T2 <: Real where T3 <: Real where T4 <: Real

        if freq <= 0.0
            error( "Retirement cycle length must be > 0.0." )
        end  # if freq < 0.0

        if maxCareer < 0.0
            error( "Maximal career length must be ⩾ 0.0." )
        end  # if maxCareer < 0.0

        if retireAge < 0.0
            error( "Mandatory retirement age must be ⩾ 0.0." )
        end  # if maxCareer < 0.0

        newRet = new()
        newRet.maxCareerLength = maxCareer
        newRet.retireAge = retireAge
        newRet.retireFreq = freq
        newRet.retireOffset = freq > 0.0 ?
            ( offset % freq + ( offset < 0.0 ? freq : 0.0 ) ) : 0.0
        newRet.isEither = isEither
        return newRet

    end  # Retirement( freq, offset, maxCareer, retireAge )

end  # type Retirement
