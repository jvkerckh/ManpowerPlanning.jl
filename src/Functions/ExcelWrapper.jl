# Making sure the Taro package is loaded...
if !isdefined( :Taro )
    using Taro.Workbook
    using Taro.CellStyle
    using Taro.createCellStyle
end  # !isdefined( :Taro )

module ExcelWrapper

# Including inside the module!
if !isdefined( :Taro )
    using Taro
    Taro.init()  # And properly initialized
end  # !isdefined( :Taro )

export Taro, Workbook

if !isdefined( :JavaCall )
    using JavaCall
end

colnum( c::AbstractString ) = Taro.colnum( c ) + 1

const BorderStyle = @jimport org.apache.poi.ss.usermodel.BorderStyle
const CellRangeAddress = @jimport org.apache.poi.ss.util.CellRangeAddress
const ColIndex = Union{AbstractString, Integer}
const HorizontalAlignment = @jimport org.apache.poi.ss.usermodel.HorizontalAlignment
const ExcelMIMEType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"

const allowedVals = Dict{DataType, Vector{String}}()

# Set up the allowed values for all defined enumeration types.
for enumType in [ HorizontalAlignment, BorderStyle ]
    allowedVals[ enumType ] = Vector{String}()

    for value in jcall( enumType, "values", Array{enumType, 1}, (), )
        push!( allowedVals[ enumType ], jcall( value, "toString", JString, (), ) )
    end  # for value in jcall( enumType, "values", Array{JavaObject, 1}, (), )
end  # for enumType in [ HorizontalAlignment, BorderStyle ]

function CellRangeAddress( firstCol::Integer, firstRow::Integer,
    lastCol::Integer, lastRow::Integer )
    return CellRangeAddress( ( jint, jint, jint, jint, ), firstRow - 1,
        lastRow - 1, firstCol - 1, lastCol - 1 )
end  # CellRangeAddress( firstCol, lastCol, firstRow, lastRow )

function CellRangeAddress( firstCol::AbstractString, firstRow::Integer,
    lastCol::AbstractString, lastRow::Integer )
    return CellRangeAddress( colnum( firstCol ), colnum( lastCol ), firstRow,
        lastRow )
end  # CellRangeAddress( firstCol, lastCol, firstRow, lastRow )

function valueOf( valType::DataType, value::AbstractString )
    if !haskey( allowedVals, valType )
        error( valType, " is not a recognised formatting type." )
    end  # !haskey( allwedVals, valType )

    tmpVal = uppercase( value )

    if !in( tmpVal, allowedVals[ valType ] )
        error( valType, " cannot have the value \"", tmpVal, "\"." )
    end  # !in( tmpVal, allowedVals[ valType ] )

    return jcall( valType, "valueOf", valType, ( JString, ), tmpVal )
end  # valueOf( valType, value )


export getSheet, getRow, getCell, getCellValue, getColumnWidth, getRowHeight,
    getCellStyle, createSheet, createRow, cloneCellStyle, createCell, numRows,
    setCellValue, setColumnWidth, setRowHeight, mergeCells, setCellStyle,
    setHorizontalAlignment, setBorder, setBorderBottom, setBorderTop,
    setBorderLeft, setBorderRight, setBorders

# Redefines the getSheet function such that sheet 1 in the code corresponds to
#   the first sheet in the Excel workbook.
getSheet( w::Workbook, s::Integer ) = Taro.getSheet( w, s - 1 )
getSheet( w::Workbook, s::AbstractString ) = Taro.getSheet( w, s )

# Redefines the getRow function such that row 1 in the code corresponds to row 1
#   in the Excel sheet.
getRow( s::Taro.Sheet, r::Integer ) = Taro.getRow( s, r - 1 )

# Redefines the getCell function such that cell 1 in the code corresponds to
#   column A in the Excel sheet.
getCell( r::Taro.Row, c::Integer ) = Taro.getCell( r, c - 1 )
getCell( r::Taro.Row, c::AbstractString ) = getCell( r, colnum( c ) )

