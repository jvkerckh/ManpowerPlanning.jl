# This file defines the Transition type. This type defines a transition between
#   states that a personnel member can make.

# The Tansition type requires the State type.
requiredTypes = [ "state" ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( dirname( Base.source_path() ), reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end  # for reqType in requiredTypes


export Transition
"""
This type defines a transition between two states that a personnel member can
perform, along with all the necessary information  about the conditions of the
transition.

The type contains the following fields:
* `name::string`: the name of the transition.
* `startState::State`: the state that the personnel member is currently in.
* `endState::State`: the state that the personnel member can attain.
* `freq::Float64`: the time between two checks in the transition's schedule.
* `offset::Float64`: the offset of the transition's schedule with respect to the
  start of the simulation.
* `minTime::Float64`: the minimum time a personnel member must hold the start
  state before he's allowed to make the transition.
"""
type Transition

    name::String
    startState::State
    endState::State
    freq::Float64
    offset::Float64
    minTime::Float64

    # Basic constructor.
    function Transition( name::String, startState::State, endState::State;
        freq::T1 = 1.0, offset::T2 = 0.0, minTime::T3 = 1.0 ) where T1 <: Real where T2 <: Real where T3 <: Real

        if freq <= 0.0
            error( "Time between two transition checks must be > 0.0" )
        end  # if freq <= 0.0

        if minTime <= 0.0
            error( "Time that personnel member must have initial state must be > 0.0" )
        end  # if minTime <= 0.0

        newTrans = new()
        newTrans.name = name
        newTrans.startState = startState
        newTrans.endState = endState
        newTrans.freq = freq
        newTrans.offset = offset % freq + ( offset < 0.0 ? freq : 0.0 )
        newTrans.minTime = minTime
        return newTrans

    end  # Transition( startState, endState )

end  # type Transition
