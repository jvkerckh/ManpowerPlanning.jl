function generateValues( attribute::Attribute, nVals::Int )

    pVals = attribute.initValueWeights ./ sum( attribute.initValueWeights )
    return attribute.initValues[rand( Categorical( pVals ), nVals )]

end  # function generateValues( attribute, nVals )