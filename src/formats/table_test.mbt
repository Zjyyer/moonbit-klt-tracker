///|
test "table export validates widths and quotes delimiters" {
  let table = Table::new(["id", "label"], [["1", "plain"], ["2", "a,b"]]).unwrap()
  let csv = table.to_delimited(",").unwrap()
  assert_true(csv.contains("\"a,b\""))
  assert_eq(table.column(0), ["1", "2"])
  assert_eq(table_schema(table), "columns: id label; rows=2")
}

///|
test "table rejects duplicate headers, bad widths and malformed delimiters" {
  assert_true(Table::new(["id", "id"], [["1", "2"]]) is Err(DuplicateHeader))
  assert_true(Table::new(["id"], [["1", "2"]]) is Err(RowWidthMismatch))
  let table = Table::new(["id"], [["1"]]).unwrap()
  assert_true(table.to_delimited("") is Err(InvalidDelimiter))
  assert_true(split_delimited("\"unfinished", ",") is Err(InvalidDelimiter))
}
