# This file allows the user to configure a system simulation from a simplified
#   Excel parameter file.

export initialiseFromSimplifiedExcel


"""
```
initialiseFromSimplifiedExcel( mpSim::ManpowerSimulation,
                               fileName::String )
```
This function initialises the manpower simulation `mpSim` from the simplified
configuration file with name `fileName`. If the filename does not have the
extension `.xlsx`, it will be added.

This function returns `nothing`.
"""
function initialiseFromSimplifiedExcel( mpSim::ManpowerSimulation,
    fileName::String )::Void

    tmpFileName = endswith( fileName, ".xlsx" ) ? fileName : fileName * ".xlsx"

    # Complain if file doesn't exist.
    if !ispath( tmpFileName )
        warn( "File is not an Excel file. Not making any changes." )
        return
    end  # if !ispath( tmpFileName )

    tmpPath = Base.source_path()
    tmpPath = tmpPath isa Void ? "" : dirname( tmpPath )
    mpSim.parFileName = joinpath( tmpPath, tmpFileName )

    XLSX.openxlsx( tmpFileName ) do xf
        pSheet = xf[ 1 ]
        mpSim.dbName = joinpath( mpSim.parFileName[ 1:(end-5) ], mpSim.dbName )

        if !ispath( dirname( mpSim.dbName ) )
            mkpath( dirname( mpSim.dbName ) )
        end  # if !ispath( dirname( mpSim.dbName ) )

        mpSim.simDB = SQLite.DB( mpSim.dbName )
        setSimulationLength( mpSim, 1200 )
        setDatabaseCommitTime( mpSim, 120 )
        setSimStartDate( mpSim, Date( now() ) )
        readStatesAndAttrs( mpSim, pSheet )
        readAllTransitions( mpSim, pSheet )
    end  # XLSX.openxlsx( tmpFileName ) do xf

    # Make sure the databases are okay, and save configuration to database.
    initialise( mpSim )
    saveSimConfigToDatabase( mpSim )

    return

end  # initialiseFromSimplifiedExcel( mpSim, fileName )


