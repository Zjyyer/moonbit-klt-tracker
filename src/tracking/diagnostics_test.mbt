///|
test "empty tracking summaries are finite and deterministic" {
  let summary = summarize_tracks([])
  assert_eq(summary.total_tracks, 0)
  assert_eq(summary.mean_confidence, 0.0)
  assert_eq(rank_tracks([]).length(), 0)
}
