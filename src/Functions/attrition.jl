# This file holds the definition of the functions pertaining to the Attrition
#   type.

# The functions of the Attrition type requires the State type.
requiredTypes = [ "state", "attrition" ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( typePath, reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end  # for reqType in requiredTypes


export setAttritionRate
"""
setAttritionRate( attrScheme::Attrition,
                  rate::T )
    where T <: Real

This function sets the attrition curve of the attrition scheme `attrScheme` to a
constant value of `rate` for all terms. If the given attrition rate is 0, this
function will also set the attrition period to 1.

This function returns `nothing`.
"""
function setAttritionRate( attrScheme::Attrition, rate::T ) where T <: Real

    if ( rate < 0.0 ) || ( rate >= 1.0 )
        warn( "Attrition rate must be a percentage between 0.0 and 1.0, not making any changes." )
        return
    end  # if ( rate < 0.0 ) || ( rate > 1.0 )

    attrScheme.attrCurvePoints = [ 0.0 ]
    attrScheme.attrRates = [ rate ]

    # If the attrition rate becomes 0.0, reset the period to 1.0.
    # if rate == 0.0
    #     attrScheme.attrPeriod = 1.0
    # end  # if rate == 0.0

    computeDistPars( attrScheme )

end  # setAttritionRate( attrScheme, rate )


export setAttritionPeriod
"""
setAttritionPeriod( attrScheme::Attrition,
                    period::T )
    where T <: Real

This function sets the attrition period of the attrition scheme `attrScheme` to
`period`. If the attrition curve is a flat 0, the function warns that it has no
practical effect.

This function returns `nothing`.
"""
function setAttritionPeriod( attrScheme::Attrition, period::T ) where T <: Real

    if period <= 0.0
        warn( "Attrition period must be > 0.0, not making any changes." )
        return
    end  # if period <= 0.0

    # if attrScheme.attrRates == [ 0.0 ]
    #     warn( "Attrition rate is a flat 0.0, changing the period has no effect." )
    #     return
    # end  # if attrScheme.attrRates == [ 0.0 ]

    attrScheme.attrPeriod = period
    computeDistPars( attrScheme )

end  # setAttritionPeriod( attrScheme, period )


export setAttritionParameters
"""
setAttritionParameters( attrScheme::Attrition,
                        rate::T1,
                        period::T2 )
    where T1 <: Real where T2 <: Real

This function sets the attrition rate of attrition scheme `attrScheme` to a
fixed attrition rate `rate` per period of length `period`.

This function returns `nothing`.
"""
function setAttritionParameters( attrScheme::Attrition, rate::T1, period::T2 ) where T1 <: Real where T2 <: Real

    setAttritionRate( attrScheme, rate )

    # if rate != 0.0
        setAttritionPeriod( attrScheme, period )
    # end  # if rate != 0.0

end  # setAttritionParameters( attrScheme, rate, period )


"""
setAttritionParameters( mpSim::ManpowerSimulation,
                        rate::T1,
                        period::T2 )
    where T1 <: Real where T2 <: Real

This function sets the attrition rate of attrition scheme in the manpower
simulation `mpSim` to a fixed attrition rate `rate` per period of length
`period`.

This function returns `nothing`.
"""
function setAttritionParameters( mpSim::ManpowerSimulation, rate::T1,
    period::T2 ) where T1 <: Real where T2 <: Real

    if rate == 0.0
        mpSim.defaultAttritionScheme = nothing
    elseif mpSim.defaultAttritionScheme === nothing
        mpSim.defaultAttritionScheme = Attrition( rate, period )
    else
        setAttritionParameters( mpSim.defaultAttritionScheme, rate, period )
    end  # if rate == 0.0

end  # setAttritionParameters( mpSim, rate, period )


export setAttritionCurve
"""
setAttritionCurve( attrScheme::Attrition,
                   curve::Array{Float64, 2} )

This function sets the attrition curve of attrition scheme `attrScheme` to
`curve`. The attrition curve is passed as a 2-dimensional `Array{Float64, 2}`
with 2 columns. The first column has the time a person exists in the simulation,
and the second column has the attrition rates per period from the time specified
by that key to the next.

This function returns `nothing`. If the given array does not have exactly 2
columns, or if there are duplicate entries in the first column, this function
does not make any changes.

This function ignores negative terms and non sensical attrition rates. If this
results in an empty set of eligible curve points, the attrition rate is set to a
constant 0 instead. The first eligible node has its term set to 0.
"""
function setAttritionCurve( attrScheme::Attrition, curve::Array{Float64, 2} )

    # Check for correct dimensions.
    if size( curve )[ 2 ] != 2
        warn( "Invalid array given to define attrition curve, not making any changes." )
        return
    end  # if size( curve )[ 2 ] != 2

    # Check for duplicate terms.
    if length( curve[ :, 1 ] ) != length( unique( curve[ :, 1 ] ) )
        warn( "Duplicate entries in the terms of the attrition curve, not making any changes." )
        return
    end  # if length( curve[ :, 1 ] ) != length( unique( curve[ :, 1 ] ) )

    # Remove curve points with non sensical attrition rates.
    tmpCurve = curve[ map( ii -> 0 <= curve[ ii, 2 ] < 1,
        eachindex( curve[ :, 1 ] ) ), : ]

    # Flat 0 rate if no more nodes are eligible.
    if isempty( tmpCurve )
        setAttritionRate( attrScheme, 0 )
        return
    end  # if isempty( tmpNodes )

    # Remove curve points with negative terms.
    tmpCurve = sortrows( tmpCurve, by = x -> x[ 1 ] )
    lastNegIndex = findlast( tmpCurve[ :, 1 ] .<= 0 )
    tmpCurve = tmpCurve[ lastNegIndex:end, : ]

    # Filter out consecutive nodes with the same attrition rate.
    tmpCurve[ 1, 1 ] = 0.0
    isDiffFromPrevious = vcat( true,
        tmpCurve[ 2:end, 2 ] .!= tmpCurve[ 1:( end - 1 ), 2 ] )

    # Update the attrition scheme.
    attrScheme.attrCurvePoints = tmpCurve[ isDiffFromPrevious, 1 ]
    attrScheme.attrRates = tmpCurve[ isDiffFromPrevious, 2 ]
    computeDistPars( attrScheme )

end  # setAttritionCurve( attrScheme, curve )


"""
setAttritionCurve( attrScheme::Attrition,
                   curve::Dict{Float64, Float64} )

This function sets the attrition curve of attrition scheme `attrScheme` to
`curve`. The attrition curve is passed as a `Dict{Float64, Float64}` with the
keys as the time a person exists in the simulation, and the values as the
attrition rates per period from the time specified by that key to the next.

This function returns `nothing`.

This function ignores negative keys and non sensical attrition rates. If this
results in an empty set of eligible curve points, the attrition rate is set to a
constant 0 instead. The first eligible node has its term set to 0.
"""
function setAttritionCurve( attrScheme::Attrition,
    curve::Dict{Float64, Float64} )

    terms = collect( keys( curve ) )
    rates = map( term -> curve[ term ], terms )
    setAttritionCurve( attrScheme, hcat( terms, collect( rates ) ) )

end  # setAttritionCurve( attrScheme, curve )


export addAttritionScheme!
"""
```
addAttritionScheme!( attrScheme::Attrition,
                     mpSim::ManpowerSimulation )
```
This function adds the attrition scheme `attrScheme` to the manpower simulation
`mpSim`. If the attrition scheme has the name `default`, the function overwrites
the default scheme of the manpower simulation (and warns about this), and if the
attrition scheme has a name that is already used, the other scheme with this
name gets overwritten.

This function returns `nothing`.
"""
function addAttritionScheme!( attrScheme::Attrition,
    mpSim::ManpowerSimulation )::Void

    # If the scheme's name is "default", overwrite the default scheme.
    if attrScheme.name == "default"
        warn( "Overwriting default attrition scheme." )
        mpSim.defaultAttritionScheme = attrScheme
        return
    end  # if attrScheme.name == "default"

    # If an attrition scheme with that name exists, overwrite it.
    if haskey( mpSim.attritionSchemes, attrScheme.name )
        warn( "Overwriting attrition scheme '$(attrScheme.name)'.")
    end  # if haskey( mpSim.attritionSchemes, attrScheme.name )

    mpSim.attritionSchemes[ attrScheme.name ] = attrScheme
    return

end  # addAttritionScheme!( attrScheme, mpSim )


export clearAttritionSchemes!
"""
```
clearAttritionSchemes!( mpSim::ManpowerSimulation )
```
This function clears all attrition schemes, except the default, from the
manpower simulation `mpSim`.

This function returns `nothing`.
"""
function clearAttritionSchemes!( mpSim::ManpowerSimulation )::Void

    empty!( mpSim.attritionSchemes )
    return

end  # clearAttritionSchemes!( mpSim )


# ==============================================================================
# Non-exported methods.
# ==============================================================================


"""
```
readAttrition( attrCat::XLSX.Worksheet,
               sLine::Int )
```
This function reads the Excel sheet `attrCat`, starting in the row with number
`sLine`, to read the parameters of the attritition scheme.

This function returns an object of type `Attrition`, the attrition scheme.
"""
function readAttrition( attrCat::XLSX.Worksheet, sLine::Int )::Attrition

    attrName = string( attrCat[ "A$sLine" ] )

    # Check if it's the default attrition scheme.
    if lowercase( attrName ) == "default"
        attrName = "default"
    end  # if lowercase( attrName ) == "default"

    newAttrScheme = Attrition( attrName )
    attrPeriod = attrCat[ "B$sLine" ]
    nPoints =  attrCat[ "C$sLine" ]
    attrCurve = zeros( nPoints, 2 )

    for ii in 1:nPoints
        attrCurve[ ii, : ] = [ attrCat[ XLSX.CellRef( sLine, 2 + 2 * ii ) ],
            attrCat[ XLSX.CellRef( sLine, 3 + 2 * ii ) ] ]
    end  # for ii in 1:nPoints

    attrCurve[ :, 1 ] *= attrPeriod
    setAttritionCurve( newAttrScheme, attrCurve )
    setAttritionPeriod( newAttrScheme, attrPeriod )
    return newAttrScheme

end  # readAttrition( attrCat, sLine )


"""
```
computeDistPars( attrScheme::Attrition )
```
This function pre-computes some reoccurring parameters of the distribution of
the time to attrition of the attrition scheme `attrScheme`.

This function returns `nothing`.
"""
function computeDistPars( attrScheme::Attrition )::Void

    attrScheme.lambdas = - log.( 1 - attrScheme.attrRates ) /
        attrScheme.attrPeriod
    alpha = vcat( 1.0, exp.( - ( attrScheme.lambdas[ 1:(end - 1) ] -
        attrScheme.lambdas[ 2:end ] ) .* attrScheme.attrCurvePoints[ 2:end ] ) )
    attrScheme.betas = cumprod( alpha )
    attrScheme.gammas = attrScheme.betas .*
        exp.( - attrScheme.lambdas .* attrScheme.attrCurvePoints )
    return

end  # computeDistPars( attrScheme )


"""
```
determineAttritionScheme( stateList::Vector{String},
                          mpSim::ManpowerSimulation )
```
This function determines the appropriate attrition scheme to use for a personnel
member belonging to the states in `statList`. The available attrition schemes
are found in the manpower simulation `mpSim`.

This function returns an object of type `Attrition` (an attrition scheme). If
multiple schemes qualify, the first is returned; if none qualify, the default
attrition scheme is returned.
"""
function determineAttritionScheme( stateList::Vector{State},
    mpSim::ManpowerSimulation )::Attrition

    # XXX Check states and determine appropriate schemes.
    attrList = map( state -> state.attrScheme, stateList )
    filter!( attrScheme -> attrScheme !== mpSim.defaultAttritionScheme,
        attrList )

    return isempty( attrList ) ? mpSim.defaultAttritionScheme : attrList[ 1 ]

end  # determineAttritionScheme( stateList, mpSim )


"""
```
generateTimeOfAttrition( attrScheme::Attrition,
                         nowTime::Float64 )
```
This function generates a time to attrition for the attrition scheme
`attrScheme`, starting from the current time.

This function returns a `Float64`, the time to attrition, or a `String` equal to
`"NULL"` if the time to attrition is infinite.
"""
function generateTimeOfAttrition( attrScheme::Attrition, nowTime::Float64 )

    u = rand()
    ii = findlast( 1 - attrScheme.gammas .<= u )

    if ( ii == length( attrScheme.attrCurvePoints ) ) &&
        ( attrScheme.lambdas[ end ] == 0 )
        return "NULL"
    end  # if ( ii == length( attrScheme.attrCurvePoints ) ) && ...

    return nowTime -
        log( ( 1 - u ) / attrScheme.betas[ ii ] ) / attrScheme.lambdas[ ii ]

end  # generateTimeOfAttrition( attrScheme, nowTime )


"""
```
updateTimeToAttrition( stateList::Dict{String, Vector{State}},
                       mpSim::ManpowerSimulation )
```
This function updates the time to attrition for all the personnel members with
ids in the key list of `stateList` (the argument is a list of the states the
personnel member is in), using the attrition schemes defined in the manpower
simulation `mpSim`.

This function returns `nothing`.
"""
function updateTimeToAttrition( stateList::Dict{String, Vector{State}},
    mpSim::ManpowerSimulation )::Void

    if isempty( stateList )
        return
    end  # if isempty( stateList )

    queryCmd = "SELECT $(mpSim.idKey), attritionScheme
        FROM $(mpSim.personnelDBname)
        WHERE $(mpSim.idKey) IN ('$(join( collect( keys( stateList ) ), "', '" ))')"
    attrList = SQLite.query( mpSim.simDB, queryCmd )
    idList = Vector{String}()
    newAttrTimeList = Vector{Float64}()

    for ii in eachindex( attrList[ Symbol( mpSim.idKey ) ] )
        id = attrList[ Symbol( mpSim.idKey ) ][ ii ]
        attrScheme = determineAttritionScheme( stateList[ id ], mpSim )

        # Generate a new time to attrition
        if attrList[ :attritionScheme ][ ii ] != attrScheme.name
            timeToAttr = generateTimeOfAttrition( attrScheme, now( mpSim ) )
            push!( idList, id )
            push!( newAttrTimeList,
                isa( timeToAttr, String ) ? +Inf : timeToAttr )

            # Update database
            updateCmd = "UPDATE $(mpSim.personnelDBname)
                SET attritionScheme = '$(attrScheme.name)',
                    expectedAttritionTime = $timeToAttr
                WHERE $(mpSim.idKey) IS '$id'"
            SQLite.execute!( mpSim.simDB, updateCmd )
        end  # if attrSchemeList[ id ] != attrScheme.name
    end  # for ii in length( attrList[ Symbol( mpSim.idKey ) ] )

    if isempty( idList )
        return
    end  # if isempty( idList )

    # Check if any of the new attrition times occur before the next attrition
    #   process check.
    newProcessCheckTime = ceil( now( mpSim ) / mpSim.attritionTimeSkip ) *
        mpSim.attritionTimeSkip

    for ii in eachindex( idList )
        if newAttrTimeList[ ii ] <= newProcessCheckTime
            executeAttritionProcess( mpSim.sim, idList[ ii ],
                newAttrTimeList[ ii ], mpSim )
        end  # if newAttrTimeList[ ii ] <= newProcessCheckTime
    end

end  # updateTimeToAttrition( stateList, mpSim )


#=
@resumable
attritionProcess( sim::SimJulia.Simulation,
                  id::String,
                  timeOfRetirement::T,
                  retProc::ResumableFunctions.Process,
                  mpSim::ManpowerSimulation )
    where T <: Real

This SimJulia process handles the career attrition for the person with ID `id`
in the manpower simulation `mpSim`.

The expected time of retirement for this person is `timeOfRetirement`, and the
associated retirement process is `retProc`. The argument `sim` is the
SimJulia.Simulation component of the manpower simulation, and is required by the
@process macro.
=#
@resumable function attritionProcess( sim::Simulation, id::String,
    timeOfRetirement::T, #retProc::Process, mpSim::ManpowerSimulation ) where T <: Real
    mpSim::ManpowerSimulation ) where T <: Real

    attrScheme = mpSim.defaultAttritionScheme
    timeOfEntry = now( sim )
    checkForAttrition = true
    rateIndex = 1
    attrRate = -1
    lambda = 0
    timeOfRateChange = 0
    queryCmd = "SELECT $(mpSim.idKey) FROM $(mpSim.personnelDBname)
        WHERE ( $(mpSim.idKey) IS '$id' ) AND
            ( status NOT IN ('fired', 'retirement') )"

    while checkForAttrition
        # Update attrition rate and time of next rate change if necessary.
        if attrScheme.attrRates[ rateIndex ] != attrRate
            attrRate = attrScheme.attrRates[ rateIndex ]
            lambda = - log( 1 - attrRate ) / attrScheme.attrPeriod
            timeOfRateChange = length( attrScheme.attrRates ) == rateIndex ?
                +Inf : attrScheme.attrCurvePoints[ rateIndex + 1 ] + timeOfEntry
        end  # if attrScheme.attrRates[ rateIndex ] != attrRate

        # If the attrition rate is 0, skip right ahead or terminate the
        #   attrition process, whichever is required.
        if attrRate == 0
            # Terminate if the rest of the curve is a flat 0 attrition rate.
            if length( attrScheme.attrRates ) == rateIndex
                checkForAttrition = false
            # Terminate if the time of the next rate change is
            # 1. Outside the simulation time frame, or
            # 2. Past the expected retirement time.
            elseif ( timeOfRateChange > mpSim.simLength ) ||
                ( timeOfRateChange > timeOfRetirement )
                checkForAttrition = false
            # Otherwise, skip ahead to the next attrition rate change.
            else
                @yield timeout( sim, timeOfRateChange - now( sim ),
                    priority = mpSim.phasePriorities[ :attrition ] )
                rateIndex += 1
            end  # if length( attrScheme.attrRates ) == rateIndex
        # Otherwise, perform attrition checks.
        else
            attrTime = rand( Exponential( 1 / lambda ) )
            timeOfAttr = now( sim ) + attrTime
            nextAttrPeriodStart = now( sim ) + attrScheme.attrPeriod

            # Check if attrition happens in the current attrition period.
            # 1. Attrition happens in simulation timeframe
            # 2. If yes, attrition happens in attrition period.
            # 3. If yes, attrition happens before next rate change.
            # 4. If yes, attrition happens before retirement.
            # 5. If yes, interrupt retirement process.
            if ( timeOfAttr <= mpSim.simLength ) &&
                ( attrTime <= attrScheme.attrPeriod ) &&
                ( timeOfAttr <= timeOfRateChange ) &&
                ( timeOfAttr <= timeOfRetirement )
                @yield timeout( sim, attrTime,
                    priority = mpSim.phasePriorities[ :attrition ] )

                # Make sure the person hasn't been fired.
                result = SQLite.query( mpSim.simDB, queryCmd )

                if size( result ) == ( 1, 1 )
                    retirePerson( mpSim, id, "attrition" )
                end  # if size( result ) == ( 1, 1 )

                checkForAttrition = false

                # The interrupt is only sensible if the retirement process (still)
                #   exists. This can be detected by testing for finite exptected
                #   retirement time.
                # if timeOfRetirement < +Inf
                #     interrupt( retProc )
                # end  # if timeOfRetirement < +Inf
            end  # if ( timeOfAttr <= mpSim.simLength ) && ...
        end  # if attrRate == 0

        # Check if it's sensible to start a next attrition period.
        # 1. Attrition hasn't happened yet.
        # 2. If yes, next attrition period starts in simulation timeframe.
        # 3. If yes, next attrition period starts before retirement.
        # 4. If yes, wait for next attrition period.
        if checkForAttrition && ( nextAttrPeriodStart <= mpSim.simLength ) &&
            ( nextAttrPeriodStart < timeOfRetirement )
            tmpWaitTime = min( attrScheme.attrPeriod,
                timeOfRateChange - now( sim ) )

            @yield timeout( sim, tmpWaitTime,
                priority = mpSim.phasePriorities[ :attrition ] )

            # Make sure the person hasn't been fired.
            result = SQLite.query( mpSim.simDB, queryCmd )

            if size( result ) != ( 1, 1 )
                checkForAttrition = false
            end  # if size( result ) != ( 1, 1 )

            # Prepare to update attrition rate if necessary.
            if now( sim ) == timeOfRateChange
                rateIndex += 1
            end
        else
            checkForAttrition = false
        end  # if checkForAttrition && ...
    end  # while checkForAttrition

end  # attritionProcess( sim, id, timeOfRetirement, mpSim )


@resumable function checkAttritionProcess( sim::Simulation, mpSim::ManpowerSimulation )

    processTime = Dates.Millisecond( 0 )
    tStart = now()
    timeOfNextCheck = 0.0
    priority = mpSim.phasePriorities[ :attrCheck ]
    queryCmd = "SELECT $(mpSim.idKey), expectedAttritionTime
        FROM $(mpSim.personnelDBname)
        WHERE status NOT IN ('retirement', 'attrition', 'fired')
            AND expectedAttritionTime <= "

    while now( sim ) < mpSim.simLength
        processTime += now() - tStart

        @yield( timeout( sim, timeOfNextCheck - now( sim ),
            priority = priority ) )

        tStart = now()
        timeOfNextCheck += mpSim.attritionTimeSkip
        timeOfNextCheck = timeOfNextCheck > mpSim.simLength ? mpSim.simLength :
            timeOfNextCheck
        queryResult = SQLite.query( mpSim.simDB,
            queryCmd * string( timeOfNextCheck ) )
        processTime += now() - tStart

        for ii in 1:length( queryResult[ 1 ] )
            @process executeAttritionProcess( sim, queryResult[ 1 ][ ii ],
                queryResult[ 2 ][ ii ], mpSim )
        end  # for ii in 1:length( queryResult[ 1 ] )

        tStart = now()
    end  # while now( sim ) < mpSim.simLength

    processTime += now() - tStart
    println( "Attrition check process took $(processTime.value / 1000) seconds." )

end  # checkAttritionProcess( sim, mpSim )


# This process executes the attrition if it occurs in the next period.
@resumable function executeAttritionProcess( sim::Simulation, id::String,
    timeOfAttrition::Float64, mpSim::ManpowerSimulation )

    # Wait until the time attrition should take place.
    @yield( timeout( sim, timeOfAttrition - now( sim ),
        priority = mpSim.phasePriorities[ :attrition ] ) )

    tStart = now()
    # Get the personnel record.
    queryCmd = "SELECT expectedAttritionTime, status
        FROM $(mpSim.personnelDBname)
        WHERE $(mpSim.idKey) IS '$id'"
    persRecord = SQLite.query( mpSim.simDB, queryCmd )

    # Only perform the attrition if the person is still active and the time of
    #   attrition hasn't changed.
    if ( persRecord[ :status ][ 1 ] ∉
        [ "attrition", "retirement", "fired" ] ) &&
        ( persRecord[ :expectedAttritionTime ][ 1 ] == timeOfAttrition )
        retirePerson( mpSim, id, "attrition" )
    end  # if ( persRecord[ :status ][ 1 ] ∉ ...

    mpSim.attrExecTimeElapsed += now() - tStart

end  # executeAttritionProcess( sim, id, timeOfAttrition, mpSim )


function Base.show( io::IO, attrScheme::Attrition )

    print( io, "  Attrition scheme '$(attrScheme.name)'" )

    if attrScheme.attrRates == [ 0.0 ]
        print( io, "\n    No attrition." )
        return
    end  # if attrScheme.attrRates == [ 0.0 ]

    print( io, "\n    Attrition period: $(attrScheme.attrPeriod)" )

    if length( attrScheme.attrRates ) == 1
        print( io, "\n    Attrition rate: $(attrScheme.attrRates[ 1 ] * 100)%" )
    else
        print( io, "\n    Attrition curve" )

        for ii in eachindex( attrScheme.attrRates )
            print( io, "\n      term: $(attrScheme.attrCurvePoints[ ii ]);" )
            print( io, "   rate: $(attrScheme.attrRates[ ii ] * 100)%" )
        end  # for ii in eachindex( attrScheme.attrRates )
    end  # if length( attrScheme.attrRates ) == 1

end  # Base.show( io, retScheme )