# This function return the cell "rc" from the requested worksheet. If the row r
#   doesn't exist, the function return a NULL cell.
function getCell( s::Taro.Sheet, c::Integer, r::Integer )
    rowObj = getRow( s, r )
    return rowObj.ptr === Ptr{Void}( 0 ) ? Taro.Cell( 0 ) : getCell( rowObj, c )
end  # getCell( s, c, r )

getCell( s::Taro.Sheet, c::AbstractString, r::Integer ) =
    getCell( s, colnum( c ), r )

# Redefines the getCellValue function such that it won't throw an error when
#   called on a NULL cell. Instead, it will return "nothing".
getCellValue( cell::Taro.Cell ) = cell.ptr === Ptr{Void}( 0 ) ? nothing :
    Taro.getCellValue( cell )
getCellValue( s::Taro.Sheet, c::ColIndex, r::Integer ) =
    getCellValue( getCell( s, c, r ) )

# This function allows the user to retrieve the contents of a cell with
#   s[ c, r ].
Base.getindex( s::Taro.Sheet, c::ColIndex, r::Integer ) =
    getCellValue( s, c, r )

# This function retrieves the width of a column of the sheet. As before, column
#   1 corresponds to column "A" in the sheet. The argument "inPixels" determines
#   whether the width is returned in char widths (true) or in pixels.
getColumnWidth( s::Taro.Sheet, c::Integer, inChars::Bool = true ) =
    inChars ? jcall( s, "getColumnWidth", jint, ( jint, ), c - 1 ) / 256 :
        jcall( s, "getColumnWidthInPixels", jfloat, ( jint, ), c - 1 )
getColumnWidth( s::Taro.Sheet, c::AbstractString, inChars::Bool = true ) =
    getColumnWidth( s, colnum( c ), inChars )

# This function retrieves the height of a row of the sheet in points. As before,
#   row 1 corresponds to row 1 of the sheet.
getRowHeight( r::Taro.Row ) = jcall( r, "getHeightInPoints", jfloat, () )

function getRowHeight( s::Taro.Sheet, r::Integer )
    tmpRow = getRow( s,r )
    return tmpRow.ptr === Ptr{Void}( 0 ) ?
        jcall( s, "getDefaultRowHeightInPoints", jfloat, () ) :
        getRowHeight( tmpRow )
end  # getRowHeight( s, r )

# This function gets the style of the given cell. As before, the cell in row 1,
#   column 1 corresponds to cell "A1" of the sheet.
getCellStyle( c::Taro.Cell ) = jcall( c, "getCellStyle", Taro.CellStyle, (), )
getCellStyle( s::Taro.Sheet, c::ColIndex, r::Integer ) =
    getCellStyle( createCell( s, c, r ) )

# This function clones the source cell style to the target style. Important:
#   this function has a bug in Java as it doesn't copy border styles.
function cloneCellStyle( targetStyle::Taro.CellStyle,
    sourceStyle::Taro.CellStyle )

    jcall( targetStyle, "cloneStyleFrom", Void, ( Taro.CellStyle, ),
        sourceStyle )
end  # cloneCellStyle( targetStyle, sourceStyle )

cloneCellStyle( targetStyle::Taro.CellStyle, c::Taro.Cell ) =
    cloneCellStyle( targetStyle, getCellStyle( c ) )
cloneCellStyle( targetStyle::Taro.CellStyle, s::Taro.Sheet, c::ColIndex, r::Integer ) =
    cloneCellStyle( targetStyle, getCellStyle( s, c, r ) )

# Redefines the createSheet function such that it only creates a new sheet IF
#   none of that name exists in the workbook. The function then returns the
#   created/existing sheet.
function createSheet( w::Workbook, s::AbstractString )
    tmpSheet = getSheet( w, s )

    if tmpSheet.ptr === Ptr{Void}( 0 )
        tmpSheet = Taro.createSheet( w, s )
    end  # if tmpSheet.ptr === Ptr{Void}( 0 )

    return tmpSheet
end  # cratesheet( w, s )

