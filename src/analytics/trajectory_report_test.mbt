///|
test "trajectory reports sort rows and classify anomalies" {
  let config = ReportConfig::new(2, 0, 1.0, 0.0).unwrap()
  let first = @trajectory.Trajectory::new(2, [
    {
      frame: 0,
      position: { x: 0.0, y: 0.0 },
      confidence: 1.0,
      state: @trajectory.Accepted,
    },
  ]).unwrap()
  let second = @trajectory.Trajectory::new(1, [
    {
      frame: 0,
      position: { x: 0.0, y: 0.0 },
      confidence: 1.0,
      state: @trajectory.Accepted,
    },
    {
      frame: 1,
      position: { x: 0.5, y: 0.0 },
      confidence: 1.0,
      state: @trajectory.Accepted,
    },
  ]).unwrap()
  let rows = build_report([first, second], config)
  assert_eq(rows[0].id, 1)
  assert_eq(rows[0].anomaly, Normal)
  assert_eq(rows[1].anomaly, ShortObservation)
  assert_eq(anomaly_counts(rows), [1, 1, 0, 0, 0])
  assert_true(report_row_csv(rows[0]).contains("normal"))
}
