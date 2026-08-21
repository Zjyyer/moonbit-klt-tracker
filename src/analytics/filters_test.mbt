///|
test "report filters preserve order and calculate aggregate rates" {
  let rows : Array[TrajectoryReportRow] = [
    {
      id: 1,
      first_frame: 0,
      last_frame: 2,
      observation_count: 3,
      displacement: 2.0,
      path_length: 2.0,
      mean_speed: 1.0,
      peak_speed: 1.0,
      quality_score: 0.9,
      anomaly: Normal,
    },
    {
      id: 2,
      first_frame: 0,
      last_frame: 2,
      observation_count: 1,
      displacement: 4.0,
      path_length: 4.0,
      mean_speed: 2.0,
      peak_speed: 3.0,
      quality_score: 0.2,
      anomaly: FastMotion,
    },
  ]
  assert_eq(rows_with_minimum_quality(rows, 0.5).length(), 1)
  assert_eq(rows_with_maximum_speed(rows, 1.0).length(), 1)
  assert_eq(sum_displacements(rows), 6.0)
  assert_eq(mean_observations(rows), 2.0)
  assert_eq(anomaly_rate(rows), 0.5)
  assert_true(report_is_usable(rows, 0.2))
}