"""
```
readStatesAndAttrs( mpSim::ManpowerSimulation,
                    pSheet::XLSX.Worksheet )
```
This function configures the attributes and states in the manpowre simulation
`mpSim` from the simplified Excel configuration sheet `pSheet`.

This function returns `nothing`.
"""
function readStatesAndAttrs( mpSim::ManpowerSimulation,
    pSheet::XLSX.Worksheet )::Void

    nRows, nCols = XLSX.size( XLSX.get_dimension( pSheet ) )

    # Find the node block.
    nodeRow = 1

    while ( nodeRow <= nRows ) &&
        ( isa( pSheet[ "A$nodeRow" ], Missings.Missing ) ||
        ( pSheet[ "A$nodeRow" ] != "Knopen" )   )
        nodeRow += 1
    end  # while ( nodeRow <= nRows ) && ...

    # Find node block header row.
    nodeRow += 1

    while ( nodeRow <= nRows ) &&
        ( isa( pSheet[ "A$nodeRow" ], Missings.Missing ) ||
        ( pSheet[ "A$nodeRow" ] != "Name" ) )
        nodeRow += 1
    end  # while ( nodeRow <= nRows ) && ...

    # Find number of columns in node block.
    nCols = 1
    targetCol = 0
    popCol = 0

    while isa( pSheet[ XLSX.CellRef( nodeRow, nCols + 1 ) ], String )
        nCols += 1
        cRef = XLSX.CellRef( nodeRow, nCols )

        if pSheet[ cRef ] == "Pop?"
            popCol = nCols
        elseif pSheet[ cRef ] == "Real"
            targetCol = nCols
        end  # if pSheet[ cRef ] == "Pop?"
    end  # while isa( pSheet[ XLSX.CellRef( nodeRow, nCols + 1 ) ], String )

    nAttrs = nCols - popCol

    # Find number of states, in and out included.
    nodeRow += 1
    nStates = 0

    while isa( pSheet[ "A$(nodeRow + nStates)" ], String )
        nStates += 1
    end  # while isa( pSheet[ "A$(nodeRow + nStates)" ], String )

    # Read the attributes.
    nodeRow -= 1
    attrNames = Vector{String}( nAttrs )

    for ii in 1:nAttrs
        jj = popCol + ii
        attrNames[ ii ] = pSheet[ XLSX.CellRef( nodeRow, jj ) ]
        attrValues = vec( pSheet[ XLSX.CellRange( nodeRow + 1, jj,
            nodeRow + nStates, jj ) ] )
        filter!( val -> !isa( val, Missings.Missing ), attrValues )
        newAttr = PersonnelAttribute( attrNames[ ii ], isFixed = false )
        setPossibleValues!( newAttr,
            Vector{String}( strip.( attrValues ) ) )
        addAttribute!( mpSim, newAttr )
    end  # for ii in 1:nAttrs

    # Read the states.
    for ii in 1:nStates
        jj = nodeRow + ii
        stateName = strip( pSheet[ "A$jj" ] )

        # Ignore the in and out states.
        if lowercase( stateName ) ∈ [ "in", "out" ]
            continue
        end  # if lowercase( stateName ) ∈ [ "in", "out" ]

        # Check if state should be used.
        isStateInSim = lowercase( strip(
            pSheet[ XLSX.CellRef( jj, popCol ) ] ) ) == "yes"

        if !isStateInSim
            continue
        end  # if !isStateInSim

        newState = State( stateName )
        setStateTarget!( newState, pSheet[ XLSX.CellRef( jj, targetCol ) ] )

        # Add requirements to state.
        for kk in eachindex( attrNames )
            attrVal = pSheet[ XLSX.CellRef( jj, popCol + kk ) ]

            if isa( attrVal, String )
                addRequirement!( newState, attrNames[ kk ], attrVal )
            end
        end  # for kk in eachindex( attrNames )

        addState!( mpSim, newState )
    end  # for ii in 1:nStates

    return

end  # readStatesAndAttrs( mpSim, pSheet )


