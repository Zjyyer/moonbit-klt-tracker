///|
test "seed selection is score ordered, spaced and bounded" {
  let config = SelectionConfig::new(2, 2.0, 0.5).unwrap()
  let selected = select_seeds(
    [
      { position: { x: 0.0, y: 0.0 }, score: 0.7 },
      { position: { x: 0.5, y: 0.0 }, score: 0.9 },
      { position: { x: 4.0, y: 0.0 }, score: 0.8 },
    ],
    config,
  ).unwrap()
  assert_eq(selected.length(), 2)
  assert_eq(selected[0].score, 0.9)
  assert_eq(selected[1].score, 0.8)
}

///|
test "seed selection rejects invalid controls and non-finite scores" {
  assert_true(SelectionConfig::new(0, 1.0, 0.0) is Err(InvalidMaximum))
  assert_true(SelectionConfig::new(1, -1.0, 0.0) is Err(InvalidDistance))
  assert_true(
    select_seeds(
      [{ position: { x: 0.0, y: 0.0 }, score: 0.0 / 0.0 }],
      SelectionConfig::new(1, 1.0, 0.0).unwrap(),
    )
    is Err(NonFiniteScore),
  )
}
