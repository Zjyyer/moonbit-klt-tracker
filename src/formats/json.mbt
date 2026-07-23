///|
pub fn export_json(document : TrajectoryDocument) -> String {
  let rows = sorted_rows(document)
  let output = StringBuilder()
  output.write_string("{\"schema_version\":\"")
  output.write_string(schema_version())
  output.write_string("\",\"tracks\":[")
  for index in 0..<rows.length() {
    if index > 0 {
      output.write_string(",")
    }
    let row = rows[index]
    output.write_string("{\"id\":")
    output.write_object(row.id)
    output.write_string(",\"frame\":")
    output.write_object(row.frame)
    output.write_string(",\"state\":\"")
    output.write_string(row.state)
    output.write_string("\",\"x\":")
    output.write_string(format_number(row.x))
    output.write_string(",\"y\":")
    output.write_string(format_number(row.y))
    output.write_string("}")
  }
  output.write_string("]}")
  output.to_string()
}
