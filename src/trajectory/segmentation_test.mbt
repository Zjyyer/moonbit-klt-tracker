///|
test "trajectory segmentation splits gaps and merges compatible segments" {
  let trajectory = Trajectory::new(4, [
    { frame: 0, position: { x: 0.0, y: 0.0 }, confidence: 1.0, state: Accepted },
    { frame: 1, position: { x: 1.0, y: 0.0 }, confidence: 1.0, state: Accepted },
    { frame: 4, position: { x: 4.0, y: 0.0 }, confidence: 1.0, state: Accepted },
    { frame: 5, position: { x: 5.0, y: 0.0 }, confidence: 1.0, state: Accepted },
  ]).unwrap()
  let config = SegmentationConfig::new(1, 2, 2.0).unwrap()
  let segments = trajectory.segment(config)
  assert_eq(segments.length(), 2)
  assert_eq(merge_segments(segments).unwrap().points.length(), 4)
  assert_eq(overlap(trajectory, trajectory), 1.0)
}
