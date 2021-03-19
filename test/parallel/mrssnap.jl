@testset "Multi-threaded runs test, with init pop" begin

@info "Commencing test of multi-threaded parallel simulation runs, with initial population. This test may take a few minutes, depending on the user's hardware and Julia settings."
tStart = now()
rm( "parallel/tmps", recursive=true, force=true )
rm( "parallel/simDB2.sqlite", force=true )

mrs = MRS( mpSim )
nRuns = 50
setMRSruns!( mrs, nRuns )
setMRSdatabaseName!( mrs, "parallel/simDB2.sqlite" )
setMRSmaxThreads!( mrs, 10 )
uploadSnapshot( mrs, "snapshot/test foto 1", "Sheet1", ["B", "C", "D"],
    ("A", "G", "F", "E", "H") )
@test verifySimulation!( mrs )

run( mrs )
tElapsed = ( now() - tStart ).value / 1000
@info string( "Running ", nRuns, " simulations in parallel on ",
    min( 10, Threads.nthreads() ), " threads took ", tElapsed,
    " seconds. Thank you for your patience." )

db = SQLite.DB( "parallel/simDB2.sqlite" )
@test length( SQLite.tables( db )[:name] ) == 3 * nRuns + 5
@test all( 1:nRuns ) do ii
    queryCmd = string( "SELECT * FROM `", mrs.mpSim.transDBname, ii, "`",
        "\n    WHERE transition IS 'Init'")
    initpop = DataFrame(DBInterface.execute( db, queryCmd ))
    size( initpop, 1 ) == 50
end  # all( 1:nRuns ) do ii

println()

end  # @testset "Multi-threaded runs test, with init pop"