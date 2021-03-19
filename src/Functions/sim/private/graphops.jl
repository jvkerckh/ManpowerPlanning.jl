function generateGraphNodeRanks!( grf::MetaDiGraph, isInit::Bool = true )
    fTree = generateFeasibleTree( grf, isInit )
    treeRanks = get_prop.( Ref(fTree), vertices(fTree), :rank )
    nsteps = 1
    maxsteps = 5 * nv(grf)

    while !( (leaveEdge = findLeaveEdge(fTree)) isa Nothing )
        # Get a new edge to replace the bad edge with.
        headNodes = breakFeasibleTree( SimpleGraph(fTree.graph), leaveEdge )
        validEdges = filter( edge -> ( edge.src ∈ headNodes ) &&
            ( edge.dst ∉ headNodes ), collect(edges(grf)) )
        relativeEdgeSlacks = map( validEdges) do edge
            ( treeRanks[edge.dst] - treeRanks[edge.src] ) -
                getEdgeMinSlack( grf, edge )
        end  # map(validEdges) do edge
        enterEdge = rand(validEdges[relativeEdgeSlacks .==
            minimum( relativeEdgeSlacks )])
        
        # Exchange the edges.
        clear_props!( fTree, leaveEdge )
        rem_edge!( fTree, leaveEdge )
        add_edge!( fTree, enterEdge )

        for prop in keys(props( grf, enterEdge ))
            add_prop!( fTree, enterEdge, prop,
                get_prop( grf, enterEdge, prop ) )
        end  # for prop in keys(props( grf, enterEdge ))

        generateCutValues!( fTree, grf )

        # Adjust the ranks of the nodes in the head of the tree.
        treeRanks[headNodes] .-= treeRanks[enterEdge.src] +
            getEdgeMinSlack( grf, enterEdge ) - treeRanks[enterEdge.dst]
        nsteps += 1
    end  # while !( (leaveEdge = findLeaveEdge(fTree)) isa Nothing )

    treeRanks .-= minimum(treeRanks)
    set_prop!.( Ref(grf), vertices(grf), :rank, treeRanks )
end  # generateGraphNodeRanks!( grf, isInit )


function generateFeasibleTree( grf::MetaDiGraph, isInit::Bool )
    # Generate initial node ranks if needed.
    if isInit || !all( has_prop.( Ref(grf), vertices(grf), :rank ) )
        generateInitialNodeRanks!(grf)
    end  # if isInit || ...

    graphEdges = collect(edges(grf))
    treeRanks = zeros( Float64, nv(grf) )
    fTree = MetaDiGraph(nv(grf) )

    # Add a random start node to the feasible tree.
    inTree = [rand(vertices(grf))]

    # In each step, add an edge from/to a non-tree node which has minimal rank
    #   difference (slack) in the original graph.
    while length(inTree) < nv(grf)
        # Find all edges incident on the current feasible tree.
        validEdges = filter( edge -> xor( edge.src ∈ inTree,
            edge.dst ∈ inTree ), graphEdges )
        edgeSlacks = map( edge -> get_prop( grf, edge.dst, :rank ) -
            get_prop( grf, edge.src, :rank ), validEdges )

        # Get all tight edges among incident edges.
        isTight = edgeSlacks .== getEdgeMinSlack.( Ref(grf), validEdges )
        !any(isTight) && (isTight = edgeSlacks .== minimum(edgeSlacks))  # Insurance!
        tightEdges = validEdges[isTight]
        tightSlacks = edgeSlacks[isTight]
        
        # If there are no candidates (bad initial ranks), re-initialise the 
        #   node ranks and restart.
        if isempty(tightEdges)
            generateInitialNodeRanks!(grf)
            inTree = [rand(vertices(grf))]
            continue
        end  # if isempty( tightEdges )

        # Select tight edge with minimal slack.
        minSlack = minimum(tightSlacks)
        newEdge = rand(tightEdges[tightSlacks .== minSlack])

        # Find the new node and its rank in the tree.
        isNewDst = newEdge.src ∈ inTree
        treeNode = getfield( newEdge, isNewDst ? :src : :dst )
        newNode = getfield( newEdge, isNewDst ? :dst : :src )
        treeRanks[newNode] = treeRanks[treeNode] +
            getEdgeMinSlack( grf, newEdge ) * ( isNewDst ? 1 : -1 )

        # Add the new edge.
        add_edge!( fTree, newEdge )
        setEdgeWeight!( fTree, newEdge, getEdgeWeight( grf, newEdge ) )
        setEdgeMinSlack!( fTree, newEdge, getEdgeMinSlack( grf, newEdge ) )
        push!( inTree, newNode )
    end  # while length(inTree) < nv(grf)

    # Set all node ranks in the feasible tree.
    treeRanks .-= minimum(treeRanks)
    set_prop!.( Ref(fTree), vertices(fTree), :rank, treeRanks )

    # Generate cut values for each edge in the feasible tree.
    generateCutValues!( fTree, grf )
    fTree
end  # generateFeasibleTree( grf, isInit )


function generateInitialNodeRanks!( grf::MetaDiGraph )
    ranks = - ones( Float64, nv( grf ) )
    unprocessedClearNodes = Queue{Int}()

    # In each step, get the list of nodes that no unprocessed in neighbours,
    #   and assign them the lowest possible rank which respects the minimum
    #   slacks for each incoming edge.
    while any( ranks .< 0 )
        getClearNodes( grf, ranks, unprocessedClearNodes )
        node = dequeue!(unprocessedClearNodes)

        minRanks = map(inneighbors( grf, node )) do srcNode
            ranks[srcNode] + getEdgeMinSlack( grf, srcNode, node )
        end  # map(inneighbors( grf, node )) do srcNode

        ranks[node] = isempty(minRanks) ? 0 : maximum(minRanks)
    end  # while any( ranks .< 0 )

    set_prop!.( Ref(grf), vertices(grf), :rank, ranks )
