@testset "Snapshot reading tests" begin

# Bad data filter procedures.
uploadSnapshot( mpSim, "snapshot/test foto 1", "Sheet1", ["B", "C", "D"],
    ("A", "G", "F", "E", "H") )
@test ( mpSim.orgSize == 50 ) && !mpSim.isVirgin

uploadSnapshot( mpSim, "snapshot/test foto 2", "Sheet1", ["B", "C", "D"],
    ("A", "G", "F", "E", "H") )
@test ( mpSim.orgSize == 45 ) && !mpSim.isVirgin

uploadSnapshot( mpSim, "snapshot/test foto 3", "Sheet1", ["B", "C", "D"],
    ("A", "G", "F", "E", "H") )
@test ( mpSim.orgSize == 45 ) && !mpSim.isVirgin

uploadSnapshot( mpSim, "snapshot/test foto 4", "Sheet1", ["B", "C", "D"],
    ("A", "G", "F", "E", "H") )
@test ( mpSim.orgSize == 50 ) && !mpSim.isVirgin

# Generate data procedure.
clearSimulationAttributes!( mpSim )
clearSimulationBaseNodes!( mpSim )
uploadSnapshot( mpSim, "snapshot/test foto 1", "Sheet1", ["B", "C", "D"],
    ("A", "G", "F", "E", "H"), generateSimData=true )
@test ( mpSim.orgSize == 50 ) && !mpSim.isVirgin
@test length( mpSim.attributeList ) == 3
@test length( mpSim.baseNodeList ) == 5

uploadSnapshot( mpSim, "snapshot/test foto 1", "Sheet1", ["B", "C", "D"],
    ("A", "G", "F", "E", 0), generateSimData=true )
@test ( mpSim.orgSize == 50 ) && !mpSim.isVirgin
nodes = get.( Ref(mpSim.baseNodeList), ["A", "B", "C", "D", "E"], nothing )
@test all( length.( getfield.( nodes, :inNodeSince ) ) .== [17, 13, 10, 5, 5] )

# Attrition generation procedure.
setNodeAttritionScheme!( mpSim.baseNodeList["A"], "A/B" )
setNodeAttritionScheme!( mpSim.baseNodeList["B"], "A/B" )
setNodeAttritionScheme!( mpSim.baseNodeList["C"], "C/D" )
setNodeAttritionScheme!( mpSim.baseNodeList["D"], "C/D" )
setNodeAttritionScheme!( mpSim.baseNodeList["E"], "E" )

uploadSnapshot( mpSim, "snapshot/test foto 1", "Sheet1", ["B", "C", "D"],
    ("A", "G", "F", "E", "H") )

for node in keys( mpSim.baseNodeList )
    setNodeAttritionScheme!( mpSim.baseNodeList[node], "default" )
end  # for node in keys( mpSim.baseNodeList )

end  # @testset "Snapshot reading tests"