# This file holds the functions used to read an Excel parameter file and store
#   the configuration in a SQLite table.

export readParFileToDatabase


"""
```
readParFileToDatabase( fileName::String,
                       dbName::String,
                       configName::String = "config" )
```
This function reads the Excel file with filename `fileName`, processes the
parameters, and stores them in the `config` of the SQLite database with filename
`dbName`. If these filenames do not have the proper extension, `.xlsx` for the
Excel and `.sqlite` for the database, it will be apended to the name.

This function returns `nothing`. If the Excel file doesn't exist, this function
will throw an error.
"""
function readParFileToDatabase( fileName::String, dbName::String,
    configName::String = "config" )::Void

    newMPsim = ManpowerSimulation( fileName )
    saveSimConfigToDatabase( mpSim, dbName, configName )
    return

end  # readParFileToDatabase( fileName, dbName )
