function XLSX.read_worksheet_dimension(xf::XLSX.XLSXFile, relationship_id, name) :: XLSX.CellRange
    wb = XLSX.get_workbook(xf)
    target_file = "xl/" * XLSX.get_relationship_target_by_id(wb, relationship_id)
    zip_io, reader = XLSX.open_internal_file_stream(xf, target_file)

    local result::Nullable{XLSX.CellRange} = Nullable{XLSX.CellRange}()

    # read Worksheet dimension
    while !EzXML.done(reader)
        if EzXML.nodetype(reader) == EzXML.READER_ELEMENT && EzXML.nodename(reader) == "dimension"
            @assert EzXML.nodedepth(reader) == 1 "Malformed Worksheet \"$(ws.name)\": unexpected node depth for dimension node: $(EzXML.nodedepth(reader))."
            ref_str = reader["ref"]
            if XLSX.is_valid_cellname(ref_str)
                result = XLSX.CellRange("$(ref_str):$(ref_str)")
            else
                # Workaround in case the dimension of a worksheet is given as
                #   a range of rows instead of a proper cell range.
                tmpRefStr = split( ref_str, ":" )

                if tryparse( Int, tmpRefStr[ 1 ] ).hasvalue
                    tmpRefStr = "XFD" .* tmpRefStr
                    ref_str = join( tmpRefStr, ":" )
                end

                result = XLSX.CellRange(ref_str)
            end

            break
        end
    end

    close(reader)
    close(zip_io)

    if isnull(result)
        error("Couldn't parse worksheet $name dimension.")
    else
        return get(result)
    end
end
