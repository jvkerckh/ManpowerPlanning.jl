# This file holds the definition of the functions pertaining to the Attribute
#   type.

export  setAttributeName!,
        addPossibleAttributeValue!,
        removePossibleAttributeValue!,
        clearPossibleAttributeValues!,
        setPossibleAttributeValues!,
        addInitialAttributeValue!,
        removeInitialAttributeValue!,
        clearInitialAttributeValues!,
        setInitialAttributeValues!


"""
```
setAttributeName!(
    attribute::Attribute,
    name::String )
```
This function sets the name of the personnel attribute `attribute` to `name`.

This function returns `true`, indicating the name has been set successfully.
"""
function setAttributeName!( attribute::Attribute, name::String )::Bool

    attribute.name = name
    return true

end  # setAttributeName!( attribute, name )


"""
```
addPossibleAttributeValue!(
    attribute::Attribute,
    values::String... )
```
This function adds the values in `values` to the list of possible attribute values of the personnel attribute `attribute`, assuming they aren't in the list already.

This function returns `true` if any of the values has been added successfully, `false` if all of them were already in the list.
"""
function addPossibleAttributeValue!( attribute::Attribute,
    values::String... )::Bool

    tmpVals = unique( collect( values ) )
    inList = map( val -> val ∈ attribute.possibleValues, tmpVals )

    if all( inList )
        return false
    end  # if all( inList )

    append!( attribute.possibleValues, tmpVals[.!inList] )
    return true

end  # addPossibleAttributeValue!( attribute, values )


"""
```
removePossibleAttributeValue!(
    attribute::Attribute,
    values::String... )
```
This function removes the values in `values` from the list of possible attribute values of the personnel attribute `attribute`, assuming they are in the list. This function will also remove these values from the initialisation values if necessary.

This function returns `true` if any of the values has been removed successfully, `false` if none of them were in the list to begin with.
"""
function removePossibleAttributeValue!( attribute::Attribute,
    values::String... )::Bool

    toDelete = map( val -> val ∈ values, attribute.possibleValues )

    if !any( toDelete )
        return false
    end  # if !any( toDelete )

    deleteat!( attribute.possibleValues, toDelete )
    return true

end  # removePossibleAttributeValue!( attribute, values )


"""
```
clearPossibleAttributeValues!( attribute::Attribute )
```
This function clears the list of possible values of the personnel attribute `attribute`. This function also clears the initialisation values.

This function returns `true`, indicating the list of possible values has been cleared successfully.
"""
function clearPossibleAttributeValues!( attribute::Attribute )::Bool

    empty!( attribute.possibleValues )
    return true

end  # clearPossibleAttributeValues!( attribute::Attribute )


"""
```
setPossibleAttributeValues!(
    attribute::Attribute,
    values::Vector{String} )
```
This function sets the list of possible values of the personnel attribute `attribute` to the list given in `values`. This function will also remove those entries among the initialisation values that aren't found in the new list of possible values.

This function returns `true`, indicating the possible values have been set successfully.
"""
function setPossibleAttributeValues!( attribute::Attribute,
    values::Vector{String} )::Bool

    attribute.possibleValues = unique( values )
    return true

end  # setPossibleAttributeValues!( attribute, values )


