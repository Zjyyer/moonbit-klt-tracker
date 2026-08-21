///|
test "tracking timeline sorts reports and summarizes decisions" {
  let timeline = build_timeline([])
  assert_eq(peak_active(timeline), 0)
  assert_eq(total_decisions(timeline), 0)
  assert_eq(timeline_quality(timeline), 0.0)
}
