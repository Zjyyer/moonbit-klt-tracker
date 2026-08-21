///|
test "grid analysis returns deterministic cell quality summaries" {
  let frame = GrayFrame::new(4, 4, [
    0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150,
  ]).unwrap()
  let cells = analyze_grid(frame, 2, 2, 0.0)
  assert_eq(cells.length(), 4)
  assert_eq(usable_cells(cells).length(), 4)
  assert_eq(cells_to_points(cells).length(), 4)
  assert_true(best_cell(cells) is Some(_))
}
