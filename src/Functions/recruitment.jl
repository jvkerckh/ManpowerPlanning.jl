# This file covers everything related to recruitment.

# The functions of the Recruitment type require SimJulia and ResumableFunctions.

# The functions of the Retirement type require the Personnel, PersonnelDatabase,
#   ManpowerSimulation, Attrition, and Retirement types.
requiredTypes = [ "manpowerSimulation",
    "attrition", "retirement" ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( dirname( Base.source_path() ), "..", "Types",
            reqType * ".jl" ) )
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

    if maxRec <= 0
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


#=
# This function defines the distribution for the number of available people
#   each recruiting period. If the number of available positions is lower than
#   this, a smaller number of people will of course be recruited.
# The dictionary argument gives the (unweighted) probabilities for each outcome.
# Values < 0 are ignored, and so are unweighted probabilities <= 0.
export setRecruitmentDistribution
function setRecruitmentDistribution( recScheme::Recruitment,
    recDist::Dict{Int, Float64} )

    tmpMap = collect( keys( recDist ) )
    tmpMap = tmpMap[ map( key -> ( key >= 0 ) && ( recDist[ key ] > 0 ),
        tmpMap ) ]

    # Throw an error if there are no valid outcomes.
    if length( tmpMap ) == 0
        error( "No valid positive outcomes (p > 0) for the proposed recruitment distribution." )
    end

    # Reweight the probability vector to 1.
    tmpProbs = map( key -> recDist[ key ], tmpMap )
    tmpProbs /= sum( tmpProbs )

    recScheme.recruitDist = Categorical( tmpProbs )
    recScheme.recruitMap = tmpMap

end  #  setRecruitmentDistribution( recScheme, recDist )
=#


# This function sets the fixed number of people to recruit during every
#   recruitment cycle.
export setRecruitmentFixed
function setRecruitmentFixed( recScheme::Recruitment, amount::T ) where T <: Integer

    if amount <= 0
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

    if ( mpSim.personnelTarget > 0 ) && ( recScheme.isAdaptive )
        personnelNeeded = mpSim.personnelTarget - mpSim.personnelSize
        nrToRecruit = max( min( personnelNeeded, nrToRecruit ),
            recScheme.minRecruit )
    elseif !recScheme.isAdaptive
        nrToRecruit = recScheme.recDist()
    end  # if ( mpSim.personnelTarget > 0 ) && ...

    return nrToRecruit

end  # generatePoolSize( mpSim, recScheme )


# This function generates a single personnel member using the information in
#   the recruitment scheme.
# XXX Right now this is a very trivial function, but this will change once
#   attributes are added.
function createPerson( mpSim::ManpowerSimulation, recScheme::Recruitment )

    # Create the person in the database.
    # XXX Additional attributes need to be implemented
    id = "Sim" * string( mpSim.resultSize + 1 )
    ageAtRecruitment = recScheme.ageDist()

    # Generate initial values
    initVals = Array{Any}( 3, length( mpSim.initAttrList ) )

    for ii in eachindex( mpSim.initAttrList )
        attr = mpSim.initAttrList[ ii ]
        initVals[ :, ii ] = [ attr.name, "'" * generateAttrValue( attr ) * "'",
            attr.isFixed ]
    end  # for attr in mpSim.initAttrList

    # Add person to the personnel database.
    command = "INSERT INTO $(mpSim.personnelDBname)
        ($(mpSim.idKey), status, timeEntered, ageAtRecruitment,
        $(join( initVals[ 1, : ], ", " ))) values
        ('$id', 'active', $(now( mpSim )), $ageAtRecruitment,
        $(join( initVals[ 2, : ], ", " )))"
    SQLite.execute!( mpSim.simDB, command )

    # Add entry of person to the history database.
    command = "INSERT INTO $(mpSim.historyDBname)
        ($(mpSim.idKey), attribute, timeIndex, strValue) values
        ('$id', 'status', $(now( mpSim )), 'active')"

    # Additional variable attributes.
    for ii in find( .!initVals[ 3, : ] )
        command *= ", ('$id', '$(initVals[ 1, ii ])', $(now( mpSim )),
            $(initVals[ 2, ii ]))"
    end  # for ii in find( !initVals[ 3, : ] )

    SQLite.execute!( mpSim.simDB, command )

    # If a proper retirement scheme has been defined, start this person's
    #   retirement process.
    # Necessary to retain expected retirement time in database?
    timeOfRetirement = computeExpectedRetirementTime( mpSim, id,
        ageAtRecruitment, now( mpSim ) )
    retProc = nothing

    if isa( mpSim.retirementScheme, Retirement )
        retProc = @process retireProcess( mpSim.sim, id, timeOfRetirement,
            mpSim )
    end  # if isa( mpSim.retirementScheme, Retirement )

    # If a proper attrition scheme has been defined, set the attrition process.
    #   This must be defined AFTER the retirement scheme because it requires the
    #   expected time of retirement.
    if isa( mpSim.attritionScheme, Attrition )
        @process attritionProcess( mpSim.sim, id, timeOfRetirement, retProc,
            mpSim )
    end  # if isa( mpSim.attritionScheme, Attrition )

    # Adjust the size of the personnel database.
    mpSim.personnelSize += 1
    mpSim.resultSize += 1

