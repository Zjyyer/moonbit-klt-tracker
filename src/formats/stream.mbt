///|
/// Framing helpers for newline-delimited trajectory records.
pub(all) struct StreamCursor {
  offset : Int
  line : Int
  column : Int
} derive(Debug, Eq)

///|
pub fn StreamCursor::new() -> StreamCursor {
  { offset: 0, line: 1, column: 1 }
}

///|
pub fn StreamCursor::advance(
  self : StreamCursor,
  character : Char,
) -> StreamCursor {
  if character == '\n' {
    { offset: self.offset + 1, line: self.line + 1, column: 1 }
  } else {
    { offset: self.offset + 1, line: self.line, column: self.column + 1 }
  }
}

///|
pub(all) enum StreamError {
  EmptyRecord
  MissingNewline
  InvalidHeader
  InvalidLine
  TrailingData
} derive(Debug, Eq)

///|
pub(all) struct StreamRecord {
  line : Int
  payload : String
} derive(Debug, Eq)

///|
pub fn split_records(text : String) -> Result[Array[StreamRecord], StreamError] {
  if text.length() == 0 {
    return Err(EmptyRecord)
  }
  let records : Array[StreamRecord] = []
  let mut line = 1
  let mut current = ""
  for character in text {
    if character == '\n' {
      if current.length() == 0 {
        return Err(EmptyRecord)
      }
      records.push({ line, payload: current })
      current = ""
      line += 1
    } else {
      current += character.to_string()
    }
  }
  if current.length() > 0 {
    return Err(MissingNewline)
  }
  Ok(records)
}

///|
pub fn stream_header(
  records : Array[StreamRecord],
) -> Result[StreamRecord, StreamError] {
  if records.length() == 0 {
    return Err(EmptyRecord)
  }
  let first = records[0]
  if !first.payload.has_prefix("schema_version") {
    Err(InvalidHeader)
  } else {
    Ok(first)
  }
}

///|
pub fn normalize_newlines(text : String) -> String {
  let mut output = ""
  let mut previous_was_cr = false
  for character in text {
    if character == '\r' {
      previous_was_cr = true
    } else {
      if character == '\n' && previous_was_cr {
        output += "\n"
      } else {
        if previous_was_cr {
          output += "\n"
        }
        output += character.to_string()
      }
      previous_was_cr = false
    }
  }
  if previous_was_cr {
    output += "\n"
  }
  output
}

///|
pub fn ensure_trailing_newline(text : String) -> String {
  if text.has_suffix("\n") {
    text
  } else {
    text + "\n"
  }
}

///|
pub fn record_count(text : String) -> Int {
  match split_records(ensure_trailing_newline(text)) {
    Ok(records) => records.length()
    Err(_) => 0
  }
}

///|
pub fn record_payloads(records : Array[StreamRecord]) -> Array[String] {
  let result : Array[String] = []
  for record in records {
    result.push(record.payload)
  }
  result
}

///|
pub fn records_are_monotonic(records : Array[StreamRecord]) -> Bool {
  for index in 1..<records.length() {
    if records[index].line <= records[index - 1].line {
      return false
    }
  }
  true
}
