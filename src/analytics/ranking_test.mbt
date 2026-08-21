///|
fn report_test_row(
  id : Int,
  quality : Double,
  displacement : Double,
) -> TrajectoryReportRow {
  {
    id,
    first_frame: 0,
    last_frame: 1,
    observation_count: 2,
    displacement,
    path_length: displacement,
    mean_speed: displacement,
    peak_speed: displacement,
    quality_score: quality,
    anomaly: Normal,
  }
}

///|
test "report ranking is stable and supports top rows and percentiles" {
  let rows = [
    report_test_row(2, 0.5, 4.0),
    report_test_row(1, 0.9, 2.0),
    report_test_row(3, 0.9, 1.0),
  ]
  let ranked = rank_rows(rows, Quality, Descending)
  assert_eq(ranked[0].id, 1)
  assert_eq(ranked[1].id, 3)
  assert_eq(top_rows(rows, Displacement, 2).length(), 2)
  assert_eq(rank_percentile(rows, 1), Some(1.0 / 3.0))
  assert_eq(stable_unique_ids([rows[0], rows[0], rows[1]]), [1, 2])
}
