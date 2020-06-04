function generateValues( attribute::Attribute, nVals::Int )

    pVals = attribute.initValueWeights ./ sum( attribute.initValueWeights )
    return attribute.initValues[rand( attribute.initRNG, Categorical( pVals ),
        nVals )]

end  # function generateValues( attribute, nVals )