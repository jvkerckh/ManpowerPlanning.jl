using ManpowerPlanning
using Test

MP = ManpowerPlanning

@testset "Basic test of types" begin

include( "attrition.jl" )
include( "attribute.jl" )
include( "condition.jl" )

end  # @testset "Basic test of types"