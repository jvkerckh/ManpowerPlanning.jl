# This file holds the definition of the functions pertaining to the State type.

# The functions of the State type require the Attrition type.
requiredTypes = [ "attrition", "state" ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( typePath, reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end  # for reqType in requiredTypes


export setName!,
       addRequirement!,
       removeRequirement!,
       clearRequirements!,
       setInitial!,
       setStateTarget!,
       setStateRetirementAge!,
       setStateAttritionScheme!


"""
```
setName!( state::State,
          name::String )
```
This function sets the name of the state `state` to `name`.

This function returns `nothing`.
"""
function setName!( state::State, name::String )::Void

    state.name = name
    return

end  # setName!( state, name )


"""
```
addRequirement!( state::State,
                 attribute::String,
                 value::String )
```
This function adds a requirement to the state `state`, requiring that the
attribute `attribute` has the value `value`. The spaces in the attribute are
replaced with underscores (`_`). If there is already a requirement on the
attribute, the function overwrites the requirement.

This function returns `nothing`.
"""
function addRequirement!( state::State, attribute::String, value::String )::Void

    if haskey( state.requirements, attribute )
        warn( "State already has a requirement on attribute '$attribute'." )
    end  # if haskey( state.requirements, tmpAttr )

    state.requirements[ attribute ] = [ value ]
    return

end  # addRequirement!( state, attribute, value )


"""
```
addRequirement!( state::State,
                 attribute::String,
                 values::Vector{String} )
```
This function adds a requirement to the state `state`, requiring that the
attribute `attribute` has a value in `values`. The spaces in the attribute are
replaced with underscores (`_`). If there is already a requirement on the
attribute, the function overwrites the requirement.

This function returns `nothing`.
"""
function addRequirement!( state::State, attribute::String,
    values::Vector{String} )::Void

    if haskey( state.requirements, attribute )
        warn( "State already has a requirement on attribute '$attribute'." )
    end  # if haskey( state.requirements, tmpAttr )

    state.requirements[ attribute ] = values
    return

end  # addRequirement!( state, attribute, values )


"""
```
removeRequirement!( state::State,
                    attribute::String )
```
This function removes the requirement for state `state` on attribute
`attribute`. If the attribute had no requirement on it, nothing happens.

This function returns `nothing`.
"""
function removeRequirement!( state::State, attribute::String )::Void

    delete!( state.requirements, attribute )
    return

end  # removeRequirement!( state, attribute )


"""
```
clearRequirements!( state::State )
```
This function clears all the requirements for state `state`.

This function returns `nothing`.
"""
function clearRequirements!( state::State )::Void

    empty!( state.requirements )
    return

end  # clearRequirements!( state )


"""
```
setInitial!( state::State,
             isInitial::Bool )
```
This function sets the flag of `state` which indicates the state is an initial
state to `isInitial`.

This function returns `nothing`.
"""
function setInitial!( state::State, isInitial::Bool )::Void

    state.isInitial = isInitial
    return

end  # setInitial!( state, isInitial )


"""
```
setStateTarget!( state::State,
                 target::T )
    where T <: Integer
```
This function sets the target number of personnel members in state `state` to
`target`. If the number is less than zero, it means there's no target.

This function returns `nothing`.
"""
function setStateTarget!( state::State, target::T )::Void where T <: Integer

    state.stateTarget = target < 0 ? -1 : target
    return

end  # setStateTarget!( state, target )


"""
```
setStateAttritionScheme!( state::State,
                          attrScheme::Attrition )
```
This function sets the attrition scheme of the state `state` to `attrScheme`.

This function returns `nothing.`
"""
function setStateAttritionScheme!( state::State, attrScheme::Attrition )::Void

    state.attrScheme = attrScheme
    return

end  # setStateAttritionScheme!( state, attrScheme )


"""
```
setStateAttritionScheme!( state::State,
                          attrRate::Float64,
                          attrPeriod::Float64,
                          mpSim::ManpowerSimulation )
```
This function sets the attrition scheme of the state `state` to a new attrition
scheme with an attrition rate of `attrRate` per period of `attrPeriod`, and
stores the scheme in the manpower simulation `mpSim`.

This function returns `nothing.`
"""
function setStateAttritionScheme!( state::State, attrRate::Float64,
    attrPeriod::Float64, mpSim::ManpowerSimulation )::Void

    newAttrScheme = Attrition( "Attrition:" * state.name, attrRate, attrPeriod )
    addAttritionScheme!( newAttrScheme, mpSim )
    state.attrScheme = newAttrScheme
    return

end  # setStateAttritionScheme!( state, attrScheme )


"""
```
setStateRetirementAge!( state::State,
                        retAge::T )
    where T <: Real
```
This function sets the retirement age for personnel in the state `state` to
`retAge`. If the age is set to 0, the default retirement scheme is used instead.

This function returns `nothing`.
"""
function setStateRetirementAge!( state::State, retAge::T )::Void where T <: Real

    if retAge < 0
        warn( "Retirement age must be > 0. Not making change." )
        return
    end  # if retAge < 0

    state.stateRetAge = retAge
    return

end  # setStateRetirementAge( state::State, retAge::T )


"""
```
setStateAttritionScheme!( state::State,
                          attrName::String,
                          mpSim::ManpowerSimulation )
```
This function sets the attrition scheme of the state `state` to the scheme with
name `attrName` as defined in the manpower simulation `mpSim`. If the name is
'default' or unknown, the default scheme is set.

This function returns `nothing.`
"""
function setStateAttritionScheme!( state::State, attrName::String,
    mpSim::ManpowerSimulation )::Void

    if ( lowercase( attrName ) == "default" ) ||
        !haskey( mpSim.attritionSchemes, attrName )
        state.attrScheme = mpSim.defaultAttritionScheme
        return
    end  # if ( lowercase( attrName ) == "default" ) || ...

    state.attrScheme = mpSim.attritionSchemes[ attrName ]
    return

end  # setStateAttritionScheme!( state, attrName, mpSim )


function Base.show( io::IO, state::State )

    print( io, "  State: $(state.name)" )
    print( io, "\n    Associated attrition scheme: $(state.attrScheme)" )

    if isempty( state.requirements )
        print( io, "\n    State '$(state.name)' has no requirements" )
        return
    else
        print( io, "\n    Requirements" )

        for attr in keys( state.requirements )
            print( io, "\n      $attr " )
            vals = state.requirements[ attr ]
            multival = length( vals ) != 1
            print( io, multival ? "∈ { " : "= " )
            print( io, join( map( val -> "'$val'", vals ), ", " ) )
            print( io, multival ? " }" : "" )
        end  # for attr in keys( state.requirements )
    end  # if isempty( state.requirements )

    if state.stateTarget >= 0
        print( io, "\n    Target of $(state.stateTarget) personnel members in state." )
    end  # if state.stateTarget >= 0

end  # show( io, state )


# ==============================================================================
# Non-exported methods.
# ==============================================================================

"""
```
readState( sheet::XLSX.Worksheet,
           stateCat::XLSX.Worksheet,
           sLine::T )
```
This function reads line `sline` of the Excel sheet `sheet`, and uses the state
catalogue sheet `stateCat` to generate a single state from it.

This function returns a `Tuple{State, T}` where `T` is either a `String` or a
`Tuple{Float64, Float64}`. The first element is the state object as it is
described in the Excel sheet, the second element is either the name of the
attached attrition scheme, or the attrition period/rate pair describing
attrition in this state.
"""
function readState( sheet::XLSX.Worksheet, stateCat::XLSX.Worksheet,
    sLine::T ) where T <: Integer

    newState = State( string( sheet[ "A$sLine" ] ) )
    catLine = sheet[ "C$sLine" ]

    if isa( catLine, Missings.Missing )
        error( "State '$(newState.name)' not defined in catalogue." )
    end  # if isa( catLine, Void )

    stateTarget = sheet[ "B$sLine" ]
    setStateTarget!( newState, isa( stateTarget, Missings.Missing ) ? -1 :
        stateTarget )
    catLine += 1
    setInitial!( newState, stateCat[ "B$catLine" ] == "YES" )

    # Read attrition scheme.
    isFixedAttr = stateCat[ "C$catLine" ] == "YES"

    if isFixedAttr
        attrPar = Float64( stateCat[ "D$catLine" ] ),
            Float64( stateCat[ "E$catLine" ] )

        if any( par -> isa( par, Missings.Missing ), attrPar )
            error( "Attrition parameters for state '$(newState.name)' aren't properly defined." )
        end  # if any( par -> isa( par, Missings.Missing ), attrPar )

    else
        attrPar = stateCat[ "F$catLine" ]

        if isa( attrPar, Missings.Missing )
            attrPar = "default"
        end  # if isa( attrPar, Missings.Missing )

    end

    # Read state requirements/updates.
    nReqs = Int( stateCat[ "G$catLine" ] )

    for ii in 1:nReqs
        addRequirement!( newState,
            stateCat[ XLSX.CellRef( catLine, 6 + 2 * ii ) ],
            stateCat[ XLSX.CellRef( catLine, 7 + 2 * ii ) ] )
    end  # for ii in 1:nReqs

    return newState, attrPar

end  # readState( sheet, stateCat, sLine )


"""
```
processStateOptions( opts::String )
```
This function processes the list of options given in `opts`.

This function returns either a `String` if there was only one option, or a
`Vector{String}` if there were multiple, comma separated options.
"""
function processStateOptions( opts::String )

    vals = split( opts, "," )
    vals = map( val -> String( strip( val ) ), vals )
    return length( vals ) == 1 ? vals[ 1 ] : vals

end  # processStateOptions( opts )


"""
```
isPersonnelOfState( persAttrs::Dict{String, Any},
                    state::State )
```
This function tests if the personnel members with initialised attributes
`persAttrs` satisfies the requirements of state `state`.

This function returns a `Bool` with the result of the test.
"""
function isPersonnelOfState( persAttrs::Dict{String, Any}, state::State )::Bool

    for attr in keys( state.requirements )
        # If the attribute isn't initialised for the personnel member, the
        #   personnel doesn't satisfy it, and isn't in the state. Otherwise,
        #   the attribute's value must match with the requirements of the state.
        if !haskey( persAttrs, attr ) ||
            persAttrs[ attr ] ∉ state.requirements[ attr ]
            return false
        end  # if !haskey( persAttrs ) || ...
    end  # for attr in keys( state.requirements )

    return true

end  # isPersonnelOfState( persAttrs, state )


"""
```
orderStates( mpSim::ManpowerSimulation )
```
This function orders the states in the manpower simulation `mpSim` in such a
manner that a lower ordered state does not have any transitions to a higher
ordered state.

This function returns a `Vector{String}`, the list of ordered states.
"""
function orderStates( mpSim::ManpowerSimulation )::Vector{String}

    # Build a graph of the network.
    graph = ManpowerPlanning.buildTransitionNetwork( mpSim,
        keys( mpSim.stateList )... )[ 1 ]

    # Initialises the lists.
    sortedNodes = Vector{Int}()
    connectedNodes = Vector{Int}()
    unconnectedNodes = collect( vertices( graph ) )[ 1:(end-2) ]

    # For each node, find the first state in the sorted node list for which a
    #   transition state -> node exists. Insert the new node before the found
    #   transition.
    while !isempty( unconnectedNodes ) || !isempty( connectedNodes )
        # Grab the last node of those queued for insertion, or the last unsorted
        #   node if the queue is empty.
        node = pop!( isempty( connectedNodes ) ? unconnectedNodes :
            connectedNodes )

        # If there are unsorted nodes left, find all that link directly with the
        #   currently considered node, and shift them to the sorting queue.
        if !isempty( unconnectedNodes )
            hasLink = has_edge.( graph, node, unconnectedNodes ) .|
                has_edge.( graph, unconnectedNodes, node )
            push!( connectedNodes, unconnectedNodes[ hasLink ]... )
            unconnectedNodes = unconnectedNodes[ .!hasLink ]
        end  # if !isempty( unconnectedNodes )

        # Insert the node in the right place in the list of sorted nodes.
        firstFailIndex = findfirst( jj -> has_edge( graph, jj, node ),
            sortedNodes )

        if firstFailIndex == 0
                push!( sortedNodes, node )
        else
            insert!( sortedNodes, firstFailIndex, node )
        end  # if firstFailIndex == 0
    end  # while !isempty( unconnectedNodes ) || ...

    return map( ii -> get_prop( graph, ii, :state ), sortedNodes )

end  # orderStates( mpSim::ManpowerSimulation )


function orderStatesOld( mpSim::ManpowerSimulation )::Vector{String}

    # Build a graph of the network.
    graph = ManpowerPlanning.buildTransitionNetwork( mpSim,
        keys( mpSim.stateList )... )[ 1 ]

    # Initialises the lists.
    sortedNodes = Vector{Int}()
    unsortedNodes = collect( vertices( graph ) )[ 1:(end-2) ]
    nChecks = 0

    # For each node, find the first state in the sorted node list for which a
    #   transition state -> node exists. Insert the new node before the found
    #   transition.
    while !isempty( unsortedNodes )
        node = unsortedNodes[ 1 ]

        # Only insert the new node if it's the first one, or if it has any links
        #   to already sorted states. Otherwise, put it at the end of the
        #   unsorted node list.
        if isempty( sortedNodes ) || any( jj -> has_edge( graph, node, jj ) ||
                has_edge( graph, jj, node ), sortedNodes )
            firstFailIndex = findfirst( jj -> has_edge( graph, jj, node ),
                sortedNodes )
            lastFailIndex = findlast( jj -> has_edge( graph, node, jj ),
                sortedNodes )

            if firstFailIndex == 0
                    push!( sortedNodes, node )
            else
                insert!( sortedNodes, firstFailIndex, node )
            end  # if firstFailIndex == 0

            deleteat!( unsortedNodes, 1 )
            nChecks = 1
        elseif nChecks == length( unsortedNodes )
            push!( sortedNodes, node )
            deleteat!( unsortedNodes, 1 )
            nChecks = 1
        else
            unsortedNodes = vcat( unsortedNodes[ 2:end ], unsortedNodes[ 1 ] )
            nChecks += 1
        end  # if isempty( sortedNodes ) || ...

    end  # while !isempty( unsortedNodes )

    return map( ii -> get_prop( graph, ii, :state ), sortedNodes )

end  # orderStates( mpSim::ManpowerSimulation )
