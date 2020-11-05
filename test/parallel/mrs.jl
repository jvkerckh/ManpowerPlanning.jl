@testset "Multi-threaded runs test" begin

@info "Commencing test of multi-threaded parallel simulation runs. This test may take a few minutes, depending on the user's hardware and Julia settings."
tStart = now()
rm( "tmps", recursive=true, force=true )
mrs = MRS( mpSim )
@test verifySimulation!( mrs )
setMRSruns!( mrs, 30 )
setMRSdatabaseName!( mrs, "parallel/simDB.sqlite" )
setMRSmaxThreads!( mrs, 10 )
run( mrs )
tElapsed = ( now() - tStart ).value / 1000
@info string( "Running 30 simulations in parallel on ",
    min( 10, Threads.nthreads() ), " threads took ", tElapsed,
    " seconds. Thank you for your patience." )

db = SQLite.DB( "parallel/simDB.sqlite" )
@test length( SQLite.tables( db )[:name] ) == 92

println()

end  # @testset "Multi-threaded runs test"