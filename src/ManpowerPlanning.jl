__precompile__()

# This file creates the Manpower module, holding all the types, definitions, and
#   methods for the manpower planning project.

module ManpowerPlanning

    using DataFrames
    using Dates
    using Distributions
    using HierarchicalGraphPlot
    using LightGraphs
    using MetaGraphs
    using ResumableFunctions
    using SimJulia
    using SQLite
    
    # using IterTools
    # using Plots
    # using GraphIO
    # using EzXML
    # using GraphPlot
    # using Compose
    # using Gadfly
    # using Luxor
    # using Polynomials
    # using FileIO
    # using StatsBase
    # using XLSX
    # using ExcelWrapper

    version = v"2.1.0"

    export versionMP
    versionMP() = @info string( "Running version ", version,
        " of ManpowerPlanning module in Julia v", VERSION )

    # include( "Functions/XLSXfix.jl")

    types = [
        "attrition",
        "basenode",
        "attribute",
        "condition",
        "transition",
        "recruitment",
        "retirement",
        "compoundnode",
        "manpowersimulation",
        "subpopulation"
    ]

    rootPath = Base.source_path()
    rootPath = rootPath isa Nothing ? "" : dirname( rootPath )
    typePath = joinpath( rootPath, "Types" )
    funcPath = joinpath( rootPath, "Functions" )
    privPath = joinpath( funcPath, "private" )
    repPath = joinpath( funcPath, "reports" )
    repPrivPath = joinpath( repPath, "private" )
    simPath = joinpath( funcPath, "sim" )
    simPrivPath = joinpath( simPath, "private" )

    # The types
    map( mpType -> include( joinpath( typePath, mpType * ".jl" ) ), types )

    # Some union type aliases
    include( joinpath( typePath, "typeAliases.jl" ) )

    # The functions
    map( mpType -> include( joinpath( funcPath, mpType * ".jl" ) ), types )
    include( joinpath( funcPath, "reports.jl" ) )

    # Deprecated functions
    include( joinpath( funcPath, "deprecated.jl" ) )

end  # module ManpowerPlanning
