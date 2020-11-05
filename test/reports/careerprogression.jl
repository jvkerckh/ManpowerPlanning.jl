@testset "Career progression report" begin

@testset "function generateCareerProgression" begin
    report = generateCareerProgression( mpSim, "Test", "Sim1", "Sim100",
        "Sim500", "Sim1000" )
    @test all( haskey.( Ref( report ), ["Sim1", "Sim100", "Sim500"] ) ) &&
        !any( haskey.( Ref( report ), ["Test", "Sim1000"] ) )
    @test all( [report["Sim1"][1] == 240, report["Sim100"][1] == 240,
        report["Sim500"][1] == 240] )
    @test all( [
        all( report["Sim1"][2][:, "timeIndex"] .== [0, 24] ),
        all( report["Sim100"][2][:, "timeIndex"] .== [36, 60, 156] ),
        all( report["Sim500"][2][:, "timeIndex"] .==
            [192, 216, 252] )] )
    @test all( [
        all( report["Sim1"][2][:, "transition"] .== ["EW", "B-"] ),
        all( report["Sim100"][2][:, "transition"] .==
            ["EW", "Promotion", "PE"] ),
        all( report["Sim500"][2][:, "transition"] .==
            ["EW", "Promotion", "Promotion"] )] )
end  # @testset "function generateCareerProgression"

end  # @testset "Career progression report"