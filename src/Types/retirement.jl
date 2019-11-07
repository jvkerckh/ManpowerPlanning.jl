# This file holds the definition of the Retirement type. This type is used to
#   describe the particulars of retirement due to age and/or tenure.

export Retirement
"""
The `Retirement` type defines a retirement scheme for mandatory retirement of personnel members based on age or tenure. This type is used only to define the default retirement scheme, and will generally be overruled by OUT transitions attached to specific nodes.

The type contains the following fields:
* `maxCareerLength::Float64`: the maximum length of a personnel member's career. A value of 0 means this criterion is ignored. Default = 0.0
* `retirementAge::Float64`: the mandatory retirement age. A value of 0 means this criterion is ignored. Default = 0.0
* 'isEither::Bool': a flag indicating whether either of the criteria (age or tenure) must be satisfied for retirement, or both. Default = `true`
* `freq::Float64`: the length of the time interval between two retirement checks. Default = 1.0
* `offset::Float64`: the offset of the retirement schedule with respect to the start of the simulation. Default = 0.0

Constructor:
```
Retirement()
```
This constructor creates a `Retirement` object with the above mentioned default values for the parameters.
"""
mutable struct Retirement

    maxCareerLength::Float64
    retirementAge::Float64
    isEither::Bool
    freq::Float64
    offset::Float64

    function Retirement()::Retirement

        newRet = new()
        newRet.maxCareerLength = 0.0
        newRet.retirementAge = 0.0
        newRet.isEither = true
        newRet.freq = 1.0
        newRet.offset = 0.0
        return newRet

    end  # Retirement()

end  # mutable struct Retirement