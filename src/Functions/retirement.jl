# This file covers everything related to retirement.

# The functions of the Retirement type require SimJulia and ResumableFunctions.

# The functions of the Retirement type require the Personnel, PersonnelDatabase,
#   and ManpowerSimulation types.
requiredTypes = [ "manpowerSimulation",
    "retirement" ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( typePath, reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end  # for reqType in requiredTypes


if !isdefined( :retirementReasons )
    const retirementReasons = [ "retirement", "attrition", "fired" ]
end # if !isdefined( :retirementReasons )


function retirePerson( mpSim::ManpowerSimulation, id::String, reason::String )

    mpSim.personnelSize -= 1
    personInStates = [ "active" ]

    for state in keys( merge( mpSim.initStateList, mpSim.otherStateList ) )
        if haskey( state.inStateSince, id )
            push!( personInStates, state.name )
        end  # if haskey( state.inStateSince, id )

        delete!( state.inStateSince, id )
    end  # for id in keys( merge( ...

    # Change the person's status in the personnel database.
    command = "UPDATE `$(mpSim.personnelDBname)`
        SET status = '$reason', timeExited = $(now( mpSim ))
        WHERE `$(mpSim.idKey)` = '$id'"
    SQLite.execute!( mpSim.simDB, command )

    # Add the person's status change to the history database.
    command = "INSERT INTO `$(mpSim.historyDBname)`
        (`$(mpSim.idKey)`, attribute, timeIndex, strValue) VALUES
        ('$id', 'status', $(now( mpSim )), '$reason')"
    SQLite.execute!( mpSim.simDB, command )

    # Add the person's retirement event to the transition database.
    retEvents = "('$id', $(now( mpSim )), '$reason', '" .*
        personInStates .* "')"
    command = "INSERT INTO `$(mpSim.transitionDBname)`
        (`$(mpSim.idKey)`, timeIndex, transition, startState) VALUES
        $(join( retEvents, ", " ))"
    SQLite.execute!( mpSim.simDB, command )

end  # retirePerson( mpSim, id, reason )


function retirePersons( mpSim::ManpowerSimulation, ids::Vector{String},
    reason::String )::Void

    if isempty( ids )
        return
    end  # if isempty( ids )

    mpSim.personnelSize -= length( ids )
    idsInStates = ids
    personInStates = fill( "active", length( ids ) )

    for state in keys( merge( mpSim.initStateList, mpSim.otherStateList ) ),
        id in ids
        if haskey( state.inStateSince, id )
            push!( idsInStates, id )
            push!( personInStates, state.name )
        end  # if haskey( state.inStateSince, id )

        delete!( state.inStateSince, id )
    end  # for state in keys( merge( ...

    # Change the person's status in the personnel database.
    command = "UPDATE `$(mpSim.personnelDBname)`
        SET status = '$reason', timeExited = $(now( mpSim ))
        WHERE `$(mpSim.idKey)` IN ('$(join( ids, "', '" ))')"
    SQLite.execute!( mpSim.simDB, command )

    # Add the person's status change to the history database.
    command = "('" .* ids .* "', 'status', $(now( mpSim )), '$reason')"
    command = "INSERT INTO `$(mpSim.historyDBname)`
        (`$(mpSim.idKey)`, attribute, timeIndex, strValue) VALUES
        $(join( command, ", " ))"
    SQLite.execute!( mpSim.simDB, command )

    # Add the person's retirement event to the transition database.
    command = "('" .* idsInStates .* "', $(now( mpSim )), '$reason', '" .*
        personInStates .* "')"
    command = "INSERT INTO `$(mpSim.transitionDBname)`
        (`$(mpSim.idKey)`, timeIndex, transition, startState) VALUES
        $(join( command, ", " ))"
    SQLite.execute!( mpSim.simDB, command )
    return

end  # retirePersons( mpSim, ids, reason )
