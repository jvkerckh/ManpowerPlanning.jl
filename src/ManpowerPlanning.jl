# This file creates the Manpower module, holding all the types, definitions, and
#   methods for the manpower planning project.

include( joinpath( dirname( Base.source_path() ), "Functions",
    "ExcelWrapper.jl" ) )

using SimJulia
using ResumableFunctions
using Distributions

module ManpowerTypes
    using SimJulia
    using ResumableFunctions
    using Distributions
    using SQLite

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

    map( mpType -> include( joinpath( dirname( Base.source_path() ),
        "Types", mpType * ".jl" ) ), types )
#    map( mpType -> include( joinpath( dirname( Base.source_path() ),
#        "Functions", mpType * ".jl" ) ), types )

    #include( joinpath( dirname( Base.source_path() ), "Base Classes", "base.jl" ) )
    #include( joinpath( dirname( Base.source_path() ), "Simulation Classes", "sim.jl" ) )
    #, "auxiliary.jl",
      #"fileio.jl", "career.jl",
      #"skill.jl", "rank.jl", "rankStructure.jl" ]
  # personnel.jl must be loaded first to ensure that the type Personeel is known
  #   to all the other files.

#  include( joinpath( dirname( Base.source_path() ), "Simulation Engine",
#      "manpowerSimulation.jl" ) )
end  # module ManpowerTypes

using ManpowerTypes

# The types need to be defined, AND made available for the @resumable macro to
#   work properly.

module ManpowerPlanning
    using SimJulia
    using ResumableFunctions
    using Distributions
    using FileIO
    using SQLite
    using StatsBase
    using ManpowerTypes
    using ExcelWrapper

    include( joinpath( dirname( Base.source_path() ), "Types",
        "typeAliases.jl" ) )

    map( mpType -> include( joinpath( dirname( Base.source_path() ),
        "Functions", mpType * ".jl" ) ), ManpowerTypes.types )
end  # module Manpower
