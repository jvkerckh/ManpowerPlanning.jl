# This file holds the definition of the functions pertaining to the Recruitment
#   type.

export  setRecruitmentName!,
        setRecruitmentSchedule!,
        setRecruitmentTarget!,
        setRecruitmentAdaptiveRange!,
        setRecruitmentFixed!,
        setRecruitmentDist!,
        setRecruitmentAgeDist!


"""
```
setRecruitmentName!(
    recruitment::Recruitment,
    name::String )
```
This function sets the name of the recruitment scheme `recruitment` to `name`.

This function returns `true`, indicating that the name has been successfully set.
"""
function setRecruitmentName!( recruitment::Recruitment, name::String )::Bool

    recruitment.name = name
    return true

end  # function setRecruitmentName!( recruitment, name )


"""
```
setRecruitmentSchedule!(
    recruitment::Recruitment,
    freq::Real,
    offset::Real = 0.0 )
```
This function sets the schedule of the recruitment scheme `recruitment` to once every `freq` time units, with an offset `offset` w.r.t. the start of the simulation.

If the given time between two recruitment drives ⩽ 0, the function issues a warning and makes no changes.

The function returns `true` if the recruitment schedule has been successfully set, and `false` if the entered period ⩽ 0.
"""
function setRecruitmentSchedule!( recruitment::Recruitment, freq::Real,
    offset::Real = 0.0 )::Bool

    if freq <= 0.0
        @warn "Recruitment frequency must be > 0.0, not making any changes."
        return false
    end  # if freq <= 0.0

    recruitment.freq = freq
    recruitment.offset = ( offset % freq ) +
        ( offset < 0.0 ? freq : 0.0 )
    return true

end  # setRecruitmentSchedule!( recruitment, freq, offset )


"""
```
setRecruitmentTarget!(
    recruitment::Recruitment,
    node::String )
```
This function sets the target node of the recruitment scheme `recruitment` to `node`. Note that this function does NOT check if the node actually exists in the simulation.

This function returns `true`, indicating that the target node has been successfully set.
"""
function setRecruitmentTarget!( recruitment::Recruitment, node::String )::Bool

    recruitment.targetNode = node
    return true

end  # setRecruitmentTarget!( recruitment, node )


"""
```
setRecruitmentAdaptiveRange!(
    recruitment::Recruitment,
    minRec::Integer,
    maxRec::Integer = -1 )
```
This function sets the recruitment amount of the recruitment scheme `recruitment` to an adaptive scheme with recruitment in the range `minRec` and `maxRec`. A negative value for the maximum recruitment means there is no upper limit and all vacancies in the target node will be filled.
    
If the entered minimum recruitment is larger than the maximum recruitment, the function issues a warning and makes no changes.

This function returns `true` if the adaptive range has been successfully set, and `false` if the entered minimum recruitment is larger than the maximum recruitment.
"""
function setRecruitmentAdaptiveRange!( recruitment::Recruitment,
    minRec::Integer, maxRec::Integer = -1 )::Bool

    if ( maxRec >= 0 ) && ( minRec > maxRec )
        @warn "Minimum recruitment must be ⩽ max recruitment, mot making any changes."
        return false
    end  # if ( maxRec >= 0 ) && ...

    recruitment.isAdaptive = true
    recruitment.minRecruitment = max( minRec, 0 )
    recruitment.maxRecruitment = max( maxRec, -1 )
    return true

end  # setRecruitmentAdaptiveRange!( recruitment, minRec, maxRec )


"""
```
setRecruitmentFixed!(
    recruitment::Recruitment,
    amount::Integer )
```
This function sets the number of people to recruit for the recruitment scheme `recruitment` to a fixed `amount` per recritment drive.

If the entered amount < 0, the function issues a warning and makes no changes.

The function returns `true` if the number of people to recruit has been successfully set, and `false` if the entered amount < 0.
"""
function setRecruitmentFixed!( recruitment::Recruitment, amount::Integer )::Bool

    if amount < 0
        @warn "Negative number of people to recruit entered, not making any changes."
        return false
    end  # if amount < 0

    recruitment.isAdaptive = false
    recruitment.recruitmentDistType = :disc
    recruitment.recruitmentDistNodes = Dict( Int( amount ) => 1.0 )
    recruitment.recruitmentDist = function() return Int( amount ) end
    return true

