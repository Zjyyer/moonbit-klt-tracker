///|
test "matrix supports transpose multiply and norms" {
  let matrix = Matrix::new(2, 2, [1.0, 2.0, 3.0, 4.0]).unwrap()
  assert_eq(matrix.transpose().at(0, 1), Ok(3.0))
  let product = matrix.multiply(matrix).unwrap()
  assert_eq(product.at(0, 0), Ok(7.0))
  assert_true(abs(matrix.frobenius_norm() - 5.477225575) < 0.000000001)
}

///|
test "matrix solves a pivoted system and rejects singular input" {
  let matrix = Matrix::new(2, 2, [0.0, 2.0, 1.0, 1.0]).unwrap()
  let result = matrix.solve([4.0, 3.0]).unwrap()
  assert_eq(result, [1.0, 2.0])
  let singular = Matrix::new(2, 2, [1.0, 2.0, 2.0, 4.0]).unwrap()
  assert_true(singular.solve([1.0, 2.0]) is Err(Singular))
}

///|
test "matrix validates shape indices and finite values" {
  assert_true(Matrix::new(2, 2, [1.0]) is Err(LengthMismatch))
  let matrix = Matrix::zeros(2, 2).unwrap()
  assert_true(matrix.at(2, 0) is Err(IndexOutOfBounds))
  assert_true(matrix.set(0, 0, 0.0 / 0.0) is Err(NonFiniteInput))
  assert_true(Matrix::identity(0) is Err(InvalidShape))
}

///|
fn abs(value : Double) -> Double {
  if value < 0.0 {
    -value
  } else {
    value
  }
}
