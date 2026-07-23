///|
fn csv_field(value : String) -> String {
  let must_quote = value.contains(",") || value.contains("\"") || value.contains("\n")
  if !must_quote {
    value
  } else {
    "\"" + value.replace_all(old="\"", new="\"\"") + "\""
  }
}

///|
pub fn export_csv(document : TrajectoryDocument) -> String {
  let rows = sorted_rows(document)
  let output = StringBuilder()
  output.write_string("schema_version,track_id,frame,state,x,y\n")
  for row in rows {
    output.write_string(csv_field(schema_version()))
    output.write_string(",")
    output.write_object(row.id)
    output.write_string(",")
    output.write_object(row.frame)
    output.write_string(",")
    output.write_string(csv_field(row.state))
    output.write_string(",")
    output.write_string(csv_field(format_number(row.x)))
    output.write_string(",")
    output.write_string(csv_field(format_number(row.y)))
    output.write_string("\n")
  }
  output.to_string()
}
