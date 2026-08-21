///|
test "geometry helpers cover segments rectangles and polygons" {
  let segment = Segment2::{ start: { x: 0.0, y: 0.0 }, end: { x: 4.0, y: 0.0 } }
  assert_eq(segment.length(), 4.0)
  assert_eq(segment.project({ x: 2.0, y: 3.0 }).y, 0.0)
  assert_eq(rectangle_area({ x: 0.0, y: 0.0 }, { x: 2.0, y: 3.0 }), 6.0)
  assert_true(
    rectangle_contains({ x: 0.0, y: 0.0 }, { x: 2.0, y: 3.0 }, {
      x: 1.0,
      y: 1.0,
    }),
  )
  assert_eq(
    polygon_area([{ x: 0.0, y: 0.0 }, { x: 2.0, y: 0.0 }, { x: 0.0, y: 2.0 }]),
    2.0,
  )
}
