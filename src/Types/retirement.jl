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
type Retirement
    # The maximum length of a personnel member's career.
    maxCareerLength::Float64

    # The mandatory retirement age.
    retireAge::Float64

    # The time between two retirement cycles.
    retireFreq::Float64

    # The offset of the retirement cycle.
    retireOffset::Float64

    function Retirement( ; freq::T1 = 0.0, offset::T2 = 0.0,
        maxCareer::T3 = 0.0, retireAge::T4 = 0.0 ) where T1 <: Real where T2 <: Real where T3 <: Real where T4 <: Real
        if freq < 0.0
            error( "Retirement cycle length must be ⩾ 0.0." )
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
        return newRet
    end  # Retirement( freq, offset, maxCareer, retireAge )
end  # type Retirement
