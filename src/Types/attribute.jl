# This file defines the Attribute type. This type defines an attribute of
#   personnel members (field in the database).

export Attribute

"""
The `Attribute` type defines an attribute of the personnel members in the simulation -- equivalent to a field in the personnel database.

The type contains the following fields:
* `name::String`: the name of the attribute.
* `possibleValues::Vector{String}`: the vector of possible values the attribute can take.
* `initValues::Vector{String}`: the values that the attribute can take upon initialisation.
* `initValueWeights::Vector{String}`: the weights of each initial value, in the same order as the `initValues` vector.

Two additional fields are used to speed up computations:
* `initValueDist::Categorical`: a categorical distribution object which can be sampled whenever an initial value is needed. This object is created in advance and stored to avoid the overhead of computing the probabilities and creating the distribution object every time an initial value must be sampled.
* `initRNG::MersenneTwister`: the random stream that generates the initial values for the attribute.

Constructor:
```
Attribute( name::String )
```
This constructor generates an `Attribute` object with name `name` and no defined possible values.
"""
mutable struct Attribute

    name::String
    # isOrdinal::Bool
    possibleValues::Vector{String}
    initValues::Vector{String}
    initValueWeights::Vector{Float64}

    initValueDist::Categorical
    initRNG::MersenneTwister


    # Basic constructor.
    function Attribute( name::String; # isOrdinal = false
        )::Attribute

        newAttr = new()
        newAttr.name = name
        # newAttr.isOrdinal = isOrdinal
        newAttr.possibleValues = Vector{String}()
        newAttr.initValues = Vector{String}()
        newAttr.initValueWeights = Vector{Float64}()
        newAttr.initValueDist = Categorical( [1.0] )
        newAttr.initRNG = MersenneTwister()
        return newAttr

    end  # Attribute( name )

end  # type Attribute

# ? Is the `isFixed` field still used anywhere? Not really.
# * `isOrdinal::Bool`: a flag that indicates if the attribute has ordinal values, that is, string values that have a hierarchical ordering.
# If the field `isOrdinal` is `true`, these values must be ordered from lowest to highest in the hierarchy.