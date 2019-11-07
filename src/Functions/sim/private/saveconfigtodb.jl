function wipeConfigTable( mpSim::MPsim )

    SQLite.execute!( mpSim.simDB, "DROP TABLE IF EXISTS config" )
    sqliteCmd = string( "CREATE TABLE config(",
        "\n    parName VARCHAR(32),",
        "\n    parType VARCHAR(32),",
        "\n    parValue TEXT )" )
    SQLite.execute!( mpSim.simDB, sqliteCmd )

end  # wipeConfigTable( mpSim )


function storeGeneralPars( mpSim::MPsim )

    sqliteCmd = string( "INSERT INTO config (parName, parType, parValue)",
        " VALUES",
        "\n    ('Sim name', 'General', '", mpSim.simName, "'),",
        "\n    ('ID key', 'General', '", mpSim.idKey, "'),",
        "\n    ('Personnel target', 'General', '", mpSim.personnelTarget, "'),",
        "\n    ('Sim length', 'General', '", mpSim.simLength, "'),",
        "\n    ('Current time', 'General', '", now( mpSim ), "'),",
        "\n    ('DB commits', 'General', '", mpSim.nCommits, "')" )
    SQLite.execute!( mpSim.simDB, sqliteCmd )

end  # storeGeneralPars( mpSim )


function storeAttributes( mpSim::MPsim )

    if isempty( mpSim.attributeList )
        return
    end  # if isempty( mpSim.attributeList )

    sqliteCmd = map( collect( keys( mpSim.attributeList ) ) ) do name
        attribute = mpSim.attributeList[ name ]
        return string( "\n    ('", name, "', 'Attribute', '[",
            join( attribute.possibleValues, "," ), "];[",
            join( string.( attribute.initValues, ":",
            attribute.initValueWeights ), "," ), "]')" )
    end  # map( ... ) do name

    sqliteCmd = string( "INSERT INTO config (parName, parType, parValue)",
        " VALUES", join( sqliteCmd, "," ) )
    SQLite.execute!( mpSim.simDB, sqliteCmd )

end  # storeAttributres( mpSim )


function storeAttrition( mpSim )

    sqliteCmd = map( collect( keys( mpSim.attritionSchemes ) ) ) do name
        attrition = mpSim.attritionSchemes[ name ]
        return string( "\n    ('", name, "', 'Attrition', '", attrition.period,     ";[", join( string.( attrition.curvePoints, ":", attrition.rates ),
            "," ), "]')" )
    end  # map( ... ) do name

    sqliteCmd = string( "INSERT INTO config (parName, parType, parValue)",
        " VALUES", join( sqliteCmd, "," ) )        
    SQLite.execute!( mpSim.simDB, sqliteCmd )

end  # storeAttrition( mpSim )


function storeNodes( mpSim::MPsim )

    if isempty( mpSim.baseNodeList ) && isempty( mpSim.compoundNodeList )
        return
    end  # if isempty( mpSim.baseNodeList ) && ...

    baseNodeCmd = map( collect( keys( mpSim.baseNodeList ) ) ) do name
        node = mpSim.baseNodeList[ name ]
        tmpCmd = join( map( attr -> string( attr, ":",
            node.requirements[ attr ] ), collect( keys( node.requirements ) ) ),
            "," )
        return string( "\n    ('", name, "', 'Base Node', '", node.target, ";",
            node.attrition, ";[", tmpCmd, "]')" )
    end  # map( ... ) do name

    compNodeCmd = map( collect( keys( mpSim.compoundNodeList ) ) ) do name
        node = mpSim.compoundNodeList[ name ]
        return string( "\n    ('", name, "', 'Compound Node', '[",
            join( node.baseNodeList, "," ), "];", node.nodeTarget, "')" )
    end  # map( ... ) do name

    sqliteCmd = string( "INSERT INTO config (parName, parType, parValue)",
        " VALUES", join( baseNodeCmd, "," ),
        isempty( baseNodeCmd ) || isempty( compNodeCmd ) ? "" : ",",
        join( compNodeCmd, "," ) )
    SQLite.execute!( mpSim.simDB, sqliteCmd )

end  # storeNodes( mpSim )


function storeRecruitment( mpSim::MPsim )

    if isempty( mpSim.recruitmentByName )
        return
    end  # if isempty( mpSim.recruitmentByName )

    sqliteCmd = map( collect( keys( mpSim.recruitmentByName ) ) ) do name
        recruitmentList = mpSim.recruitmentByName[ name ]

        return map( recruitmentList ) do recruitment
            # recNrConfig = nothing

            if recruitment.isAdaptive
                recNrConfig = string( recruitment.minRecruitment, ";",
                    recruitment.maxRecruitment )
            else
                recNrConfig = map( collect( keys(
                    recruitment.recruitmentDistNodes ) ) ) do amount
                    return string( amount, ":",
                        recruitment.recruitmentDistNodes[ amount ] )
                end  # map( ... ) do amount

                recNrConfig = string( recruitment.recruitmentDistType, ";[",
                    join( recNrConfig, "," ), "]" )
            end  # if recruitment.isAdaptive

            recAgeConfig = map( collect( keys(
                recruitment.ageDistNodes ) ) ) do age
                return string( age, ":", recruitment.ageDistNodes[ age ] )
            end  # map( ... ) do age
            
            recAgeConfig = string( recruitment.ageDistType, ";[",
                join( recAgeConfig, "," ), "]" )

            return string( "\n    ('", name, "', 'Recruitment', '",
                recruitment.freq, ";", recruitment.offset, ";",
                recruitment.targetNode, ";", recNrConfig, ";", recAgeConfig,
                "')" )
        end  # map( recruitmentList ) do recruitment
    end  # map( ... ) do name

    sqliteCmd = string( "INSERT INTO config (parName, parType, parValue)",
        " VALUES", join( join.( sqliteCmd, "," ), "," ) )
    SQLite.execute!( mpSim.simDB, sqliteCmd )

end  # storeRecruitment( mpSim )