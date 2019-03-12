# This file defines the Transition type. This type defines a transition between
#   nodes that a personnel member can make.

# The Tansition type requires the State type.
requiredTypes = [ "state" ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( typePath, reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end  # for reqType in requiredTypes


export Transition
"""
This type defines a transition between two nodes that a personnel member can
perform, along with all the necessary information  about the conditions of the
transition.

The type contains the following fields:
* `name::string`: the name of the transition.
* `startState::State`: the node that the personnel member is currently in.
* `endState::State`: the node that the personnel member can attain.
* `isOutTrans::Bool`: a flag to indicate if this is a transition out of the
  organisation. If this is `true`, the end node gets ignored.
* `freq::Float64`: the time between two checks in the transition's schedule.
* `offset::Float64`: the offset of the transition's schedule with respect to the
  start of the simulation.
* `extraConditions::Vector{Condition}`: the extra conditions that must be
  satisfied before the transition can take place.
* `extraChanges::Vector{PersonnelAttribute}`: the extra changes to attributes
  that happen during the transition.
* `probabilityList::Vector{Float64}`: the list of probabilities for this
  transition to occur.
* `maxAttempts::Int`: the maximum number of tries a personnel member has to
  undergo the transition.
* `minFlux::Int`: the minimum number of people that must undergo the transition
  at the same time, if this many people are eligible.
* `maxFlux::Int`: the maximum number of people that can undergo the transition
  at the same time.
* `hasPriority::Bool`: a flag indicating that this transition can override the
  target population of the transition's target node. If the flag is `true`, it
  means that if the max flux of the node is 15, and only 10 spots are available
  in the target node, 15 people will undergo the transition nonetheless. If the
  flag is `false`, 10 persons would.
* `transPriority::Int`: the priority in the simulation on which the transition
  gets executed. This priority will be 0 for transitions with the `hasPriority`
  flag set to `true`, and < 0 otherwise. A priority == 1 means it needs to be
  determined first.
"""
type Transition

    name::String
    startState::State
    endState::State
    isOutTrans::Bool
    freq::Float64
    offset::Float64
    extraConditions::Vector{Condition}
    extraChanges::Vector{PersonnelAttribute}
    probabilityList::Vector{Float64}
    maxAttempts::Int
    minFlux::Int
    maxFlux::Int
    hasPriority::Bool
    transPriority::Int

    # Basic constructor.
    function Transition( name::String, startState::State, endState::State;
        freq::Real = 1.0, offset::Real = 0.0, maxAttempts::Integer = 1,
        minFlux::Integer = 0, maxFlux::Integer = -1 )

        if freq <= 0.0
            error( "Time between two transition checks must be > 0.0" )
        end  # if freq <= 0.0

        if maxAttempts < -1
            error( "Maximum number of attempts must be => -1, where -1 stands ",
                "for infinite" )
        end  # if maxAttempts < -1

        if minFlux < 0
            error( "Minimum flux must be >= 0" )
        end  # if minFlux < 0

        if maxFlux < -1
            error( "Maximum flux must be => -1, where -1 stands for infinite" )
        end  # if maxFlux < -1

        if ( maxFlux != -1 ) && ( minFlux > maxFlux )
            error( "Minimum flux cannot be higher than maximum flux" )
        end  # if ( maxFlux != -1 ) && ...

        newTrans = new()
        newTrans.name = name
        newTrans.startState = startState
        newTrans.endState = endState
        newTrans.isOutTrans = false
        newTrans.freq = freq
        newTrans.offset = offset % freq + ( offset < 0.0 ? freq : 0.0 )
        newTrans.extraConditions = Vector{Condition}()
        newTrans.extraChanges = Vector{PersonnelAttribute}()
        newTrans.probabilityList = [ 1.0 ]
        newTrans.maxAttempts = maxAttempts
        newTrans.minFlux = minFlux
        newTrans.maxFlux = maxFlux
        newTrans.hasPriority = false
        newTrans.transPriority = 1
        return newTrans

    end  # Transition( name, startState, endState; freq, offset, maxAttempts,
         #   maxFlux )

    function Transition( name::String, startNode::State; freq::Real = 1.0,
        offset::Real = 0.0, maxAttempts::Integer = 1, minFlux::Integer = 0,
        maxFlux::Integer = -1 )

        newTrans = Transition( name, startNode, dummyNode, freq = freq,
            offset = offset, maxAttempts = maxAttempts, minFlux = minFlux,
            maxFlux = maxFlux )
        newTrans.isOutTrans = true
        return newTrans

    end  # Transition( name, startNode; freq, offset, maxAttempts, maxFlux )

end  # type Transition
