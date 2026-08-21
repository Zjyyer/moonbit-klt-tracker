///|
test "feature score tools summarize and suppress spatial candidates" {
  let seeds : Array[SeedPoint] = [
    { position: { x: 0.0, y: 0.0 }, score: 0.5 },
    { position: { x: 0.1, y: 0.0 }, score: 0.9 },
    { position: { x: 4.0, y: 0.0 }, score: 0.7 },
  ]
  let summary = score_summary(seeds, 10, 10).unwrap()
  assert_eq(summary.count, 3)
  assert_eq(summary.maximum, 0.9)
  assert_eq(suppress_by_radius(seeds, 1.0).unwrap().length(), 2)
  assert_eq(grid_occupancy(seeds, 1.0).unwrap(), 2)
  assert_eq(score_percentile(seeds, 0.7), Ok(2.0 / 3.0))
}

///|
test "feature score tools reject empty and invalid controls" {
  assert_true(score_summary([], 10, 10) is Err(Empty))
  assert_true(suppress_by_radius([], -1.0) is Err(InvalidRadius))
  assert_true(grid_occupancy([], 0.0) is Err(InvalidRadius))
  assert_true(
    score_percentile([{ position: { x: 0.0, y: 0.0 }, score: 0.0 / 0.0 }], 0.0)
    is Err(NonFinite),
  )
}
