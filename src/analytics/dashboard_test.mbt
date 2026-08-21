///|
test "dashboard is explicit for empty reports" {
  let value = dashboard([])
  assert_eq(value.track_count, 0)
  assert_eq(value.best_track_id, None)
  assert_eq(dashboard_label(value), "empty")
}
