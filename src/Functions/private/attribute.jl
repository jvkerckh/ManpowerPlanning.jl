"""
```
createInitialValueDistribution( attribute::Attribute )
```
This function initialises the `initValueDist` field of the personnel attribute `attribute`, using the information int he other fields of the attribute object.

This function returns `nothing`.
"""
function createInitialValueDistribution( attribute::Attribute )::Nothing

    probs = attribute.initValueWeights / sum( attribute.initValueWeights )
    attribute.initValueDist = Categorical( probs )
    return

end  # createInitialValueDistribution( attribute )


"""
```
isAttributeValuePossible(
    attribute::Attribute,
    value::String )
```
This function checks if the attribute `attribute` van have the value `value`.

This function returns a `Bool`, the result of the check.
"""
isAttributeValuePossible( attribute::Attribute, value::String )::Bool =
    value ∈ attribute.possibleValues