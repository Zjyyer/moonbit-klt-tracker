///|
test "stream framing tracks lines and enforces a terminal newline" {
  let records = split_records("schema_version,1\ntrack,1\n").unwrap()
  assert_eq(records.length(), 2)
  assert_eq(records[1].line, 2)
  assert_true(stream_header(records) is Ok(_))
  assert_true(split_records("missing-newline") is Err(MissingNewline))
  assert_eq(ensure_trailing_newline("a"), "a\n")
  assert_eq(normalize_newlines("a\r\nb\r\n"), "a\nb\n")
}