end  # createPerson( mpSim, recScheme )


# This function performs the recruitment part of a single recruitment cycle.
function recruitmentCycle( mpSim::ManpowerSimulation, recScheme::Recruitment )

    nrToRecruit = generatePoolSize( mpSim, recScheme )

    # Stop here if no recruitments happen in this period.
    if nrToRecruit == 0
        return
    end  # if nrToRecruit == 0

#    SQLite.execute!( mpSim.simDB, "BEGIN TRANSACTION" )

    for ii in 1:nrToRecruit
        createPerson( mpSim, recScheme )
    end  # for ii in 1:nrToRecruit

#    command = "INSERT INTO $(mpSim.personnelDBname) ($(mpSim.idKey), status, " *
#        "timeEntered, ageAtRecruitment) values " * join( persBuffer, ", " )
#    SQLite.execute!( mpSim.simDB, command )
    # command = "INSERT INTO $(mpSim.historyDBname) ($(mpSim.idKey), " *
    #     "attribute, timeIndex, strValue) values " * join( histBuffer, ", " )
    # SQLite.execute!( mpSim.simDB, command )
#    SQLite.execute!( mpSim.simDB, "COMMIT" )

end  # recruitmentCycle( mpSim, recScheme )


# This is the process in the simulation for a single recruitment scheme.
# Version for JuliaBox
@resumable function recruitProcess( sim::Simulation,
    schemeNr::Integer, mpSim::ManpowerSimulation )

    recScheme = mpSim.recruitmentSchemes[ schemeNr ]
    timeToWait = recScheme.recruitOffset
    priority = mpSim.phasePriorities[ recScheme.isAdaptive ? :recruitment :
        :retirement ]

    while now( sim ) + timeToWait <= mpSim.simLength
        @yield timeout( sim, timeToWait, priority = priority )
        timeToWait = recScheme.recruitFreq
        recruitmentCycle( mpSim, recScheme )
    end  # while now( sim ) + timeToWait <= mpSim.simLength

end


function Base.show( io::IO, recScheme::Recruitment )

    print( io, "Recruitment schedule: $(recScheme.recruitFreq) (+ $(recScheme.recruitOffset))\n" )
    print( io, recScheme.isAdaptive ? "A" : "Non-a" )
    print( io, "daptive recruitment scheme" )

    if recScheme.isAdaptive
        print( io, "\nRecruitment per cycle: $(recScheme.minRecruit) - $(recScheme.maxRecruit)" )
    end  # if recScheme.isAdaptive || ...

end  # show( io, recScheme )
