///|
test "image tiling covers partial right and bottom edges" {
  let list = tiles(5, 4, 3, 3)
  assert_eq(list.length(), 4)
  assert_eq(list[3].width, 2)
  assert_eq(list[3].height, 1)
  assert_eq(tile_for_point(list, 4, 3).unwrap().index, 3)
  let frame = GrayFrame::new(5, 4, [
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19,
  ]).unwrap()
  assert_true(tile_quality(frame, list[0], 0.0))
}
