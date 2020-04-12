const defaultTransitions = ["attrition", "retirement"]
const specialNodes = ["", "external", "out"]


function validateTransition( mpSim::MPsim, transition::String )

    if lowercase( transition ) ∈ defaultTransitions
        return true
    end  # if lowercase( transition ) ∈ defaultTransitions

    # Transition name can be a recruitment, or another transition.
    return haskey( mpSim.recruitmentByName, transition ) ||
        haskey( mpSim.transitionsByName, transition )

end  # validateTransition( mpSim, transition )

function validateTransition( mpSim::MPsim, transition::NTuple{2,String} )

    sourceNode, targetNode = transition

    # If the source is external, the transition is a recruitment.
    if lowercase( sourceNode ) ∈ specialNodes
        return haskey( mpSim.recruitmentByTarget, targetNode )
    end  # if lowercase( sourceNode ) ∈ specialNodes

    # If the target is external, the transition is an OUT transition.
    if lowercase( targetNode ) ∈ specialNodes
        return true
    end  # if lowercase( targetNode ) ∈ specialNodes

    if !haskey( mpSim.transitionsBySource, sourceNode )
        return false
    end  # if !haskey( mpSim.transitionsBySource, sourceNode )

    return any( transition -> transition.targetNode == targetNode,
        mpSim.transitionsBySource[sourceNode] )

end  # validateTransition( mpSim, transition )

function validateTransition( mpSim::MPsim, transition::NTuple{3,String} )

    name, sourceNode, targetNode = transition

    # If the source is external, the transition is a recruitment.
    if lowercase( sourceNode ) ∈ specialNodes
        return haskey( mpSim.recruitmentByName, name ) &&
            any( recruitment -> recruitment.targetNode == targetNode,
                mpSim.recruitmentByName[name] )
    end  # if lowercase( sourceNode ) ∈ specialNodes

    # Default transitions (attrition and retirement).
    if lowercase( name ) ∈ defaultTransitions 
        return lowercase( targetNode ) ∈ specialNodes
    end  # if lowercase( name ) ∈ defaultTransitions

    # If the target is external, the transition is OUT.
    if lowercase( targetNode ) ∈ specialNodes
        return any( transition -> ( transition.name == name ) &&
            ( transition.sourceNode == sourceNode ),
            mpSim.transitionsByTarget["OUT"] )
    end  # if lowercase( targetNode ) ∈ specialNodes

    return haskey( mpSim.transitionsByTarget, targetNode ) &&
        any( transition -> ( transition.name == name ) &&
            ( transition.sourceNode == sourceNode ),
            mpSim.transitionsByTarget[targetNode] )

end  # validateTransition( mpSim, transition )


function createTransitionFluxReport( mpSim::MPsim, timeGrid::Vector{Float64},
    transition::TransitionType )

    queryPartCmd = string( "SELECT count( `", mpSim.idKey,
        "` ) counts FROM `", mpSim.transDBname, "` WHERE\n    ",
        generateTransitionQuery( transition, mpSim ), " AND\n    " )

    result = zeros( Int, length( timeGrid ) )

    for ii in eachindex( timeGrid )
        queryCmd = string( queryPartCmd, generateTimeFork( ii == 1 ?
            timeGrid[1] : timeGrid[ii - 1], timeGrid[ii] ) )
        result[ii] =
            DataFrame( DBInterface.execute( mpSim.simDB, queryCmd ) )[1, 1]
    end  # for ii in eachindex( timeGrid )

    return result

end  # createTransitionFluxReport( mpSim, timeGrid, transition )


generateTransitionQuery( transition::String, mpSim::MPsim ) =
    string( "transition IS '", transition, "' AND",
    "\n    ", mpSim.sNode, " IS NOT 'active' AND",
    "\n    ", mpSim.tNode, " IS NOT 'active'" )

function generateTransitionQuery( transition::NTuple{2,String }, mpSim::MPsim )

    sourceNode = lowercase( transition[1] ) ∈ specialNodes ? "NULL" :
        string( "'", transition[1], "'" )
    targetNode = lowercase( transition[2] ) ∈ specialNodes ? "NULL" :
        string( "'", transition[2], "'" )
    return string( mpSim.sNode, " IS ", sourceNode, " AND",
        "\n    ", mpSim.tNode, " IS ", targetNode )

end  # generateTransitionQuery( transition, mpSim )
    

generateTransitionQuery( transition::NTuple{3,String}, mpSim::MPsim ) =
    string( "transition IS '", transition[1], "' AND",
    "\n    ", generateTransitionQuery( transition[2:3], mpSim ) )


generateTransitionName( transition::String ) =
    lowercase( transition ) ∈ defaultTransitions ? lowercase( transition ) :
    transition

function generateTransitionName( transition::NTuple{2,String} )

    sourceNode, targetNode = transition
    sourceNode = lowercase( sourceNode ) ∈ specialNodes ? "external" :
        sourceNode
    targetNode = lowercase( targetNode ) ∈ specialNodes ? "external" :
        targetNode
    return string( sourceNode, " => ", targetNode )

end  # generateTransitionName( transition )

generateTransitionName( transition::NTuple{3,String} ) =
    string( generateTransitionName( transition[1] ), ": ",
    generateTransitionName( transition[2:3] ) )