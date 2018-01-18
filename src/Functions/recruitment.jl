# This file covers everything related to recruitment.

# The functions of the Recruitment type require SimJulia and ResumableFunctions.

# The functions of the Retirement type require the Personnel, PersonnelDatabase,
#   ManpowerSimulation, Attrition, and Retirement types.
requiredTypes = [ "personnel", "personnelDatabase", "manpowerSimulation",
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


# This function sets the maximum number of people to recruit during every
#   recruitment cycle.
export setRecruitmentCap
function setRecruitmentCap( recScheme::Recruitment, cap::T ) where T <: Integer

    if cap < 0
        warn( "Negative recruitment cap entered. Not making changes to recruitment scheme." )
        return
    end

    recScheme.recruitDist = Categorical( [ 1.0 ] )
    recScheme.recruitMap = [ cap ]

end


# This function sets the recruitment age to a single, fixed number.
export setRecruitmentAge
function setRecruitmentAge( recScheme::Recruitment, age::T ) where T <: Real

    if age < 0.0
        warn( "Age at recruitment must be ⩾ 0.0. Not making changes to recruitment scheme." )
        return
    end

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
    map( node -> pMass += ageDist[ node ], tmpNodes )

    if ( pMass == 0.0 ) || ( ( ageDistType === :pUnif ) &&
        ( ageDist[ tmpNodes[ end ] ] == pMass ) )
        warn( "Proposed distribution has 0 probability mass. Age distribution not set." )
        return
    end  # if pMass == 0.0

    # Set the distribution
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

# This function generates and returns the number of available personnel members
#   in a recruitment cycle.
function generatePoolSize( recScheme::Recruitment )

    return recScheme.recruitMap[ rand( recScheme.recruitDist ) ]

end  # generatePoolSize( recScheme )


# This function generates a single personnel member using the information in
#   the recruitment scheme.
# XXX Right now this is a very trivial function, but this will change once
#   attributes are added.
function createPerson( mpSim::ManpowerSimulation, recScheme::Recruitment )

    # Create the person in the database.
    # XXX Additional attributes need to be implemented
    id = "Sim" * string( mpSim.resultSize + 1 )
    person = Dict{String, Any}()
    person[ mpSim.idKey ] = "'$id'"
    person[ "status" ] = "'active'"
    person[ "timeEntered" ] = now( mpSim )
    person[ "ageAtRecruitment" ] = recScheme.ageDist()

    command = "INSERT INTO $(mpSim.personnelDBname) (" *
        join( keys( person ), "," ) * ") values (" *
        join( values( person ), "," ) * ")"
    SQLite.execute!( mpSim.simDB, command )

    # Add the person's entry to the history database.
    # XXX Additional attributes need to be implemented(?)
    command = "INSERT INTO $(mpSim.historyDBname) ($(mpSim.idKey), " *
        "attribute, timeIndex, strValue) values ('$id', 'status', " *
        "$(now( mpSim )), $(person[ "status" ]))"
    SQLite.execute!( mpSim.simDB, command )

    # If a proper retirement scheme has been defined, start this person's
    #   retirement process.
    # XXX Needs to be adjusted for update of retirement process implementation.
    # Necessary to retain expected retirement time in database?
    # Split retirement process up in two if necessary.
    timeOfRetirement = computeExpectedRetirementTime( mpSim, id )
    retProc = nothing

    if isa( mpSim.retirementScheme, Retirement )
        retProc = @process retireProcess( mpSim.sim, id, timeOfRetirement,
            mpSim )
    end  # if isa( mpSim.retirementScheme, Retirement )

    # If a proper attrition scheme has been defined, set the attrition process.
    #   This must be defined AFTER the retirement scheme because it requires the
    #   expected time of retirement.
    # XXX Needs to be adjusted for update of attrition process implementation.
    if isa( mpSim.attritionScheme, Attrition ) &&
        ( mpSim.attritionScheme.attrRate > 0.0 )
        @process attritionProcess( mpSim.sim, id, timeOfRetirement, retProc,
            mpSim )
    end  # if isa( mpSim.attritionScheme, Attrition ) && ...

    # Adjust the size of the personnel database.
    mpSim.personnelSize += 1
    mpSim.resultSize += 1
#=

    # If a proper retirement scheme has been defined, set the retirement
    #   process.
    if isa( mpSim.retirementScheme, Retirement )
        person[ :processRetirement ] = @process retireProcess( mpSim.sim,
            person, result, mpSim )
    else
        person[ :expectedRetirementTime ] = +Inf
    end  # if isa( mpSim.retirementScheme, Retirement )

    # If a proper attrition scheme has been defined, set the attrition process.
    #   This must be defined AFTER the retirement scheme because it requires the
    #   expected time of retirement.
    if isa( mpSim.attritionScheme, Attrition ) &&
        ( mpSim.attritionScheme.attrRate > 0.0 )
        person[ :processAttrition ] = @process attritionProcess( mpSim.sim,
            person, result, mpSim )
    end  # if isa( mpSim.attritionScheme, Attrition ) && ...
=#
end  # createPerson( mpSim, recScheme )


# This function performs the recruitment part of a single recruitment cycle.
function recruitmentCycle( mpSim::ManpowerSimulation, recScheme::Recruitment )

    nrToRecruit = generatePoolSize( recScheme )
    personnelNeeded = mpSim.personnelCap - mpSim.personnelSize

    if mpSim.personnelCap > 0
        nrToRecruit = min( personnelNeeded, nrToRecruit )
    end  # if mpSim.personnelCap > 0

    for ii in 1:nrToRecruit
        createPerson( mpSim, recScheme )
    end  # for ii in 1:nrToRecruit

end  # recruitmentCycle( mpSim, recScheme )


# This is the process in the simulation for a single recruitment scheme.
# Version for JuliaBox
@resumable function recruitProcess( sim::Simulation,
    schemeNr::Integer, mpSim::ManpowerSimulation )

    recScheme = mpSim.recruitmentSchemes[ schemeNr ]
    timeToWait = recScheme.recruitOffset
    priority = mpSim.phasePriorities[ :recruitment ]

    while now( sim ) + timeToWait <= mpSim.simLength
        @yield timeout( sim, timeToWait, priority = priority )
        timeToWait = recScheme.recruitFreq
        recruitmentCycle( mpSim, recScheme )
    end  # while now( sim ) + timeToWait <= mpSim.simLength

end

#= # Version for Atom
@resumable function recruitProcess( sim::Simulation,
    schemeNr::T, mpSim::ManpowerSimulation ) where T <: Integer
    recScheme = mpSim.recruitmentSchemes[ schemeNr ]
    timeToWait = recScheme.recruitOffset
    priority = mpSim.phasePriorities[ :recruitment ]

    while now( sim ) + timeToWait <= mpSim.simLength
        @yield timeout( sim, timeToWait, priority = priority )
        timeToWait = recScheme.recruitFreq
#        println( "Recruitment at time $(now( sim ))" )
        recruitmentCycle( mpSim, recScheme )
    end  # while now( sim ) + timeToWait <= mpSim.simLength
end
=#

function Base.show( io::IO, recScheme::Recruitment )

    out = "Recruitment schedule: $(recScheme.recruitFreq)"
    out *= " (+ $(recScheme.recruitOffset))"
    out *= "\nMax recruitment per cycle: "

    if length( recScheme.recruitMap ) == 1
        out *= "$(recScheme.recruitMap[ 1 ])"
    else
        out *= join( map( ( val, p ) -> "$val: $p", recScheme.recruitMap,
            recScheme.recruitDist.p ), "; " )
    end  # if length( recScheme.recruitMap ) == 1

    print( io, out )

end