"""
```
addInitialAttributeValue!(
    attribute::Attribute,
    valWeights::Tuple{String, Float64}... )
```
This function adds each value/weight pair in `valWeights` to the initial values of the personnel attribute `attribute`. Values that aren't in the list of possible values get added as well.

Some remarks:
* If multiple pairs have the same value, this function gives a warning and makes no changes.
* Values with negative weights get ignored.
* If a value is already in the list of initial values, its weight gets updated.

This function returns `true` if it successfully adds initial values and/or updates their weights, and `false` if it makes no changes.
"""
function addInitialAttributeValue!( attribute::Attribute,
    valWeights::Tuple{String, Float64}... )::Bool

    newVals = map( valWeight -> valWeight[1], collect( valWeights ) )
    newWeights = map( valWeight -> valWeight[2], collect( valWeights ) )
    addPossibleAttributeValue!( attribute, newVals... )

    if length( newVals ) != length( unique( newVals ) )
        @warn "Duplicate entries in the value/weight list, not making any changes."
        return false
    end  # if length( newVals ) != length( unique( newVals ) )

    # Filter out values with negative weights.
    isPosWeight = newWeights .> 0
    newVals = newVals[isPosWeight]
    newWeights = newWeights[isPosWeight]

    if isempty( newVals )
        return false
    end  # if isempty( newVals )

    # Add the new values to the list of initial values.
    isNewVal = map( newVal -> newVal ∉ attribute.initValues, newVals )
    append!( attribute.initValues, newVals[isNewVal] )
    append!( attribute.initValueWeights, zeros( Float64, count( isNewVal ) ) )

    # Add/update the weights where needed.
    valInds = findfirst.( map( newVal -> newVal .== attribute.initValues,
        newVals ) )
    attribute.initValueWeights[valInds] = newWeights

    createInitialValueDistribution( attribute )
    return true

end  # addInitialAttributeValue!( attribute, valWeights )

"""
```
addInitialAttributeValue!(
    attribute::Attribute,
    val::String,
    weight::Real )
```
This function adds the value `val` as an initial value with weight `weight` to the personnel attribute `attribute`.

All remarks for the version of this function with `Tuples` are valid here as well.

This function returns `true` if it successfully adds the initial value or updates its weight, and `false` if it makes no changes.
"""
addInitialAttributeValue!( attribute::Attribute, val::String,
    weight::Real )::Bool = addInitialAttributeValue!( attribute,
    (val, Float64( weight )) )


"""
```
removeInitialAttributeValue!(
    attribute::Attribute,
    values::String... )
```
This function removes the values in `values` from the list of initial values of the personnel attribute `attribute`, insofar as those values are on the list.

This function returns `true` if any values have been successfully removed from the list of initial values, and `false` if none were removed.
"""
function removeInitialAttributeValue!( attribute::Attribute,
    values::String... )::Bool

    removeVals = map( val -> val ∈ values, attribute.initValues )

    if !any( removeVals )
        return false
    end  # if !any( removeVals )

    deleteat!( attribute.initValues, removeVals )
    deleteat!( attribute.initValueWeights, removeVals )
    createInitialValueDistribution( attribute )
    return true

end  # removeInitialAttributeValue!( attribute, values )


"""
```
clearInitialAttributeValues!( attribute::Attribute )
```
This function clears the list of initial values of the personnel attribute `attribute`.

This function returns `true`, indicating the list of initial values has been cleared successfully.
"""
function clearInitialAttributeValues!( attribute::Attribute )::Bool

    empty!( attribute.initValues )
    empty!( attribute.initValueWeights )
    return true

end  # clearInitialAttributeValues!( attribute::Attribute )


"""
```
setInitialAttributeValues!(
    attribute::Attribute,
    valWeights::Dict{String, T} )
    where T <: Real
```
This function sets the list of interval values, with associated weights, of the personnel attribute `attribute` to the pairs in `valWeights`. Values with a negative weight are ignored. If the dictionary contains no valid entires, this function makes no changes. Hence, to clear the list of initial values, `clearInitialAttributeValues!` should be used.

This function returns `true` if the list of initial values is successfully set, and `false` if the dictionary contained no valid entries.
"""
function setInitialAttributeValues!( attribute::Attribute,
    valWeights::Dict{String, T} )::Bool where T <: Real

    newVals = filter( val -> valWeights[val] > 0,
        collect( keys( valWeights ) ) )

    if isempty( newVals )
        return false
    end  # if isempty( newVals )

    addPossibleAttributeValue!( attribute, newVals... )
    attribute.initValues = newVals
    attribute.initValueWeights = map( val -> Float64( valWeights[val] ),
        newVals )
    createInitialValueDistribution( attribute )
    return true

