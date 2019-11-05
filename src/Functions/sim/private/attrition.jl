function generateTimeToAttrition( attrition::Attrition, nVals::Int )

    urand = rand( nVals )
    nSections = map( u -> findlast( u .<= attrition.gammas ), urand )
    result = map( 1:nVals ) do ii
        nSection = nSections[ ii ]
        return attrition.lambdas[ nSection ] == 0 ? +Inf :
            attrition.curvePoints[ nSection ] -
            log( urand[ ii ] / attrition.gammas[ nSection ] ) /
                attrition.lambdas[ nSection ]
    end  # map( 1:nVals ) do ii

    return result ./ attrition.period

end  # generateTimeToAttrition( attrition, nVals )