# Redefines the createRow function such that row 1 in the code corresponds to
#   row 1 in the Excel sheet. The function only creates the row if it doesn't
#   exist yet in the sheet, and returns the created/existing row.
function createRow( s::Taro.Sheet, r::Integer )
    tmpRow = getRow( s, r )

    if tmpRow.ptr === Ptr{Void}( 0 )
        tmpRow = Taro.createRow( s, r - 1 )
    end  # if tmpRow.ptr === Ptr{Void}( 0 )

    return tmpRow
end  # createRow( s, r )

# Redefines the createCell function such that column 1 in the code corresponds
#   to column A in the Excel sheet.The function only creates the cell if it
#   doesn't exist yet in the row, and returns the created/existing cell.
function createCell( r::Taro.Row, c::Integer )
    tmpCell = getCell( r, c )

    if tmpCell.ptr === Ptr{Void}( 0 )
        tmpCell = Taro.createCell( r, c - 1 )
    end  # if tmpCell.ptr === Ptr{Void}( 0 )

    return tmpCell
end  # createCell( r, c )

createCell( r::Taro.Row, c::AbstractString ) = createCell( r, colnum( c ) )

# This function creates a cell in column c and row r. If the row doesn't exist,
#   the function creates the new row as well and returns the new cell.
createCell( s::Taro.Sheet, c::ColIndex, r::Integer ) =
    createCell( createRow( s, r ), c )


# This function counts the number of defined rows in an Excel sheet. If the
#   second argument is not zero, it checks if the first 'nCols' columns have
#   content and returns the last row that has content in one of those columns.
function numRows( s::Taro.Sheet, nCols::T = 0 ) where T <: Integer
    nRows = jcall( s, "getLastRowNum", jint, () ) + 1

    if nCols <= 0
        return nRows
    end  # if nCols <= 0

    # Check the first nCols of each row to see if anything's actually been
    #   defined in the row, starting from the last.
    isRowEmpty = true

    while ( nRows > 0 ) && isRowEmpty
        isRowEmpty = all( ii -> s[ ii, nRows ] === nothing, 1:nCols )
        nRows -= isRowEmpty ? 1 : 0
    end  # ( nRows > 0 ) && !isRowEmpty

    return nRows
end  # numRows( s, nCols )

function numRows( s::Taro.Sheet, colEnd::String )
    return numRows( s, colnum( colEnd ) )
end  # numRows( s, colEnd )


# This function does the same as the previous numRows function, but checks the
#   columns with a number between "colStart" and "colEnd"
function numRows( s::Taro.Sheet, colStart::T1, colEnd::T2 ) where T1 <: Integer where T2 <: Integer
    nRows = jcall( s, "getLastRowNum", jint, () ) + 1

    if colStart > colEnd
        return nRows
    end  # if colStart > colEnd

    # Check all columns between column "colStart" and "colEnd" to see if
    #   anything's defined in those cells of that row, starting from the last.
    isRowEmpty = true

    while ( nRows > 0 ) && isRowEmpty
        isRowEmpty = all( ii -> s[ ii, nRows ] === nothing, colStart:colEnd )
        nRows -= isRowEmpty ? 1 : 0
    end  # ( nRows > 0 ) && !isRowEmpty

    return nRows
end  # numRows( s, colStart, colEnd )

function numRows( s::Taro.Sheet, colStart::String, colEnd::String )
    return numRows( s, colnum( colStart ), colnum( colEnd ) )
end  # numRows( s, colStart, colEnd )


# Redefines the setCellValue function to bundle the setCellValue and
#   setCellFormula functions. If the string starts with '=', it is considered to
#   be a formula. Otherwise, it's an ordinary string.
setCellValue( c::Taro.Cell, val::AbstractString ) = startswith( val, "=" ) ?
    Taro.setCellFormula( c, val[ 2:end ] ) : Taro.setCellValue( c, val )
setCellValue( c::Taro.Cell, val::Union{Real, Date, DateTime} ) =
    Taro.setCellValue( c, val )
setCellValue( s::Taro.Sheet, c::ColIndex, r::Integer,
    val::Union{AbstractString, Real, Date, DateTime} ) =
    setCellValue( createCell( s, c, r ), val )

# This function allows the user to set a cell's value with s[ c, r ] = val.
Base.setindex!( s::Taro.Sheet, val::Union{AbstractString, Real, Date, DateTime},
    c::ColIndex, r::Integer ) =
    setCellValue( s, c, r, val )

