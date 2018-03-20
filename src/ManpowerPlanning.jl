# This file creates the Manpower module, holding all the types, definitions, and
#   methods for the manpower planning project.

# XXX Not sure if this file needs to be defined outside the module...
include( joinpath( dirname( Base.source_path() ), "Functions",
    "ExcelWrapper.jl" ) )


module ManpowerPlanning
    using SimJulia
    using ResumableFunctions
    using Distributions
    using FileIO
    using SQLite
    using StatsBase
    using ExcelWrapper

    types = [
        "historyEntry",
        "history",
        "personnel",
        "personnelDatabase",
        "prerequisite",
        "prerequisiteGroup",
        "recruitment",
        "retirement",
        "attrition",
        "cacheEntry",
        "simulationCache",
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
