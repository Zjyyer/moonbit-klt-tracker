///|
test "validation diagnostics classify rejection causes and score confidence" {
  let config = ValidationConfig::new(0.5, 1.0, 1.0).unwrap()
  assert_eq(classify(1.0, 0.1, 0.1, false, config), Ok(None))
  assert_eq(classify(0.1, 0.1, 0.1, false, config), Ok(Some(LowTexture)))
  assert_eq(classify(1.0, 2.0, 0.1, false, config), Ok(Some(HighResidual)))
  assert_eq(
    classify(1.0, 0.1, 2.0, false, config),
    Ok(Some(ForwardBackwardMismatch)),
  )
  let summary = summarize_validations(
    [1.0, 0.1, 1.0],
    [0.1, 0.1, 2.0],
    [0.1, 0.1, 0.1],
    [false, false, false],
    config,
  ).unwrap()
  assert_eq(summary.total, 3)
  assert_eq(summary.accepted, 1)
  assert_true(confidence_score(summary) > 0.2)
}

///|
test "validation diagnostics reject mismatched arrays and non-finite controls" {
  assert_true(ValidationConfig::new(0.0 / 0.0, 1.0, 1.0) is Err(NonFinite))
  let config = ValidationConfig::new(0.5, 1.0, 1.0).unwrap()
  assert_true(
    summarize_validations([1.0], [], [1.0], [false], config)
    is Err(DuplicateFrame),
  )
  assert_true(classify(0.0 / 0.0, 1.0, 1.0, false, config) is Err(NonFinite))
}