# This function sets the width of a column of the sheet to the given value. As
#   before, column 1 corresponds to column "A" in the sheet. The width of the
#   column is given in char widths.
setColumnWidth( s::Taro.Sheet, c::Integer, w::Real ) =
    jcall( s, "setColumnWidth", Void, ( jint, jint, ), c - 1,
        floor( Integer, w * 256 ) )
setColumnWidth( s::Taro.Sheet, c::AbstractString, w::Real ) =
    setColumnWidth( s, colnum( c ), w )

# This function sets the height of a row of the sheet to the given value. As
#   before, row 1 corresponds to row 1 in the sheet. The height of the row is
#   given in points.
setRowHeight( r::Taro.Row, h::Real ) =
    jcall( r, "setHeightInPoints", Void, ( jfloat, ), h )

setRowHeight( s::Taro.Sheet, r::Integer, h::Real ) =
    setRowHeight( createRow( s, r ), h )

# This function merges the cells in the given range. As always, the cell in
#   row 1, column 1 corresponds to cell "A1".
mergeCells( s::Taro.Sheet, firstCol::Integer, firstRow::Integer,
    lastCol::Integer, lastRow::Integer ) =
    jcall( s, "addMergedRegion", jint, ( CellRangeAddress, ),
        CellRangeAddress( firstCol, firstRow, lastCol, lastRow,  ) )
mergeCells( s::Taro.Sheet, firstCol::AbstractString, firstRow::Integer,
    lastCol::AbstractString, lastRow::Integer ) =
    mergeCells( s, colnum( firstCol ), firstRow, colnum( lastCol ), lastRow )

# This function sets the style of the given cell. As before, the cell in row 1,
#   column 1 corresponds to cell "A1" of the sheet.
setCellStyle( c::Taro.Cell, style::Taro.CellStyle ) =
    jcall( c, "setCellStyle", Void, ( Taro.CellStyle, ), style )
setCellStyle( s::Taro.Sheet, c::ColIndex, r::Integer,
    style::Taro.CellStyle ) =
    setCellStyle( createCell( s, c, r ), style )

# Sets the desired border of the given style.
# XXX Directly passing the border as argument doesn't work since the function
#   jcall cannot properly handle an enum type as argument to pass to the Java
#   function.
function setBorder( style::Taro.CellStyle, border::BorderStyle,
    location::AbstractString )

    tmpLoc = titlecase( location )

    if !in( tmpLoc, [ "Top", "Bottom", "Left", "Right" ] )
        return
    end  # if !in( tmpLoc, [ "top", "bottom", "left", "right" ] )

    borderIndex = jcall( border, "ordinal", jint, (), )
    jcall( style, "setBorder" * tmpLoc, Void, ( jshort, ), borderIndex )
end  # setBorder( style, border, location )

function setBorder( style::Taro.CellStyle, border::AbstractString,
    location::AbstractString )

    tmpBorder = valueOf( BorderStyle, border )
    setBorder( style, tmpBorder, location )
end  # setBorder( style, border, location )

# These functions set the desired border of the given style.
setBorderBottom( style::Taro.CellStyle,
    border::Union{BorderStyle, AbstractString} ) =
    setBorder( style, border, "bottom" )
setBorderTop( style::Taro.CellStyle,
    border::Union{BorderStyle, AbstractString} ) =
    setBorder( style, border, "top" )
setBorderLeft( style::Taro.CellStyle,
    border::Union{BorderStyle, AbstractString} ) =
    setBorder( style, border, "left" )
setBorderRight( style::Taro.CellStyle,
    border::Union{BorderStyle, AbstractString} ) =
    setBorder( style, border, "right" )

# This function sets all the borders of the given style.
function setBorders( style::Taro.CellStyle,
    border::Union{BorderStyle, AbstractString} )

    for loc in [ "bottom", "top", "left", "right" ]
        setBorder( style, border, loc )
    end  # for loc in [ "bottom", "top", "left", "right" ]
end  # setBorders( style, border )

end  # module ExcelWrapper
