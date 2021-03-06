# This file defines the ManpowerSimulation type. This type bundles all the
#   information of the simulation.


export ManpowerSimulation, MPsim
"""
The 'ManpowerSimulation' type defines a manpower simulation, holding its complete configuration and the `SimJulia.Simulation` object driving the simulation.

The type contains the following fields:
* `simName::String`: the name of the simulation. Default = "simulation"
* `attributeList::Dict{String,Attribute}`: the list of attributes in the simulation.
* `idKey::String`: the name of the unique personnel identifier key. This is used only in the results database. Default = `"id"`
* `baseNodeList::Dict{String,BaseNode}`: the list of base nodes in the simulation.
* `baseNodeOrder::Dict{String,Int}`: the preferred order in which the base nodes are visited by transitions.
* `compoundNodeList::Dict{String,CompoundNode}`: the list of compound nodes in the simulation.
* `recruitmentByName::Dict{String,Vector{Recruitment}}`: the list of recruitment schemes in the simulation, grouped by name.
* `recruitmentByTarget::Dict{String,Vector{Recruitment}}`: the list of recruitment schemes in the simulation, grouped by target node.
* `transitionsByName::Dict{String,Vector{Transition}}`: the list of transitions in the simulation, grouped by name.
* `transitionsByTarget::Dict{String,Vector{Transition}}`: the list of transitions in the simulation, grouped by source node.
* `transitionsByTarget::Dict{String,Vector{Transition}}`: the list of transitions in the simulation, grouped by target node.
* `retirement::Retirement`: the default retirement scheme. Defaults of no retirement.
* `transitionTypeOrder::Dict{String,Int}`: the preferred order in which transitions of different types are handled.
* `retirement::Retirement`: the fallback retirement scheme for personnel member who haven't had an OUT transition yet.
* `attritionSchemes::Dict{String,Attrition}`: the list of attrition schemes in the simulation. This list always contains a default attrition scheme with a flat zero attrition.
* `simLength::Float64`: the length of the simulation (in internal time units). Default = 0.0
* `personnelTarget:Int`: the target number of personnel members in the simulation. Default = 0
* `dbName::String`: the name of the SQLite databases holding the simulation results. Default = `""`, indicating the database is kept in memory only.
* `showInfo::Bool`: a flag indicating whether execution times of the various processes and other information should be shown. Default = `false`

Several additional fields are used to speed up computations, retain extra information, etcetera:
* `sim::Simulation`: the `SimJulia.Simulation` object driving the simulation.
* `nRecruitment::Int`: the number of recruitment schemes in the simulation.
* `nPriorities::Int`: the number of priority levels in the simulation.
* `orgSize::Int`: the current number personnel members in the simulation.
* `dbSize::Int`: the total number of personnel members in the database.
* `simDB::SQLite.DB`: the SQLite database holding the simulation results.
* `persDBname::String`: the name of the database table holding the personnel records.
* `histDBname::String`: the name of the database table holding the attribute change history records.
* `transDBname::String`: the name of the database table holding the transition history records.
* `catFileName::String`: the name of the catalogue file. Might become obsolete.
* `isVirgin::Bool`: a flag indicating that the results database is empty.
* `isStale::Bool`: a flag indicating if the configuration of the simulated organisation has been changed. If any of the other simulation parameters have been changed, it will not alter the freshness of the simulation.
* `isConsistent::Bool`: a flag indicating whether the simulation is in a consistent state.
* `simExecTime::Millisecond`: the total execution time of the simulation.
* `attritionExecTime::Millisecond`: the total execution time of the attrition process.
* `nCommits::Int`: the number of times the database is saved to file throughout the simulation.
* `attritionTimeSkip::Float64`: the period for the attrition check process.
* `isOldDB::Bool`: a flag indicating whether the simulation database is configured in the old style (which will be deprecated) or the new style.
* `sNode::String`: the name of the source node field in the database.
* `tNode::String`: the name of the target node field in the database.
* `valName::String`: the name of the value field in the history database.
* `seedRNG::String`: the generator of the seeds for the random streams for each individual process.

These fields cannot be affected directly by the type's set! function, and should NEVER be changed by the user.

Constructor:
```
ManpowerSimulation( simName::String = "simulation" )
```
This constructor defines a `ManpowerSimulation` object where the simulation has name `simName` and all other fields have their default values.

Shorthand: `MPsim` for `ManpowerSimulation`
"""
mutable struct ManpowerSimulation

    simName::String
    idKey::String
    attributeList::Dict{String,Attribute}
    baseNodeList::Dict{String,BaseNode}
    baseNodeOrder::Dict{String,Int}
    compoundNodeList::Dict{String,CompoundNode}
    recruitmentByName::Dict{String,Vector{Recruitment}}
    recruitmentByTarget::Dict{String,Vector{Recruitment}}
    transitionsByName::Dict{String,Vector{Transition}}
    transitionsBySource::Dict{String,Vector{Transition}}
    transitionsByTarget::Dict{String,Vector{Transition}}
    transitionTypeOrder::Dict{String,Int}
    retirement::Retirement
    attritionSchemes::Dict{String,Attrition}
    simLength::Float64
    personnelTarget::Int
    dbName::String
    showInfo::Bool

    sim::Simulation
    nRecruitment::Int
    nPriorities::Int
    orgSize::Int
    dbSize::Int
    simDB::SQLite.DB
    reportFolder::String
    persDBname::String
    histDBname::String
    transDBname::String
    catFileName::String
    isVirgin::Bool
    isStale::Bool
    isConsistent::Bool
    simExecTime::Millisecond
    attritionExecTime::Millisecond
    nCommits::Int
    attritionTimeSkip::Float64
    isOldDB::Bool
    sNode::String
    tNode::String
    valName::String
    seedRNG::MersenneTwister


    function ManpowerSimulation( simName::String = "simulation" )::MPsim

        newMPsim = new()
        newMPsim.idKey = "id"
        newMPsim.simName = simName
        newMPsim.attributeList = Dict{String,Attribute}()
        newMPsim.baseNodeList = Dict{String,BaseNode}()
        newMPsim.baseNodeOrder = Dict{String,Int}()
        newMPsim.compoundNodeList = Dict{String,CompoundNode}()
        newMPsim.recruitmentByName = Dict{String,Vector{Recruitment}}()
        newMPsim.recruitmentByTarget = Dict{String,Vector{Recruitment}}()
        newMPsim.transitionsByName = Dict{String,Vector{Transition}}()
        newMPsim.transitionsBySource = Dict{String,Vector{Transition}}()
        newMPsim.transitionsByTarget = Dict( "OUT" => Vector{Transition}() )
        newMPsim.transitionTypeOrder = Dict{String,Int}()
        newMPsim.retirement = Retirement()
        newMPsim.attritionSchemes = Dict( "default" => Attrition() )
        newMPsim.simLength = 0.0
        newMPsim.personnelTarget = 0
        newMPsim.dbName = ""
        newMPsim.showInfo = false
        
        newMPsim.sim = Simulation()
        newMPsim.nRecruitment = 0
        newMPsim.nPriorities = 0
        newMPsim.orgSize = 0
        newMPsim.dbSize = 0
        newMPsim.simDB = SQLite.DB( "" )
        newMPsim.persDBname = string( "Personnel_", simName )
        newMPsim.histDBname = string( "History_", simName )
        newMPsim.transDBname = string( "Transitions_", simName )
        newMPsim.catFileName = ""
        newMPsim.isVirgin = true
        newMPsim.isStale = false
        newMPsim.isConsistent = true
        newMPsim.simExecTime = Millisecond( 0 )
        newMPsim.attritionExecTime = Millisecond( 0 )
        newMPsim.nCommits = 1
        newMPsim.attritionTimeSkip = 1.0
        newMPsim.isOldDB = false
        newMPsim.sNode = "sourceNode"
        newMPsim.tNode = "targetNode"
        newMPsim.valName = "value"
        newMPsim.seedRNG = MersenneTwister()

        # This line ensures that foreign key logic works.
        DBInterface.execute( newMPsim.simDB, "PRAGMA foreign_keys = ON" )

        return newMPsim

    end  # ManpowerSimulation( simName )

end  # mutable struct ManpowerSimulation


const MPsim = ManpowerSimulation