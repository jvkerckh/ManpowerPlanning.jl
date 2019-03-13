__precompile__()

# This file creates the Manpower module, holding all the types, definitions, and
#   methods for the manpower planning project.

module ManpowerPlanning
    using IterTools
    using SimJulia
    using ResumableFunctions
    using Plots
    using LightGraphs
    using MetaGraphs
    using GraphIO
    using EzXML
    using GraphPlot
    using Compose
    using Gadfly
    using Distributions
    using Polynomials
    using FileIO
    using SQLite
    using DataFrames
    using StatsBase
    using XLSX
    # using ExcelWrapper

    version = v"1.1.2"

    export versionMP
    versionMP() = info( "Running version ", version, " of ManpowerPlanning module" )

    include( "Functions/XLSXfix.jl")

    types = [
#        "historyEntry",
#        "history",
        "attrition",
        "personnelAttribute",
        "state",
        "compoundState",
        "condition",
        "transition",
#        "personnel",
#        "personnelDatabase",
#        "prerequisite",
#        "prerequisiteGroup",
        "recruitment",
        "retirement",
        # "simulationReport",
        "manpowerSimulation"
    ]

    rootPath = Base.source_path()
    rootPath = rootPath isa Void ? "" : dirname( rootPath )
    funcPath = joinpath( rootPath, "Functions" )
    typePath = joinpath( rootPath, "Types" )

    # The types
    map( mpType -> include( joinpath( typePath, mpType * ".jl" ) ), types )

    # Some union type aliases
    include( joinpath( typePath, "typeAliases.jl" ) )

    # The functions
    map( mpType -> include( joinpath( funcPath, mpType * ".jl" ) ), types )

end  # module ManpowerPlanning
