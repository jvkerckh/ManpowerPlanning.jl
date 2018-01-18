# This file holds the definition of the functions pertaining to the Attrition
#   type.

# The functions of the Attrition type require no additional types.
requiredTypes = [ "attrition" ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( dirname( Base.source_path() ), "..", "Types",
            reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end  # for reqType in requiredTypes


# This function sets the attrition rate of the attrition scheme. This rate is
#   given as a percentage.
export setAttritionRate
function setAttritionRate( attrScheme::Attrition, rate::T ) where T <: Real

    if ( rate < 0.0 ) || ( rate >= 100.0 )
        warn( "Attrition rate must be a percentage between 0.0 and 100.0, not making any changes." )
        return
    end  # if ( rate < 0.0 ) || ( rate > 100.0 )

    attrScheme.attrRate = rate / 100.0

    # If the attrition rate becomes 0.0, reset the period to 1.0.
    if rate == 0.0
        attrScheme.attrPeriod = 1.0
    end  # if rate == 0.0

end  # setAttritionRate( attrScheme, rate )


# This function sets the attrition period of the attrition scheme. If the
#   attrition rate is 0.0, nothing happens.
export setAttritionPeriod
function setAttritionPeriod( attrScheme::Attrition, period::T ) where T <: Real

    if attrScheme.attrRate == 0.0
        warn( "Attrition rate is 0.0, changing the period has no effect so not making any changes." )
        return
    end  # if attrScheme.attrRate == 0.0

    if period <= 0.0
        warn( "Attrition period must be > 0.0, not making any changes." )
        return
    end  # if period <= 0.0

    attrScheme.attrPeriod = period

end  # setAttritionPeriod( attrScheme, period )


# This function sets both attrition parameters of the attrition scheme. If the
#   attrition rate is 0.0, the period parameter is ignored, and the period will
#   be set to 1.0.
export setAttritionParameters
function setAttritionParameters( attrScheme::Attrition, rate::T1, period::T2 ) where T1 <: Real where T2 <: Real

    setAttritionRate( attrScheme, rate )

    if rate != 0.0
        setAttritionPeriod( attrScheme, period )
    end  # if rate != 0.0

end  # setAttritionParameters( attrScheme, rate, period )


function setAttritionParameters( mpSim::ManpowerSimulation, rate::T1,
    period::T2 ) where T1 <: Real where T2 <: Real

    oldAttritionRate = mpSim.attritionScheme === nothing ? 0.0 :
        mpSim.attritionScheme.attrRate * 100.0
    oldAttritionPeriod = oldAttritionRate == 0.0 ? 1.0 :
        mpSim.attritionScheme.attrPeriod

    # Check if the attrition scheme must be updated or not.
    isUpdateNeeded = ( oldAttritionRate != rate ) && ( rate != 0.0 ) &&
        ( oldAttritionPeriod != period )

    # Don't make unnecessary changes.
    if !isUpdateNeeded
        return
    end  # if !isUpdateNeeded

    if rate == 0.0
        mpSim.attritionScheme = nothing
    elseif mpSim.attritionScheme === nothing
        mpSim.attritionScheme = Attrition( rate, period )
    else
        setAttritionParameters( mpSim.attritionScheme, rate, period )
    end  # if rate == 0.0

end  # setAttritionParameters( mpSim, rate, period )


# This function generates a time to attrition. This is drawn from an
#   exponential distribution T, where lambda is chosen such that
#   P( T < period ) = rate.
export generateAttritionTime
function generateAttritionTime( attrScheme::Attrition )  # XXX will need to be refined

    lambda = - log( 1 - attrScheme.attrRate ) / attrScheme.attrPeriod
    return rand( Exponential( 1 / lambda ) )

end  # generateAttritionTime( attrScheme )


# This is the process in the simulation that handles the attrition of a person.
@resumable function attritionProcess( sim::Simulation, id::String,
    timeOfRetirement::T, retProc::Process, mpSim::ManpowerSimulation ) where T <: Real

    attrScheme = mpSim.attritionScheme
    checkForAttrition = true

    while checkForAttrition
        attrTime = generateAttritionTime( attrScheme )
        timeOfAttr = now( sim ) + attrTime
        nextAttrPeriodStart = now( sim ) + attrScheme.attrPeriod

        # Check if attrition happens in the current attrition period.
        # 1. Attrition happens in simulation timeframe
        # 2. If yes, attrition happens in attrition period.
        # 3. If yes, attrition happens before retirement.
        # 4. If yes, interrupt retirement process.
        if ( timeOfAttr <= mpSim.simLength ) &&
            ( attrTime <= attrScheme.attrPeriod ) &&
            ( timeOfAttr <= timeOfRetirement )
            @yield timeout( sim, attrTime,
                priority = mpSim.phasePriorities[ :attrition ] )
            retirePerson( mpSim, id, "resigned" )
            checkForAttrition = false

            # The interrupt is only sensible if the retirement process (still)
            #   exists. This can be detected by testing for finite exptected
            #   retirement time.
            if timeOfRetirement < +Inf
                interrupt( retProc )
            end  # if timeOfRetirement < +Inf
        end  # if ( timeOfAttr <= mpSim.simLength ) && ...

        # Check if it's sensible to start a next attrition period.
        # 1. Attrition hasn't happened yet.
        # 2. If yes, next attrition period starts in simulation timeframe.
        # 3. If yes, next attrition period starts before retirement.
        # 4. If yes, wait for next attrition period.
        if checkForAttrition && ( nextAttrPeriodStart <= mpSim.simLength ) &&
            ( nextAttrPeriodStart < timeOfRetirement )
            @yield timeout( sim, attrScheme.attrPeriod,
                priority = mpSim.phasePriorities[ :attrition ] )
        else
            checkForAttrition = false
        end  # if checkForAttrition && ...
    end  # while checkForAttrition

end  # attritionProcess( sim, id, timeOfRetirement, retProc, mpSim )


@resumable function attritionProcess( sim::Simulation, person::Personnel,
    result::Personnel, mpSim::ManpowerSimulation )

    attrScheme = mpSim.attritionScheme
    checkForAttrition = true

    while checkForAttrition
        attrTime = generateAttritionTime( attrScheme )
        timeOfAttr = now( sim ) + attrTime
        nextAttrPeriodStart = now( sim ) + attrScheme.attrPeriod

        # Checks to perform:
        # 1. Attrition happens in simulation timeframe
        # 2. If yes, attrition happens in attrition period.
        # 3. If yes, attrition happens before retirement.
        # 4. If yes, interrupt retirement process.
        if ( timeOfAttr <= mpSim.simLength ) &&
            ( attrTime <= attrScheme.attrPeriod ) &&
            ( timeOfAttr <= person[ :expectedRetirementTime ] )
            @yield timeout( sim, attrTime,
                priority = mpSim.phasePriorities[ :attrition ] )
            retirePerson( mpSim, person, result, :resigned )
            checkForAttrition = false

            # The interrupt is only sensible if the retirement process (still)
            #   exists. This can be detected by testing for finite exptected
            #   retirement time.
            if person[ :expectedRetirementTime ] < +Inf
                interrupt( person[ :processRetirement ] )
            end  # if person[ :expectedRetirementTime ] < +Inf
        end  # if ( timeOfAttr <= mpSim.simLength ) && ...

        # 1. Attrition hasn't happened yet.
        # 2. If yes, next attrition period starts in simulation timeframe.
        # 3. If yes, next attrition period starts before retirement.
        # 4. If yes, wait for next attrition period.
        if checkForAttrition && ( nextAttrPeriod <= mpSim.simLength ) &&
            ( nextAttrPeriodStart < person[ :expectedRetirementTime ] )
            @yield timeout( sim, attrScheme.attrPeriod,
                priority = mpSim.phasePriorities[ :attrition ] )
        else
            checkForAttrition = false
        end  # if checkForAttrition && ...
    end  # while checkForAttrition

end  # attritionProcess( sim, person, result, mpSim )


function Base.show( io::IO, attrScheme::Attrition )

    if attrScheme.attrRate == 0.0
        print( io, "No attrition scheme." )
        return
    end  # if attrScheme.attrRate == 0.0

    print( io, "Attrition rate: $(attrScheme.attrRate * 100)%" )
    print( io, "\nAttrition period: $(attrScheme.attrPeriod)" )

end  # Base.show( io, retScheme )
