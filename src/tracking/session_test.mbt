///|
test "empty tracking sessions have explicit labels and zero coverage" {
  let summary = session_summary([])
  assert_eq(session_label(summary), "empty")
  assert_eq(session_coverage(summary), 0.0)
}
