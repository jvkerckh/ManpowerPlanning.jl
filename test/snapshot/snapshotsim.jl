@testset "Snapshot simulation tests" begin

uploadSnapshot( mpSim, "snapshot/test foto 1", "Sheet1", ["B", "C", "D"],
    ("A", "G", "F", "E", "H") )
run( mpSim )

report = nodeFluxReport( mpSim, 12, :in, "A", "B", "C", "D", "E" )
@test all( map( ["A", "B", "C", "D", "E"] ) do node
        return report[node][1, string( "other => ", node )] ==
            report[node][1, string( "Init: external => ", node )]
    end )

report = nodeFluxReport( mpSim, 12, :out, "A", "B", "C", "D", "E" )
@test all( map( ["A", "B", "C", "D", "E"] ) do node
        return report[node][1, string( node, " => other" )] == 0
    end )

report = initPopReport( mpSim )
sortNodes = sortperm( report[:, "targetNode"] )
@test all( report[sortNodes, "amount"] .== [17, 13, 10, 5, 5] )

report = initPopAgeReport( mpSim, 12, :age )
@test size( report ) == (17, 2)

report = initPopAgeReport( mpSim, 12, :tenure )
@test size( report ) == (15, 2)

report = initPopAgeReport( mpSim, 12, :timeInNode )
@test size( report ) == (10, 2)

end  # @testset "Snapshot simulation tests" begin