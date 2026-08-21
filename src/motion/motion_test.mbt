///|
fn point(x : Double, y : Double) -> @math.Vec2 {
  { x, y }
}

///|
test "translation maps points and reports residual" {
  let model = Translation::new(point(2.0, -3.0))
  let result = model.transform(point(4.0, 5.0))
  assert_eq(result.x, 6.0)
  assert_eq(result.y, 2.0)
  assert_eq(model.residual(point(4.0, 5.0), point(6.0, 2.0)), 0.0)
}

///|
test "affine fitting recovers an exact transform" {
  let model = Affine::new(2.0, 0.0, 4.0, 0.0, 3.0, -2.0)
  let samples = [
    Correspondence::new(point(0.0, 0.0), model.transform(point(0.0, 0.0))),
    Correspondence::new(point(1.0, 0.0), model.transform(point(1.0, 0.0))),
    Correspondence::new(point(0.0, 1.0), model.transform(point(0.0, 1.0))),
    Correspondence::new(point(2.0, 3.0), model.transform(point(2.0, 3.0))),
  ]
  let fitted = fit_affine(samples, FitConfig::default())
  guard fitted is Ok(value) else { fail("exact affine fit rejected") }
  let transformed = value.transform(point(3.0, 2.0))
  assert_true(abs(transformed.x - 10.0) < 0.000000001)
  assert_true(abs(transformed.y - 4.0) < 0.000000001)
}

///|
test "projective transform rejects points at infinity" {
  let model = Projective::new([1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0])
  guard model.transform(point(2.0, 3.0)) is Ok(value) else {
    fail("identity projective transform rejected")
  }
  assert_eq(value.x, 2.0)
  assert_eq(value.y, 3.0)
  let singular = Projective::new([1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0])
  guard singular.transform(point(2.0, 3.0)) is Err(AtInfinity) else {
    fail("point at infinity accepted")
  }
}

///|
test "fit rejects insufficient and non-finite correspondences" {
  let short = fit_affine([], FitConfig::default())
  guard short is Err(InsufficientSamples) else { fail("empty fit accepted") }
  let bad = Correspondence::new(point(0.0, 0.0), point(0.0 / 0.0, 1.0))
  let config = FitConfig::new(1, 1.0, 1).unwrap()
  guard fit_translation([bad], config) is Err(NonFiniteInput) else {
    fail("non-finite sample accepted")
  }
}

///|
test "consensus is deterministic and keeps the best inlier set" {
  let base = Translation::new(point(5.0, 2.0))
  let samples = [
    Correspondence::new(point(0.0, 0.0), base.transform(point(0.0, 0.0))),
    Correspondence::new(point(1.0, 0.0), base.transform(point(1.0, 0.0))),
    Correspondence::new(point(0.0, 1.0), base.transform(point(0.0, 1.0))),
    Correspondence::new(point(2.0, 2.0), point(100.0, 100.0)),
  ]
  let config : FitConfig = {
    minimum_inliers: 3,
    threshold: 0.01,
    iterations: 8,
  }
  guard consensus_translation(samples, config) is Ok(result) else {
    fail("consensus rejected valid inliers")
  }
  assert_eq(result.inlier_count, 3)
  let transformed = result.model.transform(point(3.0, 4.0))
  assert_eq(transformed.x, 8.0)
  assert_eq(transformed.y, 6.0)
}
