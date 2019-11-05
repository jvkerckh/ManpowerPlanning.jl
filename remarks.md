The line `DataFrames = "<0.19"` in the `project.toml` file is needed to avoid a deprecation warning for `df[ :, col_index::ColIndex ] = v`.

The line `SQLite = "<0.8.2"` in the `project.toml` file is needed to avoid an error in the subpopulation population reports. Sometimes incorrect numbers are reported when using `SQLite v0.8.2`. Need to investigate!

Why do I have to list `ResumableFunctions` as an explicit dependency in the `project.toml` file without needing to add `using ResumableFunctions`? **Ask Ben**