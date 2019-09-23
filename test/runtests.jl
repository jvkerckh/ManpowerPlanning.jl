using ManpowerPlanning
using Test

MP = ManpowerPlanning

versionMP()
println()

@testset "Basic test of types" begin

include( "attrition.jl" )
include( "attribute.jl" )
include( "condition.jl" )
include( "basenode.jl" )
include( "transition.jl" )
include( "retirement.jl" )
include( "compoundnode.jl")
include( "recruitment.jl" )
include( "manpowersimulation.jl" )

end  # @testset "Basic test of types"