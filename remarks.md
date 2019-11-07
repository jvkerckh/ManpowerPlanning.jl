The line `DataFrames = "<0.19"` in the `project.toml` file is needed to avoid a deprecation warning for `df[ :, col_index::ColIndex ] = v` under Julia `v1.2`.

The line `SQLite = "<0.8.2"` in the `project.toml` file is needed to avoid an error in the subpopulation population reports. Sometimes incorrect numbers are reported when using `SQLite v0.8.2`. Need to investigate!

The line `SimJulia = "<0.8` in the `project.toml` file is needed to avoid an error in the processes under Julia `v1.2`. This is due to the changing type of the `priority` argument, from `Int8` to `Int`.

Separate process for retirement will be removed in the next major version update.

Why do I have to list `ResumableFunctions` as an explicit dependency in the `project.toml` file without needing to add `using ResumableFunctions`? **Ask Ben**
*Answer*: it shouldn't... to be continued. Maybe it's not necessary anymore under Julia `v1.2`?