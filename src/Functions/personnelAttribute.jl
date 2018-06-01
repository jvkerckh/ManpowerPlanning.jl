# This file holds the definition of the functions pertaining to the
#   PersonnelAttribute type.

# The functions of the PersonnelAttribute type require no additional types.
requiredTypes = [ "personnelAttribute" ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( dirname( Base.source_path() ), "..", "Types",
            reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end  # for reqType in requiredTypes


export setAttrValues!,
       addValueToAttr!,
       removeValueFromAttr!,
       generateAttrValue


"""
```
setAttrValues!( attr::PersonnelAttribute,
                vals::Dict{String, Float64} )
```
This function sets the list of possible values of the personnel attribute `attr`
to the list given in `vals`. The function ignores values which have an
accompanying probability weight ⩽ 0, and will reweight the valid entries in the
list such that their sum of probabilities equals 1. If no valid entries remain,
the list is wiped, and a warning is issued.

This function returns `nothing`.
"""
function setAttrValues!( attr::PersonnelAttribute,
    vals::Dict{String, Float64} )::Void

    # Remove the entries with a probability weight <= 0.
    tmpVals = Dict{String, Float64}()
    foreach( val -> if vals[ val ] > 0 tmpVals[ val ] = vals[ val ] end,
        keys( vals ) )
        # XXX Actually removing them can give trouble.

    # Normalise the probability weights of the entries to 1.
    if isempty( tmpVals )
        warn( "No valid entries in list of possible values for the attribute. Wiping the list." )
    else
        probMass = sum( map( val -> tmpVals[ val ], keys( tmpVals ) ) )
        foreach( val -> tmpVals[ val ] /= probMass, keys( tmpVals ) )
    end

    attr.values = tmpVals
    return

end  # setValues!( attr, vals )


"""
```
addValueToAttr!( attr::PersonnelAttribute,
                 val::String,
                 prob::T )
    where T <: Real
```
This function adds a possible initialisation value to the personnel attribute
`attr`. The new value is `val` and will be generated with probability `prob`
which must lie between 0.0 and 1.0 (endpoints exclusive). The generation
probabilities of the other possible values are adjusted accordingly by a factor
`1 - prob`.

If an impossible probability is entered, the function does nothing and returns a
warning. If the value to be added is already a possibility, its probability will
be adjusted, as well as the probability of the other possible values. If the
list was empty, the new value will have probability 100%.

The function returns `nothing`.
"""
function addValueToAttr!( attr::PersonnelAttribute, val::String, prob::T )::Void where T <: Real

    # Check if the entered probabilty makes sense.
    if ( prob <= 0 ) || ( prob >= 1 )
        warn( "Probability of value occurring must be between 0 and 1. Not adding value." )
        return
    end  # if ( prob <= 0 ) || ( prob >= 1 )

    # Check if there are already entries in the list.
    if isempty( attr.values )
        attr.values[ val ] = 1
        return
    end  # if isempty( attr.values )

    # Check if the new value is already in the list..
    if haskey( attr.values, val )
        warn( "Value is already in the list, changing probabilities." )
    end  # if haskey( attr.values, val )

    # Set cumulative probabilty of existing entries to 1 - prob
    adjFactor = ( 1 - prob ) / ( 1 - get( attr.values, val, 0 ) )
    foreach( tmpVal -> attr.values[ tmpVal ] *= adjFactor, keys( attr.values ) )
    attr.values[ val ] = prob
    return

end  # addValueToAttr!( attr, val, prob )


"""
```
removeValueFromAttr!( attr::PersonnelAttribute,
                      val::String )
```
This function removes the value `val` from the possible values of the personnel
attribute `attr`, and adjusts the probabilities accordingly.

This function returns `nothing`.
"""
function removeValueFromAttr!( attr::PersonnelAttribute, val::String )::Void

    # Do nothing if the value isn't in the list of possible values.
    if !haskey( attr.values, val )
        return
    end  # if !haskey( attr.values, val )

    prob = attr.values[ val ]
    foreach( tmpVal -> attr.values[ tmpVal ] /= 1 - prob, keys( attr.values ) )
    delete!( attr.values, val )
    return

end  # removeValueFromAttr!( attr, val )


function Base.show( io::IO, attr::PersonnelAttribute )

    print( io, "  Attribute: $(attr.name) (" )
    print( io, attr.isFixed ? "fixed" : "variable" )
    print( io, ")" )

    if isempty( attr.values )
        print( io, "\n    No possible values" )
        return
    end  # if isempty( attr.values )

    print( io, "\n    Values:" )
    foreach( val -> print( io, "\n      $val ($(signif(attr.values[ val ] * 100, 3))%)" ),
        keys( attr.values ) )

end  # show( io, attr )


"""
```
generateAttrValue( attr::PersonnelAttribute )
```
This function generates a value for the personnel attribute `attr` and returns
it as a `String`. If the attribute has no possible initialisation values, the
function returns `nothing`.
"""
function generateAttrValue( attr::PersonnelAttribute )

    if isempty( attr.values )
        return
    end  # if isempty( attr.values )

    vals = collect( keys( attr.values ) )
    return vals[ rand( Categorical( map( val -> attr.values[ val ], vals ) ) ) ]

end  # generateAttrValue( attr )


# ==============================================================================
# Non-exported methods.
# ==============================================================================


function readAttribute( s::Taro.Sheet, sLine::T ) where T <: Integer

    newAttr = PersonnelAttribute( s[ "B", sLine ], s[ "B", sLine + 1 ] == 1 )
    nOpts = Int( s[ "B", sLine + 2 ] )

    if nOpts > 0
        attrDict = Dict{String, Float64}()
        foreach( ii -> attrDict[ s[ "B", sLine + 4 + ii ] ] =
            s[ "C", sLine + 4 + ii ], 1:nOpts )
        setAttrValues!( newAttr, attrDict )
    # If there are no options, the attribute is by definition a variable
    #   attribute.
    else
        newAttr.isFixed = false
    end  # if nOpts > 0

    return newAttr, sLine + 6 + nOpts

end  # readAttribute( s, sLine )
