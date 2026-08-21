///|
/// A row-major dense matrix for small deterministic vision problems.
pub(all) struct Matrix {
  rows : Int
  columns : Int
  values : Array[Double]
} derive(Debug)

///|
pub(all) enum MatrixError {
  InvalidShape
  LengthMismatch
  IndexOutOfBounds
  NonFiniteInput
  Singular
  NonFiniteResult
} derive(Debug, Eq)

///|
pub fn Matrix::new(
  rows : Int,
  columns : Int,
  values : Array[Double],
) -> Result[Matrix, MatrixError] {
  if rows <= 0 || columns <= 0 {
    return Err(InvalidShape)
  }
  if rows > 2147483647 / columns || values.length() != rows * columns {
    return Err(LengthMismatch)
  }
  for value in values {
    if !finite(value) {
      return Err(NonFiniteInput)
    }
  }
  Ok({ rows, columns, values: values.copy() })
}

///|
pub fn Matrix::zeros(rows : Int, columns : Int) -> Result[Matrix, MatrixError] {
  if rows <= 0 || columns <= 0 {
    return Err(InvalidShape)
  }
  let values : Array[Double] = []
  for _ in 0..<(rows * columns) {
    values.push(0.0)
  }
  Ok({ rows, columns, values })
}

///|
pub fn Matrix::identity(size : Int) -> Result[Matrix, MatrixError] {
  match Matrix::zeros(size, size) {
    Err(error) => Err(error)
    Ok(matrix) => {
      for index in 0..<size {
        matrix.values[index * size + index] = 1.0
      }
      Ok(matrix)
    }
  }
}

///|
pub fn Matrix::at(
  self : Matrix,
  row : Int,
  column : Int,
) -> Result[Double, MatrixError] {
  if row < 0 || column < 0 || row >= self.rows || column >= self.columns {
    Err(IndexOutOfBounds)
  } else {
    Ok(self.values[row * self.columns + column])
  }
}

///|
pub fn Matrix::set(
  self : Matrix,
  row : Int,
  column : Int,
  value : Double,
) -> Result[Unit, MatrixError] {
  if row < 0 || column < 0 || row >= self.rows || column >= self.columns {
    Err(IndexOutOfBounds)
  } else if !finite(value) {
    Err(NonFiniteInput)
  } else {
    self.values[row * self.columns + column] = value
    Ok(())
  }
}

///|
pub fn Matrix::transpose(self : Matrix) -> Matrix {
  let values : Array[Double] = []
  for column in 0..<self.columns {
    for row in 0..<self.rows {
      values.push(self.values[row * self.columns + column])
    }
  }
  { rows: self.columns, columns: self.rows, values }
}

///|
pub fn Matrix::add(
  self : Matrix,
  other : Matrix,
) -> Result[Matrix, MatrixError] {
  if self.rows != other.rows || self.columns != other.columns {
    return Err(LengthMismatch)
  }
  let values : Array[Double] = []
  for index in 0..<self.values.length() {
    values.push(self.values[index] + other.values[index])
  }
  Matrix::new(self.rows, self.columns, values)
}

///|
pub fn Matrix::scale(
  self : Matrix,
  factor : Double,
) -> Result[Matrix, MatrixError] {
  if !finite(factor) {
    return Err(NonFiniteInput)
  }
  let values : Array[Double] = []
  for value in self.values {
    values.push(value * factor)
  }
  Matrix::new(self.rows, self.columns, values)
}

///|
pub fn Matrix::multiply(
  self : Matrix,
  other : Matrix,
) -> Result[Matrix, MatrixError] {
  if self.columns != other.rows {
    return Err(LengthMismatch)
  }
  let values : Array[Double] = []
  for row in 0..<self.rows {
    for column in 0..<other.columns {
      let mut value = 0.0
      for index in 0..<self.columns {
        value += self.values[row * self.columns + index] *
          other.values[index * other.columns + column]
      }
      if !finite(value) {
        return Err(NonFiniteResult)
      }
      values.push(value)
    }
  }
  Matrix::new(self.rows, other.columns, values)
}

///|
pub fn Matrix::frobenius_norm(self : Matrix) -> Double {
  let mut sum = 0.0
  for value in self.values {
    sum += value * value
  }
  sum.sqrt()
}

///|
pub fn Matrix::solve(
  self : Matrix,
  right : Array[Double],
) -> Result[Array[Double], MatrixError] {
  if self.rows != self.columns || right.length() != self.rows {
    return Err(LengthMismatch)
  }
  let augmented : Array[Array[Double]] = []
  for row in 0..<self.rows {
    let values : Array[Double] = []
    for column in 0..<self.columns {
      values.push(self.values[row * self.columns + column])
    }
    values.push(right[row])
    augmented.push(values)
  }
  for pivot in 0..<self.rows {
    let mut best = pivot
    for candidate in (pivot + 1)..<self.rows {
      if abs(augmented[candidate][pivot]) > abs(augmented[best][pivot]) {
        best = candidate
      }
    }
    if abs(augmented[best][pivot]) <= 0.000000000001 {
      return Err(Singular)
    }
    if best != pivot {
      let row = augmented[pivot]
      augmented[pivot] = augmented[best]
      augmented[best] = row
    }
    let divisor = augmented[pivot][pivot]
    for column in pivot..<(self.columns + 1) {
      augmented[pivot][column] /= divisor
    }
    for row in 0..<self.rows {
      if row != pivot {
        let factor = augmented[row][pivot]
        for column in pivot..<(self.columns + 1) {
          augmented[row][column] -= factor * augmented[pivot][column]
        }
      }
    }
  }
  let result : Array[Double] = []
  for row in augmented {
    if !finite(row[self.columns]) {
      return Err(NonFiniteResult)
    }
    result.push(row[self.columns])
  }
  Ok(result)
}

///|
fn finite(value : Double) -> Bool {
  !value.is_nan() && !value.is_inf()
}

///|
fn abs(value : Double) -> Double {
  if value < 0.0 {
    -value
  } else {
    value
  }
}
