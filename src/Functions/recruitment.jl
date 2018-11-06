# This file covers everything related to recruitment.

# The functions of the Recruitment type require SimJulia and ResumableFunctions.

# The functions of the Retirement type require the Personnel, PersonnelDatabase,
#   ManpowerSimulation, Attrition, and Retirement types.
requiredTypes = [ "manpowerSimulation",
    "attrition", "retirement" ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( typePath, reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end  # for reqType in requiredTypes


# This function sets the recruitment schedule.
export setRecruitmentSchedule
function setRecruitmentSchedule( recScheme::Recruitment, freq::T1,
    offset::T2 = 0.0 ) where T1 <: Real where T2 <: Real

    if freq <= 0.0
        error( "Recruitment frequency must be > 0.0." )
    end  # if freq <= 0.0

    recScheme.recruitFreq = freq
    recScheme.recruitOffset = offset % freq + ( offset < 0.0 ? freq : 0.0 )

end  # setRecruitmentSchedule( recScheme, freq, offset )


export setRecruitmentLimits
"""
```
setRecruitmentLimits( recScheme::Recruitment,
                      minRec::T1,
                      maxRec::T2 )
    where T1 <: Real
    where T2 <: Real
```
This function sets the minimum and maximum number of people to recruit using
recruitment scheme `recScheme` to `minRec` and `maxRec` respectively. If the
values don't make sense (maxRec <= 0 or minRec > maxRec), no change is made.

This function returns `nothing`. If the arguments don't make sense, the function
issues a warning.
"""
function setRecruitmentLimits( recScheme::Recruitment, minRec::T1,
    maxRec::T2 )::Void where T1 <: Real where T2 <: Real

    if maxRec < 0
        warn( "Max recruitment must be > 0. Not making any changes." )
        return
    end  # if maxRec <= 0

    if minRec > maxRec
        warn( "Min recruitment must be <= max recruitment. Not making any changes." )
        return
    end  # if minRec > maxRec

    recScheme.isAdaptive = true
    recScheme.minRecruit = max( 0, minRec )
    recScheme.maxRecruit = maxRec

    return

end  # setRecruitmentLimits( recScheme, minRec, maxRec )


# This function sets the state to recruit into. Note that it doesn't check if
#   the state is defined in the simulation. If it isn't, the function will
#   perform general recruitment instead.
export setRecruitState
function setRecruitState( recScheme::Recruitment, stateName::String )::Void

    recScheme.recState = stateName
    return

end  # setRecruitState( recScheme, stateName )


# This function sets the fixed number of people to recruit during every
#   recruitment cycle.
export setRecruitmentFixed
function setRecruitmentFixed( recScheme::Recruitment, amount::T ) where T <: Integer

    if amount < 0
        warn( "Negative number of people to recruit entered. Not making changes to recruitment scheme." )
        return
    end  # if amount <= 0

    recScheme.isAdaptive = false
    recScheme.recDistType = :disc
    recScheme.recDistNodes = Dict( Float64( amount ) => 1.0 )
    recScheme.recDist = function() return amount end

end  # setRecruitmentFixed( recScheme, amount )


# This function sets the recruitment distribution of the recruitment scheme to
#   the given distribution with the given nodes.
export setRecruitmentDistribution
function setRecruitmentDistribution( recScheme::Recruitment,
    recDist::Dict{Int, Float64}, recDistType::Symbol )

    # Check if the distribution type is known.
    if recDistType ∉ [ :disc, :pUnif, :pLin ]
        warn( "Unknown distribution type. Recruitment distribution not set." )
        return
    end  # if recDistType ∉ [ :disc, :pUnif, :pLin ]

    # Get the list of proper nodes (recruitment >= 0 and p >= 0).
    tmpNodes = collect( keys( recDist ) )
    tmpNodes = tmpNodes[ map( node -> ( node >= 0.0 ) &&
        ( recDist[ node ] >= 0.0 ), tmpNodes ) ]
    sort!( tmpNodes )

    # Check if there are sufficient nodes.
    if length( tmpNodes ) < ( recDistType === :disc ? 1 : 2 )
        warn( "Not enough distribution nodes. Recruitment distribution not set." )
        return
    end  # if length( tmpNodes ) < ( recDistType === :disc ? 1 : 2 )

    # Check if the total probability mass is non-zero.
    pMass = 0.0
    foreach( node -> pMass += recDist[ node ], tmpNodes )

    if ( pMass == 0.0 ) || ( ( recDistType === :pUnif ) &&
        ( recDist[ tmpNodes[ end ] ] == pMass ) )
        warn( "Proposed distribution has 0 probability mass. Recruitment distribution not set." )
        return
    end  # if pMass == 0.0

    # Set the distribution
    recScheme.isAdaptive = false
    recScheme.recDistType = recDistType
    recScheme.recDistNodes = recDist
    distFuncs = Dict{Symbol, Function}(
        :disc => setDiscRecDist,
        :pUnif => setPunifRecDist,
        :pLin => setPlinRecDist )
    ( distFuncs[ recDistType ] )( recScheme, recDist, tmpNodes )

end  # setRecruitmentDistribution( recScheme, recDist, recDistType )


# This function sets the recruitment distribution of the recruitment scheme to a
#   discrete distribution with the given nodes.
function setDiscRecDist( recScheme::Recruitment, recDist::Dict{Int, Float64},
    nodes::Vector{Int} )

    # Get the point probabilities of the nodes.
    pNodes = map( node -> recDist[ node ], nodes )
    pNodes /= sum( pNodes )

    recScheme.recDist = function()
        return nodes[ rand( Categorical( pNodes ) ) ]
    end

end  # setDiscAgeDist( recScheme, ageDist, nodes )


# This function sets the recruitment distribution of the recruitment scheme to a
#   piecewise uniform distribution with the given nodes.
function setPunifRecDist( recScheme::Recruitment, recDist::Dict{Int, Float64},
    nodes::Vector{Int} )

    # Get the point probabilities of the intervals.
    pInts = map( node -> recDist[ node ], nodes[1:(end-1)] )
    pInts /= sum( pInts )

    recScheme.recDist = function()
        intI = rand( Categorical( pInts ) )
        return rand( DiscreteUniform( nodes[ intI ], nodes[ intI + 1 ] - 1 ) )
    end

end  # setPunifRecDist( recScheme, recDist, nodes )


# This function sets the recruitment distribution of the recruitment scheme to a
#   piecewise linear distribution with the given nodes.
function setPlinRecDist( recScheme::Recruitment, recDist::Dict{Int, Float64},
    nodes::Vector{Int} )

    # Get the point probabilities of the intervals.
    pointWeights = map( node -> recDist[ node ], nodes )
    nodeDiff = nodes[ 2:end ] - nodes[ 1:(end-1) ]
    weightDiff = pointWeights[ 2:end ] - pointWeights[ 1:(end-1) ]
    bracketWeights = map(
        ii -> 0.5 * ( pointWeights[ ii + 1 ] * ( nodeDiff[ ii ] + 1.0 ) +
        pointWeights[ ii ] * ( nodeDiff[ ii ] - 1.0 ) ),
        1:length( weightDiff ) )
    cumulWeights = cumsum( vcat( pointWeights[ 1 ], bracketWeights ) )

    recScheme.recDist = function()
        weight = rand( Uniform( 0, cumulWeights[ end ] ) )
        intI = findlast( weight .>= cumulWeights )

        if intI == 0
            return nodes[ 1 ]
        end  # if intI == 0

        wTilde = weight - cumulWeights[ intI ]
        weightNodeRatio = weightDiff[ intI ] / nodeDiff[ intI ]
        polyEq = Poly( [ -wTilde, pointWeights[ intI ] + weightNodeRatio / 2,
            weightNodeRatio / 2 ] )
        pos = filter( root -> 0 <= root < nodeDiff[ intI ],
            roots( polyEq ) )[ 1 ]

        return nodes[ intI ] + ceil( Int, pos )
    end

end  # setPunifRecDist( recScheme, recDist, nodes )


# This function sets the recruitment age to a single, fixed number.
export setRecruitmentAge
function setRecruitmentAge( recScheme::Recruitment, age::T ) where T <: Real

    if age < 0.0
        warn( "Age at recruitment must be ⩾ 0.0. Not making changes to recruitment scheme." )
        return
    end

    recScheme.ageDistType = :disc
    recScheme.ageDistNodes = Dict( Float64( age ) => 1.0 )
    recScheme.ageDist = function() return age end

end  # setRecruitmentAge( recScheme, age )


# This function sets the age distribution of the recruitment scheme to the
#   given distribution with the given nodes.
export setAgeDistribution
function setAgeDistribution( recScheme::Recruitment,
    ageDist::Dict{Float64, Float64}, ageDistType::Symbol )

    # Check if the distribution type is known.
    if ageDistType ∉ [ :disc, :pUnif, :pLin ]
        warn( "Unknown distribution type. Age distribution not set." )
        return
    end  # if recDistType ∉ [ :disc, :pUnif, :pLin ]

    # Get the list of proper nodes (age >= 0 and p >= 0).
    tmpNodes = collect( keys( ageDist ) )
    tmpNodes = tmpNodes[ map( node -> ( node >= 0.0 ) &&
        ( ageDist[ node ] >= 0.0 ), tmpNodes ) ]
    sort!( tmpNodes )

    # Check if there are sufficient nodes.
    if length( tmpNodes ) < ( ageDistType === :disc ? 1 : 2 )
        warn( "Not enough distribution nodes. Age distribution not set." )
        return
    end  # if length( tmpNodes ) < ( recDistType === :disc ? 1 : 2 )

    # Check if the total probability mass is non-zero.
    pMass = 0.0
    foreach( node -> pMass += ageDist[ node ], tmpNodes )

    if ( pMass == 0.0 ) || ( ( ageDistType === :pUnif ) &&
        ( ageDist[ tmpNodes[ end ] ] == pMass ) )
        warn( "Proposed distribution has 0 probability mass. Age distribution not set." )
        return
    end  # if pMass == 0.0

    # Set the distribution
    recScheme.ageDistType = ageDistType
    recScheme.ageDistNodes = ageDist
    distFuncs = Dict{Symbol, Function}(
        :disc => setDiscAgeDist,
        :pUnif => setPUnifAgeDist,
        :pLin => setPLinAgeDist )
    ( distFuncs[ ageDistType ] )( recScheme, ageDist, tmpNodes )

end  # setAgeDistribution( recScheme, ageDist, recDistType )


# This function sets the age distribution of the recruitment scheme to a
#   discrete distribution with the given nodes.
function setDiscAgeDist( recScheme::Recruitment,
    ageDist::Dict{Float64, Float64}, nodes::Vector{Float64} )

    # Get the point probabilities of the nodes.
    pNodes = map( node -> ageDist[ node ], nodes )
    pNodes /= sum( pNodes )

    recScheme.ageDist = function()
        return nodes[ rand( Categorical( pNodes ) ) ]
    end

end  # setDiscAgeDist( recScheme, ageDist, nodes )


# This function sets the age distribution of the recruitment scheme to a
#   piecewise uniform distribution with the given nodes.
# The probability at node t_i is the (unweighted) probability that the result
#   lies in the interval [ t_i, t_{i+1} ]. Hence, the probabilty at the last
#   node is ignored.
function setPUnifAgeDist( recScheme::Recruitment,
    ageDist::Dict{Float64, Float64}, nodes::Vector{Float64} )

    # Get the point probabilities of the intervals.
    pInts = map( node -> ageDist[ node ], nodes[1:(end-1)] )
    pInts /= sum( pInts )

    recScheme.ageDist = function()
        intI = rand( Categorical( pInts ) )
        return rand( Uniform( nodes[ intI ], nodes[ intI + 1 ] ) )
    end

end  # setPUnifAgeDist( recScheme, ageDist, nodes )


# This function sets the age distribution of the recruitment scheme to a
#   piecewise linear distribution with the given nodes.
function setPLinAgeDist( recScheme::Recruitment,
    ageDist::Dict{Float64, Float64}, nodes::Vector{Float64} )

    # Get the point probabilities of the intervals.
    pNodes = map( node -> ageDist[ node ], nodes )
    pMasses = map( ii -> ( nodes[ ii + 1 ] - nodes[ ii ] ) *
        ( pNodes[ ii ] + pNodes[ ii + 1 ] ) / 2.0, eachindex( nodes[ 2:end ] ) )
    pMasses /= sum( pMasses )

    recScheme.ageDist = function()
        intI = rand( Categorical( pMasses ) )
        pDiff = pNodes[ intI + 1 ] - pNodes[ intI ]

        if pDiff == 0
            dist = Uniform( nodes[ intI ], nodes[ intI + 1 ] )
        else
            mu = pDiff > 0 ? nodes[ intI + 1 ] : nodes[ intI ]
            sigma = max( pNodes[ intI ], pNodes[ intI + 1 ] ) *
                ( nodes[ intI + 1 ] - nodes[ intI ] ) /
                abs( pNodes[ intI + 1 ] - pNodes[ intI ] )
            dist = Truncated( SymTriangularDist( mu, sigma ), nodes[ intI ],
                nodes[ intI + 1 ] )
        end  # if pDiff == 0

        return rand( dist )
    end

end  # setPLinAgeDist( recScheme, ageDist, nodes )


# This function generates and returns the number of personnel members to recruit
#   in a recruitment cycle.
function generatePoolSize( mpSim::ManpowerSimulation, recScheme::Recruitment )

    nrToRecruit = recScheme.maxRecruit

    if recScheme.isAdaptive && ( mpSim.personnelTarget > 0 )
        personnelNeeded = mpSim.personnelTarget - mpSim.personnelSize
        nrToRecruit = max( min( personnelNeeded, nrToRecruit ),
            recScheme.minRecruit )
    elseif !recScheme.isAdaptive
        nrToRecruit = recScheme.recDist()
    end  # if ( mpSim.personnelTarget > 0 ) && ...

    return nrToRecruit

end  # generatePoolSize( mpSim, recScheme )

function generatePoolSize( mpSim::ManpowerSimulation, recScheme::Recruitment,
    recState::State )

    nrToRecruit = recScheme.maxRecruit

    if recScheme.isAdaptive
        persToOrgTarget = mpSim.personnelTarget > 0 ? mpSim.personnelTarget -
            mpSim.personnelSize : typemax( Int )
        persToStateTarget = recState.stateTarget >= 0 ? recState.stateTarget -
            length( recState.inStateSince ) : typemax( Int )
        nrToRecruit = max( min( persToOrgTarget, persToStateTarget,
            nrToRecruit ), recScheme.minRecruit )
    elseif !recScheme.isAdaptive
        nrToRecruit = recScheme.recDist()
    end  # if ( mpSim.personnelTarget > 0 ) && ...

    return nrToRecruit

end  # generatePoolSize( mpSim, recScheme )


# This function generates a single personnel member using the information in
#   the recruitment scheme.
function createPerson( mpSim::ManpowerSimulation, recScheme::Recruitment,
    recState::T = nothing ) where T <: Union{Void, State}

    # Create the person in the database.
    id = "Sim" * string( mpSim.resultSize + 1 )
    ageAtRecruitment = recScheme.ageDist()

    # Generate initial values.
    initVals = Dict{String, Any}()
    initValsFixed = Dict{String, Bool}()

    for ii in eachindex( mpSim.initAttrList )
        attr = mpSim.initAttrList[ ii ]
        initVals[ attr.name ] = generateAttrValue( attr )
        initValsFixed[ attr.name ] = attr.isFixed
    end  # for attr in mpSim.initAttrList

    initPersStates = []

    if isa( recState, State )
        # When recruiting for a specific state, set the required attributes, and
        #   put entity in that state.
        for attr in keys( recState.requirements )
            initVals[ attr ] = recState.requirements[ attr ][ 1 ]
            initValsFixed[ attr ] = false
        end  # for attr in keys( recState.requirements )

        initPersStates = [ recState ]
    else
        # Otherwise, identify all initial states the person belongs to and add
        #   entry info to each of those states.
        initPersStates = collect( Iterators.filter(
            state -> isPersonnelOfState( initVals, state ),
            keys( mpSim.initStateList ) ) )
            # XXX Iterators.filter is needed to avoid deprecation warnings.
    end  # if isa( recState, State )

    # Check if each person can be assigned to exactly one state.
    if mpSim.isWellDefined
        if isempty( initPersStates )
            mpSim.isWellDefined = false
            warn( "Person created that couldn't be assigned to any state. Please check system configuration for consistency." )
        elseif length( initPersStates ) > 1
            mpSim.isWellDefined = false
            warn( "Person created that can be assigned to multiple states. Please check system configuration for consistency." )
        end  # if isempty( initPersStates )
    end  # if mpSim.isWellDefined

    for state in initPersStates
        state.inStateSince[ id ] = now( mpSim )
        state.isLockedForTransition[ id ] = false
    end  # for state in initPersStates

    stateRetAge = isempty( initPersStates ) ? 0 :
        initPersStates[ 1 ].stateRetAge

    stateNames = map( state -> state.name, initPersStates )
    timeOfRetirement = computeExpectedRetirementTime( mpSim,
        mpSim.retirementScheme, ageAtRecruitment, stateRetAge, now( mpSim ) )
    attrScheme = determineAttritionScheme( initPersStates, mpSim )
    timeOfAttr = generateTimeOfAttrition( attrScheme, now( mpSim ) )

    # Add person to the personnel database.
    command = "INSERT INTO $(mpSim.personnelDBname)
        ($(mpSim.idKey), status, timeEntered, ageAtRecruitment,
            expectedRetirementTime, expectedAttritionTime, attritionScheme"

    if !isempty( initVals )
        command *= ", '$(join( keys( initVals ), "', '" ))'"
    end  # if !isempty( initVals )

    command *= ") VALUES
        ('$id', 'active', $(now( mpSim )), $ageAtRecruitment, $timeOfRetirement,
            $timeOfAttr, '$(attrScheme.name)'"

    if !isempty( initVals )
        command *= ", '$(join( map( attrName -> initVals[ attrName ], keys( initVals ) ), "', '" ))'"
    end # if !isempty( initVals )

    command *= ")"
    SQLite.execute!( mpSim.simDB, command )

    # Add entry of person to the history database.
    command = "INSERT INTO $(mpSim.historyDBname)
        ($(mpSim.idKey), attribute, timeIndex, strValue) VALUES
        ('$id', 'status', $(now( mpSim )), 'active')"

    # Additional variable attributes.
    for attrName in keys( initVals )
        if !initValsFixed[ attrName ]
            command *= ", ('$id', '$attrName', $(now( mpSim )), '$(initVals[ attrName ])')"
        end  # !initValsFixed[ attrName ]
    end  # for attrName in keys( initVals )

    SQLite.execute!( mpSim.simDB, command )

    # Add recruitment event and all applicable initial states to transition
    #   database.
    command = "INSERT INTO $(mpSim.transitionDBname)
        ($(mpSim.idKey), timeIndex, transition, endState) VALUES
        ('$id', $(now( mpSim )), '$(recScheme.name)', 'active')"

    # Initiate all applicable transition processes.
    for state in initPersStates
        command *= ", ('$id', $(now( mpSim )), '$(recScheme.name)', '$(state.name)')"

        # for trans in mpSim.initStateList[ state ]
        #     @process transitionProcess( mpSim.sim, trans, id, mpSim )
        # end  # for trans in mpSim.initStateList[ state ]
    end  # for state in initPersStates

    SQLite.execute!( mpSim.simDB, command )

    # Adjust the size of the personnel database.
    mpSim.personnelSize += 1
    mpSim.resultSize += 1

end  # createPerson( mpSim, recScheme )


# This function performs the recruitment part of a single recruitment cycle.
function recruitmentCycle( mpSim::ManpowerSimulation, recScheme::Recruitment )

    nrToRecruit = generatePoolSize( mpSim, recScheme )
    recState = recScheme.recState == "" ? nothing :
        mpSim.stateList[ recScheme.recState ]

    if !isa( recState, Void )
        nrToRecruit = generatePoolSize( mpSim, recScheme, recState )
    end  # if !isa( recState, Void )

    # Stop here if no recruitments happen in this period.
    if nrToRecruit == 0
        return
    end  # if nrToRecruit == 0

    foreach( ii -> createPerson( mpSim, recScheme, recState ), 1:nrToRecruit )

    return

end  # recruitmentCycle( mpSim, recScheme )


# This is the process in the simulation for a single recruitment scheme.
# Version for JuliaBox
@resumable function recruitProcess( sim::Simulation,
    schemeNr::Integer, mpSim::ManpowerSimulation )

    processTime = Dates.Millisecond( 0 )
    tStart = now()

    recScheme = mpSim.recruitmentSchemes[ schemeNr ]
    timeToWait = recScheme.recruitOffset
    priority = mpSim.phasePriorities[ :recruitment ]
    priority += recScheme.isAdaptive ? 0 : 1

    while now( sim ) + timeToWait <= mpSim.simLength
        processTime += now() - tStart
        @yield timeout( sim, timeToWait, priority = priority )
        tStart = now()
        timeToWait = recScheme.recruitFreq
        recruitmentCycle( mpSim, recScheme )
    end  # while now( sim ) + timeToWait <= mpSim.simLength

    processTime += now() - tStart
    println( "Recruitment process for '$(recScheme.name)' took $(processTime.value / 1000) seconds." )

end


function Base.show( io::IO, recScheme::Recruitment )

    print( io, "Recruitment schedule: $(recScheme.recruitFreq) (+ $(recScheme.recruitOffset))\n" )
    print( io, recScheme.isAdaptive ? "A" : "Non-a" )
    print( io, "daptive recruitment scheme" )

    if recScheme.isAdaptive
        print( io, "\nRecruitment per cycle: $(recScheme.minRecruit) - $(recScheme.maxRecruit)" )
    end  # if recScheme.isAdaptive || ...

end  # show( io, recScheme )


# ==============================================================================
# Non-exported methods
# ==============================================================================

function readRecruitmentScheme( sheet::XLSX.Worksheet,
    ii::T )::Recruitment where T <: Integer

    dataColNr = ii * 5 - 3
    name = sheet[ XLSX.CellRef( 5, dataColNr ) ]
    recScheme = Recruitment( name, sheet[ XLSX.CellRef( 6, dataColNr ) ],
        sheet[ XLSX.CellRef( 7, dataColNr ) ] )
    recState = sheet[ XLSX.CellRef( 8, dataColNr ) ]
    recState = isa( recState, Missings.Missing ) ||
        lowercase( recState ) == "active" ? "" : recState
    setRecruitState( recScheme, recState )
    isAdaptive = sheet[ XLSX.CellRef( 11, dataColNr ) ] == "YES"
    isRandom = sheet[ XLSX.CellRef( 12, dataColNr ) ] == "YES"
    nRow = 16
    numNodes = sheet[ XLSX.CellRef( nRow + 1, dataColNr ) ]

    if isAdaptive
        minRec = sheet[ XLSX.CellRef( 9, dataColNr ) ] === nothing ? 0 :
            sheet[ XLSX.CellRef( 9, dataColNr ) ]
        setRecruitmentLimits( recScheme, minRec,
            sheet[ XLSX.CellRef( 10, dataColNr ) ] )
    elseif isRandom
        distType = distTypes[ sheet[ XLSX.CellRef( nRow, dataColNr ) ] ]
        minNodes = distType == "Pointwise" ? 1 : 2
        recDist = Dict{Int, Float64}()

        for jj in (1:numNodes) + 2
            node = sheet[ XLSX.CellRef( nRow + jj, dataColNr ) ]
            weight = sheet[ XLSX.CellRef( nRow + jj, dataColNr + 1 ) ]

            if isa( node, Real ) && !haskey( recDist, node ) && ( node >= 0 ) &&
                ( weight >= 0 )
                recDist[ floor( Int, node ) ] = weight
            end  # if isa( node, Real ) && ...
        end  # for ii in (1:numNodes) + 2

        if length( recDist ) < minNodes
            error( "Recruitment type $name has an insufficient number of valid nodes defined for its population size distribution." )
        end  # if numNodes < minNodes

        setRecruitmentDistribution( recScheme, recDist, distType )
    else
        setRecruitmentFixed( recScheme, sheet[ XLSX.CellRef( 10, dataColNr ) ] )
    end  # if isAdaptive

    isFixedAge = sheet[ XLSX.CellRef( 13, dataColNr ) ] == "YES"

    # Add the age distribution.
    if isFixedAge
        setRecruitmentAge( recScheme,
            sheet[ XLSX.CellRef( 14, dataColNr ) ] * 12.0 )
    else
        # Get to the start of the age distribution
        nRow += numNodes + 4
        distType = distTypes[ sheet[ XLSX.CellRef( nRow, dataColNr ) ] ]
        numNodes = sheet[ XLSX.CellRef( nRow + 1, dataColNr ) ]
        minNodes = distType == "Pointwise" ? 1 : 2
        ageDist = Dict{Float64, Float64}()

        for jj in (1:numNodes) + 2
            age = sheet[ XLSX.CellRef( nRow + jj, dataColNr ) ]
            pMass = sheet[ XLSX.CellRef( nRow + jj, dataColNr + 1 ) ]

            # Only add the entry if it makes sense.
            if isa( age, Real ) && !haskey( ageDist, age ) && ( age >= 0 ) &&
                ( pMass >= 0 )
                ageDist[ age * 12.0 ] = pMass
            end  # if isa( age, Real ) && ...
        end  # for jj in (1:numNodes) + 2

        if length( ageDist ) < minNodes
            error( "Recruitment type $name has an insufficient number of valid nodes defined for its recruitment age distribution." )
        end  # if numNodes < ( distType == "Pointwise" ? 1 : 2 )

        setAgeDistribution( recScheme, ageDist, distType )
    end  # if isFixedAge

    return recScheme

end  # function generateRecruitmentScheme( s, ii )