end  # generateInitialNodeRanks!( grf )


function getClearNodes( grf::MetaDiGraph, ranks::Vector{Float64},
    unprocessed::Queue{Int} )
    for node in filter( node -> ranks[node] < 0, vertices(grf) )
        if ( node ∉ unprocessed ) &&
            all( ranks[inneighbors( grf, node )] .>= 0 )
            enqueue!( unprocessed, node )
        end  # if ( node ∉ unprocessed ) && ...
    end  # for node in filter( node -> ranks[node] < 0, vertices(grf) )
end  # getClearNodes( grf, ranks, unprocessed )


function generateCutValues!( fTree::MetaDiGraph, grf::MetaDiGraph )
    uTree = SimpleGraph(fTree.graph)
    grfEdges = collect(edges(grf))

    for edge in edges(fTree)
        headNodes = breakFeasibleTree( uTree, edge )
        cutEdges = filter( tmpEdge -> xor( tmpEdge.src ∈ headNodes,
            tmpEdge.dst ∈ headNodes ), grfEdges )
        isPosEdge = map( tmpEdge -> tmpEdge.dst ∈ headNodes, cutEdges )
        cutVal = sum(getEdgeWeight.( Ref(grf), cutEdges[isPosEdge] ))

        if !all(isPosEdge)
            cutVal -= sum(getEdgeWeight.( Ref(grf), cutEdges[.!isPosEdge] ))
        end  # if !all(isPosEdge)

        set_prop!( fTree, edge, :cut, cutVal )
    end  # for edge in edges(fTree)
end  # generateCutValues!( fTree, grf )


function findLeaveEdge( fTree::MetaDiGraph )
    negCutEdges = filter( edge -> get_prop( fTree, edge, :cut ) < 0,
        collect(edges(fTree)) )
    isempty(negCutEdges) ? nothing : rand(negCutEdges)
end  # findLeaveEdge( fTree )


function getEdgeMinSlack( grf::MetaDiGraph, edge::Edge )
    !has_edge( grf, edge ) && return 0
    has_prop( grf, edge, :minSlack ) ?
        get_prop( grf, edge, :minSlack ) : 1
end  # getEdgeMinSlack( grf, edge )

getEdgeMinSlack( grf::MetaDiGraph, src::Int, dst::Int ) =
    getEdgeMinSlack( grf, Edge( src, dst ) )
getEdgeMinSlack( grf::MetaDiGraph, edge::Tuple{Int, Int} ) =
    getEdgeMinSlack( grf, Edge(edge) )


function setEdgeMinSlack!( grf::MetaDiGraph, edge::Edge, minSlack::Real )
    ( !has_edge( grf, edge ) || ( minSlack < 0.0 ) ) && return
    set_prop!( grf, edge, :minSlack, Float64(minSlack) )
end  # setEdgeMinSlack!( grf, edge, minSlack )

setEdgeMinSlack!( grf::MetaDiGraph, src::Int, dst::Int, minSlack::Real ) =
    setEdgeMinSlack!( grf, Edge( src, dst ),  minSlack )
setEdgeMinSlack!( grf::MetaDiGraph, edge::Tuple{Int, Int}, minSlack::Real ) =
    setEdgeMinSlack!( grf, Edge(edge), minSlack )
    

function getEdgeWeight( grf::MetaDiGraph, edge::Edge )
    !has_edge( grf, edge ) && return 0.0
    !has_prop( grf, edge, weightfield(grf) ) && return grf.defaultweight
    get_prop( grf, edge, weightfield(grf) )
end  # getEdgeWeight( grf, edge )

getEdgeWeight( grf::MetaDiGraph, src::Int, dst::Int ) =
    getEdgeWeight( grf, Edge( src, dst ) )
getEdgeWeight( grf::MetaDiGraph, edge::Tuple{Int, Int} ) =
    getEdgeWeight( grf, Edge(edge) )


function setEdgeWeight!( grf::MetaDiGraph, edge::Edge, weight::Real )
    ( !has_edge( grf, edge ) || ( weight < 0.0 ) ) && return
    set_prop!( grf, edge, weightfield(grf), Float64(weight) )
end  # setEdgeWeight!( grf, edge, weight )

setEdgeWeight!( grf::MetaDiGraph, src::Int, dst::Int, weight::Real ) =
    setEdgeWeight!( grf, Edge( src, dst ),  weight )
setEdgeWeight!( grf::MetaDiGraph, edge::Tuple{Int, Int}, weight::Real ) =
    setEdgeWeight!( grf, Edge(edge), weight )


function breakFeasibleTree( uTree::SimpleGraph, edge::Edge )
    ii = 1
    # We have to remember that the edge is defined as tail-to-head (src-to-dst).
    headNodes = [edge.dst]
    
    while ii <= length(headNodes)
        newNodes = neighbors( uTree, headNodes[ii] )

        if ii == 1
            append!( headNodes, newNodes[newNodes .!= edge.src] )
        else
            append!( headNodes, filter( node -> node ∉ headNodes, newNodes ) )
        end  # if ii == 1

        ii += 1
    end  # while ii <= length(headNodes)
    
    headNodes
end  # breakFeasibleTree( uTree, edge )