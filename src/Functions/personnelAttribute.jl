# This file holds the definition of the functions pertaining to the
#   PersonnelAttribute type.

# The functions of the PersonnelAttribute type require no additional types.
requiredTypes = [ "personnelAttribute" ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( typePath, reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end  # for reqType in requiredTypes


export setOrdinal!,
       setPossibleValues!,
       setAttrValues!,
       setFixed!,
       addValueToAttr!,
       removeValueFromAttr!,
       generateAttrValue


"""
```
setOrdinal!( attr::PersonnelAttribute,
             isOrdinal::Bool )
```
This function sets the isOrdinal flag of the personnel attribute `attr` to
`isOrdinal`.

This function returns `nothing`.
"""
function setOrdinal!( attr::PersonnelAttribute, isOrdinal::Bool )::Void

    attr.isOrdinal = isOrdinal
    return

end  # setOrdinal!( attr, isOrdinal )


"""
```
setPossibleValues!( attr::PersonnelAttribute,
                    vals::Vector{String} )
```
This function sets the list of possible values of the personnel attribute `attr`
to the list given in `vals`.

This function returns `nothing`.
"""
function setPossibleValues!( attr::PersonnelAttribute,
    vals::Vector{String} )::Void

    attr.possibleValues = unique( vals )
    return

end  # setPossibleValues!( attr, vals )


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

end  # setAttrValues!( attr, vals )


"""
```
setFixed!( attr::PersonnelAttribute,
           isFixed::Bool )
```
This function sets the isFixed flag of the personnel attribute `attr` to
`isFixed`.

This function returns `nothing`.
"""
function setFixed!( attr::PersonnelAttribute, isFixed::Bool )::Void

    attr.isFixed = isFixed
    return

end  # setFixed!( attr, isFixed )


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

    if isempty( attr.possibleValues )
        print( io, "\n    Attribute can't take any values." )
        return
    end  # if isempty( attr.possibleValues )

    print( io, "\n    Possible values: " )
    print( io, join( attr.possibleValues, ", " ) )

    if isempty( attr.values )
        print( io, "\n    No possible initial values" )
        return
    end  # if isempty( attr.values )

    print( io, "\n    Initial values:" )
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

function readAttribute( sheet::XLSX.Worksheet, attrCat::XLSX.Worksheet,
    sLine::Integer )::PersonnelAttribute

    newAttr = PersonnelAttribute( string( sheet[ "A$sLine" ] ) )
    catLine = sheet[ "B$sLine" ]

    if isa( catLine, Missings.Missing )  # XXX Check what happens with N/A
        error( "Attribute '$(newAttr.name)' not defined in catalogue." )
    end  # if isa( catLine, Void )

    catLine = catLine + 1
    setFixed!( newAttr, attrCat[ "B$catLine" ] == "YES" )
    setOrdinal!( newAttr, attrCat[ "C$catLine" ] == "YES" )
    nVals = attrCat[ "E$catLine" ]
    vals = strip.( string.( attrCat[ XLSX.CellRange( catLine, 6, catLine,
        5 + nVals ) ][ : ] ) )
    # vals = Vector{String}( nVals )
    #
    # for ii in 1:nVals
    #     vals[ ii ] = strip( attrCat[ XLSX.CellRef( catLine, 5 + ii ) ] )
    # end  # for ii in 1:nVals

    setPossibleValues!( newAttr, vals )
    ii = 1
    nInitVals = sheet[ "B$(sLine + 2)" ]
    vals = Dict{String, Float64}()

    for ii in (1:nInitVals) + 2
        val = string( sheet[ XLSX.CellRef( sLine, ii ) ] )
        weight = sheet[ XLSX.CellRef( sLine + 1, ii ) ]

        if isa( weight, Real )
            vals[ val ] = weight + get( vals, val, 0.0 )
        end  # if isa( weight, Real )
    end  # for ii in (1:nInitVals) + 2

    setAttrValues!( newAttr, vals )
    return newAttr

end  # readAttribute( sheet, attrCat, sLine )
