using ManpowerPlanning
using Test

MP = ManpowerPlanning

versionMP()
println()

@testset "Full test " begin

#=
@testset "Basic test of types" begin

include( "basic/attrition.jl" )
include( "basic/attribute.jl" )
include( "basic/condition.jl" )
include( "basic/basenode.jl" )
include( "basic/transition.jl" )
include( "basic/retirement.jl" )
include( "basic/compoundnode.jl")
include( "basic/recruitment.jl" )
include( "basic/manpowersimulation.jl" )

end  # @testset "Basic test of types"
=#
@testset "Test of simulation reports" begin

include( "reports/simconfig.jl" )
include( "reports/fluxes.jl" )
include( "reports/nodepopulation.jl" )

end  # @testset "Test of simulation reports"

end  # @testset "Full test"