end  # setInitialAttributeValues!( attribute, valWeights )

"""
```
setInitialAttributeValues!(
    attribute::Attribute,
    valWeights::Tuple{String, Float64}... )
```
This function sets the list of interval values, with associated weights, of the personnel attribute `attribute` to the pairs in `valWeights`.

If the list of initial values contains duplicate entries, the function will issue a warning and not make any changes. All remarks associated with the version of this function with a `Dict` are valid for this version.

This function returns `true` if the list of initial values is successfully set, and `false` if the list of initial values contained no valid entries.
"""
function setInitialAttributeValues!( attribute::Attribute,
    valWeights::Tuple{String, Float64}... )::Bool

    # Check for duplicates.
    newVals = map( valWeight -> valWeight[1], collect( valWeights ) )

    if length( newVals ) != length( unique( newVals ) )
        @warn "Duplicate entries in the value/weight list, not making any changes."
        return false
    end  # if length( newVals ) != length( unique( newVals ) )

    # Convert the val/weight pairs to a dictionary.
    valWeightDict = Dict{String, Float64}()

    for valWeight in valWeights
        valWeightDict[valWeight[1]] = valWeight[2]
    end  # for valWeight in valWeights

    return setInitialAttributeValues!( attribute, valWeightDict )

end  # setInitialAttributeValues!( attribute, valWeights )

"""
```
setInitialAttributeValues!(
    attribute::Attribute,
    values::Vector{String},
    weights::Vector{T} )
    where T <: Real
```
This function sets the list of interval values, with associated weights, of the personnel attribute `attribute` to the list in `values`. The weights associated with each value are given through the vector `weights`.

If the vector of initial values and weights are of unequal length, the function will issue a warning and not make any changes.

If the list of initial values contains duplicate entries, the function will issue a warning and not make any changes.

All remarks associated with the version of this function with a `Dict` are valid for this version.

This function returns `true` if the list of initial values is successfully set, and `false` if the list of initial values contained no valid entries.
"""
function setInitialAttributeValues!( attribute::Attribute,
    values::Vector{String}, weights::Vector{T} )::Bool where T <: Real

    if length( values ) != length( weights )
        @warn "Mismatched lengths of vector of initial values and weights, not making any changes."
        return false
    end  # if length( values ) != length( weights )

    if length( values ) != length( unique( values ) )
        @warn "Duplicate entries in the initial value list, not making any changes."
        return false
    end  # if length( values ) != length( unique( values ) )

    # Convert the val/weight pairs to a dictionary.
    valWeightDict = Dict{String, Float64}()

    for ii in eachindex( values )
        valWeightDict[values[ii]] = weights[ii]
    end  # for ii in eachindex( values )

    return setInitialAttributeValues!( attribute, valWeightDict )

end  # setInitialAttributeValues!( attribute, values, weights )


function Base.show( io::IO, attribute::Attribute )::Nothing

    print( io, "Attribute: ", attribute.name )

    if isempty( attribute.possibleValues )
        print( io, "\n  Attribute can't take any values." )
        return
    end  # if isempty( attribute.possibleValues )

    print( io, "\n  Possible values: ", join( attribute.possibleValues, ", " ) )

    if isempty( attribute.initValues )
        print( io, "\n  No possible initial values" )
        return
    end  # if isempty( attribute.initValues )

    print( io, "\n  Initial values:" )
    initValueProbs = 100.0 * attribute.initValueWeights /
        sum( attribute.initValueWeights )

    for ii in eachindex( attribute.initValues )
        print( io, "\n    ", attribute.initValues[ii], " (weight ",
            attribute.initValueWeights[ii], " / ",
            round( initValueProbs[ii], sigdigits = 4 ), "%)" )
    end  # for ii in eachindex( attribute.initValues )

    return

end  # show( io, attribute )


include( joinpath( privPath, "attribute.jl" ) )