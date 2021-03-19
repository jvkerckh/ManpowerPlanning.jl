let 
    mpsim = MPsim()

    attrib = Attribute("Attr A")
    addPossibleAttributeValue!( attrib, "Val AA", "Val AB" )
    addSimulationAttribute!( mpsim, attrib )

    attrib = Attribute("Attr B")
    addInitialAttributeValue!( attrib, ("Val BA", 1), ("Val BB", 2) )
    addSimulationAttribute!( mpsim, attrib )

    attrib = Attribute("Attr C")
    addPossibleAttributeValue!( attrib, "Val CA" )
    addSimulationAttribute!( mpsim, attrib )

    node = BaseNode("Test A")
    addNodeRequirement!( node, ("Attr A", "Val AA") )
    addSimulationBaseNode!( mpsim, node )

    recr = Recruitment("EW")
    setRecruitmentTarget!( recr, "Test A" )
    setRecruitmentSchedule!( recr, 12 )
    setRecruitmentFixed!( recr, 10 )
    setRecruitmentAgeFixed!( recr, 18*12 )
    addSimulationRecruitment!( mpsim, recr )

    setSimulationLength!( mpsim, 120 )
    run( mpsim )
end