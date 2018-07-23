# Update necessary packages and initialise plots.
if !isdefined( :isUpToDate ) || !isUpToDate
    isUpToDate = false
    ENV[ "PLOTS_USE_ATOM_PLOTPANE" ] = "false"  # To open plots in external window

    try
        Pkg.update()
        isUpToDate = true
        println( "All packages updated." )
    catch
        warn( "No internet connection. Packages not updated." )
    end

    using Plots
    plotly()
end

# Initalise ManpowerPlanning module.
if !isdefined( :ManpowerSimulation )
    include( joinpath( dirname( Base.source_path() ), "..", "src",
        "ManpowerPlanning.jl" ) )
    using ManpowerPlanning
    isUpToDate = true
    println( "ManpowerPlanning module initialised." )
end

# The name of the parameter file. [Change for different configuration]
if !isdefined( :configurationFileName ) || isa( configurationFileName, Void )
    configurationFileName = "../simParFile.xlsx"
end  # if !isdefined( :configurationFileName ) ||

# Initialise the simulation.
configurationFileName = joinpath( dirname( Base.source_path() ),
    configurationFileName )
mpSim = ManpowerSimulation( configurationFileName )
println( "Simulation initialised." )

# Run the simulation.
tStart = now()
run( mpSim )
tEnd = now()
timeElapsed = (tEnd - tStart).value / 1000
println( "Simulation time: $timeElapsed seconds." )

# Create the requested plots.
tStart = now()
showPlotsFromFile( mpSim, configurationFileName )
tEnd = now()
timeElapsed = (tEnd - tStart).value / 1000
println( "Plot generation time: $timeElapsed seconds." )

configurationFileName = nothing