end  # setRecruitmentFixed!( recruitment, amount )


"""
```
setRecruitmentDist!(
    recruitment::Recruitment,
    distType::Symbol,
    distNodes::Dict{Int, Float64} )
```
This function sets the distribution of the number of people to recruit during every cycle of the recruitment scheme `recruitment` to a distribution of type `distType` with nodes `distNodes` (amount/weight). Permitted distribution types are `:disc` (discrete), `:pUnif` (piecewise uniform), and `:pLin` (piecewise linear). Nodes which have a negative amount (key) or negative weight are ignored.

If the entered distribution type is unknown, if there are insufficient proper nodes defined, or if the total weight of the proper nodes is 0, the function issues a warning and makes no changes.

The function returns `true` if the distribution of the number of people to recruit is successfully set, and `false` if any problems arose.
"""
setRecruitmentDist!( recruitment::Recruitment, distType::Symbol, distNodes::Dict{Int, Float64} )::Bool = setRecDist!( recruitment, distType, distNodes )


"""
```
setRecruitmentAgeDist!(
    recruitment::Recruitment,
    distType::Symbol,
    distNodes::Dict{Float, Float64} )
```
This function sets the distribution of the recruitment age of the recruitment scheme `recruitment` to a distribution of type `distType` with nodes `distNodes` (amount/weight). Permitted distribution types are `:disc` (discrete), `:pUnif` (piecewise uniform), and `:pLin` (piecewise linear). Nodes which have a negative amount (key) or negative weight are ignored.

If the entered distribution type is unknown, if there are insufficient proper nodes defined, or if the total weight of the proper nodes is 0, the function issues a warning and makes no changes.

The function returns `true` if the distribution of the recruitment age is successfully set, and `false` if any problems arose.
"""
setRecruitmentAgeDist!( recruitment::Recruitment, distType::Symbol, distNodes::Dict{Float64, Float64} )::Bool = setRecDist!( recruitment, distType, distNodes )


function Base.show( io::IO, recruitment::Recruitment )::Nothing

    print( io, "Recruitment scheme '", recruitment.name, "' to node '", 
        recruitment.targetNode, "'" )
    print( io, "\n  Recruitment schedule: ", recruitment.freq, " (offset ",
        recruitment.offset, ")" )

    if recruitment.isAdaptive
        print( io, "\n  Adaptive recruitment scheme, recruiting " )
        
        if recruitment.maxRecruitment == -1
            print( io, "at least ", recruitment.minRecruitment )
        else
            print( io, "in range ", recruitment.minRecruitment, " - ",
                recruitment.maxRecruitment )
        end  # if recruitment.maxRecruit == -1
    else
        print( io, "\n  Non-adaptive recruitment scheme, distribution of ",
            "number to recruit is ",
            recruitmentDists[ recruitment.recruitmentDistType ][ 1 ],
            " with node(s)" )
        
        for node in sort( collect( keys( recruitment.recruitmentDistNodes ) ) )
            print( io, "\n    ", node, " with weight ",
                recruitment.recruitmentDistNodes[ node ] )
        end  # for node in sort( collect( keys( ...
    end  # if recruitment.isAdaptive

    print( io, "\n  Distribution of recruitment age is ",
        recruitmentDists[ recruitment.ageDistType ][ 1 ], " with node(s)" )

    for node in sort( collect( keys( recruitment.ageDistNodes ) ) )
        print( io, "\n    ", node, " with weight ",
            recruitment.ageDistNodes[ node ] )
    end  # for node in sort( collect( keys( ...

    return

end  # show( io, recruitment )


include( joinpath( privPath, "recruitment.jl" ) )