# This file defines the functions pertaining to the PrerequisiteGroup type..

# The functions of the PrerequisiteGroup type require the Personnel,
#   PersonnelDatabase, and Prerequisite types.
requiredTypes = [ "personnel", "personnelDatabase", "prerequisite",
    "prerequisiteGroup" ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( typePath, reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end  # for reqType in requiredTypes


# This function tests if any of the prerequisites in the group are on the given
#   field in the personnel database.  ( necessary?? )
export isPrereqVariable
function isPrereqVariable( prereqGroup::PrerequisiteGroup, pVar::Symbol )
    return map( prereq -> isPrereqVariable( prereq, pVar ), prereqGroup.prereqs )
end  # isPrereqVariable( prereqGroup, pVar )


# This function adds a prerequisite to the group.
export addPrereq!
function addPrereq!( prereqGroup::PrerequisiteGroup, prereq::Prerequisite )
    push!( prereqGroup.prereqs, prereq )
end  # addPrereq!( prereqGroup, prereq )


# This function removes a prerequisite from the group.
export removePrereq!
function removePrereq!( prereqGroup::PrerequisiteGroup, index::T ) where T <: Integer
    if 1 <= index <= length( prereqGroup.prereqs )
        deleteat!( prereqGroup.prereqs, index )
    end  # if 1 <= index <= length( prereqGroup.prereqs )
end  # removePrereq!( prereqGroup, index )


# This function tests if a person satisfies all the prerequisites in the group.
export isSatisfied
function isSatisfied( prereqGroup::PrerequisiteGroup, person::Personnel )
    return all( prereq -> isSatisfied( prereq, person ),
        prereqGroup.prereqs )
end  # isSatisfied( prereqGroup, person )


# This function tests if a person satisfies all the prerequisites in the group
#   at the given time.
function isSatisfied( prereqGroup::PrerequisiteGroup, person::Personnel,
    timestamp::T ) where T <: Real
    return all( prereq -> isSatisfied( prereq, person, timestamp ),
        prereqGroup.prereqs )
end  # isSatisfied( prereqGroup, person, timestamp )


# This function tests if a person satisfies any of the prerequisite groups in
#   the vector of prerequisites.
function isSatisfied( prereqGroups::Vector{PrerequisiteGroup},
    person::Personnel )
    # This line is necessary since the "any" function returns false for an empty
    #   vector.
    if isempty( prereqGroups )
        return true
    end  # if isempty( prereqGroups )

    return any( prereqGroup -> isSatisfied( prereqGroup, person ),
        prereqGroups )
end  # isSatisfied( prereqGroups, person )


# This function tests if a person satisfies any of the prerequisite groups in
#   the vector of prerequisites at the given time.
function isSatisfied( prereqGroups::Vector{PrerequisiteGroup},
    person::Personnel, timestamp::T ) where T <: Real
    # This line is necessary since the "any" function returns false for an empty
    #   vector.
    if isempty( prereqGroups )
        return true
    end  # if isempty( prereqGroups )

    return any( prereqGroup -> isSatisfied( prereqGroup, person,
        timestamp ), prereqGroups )
end  # isSatisfied( prereqGroups, person, timestamp )


# This function tests if the person with the given id in the database satisfies
#   the prerequisite.
function isSatisfied( prereqGroup::PrerequisiteGroup, dbase::PersonnelDatabase,
    index::DbIndexType )
    return isSatisfied( prereqGroup, dbase[ index ] )
end  # isSatisfied( prereqGroup, dbase, index )


# This function tests if the person with the given id in the database satisfies
#   the prerequisite at the given time.
function isSatisfied( prereqGroup::PrerequisiteGroup, dbase::PersonnelDatabase,
    index::DbIndexType, timestamp::T ) where T <: Real
    return isSatisfied( prereqGroup, dbase[ index ], timestamp )
end  # isSatisfied( prereqGroup, dbase, index, timestamp )


# This function selects all the records in the database satisfying the specific
#   group of prerequisites.
export selectRecords
function selectRecords( dbase::PersonnelDatabase,
    prereqGroup::PrerequisiteGroup )
    return dbase[ find( person -> isSatisfied( prereqGroup, person ),
        dbase.dbase ) ]
end  # selectRecords( dbase, prereqGroup )


# This function counts the number of records in the database satisfying the
#   specific group of prerequisites.
export countRecords
function countRecords( dbase::PersonnelDatabase,
    prereqGroup::PrerequisiteGroup )
    return count( person -> isSatisfied( prereqGroup, person ), dbase.dbase )
end  # countRecords( dbase, prereqGroup )


# This function counts the number of records in the database satisfying the
#   specific group of prerequisites at the given time.
function countRecords( dbase::PersonnelDatabase, prereqGroup::PrerequisiteGroup,
    timestamp::T ) where T <: Real
    return count( person -> isSatisfied( prereqGroup, person,
        timestamp ), dbase.dbase )
end  # countRecords( dbase, prereqGroup, timestamp )


# This function counts the number of personnel records in the database that
#   started to satisfy the group of prerequisites during the specific time
#   interval.
# Here the start of the interval is inclusive, and the end is exclusive. In
#   other words, the change occurred for t_start ⩽ t < t_end.
export countFluxIn
function countFluxIn( dbase::PersonnelDatabase, prereqGroup::PrerequisiteGroup,
    t_begin::T1, t_end::T2 ) where T1 <: Real where T2 <: Real
    if t_begin >= t_end
        error( "Start time of the interval must be earlier than the end time of the interval." )
    end  # if t_begin >= t_end

    return count( person -> isSatisfied( prereqGroup, person, t_end ) &&
        !isSatisfied( prereqGroup, person, t_begin ), dbase.dbase )
end  # countFluxIn( dbase, prereqGroup, t_begin, t_end )


# This function counts the number of personnel records in the database that
#   stopped to satisfy the group of prerequisites during the specific time
#   interval.
# Here the start of the interval is exclusive, and the end is inclusive. In
#   other words, the change occurred for t_start < t ⩽ t_end.
export countFluxOut
function countFluxOut( dbase::PersonnelDatabase, prereqGroup::PrerequisiteGroup,
    t_begin::T1, t_end::T2 ) where T1 <: Real where T2 <: Real
    if t_begin >= t_end
        error( "Start time of the interval must be earlier than the end time of the interval." )
    end  # if t_begin >= t_end

    return count( person -> !isSatisfied( prereqGroup, person, t_end ) &&
        isSatisfied( prereqGroup, person, t_begin ), dbase.dbase )
end  # countFluxOut( dbase, prereqGroup, t_begin, t_end )


function Base.show( io::IO, prereqGroup::PrerequisiteGroup )
    if isempty( prereqGroup.prereqs )
        print( io, "No prerequisites in group." )
        return
    end  # if isempty( prereqGroup.prereqs )

    isPartPrinted = false

    for prereq in prereqGroup.prereqs
        if isPartPrinted
            println( io )
        end  # if isPartPrinted

        show( io, prereq )
        isPartPrinted = true
    end  # for prereq in prereqGroup.prereqs
end  # Base.show( io, prereqGroup )
