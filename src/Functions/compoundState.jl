# This file holds the definition of the functions pertaining to the
#   CompoundState type.

# The functions of the CompoundState type require the State type.
requiredTypes = [ "state", "compoundState" ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( typePath, reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end  # for reqType in requiredTypes


export setName!,
       setStateTarget!,
       addStateToCompound!,
       removeStateFromCompound!,
       clearStatesFromCompound!,
       generateHierarchy


"""
```
setName!( compState::CompoundState,
          name::String )
```
This function sets the name of the compound state `compState` to `name`.

This function returns `nothing`.
"""
function setName!( compState::CompoundState, name::String )::Void

    compState.name = name
    return

end  # setName!( compState::CompoundState, name::String )


"""
```
setStateTarget!( compState::CompoundState,
                 target::T )
    where T <: Integer
```
This function sets the target number of personnel members in compound state
`compState` to `target`. If the number is less than zero, it means there's no
target.

This function returns `nothing`.
"""
function setStateTarget!( compState::CompoundState, target::T )::Void where T <: Integer

    compState.stateTarget = target < 0 ? -1 : target
    return

end  # setStateTarget!( compState, target )


"""
```
addStateToCompound!( compState::CompoundState,
                     stateList::String... )
```
This function adds the states in `stateList` to the list of states composing the
compound state `compState`.

This function returns `nothing`.
"""
function addStateToCompound!( compState::CompoundState,
    stateList::String... )::Void

    for stateName in stateList
        if stateName ∉ compState.stateList
            push!( compState.stateList, stateName )
        end  # if stateName ∉ compState.stateList
    end  # for stateName in stateList

    return

end  # addStateToCompound!( compState, stateList )


"""
```
removeStateFromCompound!( compState::CompoundState,
                          stateList::String... )
```
This function removes the states in `stateList` from the list of states
composing the compound state `compState`.

This function returns `nothing`.
"""
function removeStateFromCompound!( compState::CompoundState,
    stateList::String... )::Void

    stateFlags = map( stateName -> stateName ∈ stateList, compState.stateList )
    deleteat!( compState.stateList, stateFlags )
    return

end  # removeStateFromCompound!( compState, stateList )


"""
```
clearStatesFromCompound!( compState::CompoundState )
```
This function clears the list of states composing the compound state
`compState`.

This function returns `nothing`.
"""
function clearStatesFromCompound!( compState::CompoundState )::Void

    empty!( compState.stateList )
    return

end  # clearStatesFromCompound!( compState )


"""
```
generateHierarchy( mpSim::ManpowerSimulation,
                   attrList::String... )
```
This is a shorthand functin for `generateHierarchy( mpSim, true, attrList )`.
"""
function generateHierarchy( mpSim::ManpowerSimulation,
    attrList::String... )::Void

    return generateHierarchy( mpSim, true, attrList... )

end  # generateHierarchy( mpSim, attrList... )


"""
```
generateHierarchy( mpSim::ManpowerSimulation,
                   useCat::Bool,
                   attrList::String... )
```
This function generates a hierarchy of compound states in the manpower
simulation `mpSim`, splitting them up by the values of the attributes in
`attrList`, in the order given. If `useCat` is `true`, the function will attempt
to get the names for the compound states where available, and will generate
descriptive names otherwise.

This function returns `nothing`.
"""
function generateHierarchy( mpSim::ManpowerSimulation, useCat::Bool,
    attrList::String... )::Void

    # Retain only the attributes that actually exist in the simulation.
    attrsInSim = vcat( mpSim.initAttrList, mpSim.otherAttrList )
    attrNames = map( attr -> attr.name, attrsInSim )
    tmpAttrList = unique( collect( attrList ) )
    filter!( attrName -> attrName ∈ attrNames, tmpAttrList )

    if isempty( tmpAttrList )
        return
    end  # if isempty( tmpAttrList )

    attrs = similar( tmpAttrList, PersonnelAttribute )

    # Get the attributes with the retained names.
    for ii in eachindex( tmpAttrList )
        attrInd = findfirst( attr -> attr.name == tmpAttrList[ ii ],
            attrsInSim )
        attrs[ ii ] = attrsInSim[ attrInd ]
    end  # for ii in eachindex( tmpAttrList )

    # Create a list of all the states in the catalogue.
    catStateList = Dict{String, Array{String}}()

    if useCat
        XLSX.openxlsx( mpSim.catFileName ) do catXF
            stateCat = catXF[ "States" ]
            sLine = 2

            while isa( stateCat[ "A$sLine" ], String )
                stateName = stateCat[ "A$sLine" ]
                nAttrs = stateCat[ "G$sLine" ]
                catStateList[ stateName ] = Array{String}( nAttrs, 2 )

                for ii in 1:nAttrs
                    jj = 6 + ii * 2
                    catStateList[ stateName ][ ii, : ] = [
                        stateCat[ XLSX.CellRef( sLine, jj ) ],
                        stateCat[ XLSX.CellRef( sLine, jj + 1 ) ] ]
                end  # for ii in 1:nAttrs

                sLine += 1
            end  # while isa( catXF[ "A$sLine" ], String )
        end  # XLSX.openxlsx( mpSim.catFileName ) do catXF
    end  # if useCat

    return partitionByAttribute( collect( keys( mpSim.stateList ) ), attrs, 1,
        mpSim, catStateList, collect( keys( catStateList ) ) )

end  # generateHierarchy( mpSim, useCat, attrList )


function Base.show( io::IO, compState::CompoundState )

    print( io, "    Compound state: " * compState.name )

    if isempty( compState.stateList )
        print( io, "\n      No component states in compound state." )
    else
        print( io, "\n      Component states: " *
            join( compState.stateList, ", " ) )
    end  # if isempty( compState.stateList )

    if compState.stateTarget >= 0
        print( io, "\n      Personnel target: $(compState.stateTarget) personnel members" )
    else
        print( io, "\n      No personnel target for compound state." )
    end  # if compState.stateTarget >= 0

end  # show( io, compoundState )


# ==============================================================================
# Non-exported methods.
# ==============================================================================

"""
```
isPersonnelOfState( persAttrs::Dict{String, Any},
                    compState::CompoundState,
                    mpSim::ManpowerSimulation )
```
This function tests if the person with attributes in `persAttrs` belongs to any
of the states making up the compound state `compStates`, where the base states
are defined in the manpowre simulation `mpSim`.

This function returns a `Bool`, the result of the test.
"""
function isPersonnelOfState( persAttrs::Dict{String, Any},
    compState::CompoundState, mpSim::ManpowerSimulation )::Bool

    return any( stateName -> isPersonnelOfState( persAttrs,
        mpSim.stateList[ stateName ] ), compState.stateList )

end  # isPersonnelOfState( persAttrs, compState, mpSim )


"""
```
readCompoundState( sheet::XLSX.Worksheet,
                   sLine::Int )
```
This function reads and processes the custom compound state defined in the Excel
worksheet `sheet` on line `sLine`.

This function returns a `CompoundState` object, the processed compound state.
"""
function readCompoundState( sheet::XLSX.Worksheet, sLine::Int )::CompoundState

    newCompState = CompoundState( sheet[ "H$sLine" ] )
    nStates = sheet[ "J$sLine" ]
    stateList = sheet[ XLSX.CellRange( sLine, 11, sLine, 10 + nStates ) ]
    addStateToCompound!( newCompState, stateList... )

    return newCompState

end  # readCompoundState( sheet::XLSX.worksheet, sLine::Int )::CompoundState


"""
```
processCompoundStates( mpSim::ManpowerSimulation )
```
This function processes the compound states that have been configured based on a
definition in the state catalogue.

This function returns `nothing`.
"""
function processCompoundStates( mpSim::ManpowerSimulation )::Void

    stateList = collect( keys( mpSim.stateList ) )

    for compStateName in keys( mpSim.compoundStates )
        compState = mpSim.compoundStates[ compStateName ]
        compStateReqs = compState.requirements

        isCompState = map( stateList ) do stateName
            stateReqs = mpSim.stateList[ stateName ].requirements
            return all( keys( compStateReqs ) ) do attrName
                return haskey( stateReqs, attrName ) &&
                    ( stateReqs[ attrName ] == compStateReqs[ attrName ] )
            end  # all( keys( compStateReqs ) ) do attrName
        end  # map( stateList ) do stateName

        addCompoundState!( mpSim, compStateName, -1,
            stateList[ isCompState ]... )
    end  # for compState in mpSim.compoundStates

    return

end  # processCompoundStates( mpSim )


"""
```
readHierarchy( sheet::XLSX.Worksheet,
               mpSim::ManpowerSimulation )
```
This function reads the attributes for forming a compound state hierarchy from
the Excel sheet `sheet`, and generates the hierarchy for manpower simulation
`mpSim`.

This function returns `nothing`.
"""
function readHierarchy( sheet::XLSX.Worksheet, mpSim::ManpowerSimulation )::Void

    nAttrs = sheet[ "F4" ]
    attrList = sheet[ XLSX.CellRange( 7, 5, 6+ nAttrs, 5 ) ]
    generateHierarchy( mpSim, attrList... )
    return

end  # readHierarchy( sheet, mpSim )


"""
```
partitionByAttribute( stateList::Vector{String},
                      attrList::Vector{PersonnelAttribute},
                      level::Int,
                      mpSim::ManpowerSimulation,
                      catStateList::Dict{String, Array{String}},
                      catStateNameList::Vector{String},
                      name::String = "",
                      partition::Array{String} = Array{String}( 0, 2 ) ):
```
This function generates a partition of the states in `stateList` and creates
compound states for those parts containing more than one base state. The other
parameters are:
* `stateList`: the ordered attributes for the hierarchy.
* `level`: the level of the hierarchy that needs to be generated.
* `mpSim`: the manpower simulation.
* `catStateList`: a list of all the states in the catalogue with the
  requirements for being in that state.
* `catStateNameList`: a list of all the names of the states in the catalogue.
* `name`: the current auto-generated name for the compound state containing all
  the states in `stateList`. This is not necessarily the name that is used.
* `partition`: the attributes and their values definingthe compound state
  containing all the states in `stateList`.

This function returns `nothing`.
"""
function partitionByAttribute( stateList::Vector{String},
    attrList::Vector{PersonnelAttribute}, level::Int,
    mpSim::ManpowerSimulation, catStateList::Dict{String, Array{String}},
    catStateNameList::Vector{String}, name::String = "",
    partition::Array{String} = Array{String}( 0, 2 ) )::Void

    statePartition = Dict{String, Vector{String}}()
    listOfStates = map( stateName -> mpSim.stateList[ stateName ], stateList )
    attr = attrList[ level ]
    statePartitioned = falses( stateList )

    # Generate the partition.
    for attrVal in attr.possibleValues
        stateInds = map( listOfStates ) do state
            return haskey( state.requirements, attr.name ) &&
                ( attrVal ∈ state.requirements[ attr.name ] )
        end  # map( listOfStates ) do state

        if any( stateInds )
            statePartition[ attrVal ] = stateList[ stateInds ]
        end  # if any( stateInds )

        statePartitioned .|= stateInds
    end  # for attrVal in attrList[ level ].possibleValues

    isPartitionProper = !isempty( statePartition )

    # Generate part for states with attribute not filled in.
    if !all( statePartitioned )
        statePartition[ "undefined" ] = stateList[ .!statePartitioned ]
    end  # if !all( statePartitioned )

    # Create the partition and recurse.
    for attrVal in keys( statePartition )
        newName = name
        newPart = partition

        if isPartitionProper
            newName *= ( name == "" ? "" : "; " ) * "$(attr.name):$attrVal"
            newPart = vcat( partition, [ attr.name attrVal ] )
        end  # if isPartitionProper

        # Check if this compound state already has a name.
        nPart = size( newPart )[ 1 ]
        tmpStateNames = filter( catStateNameList ) do stateName
            nReqs = size( catStateList[ stateName ] )[ 1 ]
            return nPart == nReqs
        end  # filter( catStateNameList ) do stateName

        for ii in 1:nPart
            tmpStateNames = filter( tmpStateNames ) do stateName
                stateReqs = catStateList[ stateName ]
                attrIndex = findfirst( newPart[ ii, 1 ] .== stateReqs[ :, 1 ] )

                if attrIndex == 0
                    return false
                end  # if attrIndex == 0

                return newPart[ ii, 2 ] == stateReqs[ attrIndex, 2 ]
            end  # filter( tmpStateNames ) do stateName
        end  # for ii in 1:nPart

        # Generate compound state.
        if length( statePartition[ attrVal ] ) > 1
            if isPartitionProper
                addCompoundState!( mpSim, isempty( tmpStateNames ) ? newName :
                    tmpStateNames[ 1 ], -1, statePartition[ attrVal ]... )
            end  # if isPartitionProper

            if level < length( attrList )
                partitionByAttribute( statePartition[ attrVal ], attrList,
                    level + 1, mpSim, catStateList, catStateNameList, newName,
                    newPart )
            end  # if level < length( attrList )
        end  # if length( statePartition[ attrVal ] ) > 1
    end  # for attrVal in keys( statePartition )

    return  # for attrVal in attrList[ level ].possibleValues

end  # partitionByAttribute( stateList, attrList, level, mpSim, catStateList,
     #   catStateNameList, name, partition )
