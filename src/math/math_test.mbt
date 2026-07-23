///|
test "Vec2 adds and scales Double coordinates" {
  let first : Vec2 = { x: 1.5, y: -2.0 }
  let second : Vec2 = { x: 2.5, y: 3.0 }
  let sum = first.add(second)
  assert_eq(sum.x, 4.0)
  assert_eq(sum.y, 1.0)
  let scaled = sum.scale(0.5)
  assert_eq(scaled.x, 2.0)
  assert_eq(scaled.y, 0.5)
}

///|
test "solve_symmetric_2x2 solves a well-conditioned system" {
  let rhs : Vec2 = { x: 9.0, y: 8.0 }
  match solve_symmetric_2x2(4.0, 1.0, 3.0, rhs) {
    Ok(solution) => {
      assert_eq(solution.x, 19.0 / 11.0)
      assert_eq(solution.y, 23.0 / 11.0)
    }
    Err(_) => fail("expected a solution")
  }
}

///|
test "solve_symmetric_2x2 rejects singular and near-singular matrices" {
  let rhs : Vec2 = { x: 1.0, y: 1.0 }
  assert_true(solve_symmetric_2x2(1.0, 1.0, 1.0, rhs) is Err(_))
  assert_true(
    solve_symmetric_2x2(1.0, 1.0, 1.0 + 0.000000000001, rhs) is Err(_),
  )
}

///|
test "solve_symmetric_2x2 rejects non-finite coefficients and right-hand sides" {
  let finite_rhs : Vec2 = { x: 1.0, y: 1.0 }
  let non_finite_rhs : Vec2 = { x: 0.0 / 0.0, y: 1.0 }
  assert_true(
    solve_symmetric_2x2(1.0 / 0.0, 0.0, 1.0, finite_rhs) is Err(NonFiniteInput),
  )
  assert_true(
    solve_symmetric_2x2(1.0, 0.0, 1.0, non_finite_rhs) is Err(NonFiniteInput),
  )
}

///|
test "solve_symmetric_2x2 rejects non-finite intermediate computations" {
  let unit_rhs : Vec2 = { x: 1.0, y: 1.0 }
  let large_y_rhs : Vec2 = { x: 0.0, y: 1.0e308 }
  assert_true(
    solve_symmetric_2x2(1.0e308, 0.0, 1.0e308, unit_rhs) is Err(NonFiniteResult),
  )
  assert_true(
    solve_symmetric_2x2(1.0e308, 0.0, 1.0e-308, large_y_rhs)
    is Err(NonFiniteResult),
  )
}
