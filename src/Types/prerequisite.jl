# This file defines the Prerequisite type, used to define all types of
#   prerequisites.

# It is important to note that prerequisites that define an inequality relation,
#   the relation is ALWAYS stated as
#     "prereqValue prereqRelation value_in_personnel_record".
# For example, if something requires a minimum age of 21.0, the prerequisite is
#   written as
#     "21.0 <= :age"

# The Prerequisite type requires no extra types.
requiredTypes = [ ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( dirname( Base.source_path() ), reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end  # for reqType in requiredTypes


export Prerequisite
type Prerequisite
    # This is the varaible for which there is a prerequisite.
    prereqVar::Symbol

    # This is the specific value that the prerequisite has to satisfy.
    prereqValue

    # This states how the prerequisite must be satisfied.
    prereqRelation::Function

    # Constructor.
    function Prerequisite( key::Symbol, value; valType::Type = String,
        relation::Function = == )
        prereq = new()
        prereq.prereqVar = key

        isStringLike = issubtype( valType, AbstractString ) ||
            issubtype( valType, Symbol )

        # Check if the given relation is appropriate.
        if relation ∈ [ ==, !=, <, >, <=, >=, ∈, ∉ ]
            if isStringLike && ( relation ∈ [ <, >, <=, >= ] )
                error( "Relation \"$relation\" inappropriate for argument of type $valType." )
            elseif !isStringLike && ( relation ∈ [ ∈, ∉ ] )
                error( "Relation \"$relation\" inappropriate for argument of type $valType." )
            else
                prereq.prereqRelation = relation
            end  # if isStringLike ...
        else
            error( "Unknown value for prerequisite relation parameter. Must be one of ==, !=, <, >, <=, >=, ∈, ∉." )
        end  # if relation ∈ ...

        # If the argument is supposed to be a string, cast the given argument as
        #   one.
        if issubtype( valType, AbstractString )
            prereq.prereqValue = string( value )
        # If the argument is a string, try to parse it to what it's supposed to
        #   be.
        #   If the argument can't be parsed propoerly,
        elseif isa( value, AbstractString )
            try
                prereq.prereqValue = parse( valType, value )
            catch err
                if isa( err, MethodError )
                    error( "Cannot cast argument towards a $valType." )
                elseif isa( err, ArgumentError )
                    error( "Cannot parse $value as a $valType." )
                else
                    error( "Unknown error in Prerequisite( $key, $value, $valType, relation )" )
                end  # if isa( err, MethodError )
            end  # try
        # If the argument's type is a subtype of the given type, accept it.
        elseif isa( value, valType )
            prereq.prereqValue = value
        else
            error( "$value (of type $(typeof( value ))) must be a subtype of $valType." )
        end  # if valType <: String

        return prereq
    end  # Prerequisite( key, value; valType, relation )
end  # type Prerequisite
