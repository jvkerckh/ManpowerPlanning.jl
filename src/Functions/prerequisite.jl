# This file defines the functions pertaining to the Prerequisite type.

# It is important to note that prerequisites that define an inequality relation,
#   the relation is ALWAYS stated as
#     "prereqValue prereqRelation value_in_personnel_record".
# For example, if something requires a minimum age of 21.0, the prerequisite is
#   written as
#     "21.0 <= :age"

# The functions of the Prerequisite type require the Personnel,
#   PersonnelDatabase, HistoryEntry, and History types.
requiredTypes = [ "personnel", "personnelDatabase", "historyEntry", "history",
    "prerequisite" ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( typePath, reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end  # for reqType in requiredTypes


# This function tests if the prerequisite is on the given field in the personnel
#   database.  ( necessary??? )
export isPrereqVariable
function isPrereqVariable( prereq::Prerequisite, pVar::Symbol )
    return prereq.prereqVar === pVar
end  # isPrereqVariable( prereq, pVar )


# This function tests if a person satisfies the prerequisite. If this person
#   does not have the key being checked, the result defaults to false.
export isSatisfied
function isSatisfied( prereq::Prerequisite, person::Personnel )
    # If the variable is not available, the constraint is automatically
    #   violated.
    if !hasAttribute( person, prereq.prereqVar )
        return false
    end  # if hasAttribute( person, prereq.prereqVar )

    # If the value of the attribute in the personnel record is nothing, return
    #   true if the relation is !=, and false otherwise.
    if nothing === person[ prereq.prereqVar ]
        return prereq.prereqRelation === (!=)
    end

    # The try-catch block tries to test for the constraint. If testing the
    #   constraint generates an error, for example by testing Int ∈ Int, it
    #   will automatically be violated.
    try
        return prereq.prereqRelation( prereq.prereqValue,
            person[ prereq.prereqVar ] )
    catch
        return false
    end  # try
end  # isSatisfied( prereq, person )


# This function tests if a person satisfies the prerequisite at a specific time.
#   If this person has no history of the attribute being checked, it tests on
#   the actual attribute.
function isSatisfied( prereq::Prerequisite, person::Personnel,
    timestamp::T ) where T <: Real
    # If there's no history for the attribute, check the actual attribute.
    if !hasHistory( person, prereq.prereqVar )
        return isSatisfied( prereq, person )
    end  # if !hasHistory( person, prereq.prereqVar )

    # The try-catch block tries to test for the constraint. If testing the
    #   constraint generates an error, for example by testing Int ∈ Int, it
    #   will automatically be violated.
    try
        return prereq.prereqRelation( prereq.prereqValue,
            person[ prereq.prereqVar, timestamp ] )
    catch
        return false
    end  # try
end  # isSatisfied( prereq, person, timestamp )


# This function tests if the person with the given id in the database satisfies
#   the prerequisite.
function isSatisfied( prereq::Prerequisite, dbase::PersonnelDatabase,
    index::DbIndexType )
    return isSatisfied( prereq, dbase[ index ] )
end  # isSatisfied( prereq, dbase, index )


# This function tests if the person with the given id in the database satisfies
#   the prerequisite at the given time.
function isSatisfied( prereq::Prerequisite, dbase::PersonnelDatabase,
    index::DbIndexType, timestamp::T ) where T <: Real
    return isSatisfied( prereq, dbase[ index ], timestamp )
end  # isSatisfied( prereq, dbase, index, timestamp )


# This function selects all the records in the database satisfying the specific
#   prerequisite.
export selectRecords
function selectRecords( dbase::PersonnelDatabase, prereq::Prerequisite )
    return dbase[ find( person -> isSatisfied( prereq, person ), dbase.dbase ) ]
end  # selectRecords( dbase, prereq )


# This function counts all the records in the database satisfying the specific
#   prerequisite.
export countRecords
function countRecords( dbase::PersonnelDatabase, prereq::Prerequisite )
    return count( person -> isSatisfied( prereq, person ), dbase.dbase )
end  # countRecords( dbase, prereq )


# This function counts all the records in the database satisfying the specific
#   prerequisite at the given time.
function countRecords( dbase::PersonnelDatabase, prereq::Prerequisite,
    timestamp::T ) where T <: Real
    return count( person -> isSatisfied( prereq, person, timestamp ),
        dbase.dbase )
end  # countRecords( dbase, prereq, timestamp )


function Base.show( io::IO, prereq::Prerequisite )
    showFields = [ prereq.prereqValue, ' ', prereq.prereqRelation, ' ',
        prereq.prereqVar ]

    map( x -> print( io, x ), showFields )
end  # show( io, prereq )
