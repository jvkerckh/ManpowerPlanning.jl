"""
```
computeDistPars( attrition::Attrition )
```
This function pre-computes some reoccurring parameters of the distribution of
the time to attrition of the attrition scheme `attrition`.

This function returns `nothing`.
"""
function computeDistPars( attrition::Attrition )::Nothing

    attrition.lambdas = - log.( 1 .- attrition.rates ) / attrition.period
    gammas = attrition.curvePoints[ 2:end ] -
        attrition.curvePoints[ 1:(end - 1) ]
    gammas .*= - attrition.lambdas[ 1:(end - 1 ) ]
    gammas = exp.( gammas )
    attrition.gammas = vcat( 1.0, cumprod( gammas ) )
    return

end  # computeDistPars( attrition )
