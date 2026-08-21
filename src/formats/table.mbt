///|
/// A validated rectangular table for deterministic text export.
pub(all) struct Table {
  headers : Array[String]
  rows : Array[Array[String]]
} derive(Debug)

///|
pub(all) enum TableError {
  EmptyHeader
  DuplicateHeader
  RowWidthMismatch
  EmptyRow
  InvalidDelimiter
} derive(Debug, Eq)

///|
pub fn Table::new(
  headers : Array[String],
  rows : Array[Array[String]],
) -> Result[Table, TableError] {
  if headers.length() == 0 {
    return Err(EmptyHeader)
  }
  for header in headers {
    if header.length() == 0 {
      return Err(EmptyHeader)
    }
  }
  for left_index in 0..<headers.length() {
    for right_index in (left_index + 1)..<headers.length() {
      if headers[left_index] == headers[right_index] {
        return Err(DuplicateHeader)
      }
    }
  }
  for row in rows {
    if row.length() == 0 {
      return Err(EmptyRow)
    }
    if row.length() != headers.length() {
      return Err(RowWidthMismatch)
    }
  }
  Ok({ headers: headers.copy(), rows: rows.copy() })
}

///|
pub fn Table::column(self : Table, index : Int) -> Array[String] {
  let result : Array[String] = []
  if index < 0 || index >= self.headers.length() {
    return result
  }
  for row in self.rows {
    result.push(row[index])
  }
  result
}

///|
pub fn Table::sort_rows(self : Table, column : Int) -> Result[Unit, TableError] {
  if column < 0 || column >= self.headers.length() {
    return Err(RowWidthMismatch)
  }
  self.rows.sort_by(fn(left, right) {
    let comparison = left[column].compare(right[column])
    if comparison != 0 {
      comparison
    } else {
      left[0].compare(right[0])
    }
  })
  Ok(())
}

///|
pub fn Table::to_delimited(
  self : Table,
  delimiter : String,
) -> Result[String, TableError] {
  if delimiter.length() != 1 {
    return Err(InvalidDelimiter)
  }
  let output = StringBuilder()
  write_row(output, self.headers, delimiter)
  for row in self.rows {
    write_row(output, row, delimiter)
  }
  Ok(output.to_string())
}

///|
fn write_row(
  output : StringBuilder,
  row : Array[String],
  delimiter : String,
) -> Unit {
  for index, field in row {
    if index > 0 {
      output.write_string(delimiter)
    }
    output.write_string(escape_field(field, delimiter))
  }
  output.write_string("\n")
}

///|
pub fn escape_field(field : String, delimiter : String) -> String {
  let quoted = field.contains(delimiter) ||
    field.contains("\"") ||
    field.contains("\n") ||
    field.contains("\r")
  if quoted {
    "\"" + field.replace_all(old="\"", new="\"\"") + "\""
  } else {
    field
  }
}

///|
pub fn split_delimited(
  line : String,
  delimiter : String,
) -> Result[Array[String], TableError] {
  if delimiter.length() != 1 {
    return Err(InvalidDelimiter)
  }
  let fields : Array[String] = []
  let mut current = ""
  let mut quoted = false
  let mut escaped_quote = false
  for character in line {
    if character == '"' {
      if quoted && escaped_quote {
        current += "\""
        escaped_quote = false
      } else {
        quoted = !quoted
        escaped_quote = quoted
      }
    } else if character.to_string() == delimiter && !quoted {
      fields.push(current)
      current = ""
    } else {
      current += character.to_string()
      escaped_quote = false
    }
  }
  if quoted {
    return Err(InvalidDelimiter)
  }
  fields.push(current)
  Ok(fields)
}

///|
pub fn table_schema(table : Table) -> String {
  let output = StringBuilder()
  output.write_string("columns:")
  for header in table.headers {
    output.write_string(" ")
    output.write_string(header)
  }
  output.write_string("; rows=")
  output.write_object(table.rows.length())
  output.to_string()
}