"""
```
readAllTransitions( mpSim::ManpowerSimulation,
                    pSheet::XLSX.Worksheet )
```
This function configures all the transitions in the manpower simulation `mpSim`
from the simplified Excel configuration sheet `pSheet`. This includes all
transitions: recruitment, retirement, forced resignations, and through
transitions (one in-system state to another).

This function returns `nothing`.
"""
function readAllTransitions( mpSim::ManpowerSimulation,
    pSheet::XLSX.Worksheet )::Void

    nRows, nCols = XLSX.size( XLSX.get_dimension( pSheet ) )

    # Find the transition types block.
    transTypeRow = 1

    while ( transTypeRow <= nRows ) &&
        ( isa( pSheet[ "B$transTypeRow" ], Missings.Missing ) ||
        ( pSheet[ "B$transTypeRow" ] != "Transitietypes" ) )
        transTypeRow += 1
    end  # while ( transTypeRow <= nRows ) && ...

    # Read all transition types and their priority.
    transTypeRow += 1

    while isa( pSheet[ "B$transTypeRow" ], String )
        prio = pSheet[ "C$transTypeRow" ]
        setTransTypePriority!( mpSim, pSheet[ "B$transTypeRow" ],
            isa( prio, Int ) ? prio : 0 )
        transTypeRow += 1
    end  # while isa( pSheet[ "B$transTypeRow" ], String )

    # Find the transition block.
    transRow = 1

    while ( transRow <= nRows ) &&
        ( isa( pSheet[ "A$transRow" ], Missings.Missing ) ||
        ( pSheet[ "A$transRow" ] != "Pijlen" ) )
        transRow += 1
    end  # while ( transRow <= nRows ) && ...

    # Find transition block header row.
    transRow += 1

    while ( transRow <= nRows ) &&
        ( isa( pSheet[ "A$transRow" ], Missings.Missing ) ||
        ( pSheet[ "A$transRow" ] != "From" ) )
        transRow += 1
    end  # while ( transRow <= nRows ) && ...

    # Find number of columns in node block.
    nCols = 1

    while isa( pSheet[ XLSX.CellRef( transRow, nCols + 1 ) ], String )
        nCols += 1
    end  # while isa( pSheet[ XLSX.CellRef( transRow, nCols + 1 ) ], String )

    # Find number of transitions, in and out included.
    transRow += 1
    nTrans = 0

    while isa( pSheet[ "A$(transRow + nTrans)" ], String )
        nTrans += 1
    end  # while isa( pSheet[ "A$(transRow + nTrans)" ], String )

    # Detect in/out/through transitions.
    transRow -= 1
    recruitList = find( map( (1:nTrans) + transRow ) do ii
        return ( lowercase( strip( pSheet[ "A$ii" ] ) ) == "in" ) &&
            ( lowercase( strip( pSheet[ "B$ii" ] ) ) ∉ [ "in", "out" ] )
    end )  # map( (1:nTrans) + transRow ) do ii
    throughList = find( map( (1:nTrans) + transRow ) do ii
        return ( lowercase( strip( pSheet[ "A$ii" ] ) ) ∉ [ "in", "out" ] ) &&
            ( lowercase( strip( pSheet[ "B$ii" ] ) ) ∉ [ "in", "out" ] )
    end )  # map( (1:nTrans) + transRow ) do ii
    outList = find( map( (1:nTrans) + transRow ) do ii
        return ( lowercase( strip( pSheet[ "A$ii" ] ) ) ∉ [ "in", "out" ] ) &&
            ( lowercase( strip( pSheet[ "B$ii" ] ) ) == "out" )
    end )  # map( (1:nTrans) + transRow ) do ii

    if length( recruitList ) + length( throughList ) + length( outList ) <
        nTrans
        warn( "Improperly defined transitions in list. Ignoring those." )
    end  # if length( recruitList ) + ...

    # Build the recruitment schemes.
    for ii in recruitList
        jj = ii + transRow
        recName = strip( pSheet[ "C$jj" ] )
        newRecScheme = Recruitment( recName, 12 )
        targetState = strip( pSheet[ "B$jj" ] )

        if !haskey( mpSim.stateList, targetState )
            warn( "Transition $ii is recruitment for an unknown state '$targetState'. Skipping." )
            continue
        end  # if haskey( mpSim.stateList, targetState )

        setRecruitState( newRecScheme, targetState )
        numToRecruit = pSheet[ "G$jj" ]

        if numToRecruit < 0
            warn( "Transition $ii is a recruitment line with a negative flux. Setting flux to zero." )
        end  # if numToRecruit < 0

        numToRecruit = max( 0, numToRecruit )

        if pSheet[ "N$jj" ] == "yes"
            setRecruitmentFixed( newRecScheme, numToRecruit )
        else
            setRecruitmentLimits( newRecScheme, 0, numToRecruit )
        end  # if pSheet[ "N$jj" ] == "yes"


        ageLimits = [ pSheet[ "K$jj" ], pSheet[ "L$jj" ] ] * 12.0

        if ageLimits[ 1 ] >= ageLimits[ 2 ]
            setRecruitmentAge( newRecScheme, ageLimits[ 1 ] )
        else
            setAgeDistribution( newRecScheme,
                Dict( ageLimits[ 1 ] => 1.0, ageLimits[ 2 ] => 1.0 ), :pUnif )
        end  # if ageLimits[ 1 ] >= ageLimits[ 2 ]

        addRecruitmentScheme!( mpSim, newRecScheme )
    end  # for ii in recruitList

    # XXX The big trick is to separate the retirement transitions from the
    #   forced resignations.
    transDetails = Array{String}( length( throughList ), 2 )
    hasFiredOnFail = falses( throughList )
    isFiredOnFail = Vector{Bool}( length( outList ) )

    for ii in eachindex( throughList )
        jj = throughList[ ii ] + transRow
        transDetails[ ii, 1 ] = strip( pSheet[ "A$jj" ] )
        transDetails[ ii, 2 ] = strip( pSheet[ "D$jj" ] )
    end  # for ii in eachindex( throughList )

    # Identify which through transitions have a fire on fail clause, and which
    #   out transitions are fire on fail clauses.
    for ii in eachindex( outList )
        jj = outList[ ii ] + transRow
        outDetails = [ strip( pSheet[ "A$jj" ] ), strip( pSheet[ "D$jj" ] ) ]
        transInd = findfirst( kk -> transDetails[ kk, : ] == outDetails,
            eachindex( throughList ) )
        isFiredOnFail[ ii ] = transInd > 0

        if isFiredOnFail[ ii ]
            hasFiredOnFail[ transInd ] = true
        end  # if isFiredOnFail[ ii ]
    end  # for ii in eachindex( outList )

    outList = outList[ .!( isFiredOnFail ) ]

    # Attach retirement schemes to states.
    for ii in outList
        jj = ii + transRow
        stateName = strip( pSheet[ "A$jj" ] )

        if !haskey( mpSim.stateList, stateName )
            warn( "Transition $ii is retirement from an unknown state '$stateName'. Skipping." )
            continue
        end  # if !haskey( mpSim.stateList, stateName )

        stateRetAge = pSheet[ "H$jj" ] * 12.0
        setStateRetirementAge!( mpSim.stateList[ stateName ], stateRetAge )
    end  # for jj in outList

    # Build the through transitions.
    for ii in eachindex( throughList )
        jj = throughList[ ii ] + transRow
        startState = strip( pSheet[ "A$jj" ] )
        endState = strip( pSheet[ "B$jj" ] )

        if !haskey( mpSim.stateList, startState ) ||
            !haskey( mpSim.stateList, endState )
            warn( "Transition $ii has an unknown source or target state. Skipping." )
            continue
        end  # if !haskey( mpSim.stateList, startState ) || ...

        newTrans = Transition( strip( pSheet[ "C$jj" ] ),
            mpSim.stateList[ startState ], mpSim.stateList[ endState ],
            freq = 12.0, isFiredOnFail = hasFiredOnFail[ ii ] )

        if !hasFiredOnFail[ ii ]
            setMaxAttempts( newTrans, -1 )
        end  # if !hasFiredOnFail[ ii ]

        maxFlux = pSheet[ "G$jj" ]

        if !isa( maxFlux, Missings.Missing )
            setMaxFlux( newTrans, maxFlux )
        end  # if !isa( maxFlux, Missings.Missing )

        condVal = pSheet[ "H$jj" ]

        if !isa( condVal, Missings.Missing )
            cond = processCondition( "age", ">=", condVal )
            addCondition!( newTrans, cond[ 1 ] )
        end  # if !isa( pSheet[ "H$jj" ], Missings.Missing )

        condVal = pSheet[ "I$jj" ]

        if !isa( condVal, Missings.Missing )
            cond = processCondition( "tenure", ">=", condVal )
            addCondition!( newTrans, cond[ 1 ] )
        end  # if !isa( pSheet[ "I$jj" ], Missings.Missing )

        condVal = pSheet[ "J$jj" ]

        if !isa( condVal, Missings.Missing )
            cond = processCondition( "time in state", ">=", condVal )
            addCondition!( newTrans, cond[ 1 ] )
        end  # if !isa( pSheet[ "J$jj" ], Missings.Missing )

        setHasPriority( newTrans, isa( pSheet[ "N$jj" ], String ) &&
            ( pSheet[ "N$jj" ] == "yes" ) )
        addTransition!( mpSim, newTrans )
    end  # for ii in throughList

    return

end  # readAllTransitions( mpSim, pSheet )
