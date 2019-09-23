# This file holds the definition of the functions pertaining to the Retirement
#   type.

export  setRetirementCareerLength!,
        setRetirementAge!,
        setRetirementSchedule!,
        setRetirementIsEither!


"""
```
setRetirementCareerLength!(
    retirement::Retirement,
    careerLength::Real )
```
This function sets the maximum career length of the retirement scheme `retirement` to `careerLength`, where a career length of 0 indicates there is no limit.

If a career length < 0 is entered, the function gives a warning and makes no changes.

The function returns `true` if the maximum career length has been successfully set, and `false` if the entered career length is < 0.
"""
function setRetirementCareerLength!( retirement::Retirement,
    careerLength::Real )::Bool

    if careerLength < 0.0
        @warn "Max career length must be ⩾ 0, not making any changes."
        return false
    end  # if careerLength < 0.0

    retirement.maxCareerLength = careerLength
    return true

end  # setRetirementCareerLength!( retirement, careerLength )


"""
```
setRetirementAge!(
    retirement::Retirement,
    age::Real )
```
This function sets the retirement age of the retirement scheme `retirement` to `age`, where an age of 0 indicates there is no limit.

If a retirement age < 0 is entered, the function gives a warning and makes no changes.

The function returns `true` if the retirement age has been successfully set, and `false` if the entered age is < 0.
"""
function setRetirementAge!( retirement::Retirement, age::Real )::Bool

    if age < 0.0
        @warn "Retirement age must be ⩾ 0, not making any changes."
        return false
    end  # if age < 0.0

    retirement.retirementAge = age
    return true

end  # setRetirementAge!( retirement, age )


"""
```
setRetirementSchedule!(
    retirement::Retirement,
    freq::Real,
    offset::Real = 0.0 )
```
This function sets the schedule of the retirement scheme `retirement` one one check every `freq` time units, with an offset of `offset` w.r.t. the start of the simulation.

If the entered period is ⩽ 0, the function issues a warning and makes no changes.

The function returns `true` if the schedule has been successfully set, and `false` if the entered schedule period is ⩽ 0.
"""
function setRetirementSchedule!( retirement::Retirement, freq::Real, offset::Real = 0.0 )::Bool

    if freq <= 0.0
        @warn "Frequency of retirement schedule must be > 0, not making any changes."
        return false
    end  # if freq <= 0.0

    retirement.retirementFreq = freq
    retirement.retirementOffset = ( offset % freq ) +
        ( offset < 0.0 ? freq : 0.0 )
    return true

end  # setRetirementSchedule!( retirement, freq, offset )


"""
```
setRetirementIsEither!(
    retirement::Retirement,
    isEither::Bool )
```
This function sets the `isEither` flag of the retirement scheme `retirement` to `isEither`.

This function returns `true`, indicating that the flag has been successfully set.
"""
function setRetirementIsEither!( retirement::Retirement, isEither::Bool )::Bool

    retirement.isEither = isEither
    return true

end  # setRetirementIsEither!( retirement, isEither )


function Base.show( io::IO, retirement::Retirement )::Nothing

    print( io, "Retirement scheme" )

    if ( retirement.retirementAge == 0.0 ) &&
        ( retirement.maxCareerLength == 0.0 )
        print( io, " undefined" )
        return
    end  # if ( retirement.retirementAge == 0.0 ) && ...

    print( io, "\n  Retirement check occurs with a period of ",
        retirement.retirementFreq, " (offset ", retirement.retirementOffset,
        ")" )

    print( io, "\n  Retirement occurs " )

    if retirement.retirementAge == 0.0
        print( io, "after a career of length ", retirement.maxCareerLength )
    elseif retirement.maxCareerLength == 0.0
        print( io, "at age ", retirement.retirementAge )
    else
        print( io, "at age ", retirement.retirementAge, 
            retirement.isEither ? " or" : " and", " after a career of length ",
            retirement.maxCareerLength )
    end  # if retirement.retirementAge == 0.0

    return

end  # show( io, retirement )