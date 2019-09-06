# This file holds the definition of the functions pertaining to the Attrition
#   type.

export  setAttritionName!,
        setAttritionRate!,
        setAttritionPeriod!,
        setAttritionCurve!


"""
```
setAttritionName!(
    attrition::Attrition,
    name::String )
```
This function sets the name of the attrition scheme `attrition` to `name`.

This function returns `true`, indicating the name has been set successfully.
"""
function setAttritionName!( attrition::Attrition, name::String )::Bool

    attrition.name = name
    return true

end  # setAttritionName!( attrition, name )


"""
```
setAttritionRate!(
    attrition::Attrition,
    rate::Real )
```
This function sets the attrition curve of the attrition scheme `attrition` to a constant value of `rate` per period for all terms. If the given rate is not in the interval [0.0, 1.0), the function doesn't make a change and gives a warning.

This function returns `true` if the rate was set successfully, `false` otherwise.
"""
function setAttritionRate!( attrition::Attrition, rate::Real )::Bool

    if !( 0.0 <= rate < 1.0 )
        @warn "Attrition rate must be in the range [0.0, 1.0), not making any changes."
        return false
    end  # if !( 0.0 <= rate < 1.0 )

    attrition.curvePoints = [ 0.0 ]
    attrition.rates = [ rate ]
    computeDistPars( attrition )
    return true

end  # setAttritionRate!( attrition, rate )


"""
```
setAttritionPeriod!(
    attrition::Attrition,
    period::Real )
```
This function sets the attrition period of the attrition scheme `attrition` to `period`. If the given period is ⩽ 0, the function doesn't make a change and gives a warning.

This function returns `true` if the period was set successfully, `false` otherwise.
"""
function setAttritionPeriod!( attrition::Attrition, period::Real )::Bool

    if period <= 0.0
        @warn "Attrition period must be > 0.0, not making any changes."
        return false
    end  # if period <= 0.0

    attrition.period = period
    computeDistPars( attrition )
    return true

end  # setAttritionPeriod!( attrition, period )


"""
``````
setAttritionCurve!(
    attrition::Attrition,
    curve::Dict{Float64, Float64} )
```
This function sets the attrition curve of attrition scheme `attrition` to `curve`. The attrition curve is passed as a `Dict{Float64, Float64}` with the keys as the time a person exists in the simulation, and the values as the attrition rates per period from the time specified by that key to the next.

This function ignores non-sensical attrition rates, that is, rates outside the interval [0.0, 1.0). This function takes the rate at the negative time point closest to zero as the zero rate, and ignores the other negative time points. 

If the first time point is non-zero positive, a zero attrition rate is set from time point 0 to that time point. If there are no eligible curve points, this function makes no changes.
    
This function returns `true` if the attrition rate curve is set successfully, `false otherwise`.
"""
function setAttritionCurve!( attrition::Attrition,
    curve::Dict{T1, T2} )::Bool where T1 <: Real where T2 <: Real

    terms = Float64.( sort( collect( keys( curve ) ) ) )
    rates = Float64.( map( term -> curve[ term ], terms ) )

    # Filter unsuitable attrition rates.
    isRateOkay = 0 .<= rates .< 1
    terms = terms[ isRateOkay ]
    rates = rates[ isRateOkay ]

    # If no suitable ones remain, make no changes.
    if isempty( terms )
        @warn "All attrition rates in the given curve are invalid, not making any changes."
        return false
    end  # if isempty( terms )

    # Clip the vectors to the last negative term point. If there is none, add a 
    #   0 rate at the start.
    zeroInd = findlast( terms .<= 0 )

    if zeroInd isa Nothing
        terms = vcat( 0.0, terms )
        rates = vcat( 0.0, rates )
    else
        terms = terms[ zeroInd:end ]
        terms[ 1 ] = 0.0
        rates = rates[ zeroInd:end ]
    end  # if zeroInd isa Nothing

    # Filter out successive attrition rates that are the same.
    isDifferentFromPrevious = vcat( true,
        rates[ 2:end ] .!= rates[ 1:(end - 1) ] )
    attrition.curvePoints = terms[ isDifferentFromPrevious ]
    attrition.rates = rates[ isDifferentFromPrevious ]
    computeDistPars( attrition )
    return true

end  # setAttritionCurve!( attrition, curve )

"""
setAttritionCurve!( attrition::Attrition,
                    curve::Array{Float64, 2} )

This function sets the attrition curve of attrition scheme `attrition` to
`curve`. The attrition curve is passed as a 2-dimensional `Array{Float64, 2}`
with 2 columns. The first column has the time a person exists in the simulation,
and the second column has the attrition rates per period from the time specified
by that key to the next.

If the dimensions of the curve array are incorrect, or if the curve array contains duplicate time points, this function makes no changes.

All remarks for the version of this function with a `Dict` are valid here as well.

This function returns `true` if the attrition rate curve is set successfully, `false otherwise`.
"""
function setAttritionCurve!( attrition::Attrition,
    curve::Array{T, 2} )::Bool where T <: Real

    # Check for correct dimensions.
    if size( curve )[ 2 ] != 2
        @warn "Invalid array given to define attrition curve, not making any changes."
        return false
    end  # if size( curve )[ 2 ] != 2

    # Check for duplicate terms.
    if length( curve[ :, 1 ] ) != length( unique( curve[ :, 1 ] ) )
        @warn "Duplicate entries in the terms of the attrition curve, not making any changes."
        return false
    end  # if length( curve[ :, 1 ] ) != length( unique( curve[ :, 1 ] ) )

    # Generate curve dictionary.
    curveDict = Dict{Float64, Float64}()

    for ii in eachindex( curve[ :, 1 ] )
        curveDict[ curve[ ii, 1 ] ] = curve[ ii, 2 ]
    end  # for ii in eachindex( curve[ :, 1 ] )

    return setAttritionCurve!( attrition, curveDict )

end  # setAttritionCurve!( attrition, curve )


function Base.show( io::IO, attrition::Attrition )::Nothing

    print( io, "Attrition scheme '", attrition.name, "'" )

    if all( attrition.rates .== 0.0 )
        print( io, "\n  No attrition." )
        return
    end  # if all( attrition.rates .== 0.0 )

    print( io, "\n  Attrition period: ", attrition.period )

    if length( attrition.rates ) == 1
        print( io, "\n  Attrition rate: ", attrition.rates[ 1 ] * 100.0, "%" )
    else
        print( io, "\n  Attrition curve" )

        for ii in eachindex( attrition.rates )
            print( io, "\n    term: ", attrition.curvePoints[ ii ], ";" )
            print( io, " rate: ", attrition.rates[ ii ] * 100, "%" )
        end  # for ii in eachindex( attrition.rates )
    end  # if length( attrition.rates ) == 1

    return

end  # Base.show( io, attrition )


include( joinpath( privPath, "attrition.jl" ) )