using DataFrames
using Dates
using Distributions
using HypothesisTests
using LightGraphs
using Logging
using ManpowerPlanning
using MetaGraphs
using Random
using SQLite
using StatsBase
using Test

MP = ManpowerPlanning

versionMP()
println()

disable_logging( Base.CoreLogging.Warn )

tStart = now()

@testset "Full test" begin

@testset "Basic test of types" begin

include( "basic/attrition.jl" )
include( "basic/attribute.jl" )
include( "basic/condition.jl" )
include( "basic/basenode.jl" )
include( "basic/transition.jl" )
include( "basic/retirement.jl" )
include( "basic/compoundnode.jl" )
include( "basic/recruitment.jl" )
include( "basic/manpowersimulation.jl" )

end  # @testset "Basic test of types"


@testset "Test of simulation reports" begin

include( "reports/simconfig.jl" )
include( "reports/timegrid.jl" )
include( "reports/fluxes.jl" )
include( "reports/nodepopulation.jl" )
include( "reports/nodecomposition.jl" )
include( "reports/careerprogression.jl" )
include( "basic/subpopulation.jl" )
include( "reports/subpopulationpop.jl" )
include( "reports/subpopulationage.jl" )

end  # @testset "Test of simulation reports"


@testset "Test of simulation processes" begin

include( "sim/basic.jl" )
include( "sim/recruitment.jl" )
include( "sim/retirement.jl" )
include( "sim/attrition.jl" )
include( "sim/transition.jl" )
include( "sim/transition2.jl" )
include( "sim/transition3.jl" )
include( "sim/transition4.jl" )

end  # @testset "Test of simulation processes"


@testset "Snapshot test" begin

include( "snapshot/simconfig.jl" )
include( "snapshot/snapshot.jl" )
include( "snapshot/snapshotsim.jl" )

end  # @testset "Snapshot test"

disable_logging( Base.CoreLogging.BelowMinLevel )

@testset "Parallel simulations test" begin

include( "parallel/simconfig.jl" )
include( "parallel/mrs.jl" )
include( "snapshot/simconfig.jl" )
include( "parallel/mrssnap.jl" )

end  # @testset "Parallel simulations test"

end  # @testset "Full test"

tElapsed = ( now() - tStart ).value / 1000
@info string( "Unit tests completed in ", tElapsed, " seconds." )
