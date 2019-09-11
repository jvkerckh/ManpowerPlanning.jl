using ManpowerPlanning
using Test

MP = ManpowerPlanning

@testset "Basic test of types" begin

versionMP()
println()

include( "attrition.jl" )
include( "attribute.jl" )
include( "condition.jl" )
include( "basenode.jl" )
include( "transition.jl" )
include( "retirement.jl" )
include( "compoundnode.jl")

end  # @testset "Basic test of types"