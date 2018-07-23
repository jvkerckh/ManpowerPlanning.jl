# This file creates the Manpower module, holding all the types, definitions, and
#   methods for the manpower planning project.

# XXX Not sure if this file needs to be defined outside the module...
include( joinpath( dirname( Base.source_path() ), "Functions",
    "ExcelWrapper.jl" ) )
isExcelOkay = true


module ManpowerPlanning
    using SimJulia
    using ResumableFunctions
    using Plots
    using LightGraphs
    using MetaGraphs
    using GraphPlot
    using Gadfly
    using Distributions
    using Polynomials
    using FileIO
    using SQLite
    using Query
    using DataFrames
    using StatsBase
    using ExcelWrapper

    types = [
#        "historyEntry",
#        "history",
        "personnelAttribute",
        "state",
        "condition",
        "transition",
#        "personnel",
#        "personnelDatabase",
#        "prerequisite",
#        "prerequisiteGroup",
        "recruitment",
        "retirement",
        "attrition",
        "simulationReport",
        "manpowerSimulation"
    ]

    # The types
    map( mpType -> include( joinpath( dirname( Base.source_path() ),
        "Types", mpType * ".jl" ) ), types )

    # Some union type aliases
    include( joinpath( dirname( Base.source_path() ), "Types",
        "typeAliases.jl" ) )

    # The functions
    map( mpType -> include( joinpath( dirname( Base.source_path() ),
        "Functions", mpType * ".jl" ) ), types )
end  # module ManpowerPlanning
