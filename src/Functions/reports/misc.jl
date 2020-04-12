"""
```
generateTimeGrid(
    mpSim::ManpowerSimulation,
    timeRes::Real,
    addCurrentTime::Bool = true )
```
This function generates a time grid for the manpower simulation `mpSim` with time resolution `timeRes`. The resulting grid will span from 0 to the current simulation time or the length of the simulation, whichever is smaller. If the flag `addCurrentTime` is set to `true`, the current simulation time will be added at the end.

This function issues a warning if the entered time resolution is ⩽ 0, and if the simulation hasn't started yet (current sim time == 0).

This function returns a `Vector{Float64}`, the time grid. If the entered time resolution is < 0, this vector will be empty.
"""
function generateTimeGrid( mpSim::MPsim, timeRes::Real,
    addCurrentTime::Bool = true )

    if timeRes <= 0
        @warn "Time resolution must be > 0, not generating time grid." 
        return Vector{Float64}()
    end  # if timeRes <= 0

    currentTime = now( mpSim )

    if currentTime == 0
        @warn "Simulation hasn't started yet." 
        return [0.0]
    end  # if currentTime == 0

    timeGrid = collect( 0:timeRes:currentTime )

    if addCurrentTime && ( timeGrid[end] < currentTime )
        push!( timeGrid, currentTime )
    end  # if timeGrid[end] < currentTime

    return timeGrid

end  # generateTimeGrid( mpSim, timeRes, addCurrentTime )


function generateTimeFork( startTime::Real, endTime::Real )

    if startTime == endTime
        return string( "timeIndex IS ", startTime )
    end  # if startTime == endTime

    return string( "timeIndex > ", startTime, " AND",
        "\n    timeIndex <= ", endTime )

end  # generateTimeFork( startTime, endTime )