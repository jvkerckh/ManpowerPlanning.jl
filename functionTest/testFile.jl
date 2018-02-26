# Update necessary packages.
if !isdefined( :isUpToDate ) || !isUpToDate
    isUpToDate = false
    ENV[ "PLOTS_USE_ATOM_PLOTPANE" ] = "false"  # To open plots in external window
    using Plots
    plotly()

    try
        Pkg.update()
        isUpToDate = true
        println( "All packages updated." )
    catch
        warn( "No internet connection. Packages not updated." )
    end
end


# The name of the parameter file.
configurationFileName = "../simParFile.xlsx"

# Processing parameters.
rerunSimulation = true
graphTimeResolutionInMonths = 12


include( "processing.jl" )  # Do not change this line!

plotSim( mpSim, "flux in", "flux out", "net flux", "resigned", "retired" )
plotSim( mpSim, "personnel", "net flux" )
gui( surface( simAgeDist[ 2 ] / monthFactor, simAgeDist[ 1 ] / monthFactor,
    simAgeDist[ 3 ], size = ( 800, 600 ), xlabel = "Age (y)",
    ylabel = "Simulation time (y)", zlabel = "Amount" ) )
# Allowed arguments, separated by commas, are:
# "personnel"
# "flux in"
# "flux out"
# "net flux"
# "resigned"
# "retired"
