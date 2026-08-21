///|
test "bright region extraction finds separated components" {
  let frame = GrayFrame::new(4, 2, [255, 0, 0, 255, 255, 0, 0, 255]).unwrap()
  let regions = bright_regions(frame, 200.0)
  assert_eq(regions.length(), 2)
  assert_eq(regions[0].area, 2)
  assert_eq(region_density(regions, 4, 2), 0.5)
}
