function generateTimeToAttrition( attrition::Attrition, nVals::Int )

    urand = rand( nVals )
    nSections = map( u -> findlast( u .<= attrition.gammas ), urand )
    result = map( 1:nVals ) do ii
        nSection = nSections[ ii ]

        if attrition.lambdas[ nSection ] == 0
            return +Inf
        end  # if attrition.lambdas[ nSection ] == 0

        attrTime = attrition.curvePoints[ nSection ]
        attrTime -= log( urand[ ii ] / attrition.gammas[ nSection ] ) /
            attrition.lambdas[ nSection ]
        return attrTime * attrition.period
    end  # map( 1:nVals ) do ii

    return result ./ attrition.period

end  # generateTimeToAttrition( attrition, nVals )


@resumable function checkAttritionProcess( sim::Simulation, mpSim::MPsim )

    # Timing of the process.
    processTime = Dates.Millisecond( 0 )
    tStart = now()
    attName = string( "Attrition check process " )

    # Preparatory steps.
    timeOfNextCheck = mpSim.attritionTimeSkip
    priority = typemax( Int8 )
    queryCmd = string( "SELECT `", mpSim.idKey, "`, expectedAttritionTime ",
        "FROM `", mpSim.persDBname, "` WHERE",
        "\n    status IS 'active' AND expectedAttritionTime <= " )
    idSymb = Symbol( mpSim.idKey )
    
    while now( sim ) < mpSim.simLength
        processTime += now() - tStart
        @yield( timeout( sim, timeOfNextCheck - now( sim ),
            priority = priority ) )
        tStart = now()

        # Find who'll undergo attrition in the next cycle.
        timeOfNextCheck += mpSim.attritionTimeSkip
        timeOfNextCheck = timeOfNextCheck > mpSim.simLength ? mpSim.simLength :
            timeOfNextCheck
        result = DataFrame( SQLite.Query( mpSim.simDB,
            string( queryCmd, timeOfNextCheck ) ) )

        # Execute attrition process for these people.
        processTime += now() - tStart

        for ii in 1:size( result, 1 )
            @process executeAttritionProcess( sim, result[ ii, idSymb ],
                result[ ii, :expectedAttritionTime ], mpSim, priority )
        end  # for ii in 1:size( result, 1 )

        tStart = now()
    end  # while now( sim ) < mpSim.simLength

    # Timing of the process.
    processTime += now() - tStart

    if mpSim.showInfo
        println( attName, "took ", processTime.value / 1000,
            " seconds." )
    end  # if mpSim.showInfo
    
end  # checkAttritionProcess( sim, mpSim )


@resumable function executeAttritionProcess( sim::Simulation, id::String,
    expAttrTime::Float64, mpSim::MPsim, priority::Int8 )

    # Wait until the time attrition should take place.
    @yield( timeout( sim, expAttrTime - now( sim ), priority = priority ) )
    tStart = now()

    # Get the personnel record.
    queryCmd = string( "SELECT expectedAttritionTime, status, currentNode ",
        "FROM `", mpSim.persDBname, "`  WHERE",
        "\n    `", mpSim.idKey, "` IS '", id, "'" )
    persRecord = DataFrame( SQLite.Query( mpSim.simDB, queryCmd ) )

    # Only perform the attrition if the person is still active and the time of
    #   attrition hasn't changed.
    if ( persRecord[ 1, :status ] == "active" ) &&
        ( persRecord[ 1, :expectedAttritionTime ] == expAttrTime )
        removePerson( id, persRecord[ 1, :currentNode ], "attrition", mpSim )
    end  # if ( persRecord[ 1, :status ] == "active" ) && ...

    mpSim.attritionExecTime += now() - tStart

end  # executeAttritionProcess( sim, id, expAttrTime, mpSim )