///|
test "interval operations cover containment intersections and merging" {
  let interval = Interval::new(0.0, 10.0).unwrap()
  assert_true(interval.contains(5.0))
  assert_eq(interval.clamp(20.0), 10.0)
  assert_eq(interval.lerp(0.5), 5.0)
  assert_eq(interval.split(2).length(), 2)
  assert_true(interval.intersect(Interval::new(5.0, 15.0).unwrap()) is Some(_))
  assert_eq(
    merge_intervals([
      Interval::new(0.0, 2.0).unwrap(),
      Interval::new(1.0, 3.0).unwrap(),
    ]).length(),
    1,
  )
}
