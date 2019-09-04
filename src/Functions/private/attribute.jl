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