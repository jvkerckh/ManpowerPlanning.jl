using DataFrames
using Dates
using Distributions
using HypothesisTests
using LightGraphs
using ManpowerPlanning
using MetaGraphs
using Random
using SQLite
using StatsBase
using Test

MP = ManpowerPlanning

versionMP()
println()

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

end  # @testset "Test of simulation processes"

end  # @testset "Full test"

tElapsed = ( now() - tStart ).value / 1000
@info string( "Unit tests completed in ", tElapsed, " seconds." )