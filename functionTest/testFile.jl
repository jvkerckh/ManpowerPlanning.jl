# Update necessary packages.
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


# The name of the parameter file.
configurationFileName = "../simParFile.xlsx"

# Processing parameters.
rerunSimulation = true
graphTimeResolutionInMonths = 12


include( "processing.jl" )  # Do not change this line!


generateExcelReport( mpSim, graphTimeResolutionInMonths, 12 )
plot( mpSim, graphTimeResolutionInMonths, ageRes = graphTimeResolutionInMonths,
    timeFactor = 12,
    "flux in", "flux out", "net flux", "resigned", "retired" )
plot( mpSim, graphTimeResolutionInMonths, ageRes = graphTimeResolutionInMonths,
    timeFactor = 12,
    "personnel", "flux in", "flux out", "net flux" )
plot( mpSim, graphTimeResolutionInMonths, ageRes = graphTimeResolutionInMonths,
    timeFactor = 12,
    "age dist", "age stats" )
# Allowed arguments, separated by commas, are:
# "personnel"
# "flux in"
# "flux out"
# "net flux"
# "resigned"
# "retired"
# "age dist"
# "age stats"
