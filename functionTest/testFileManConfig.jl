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

pars = Dict{String, Any}()


# Parameters are defined starting from here.

# General parameters
isSimTimeInMonths = true
pars[ "maxPersonnelMembers" ] = 10000
pars[ "simulationLengthInYears" ] = 50

# Recruitment
isRecruitmentAgeFixed = false
pars[ "timeBetweenRecruitmentCyclesInMonths" ] = 12
pars[ "offsetOfRecruitmentCycleInMonths" ] = 0
pars[ "maxNumberToRecruitEachCycle" ] = floor( Int, pars[ "maxPersonnelMembers" ] / 20 )
pars[ "ageAtRecruitmentInYears" ] = 18
pars[ "ageAtRecruitmentDistributionInYears" ] = [
    (18, 5), (19, 8), (20, 4), (21, 6), (24, 1), (25, 0)
]  # Always pairs of (ageInYears, relativeFrequency)
pars[ "recruitmentAgeDistributionType" ] = :pUnif
    # :pUnif for any possible value within the range
    # :disc for only the values defined above

# Career attrition
isProbabilityInPercent = false
pars[ "lengthOfAttritionPeriodInMonths" ] = 12
pars[ "probabilityOfAttritionPerPeriod" ] = 0.03
# XXX The "lengthOfAttritionPeriodInMonths" plays a large role in the length of
#   the simulation part. For example: for a simulation of 100 years with a
#   max personnel cap of 50 000, setting this to 3 months instead of 12
#   increases the runtime of the simulation from roughly 2'45" to 6'50", more
#   than doubling the needed time.
# The reporting part is unaffected though.


# Retirement
pars[ "maxCareerLengthInYears" ] = 0  # Set to 0 to ignore this.
pars[ "mandatoryRetirementAgeInYears" ] = 56  # Set to 0 to ignore this.
pars[ "timeBetweenRetirementCyclesInMonths" ] = 1
pars[ "offsetOfRetiretmentCycleInMonths" ] = 0

# Graph/report
rerunSimulation = true
pars[ "graphTimeResolutionInMonths" ] = 12
pars[ "numDBupdates" ] = 100

include( "processingManConfig.jl" )  # Do not change this line!

plotSim( mpSim, "flux in", "flux out", "net flux", "resigned", "retired" )
gui( surface( simAgeDist[ 2 ] / monthFactor, simAgeDist[ 1 ] / monthFactor,
    simAgeDist[ 3 ], size = ( 800, 600 ), xlabel = "Age (y)",
    ylabel = "Simulation time (y)", zlabel = "Amount" ) )
plotAgeStats( mpSim, timeResolution )
# Allowed arguments, separated by commas, are:
# "personnel"
# "flux in"
# "flux out"
# "net flux"
# "resigned"
# "retired"
