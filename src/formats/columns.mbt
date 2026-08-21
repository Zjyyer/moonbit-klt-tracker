///|
/// Column-oriented helpers for deterministic table construction.
pub fn table_from_columns(
  headers : Array[String],
  columns : Array[Array[String]],
) -> Result[Table, TableError] {
  if headers.length() != columns.length() || headers.length() == 0 {
    return Err(RowWidthMismatch)
  }
  let row_count = columns[0].length()
  for column in columns {
    if column.length() != row_count {
      return Err(RowWidthMismatch)
    }
  }
  let rows : Array[Array[String]] = []
  for row_index in 0..<row_count {
    let row : Array[String] = []
    for column in columns {
      row.push(column[row_index])
    }
    rows.push(row)
  }
  Table::new(headers, rows)
}

///|
pub fn transpose_table(table : Table) -> Table {
  let headers : Array[String] = []
  for index in 0..<table.headers.length() {
    headers.push("row_" + index.to_string())
  }
  let rows : Array[Array[String]] = []
  for index, header in table.headers {
    let row : Array[String] = [header]
    for source in table.rows {
      row.push(source[index])
    }
    rows.push(row)
  }
  { headers: ["column", ..headers], rows }
}

///|
pub fn table_row_count(table : Table) -> Int {
  table.rows.length()
}

///|
pub fn table_column_count(table : Table) -> Int {
  table.headers.length()
}

///|
pub fn table_is_rectangular(table : Table) -> Bool {
  for row in table.rows {
    if row.length() != table.headers.length() {
      return false
    }
  }
  true
}
