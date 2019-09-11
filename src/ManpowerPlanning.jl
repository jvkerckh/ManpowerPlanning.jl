__precompile__()

# This file creates the Manpower module, holding all the types, definitions, and
#   methods for the manpower planning project.

module ManpowerPlanning

    using Distributions
    # using IterTools
    # using SimJulia
    # using ResumableFunctions
    # using Plots
    # using LightGraphs
    # using MetaGraphs
    # using GraphIO
    # using EzXML
    # using GraphPlot
    # using Compose
    # using Gadfly
    # using Luxor
    # using Polynomials
    # using FileIO
    # using SQLite
    # using DataFrames
    # using StatsBase
    # using XLSX
    # using ExcelWrapper

    version = v"2.0.7"

    export versionMP
    versionMP() = @info string( "Running version ", version,
        " of ManpowerPlanning module" )

    # include( "Functions/XLSXfix.jl")

    types = [
        "attrition",
        "basenode",
        "attribute",
        "condition",
        "transition",
        "retirement",
        "compoundnode"
        # "recruitment",
        # "subpopulation",
        # "simulationReport",
        # "manpowerSimulation"
    ]

    rootPath = Base.source_path()
    rootPath = rootPath isa Nothing ? "" : dirname( rootPath )
    funcPath = joinpath( rootPath, "Functions" )
    privPath = joinpath( funcPath, "private" )
    typePath = joinpath( rootPath, "Types" )

    # The types
    map( mpType -> include( joinpath( typePath, mpType * ".jl" ) ), types )

    # Some union type aliases
    # include( joinpath( typePath, "typeAliases.jl" ) )

    # The functions
    map( mpType -> include( joinpath( funcPath, mpType * ".jl" ) ), types )

    # Deprecated functions
    include( joinpath( funcPath, "deprecated.jl" ) )

end  # module ManpowerPlanning
