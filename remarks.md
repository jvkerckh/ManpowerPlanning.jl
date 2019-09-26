To ensure compatibility with both Julia v0.7 and v1.2 without deprecation warning, we added the line
```
DataFrames = "<0.19"
```
to the `project.toml` file. Using `Dataframes` v0.19.0 and above will generate a deprecation warning for `getindex( df::DataFrame, col_ind::ColumnIndex )`.