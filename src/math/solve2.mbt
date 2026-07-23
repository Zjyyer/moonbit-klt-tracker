///|
/// The matrix could not be safely inverted.
pub(all) enum SolveError {
  Singular
  NonFiniteInput
  NonFiniteResult
} derive(Debug, Eq)

///|
/// Determinants at or below this magnitude are treated as singular.
const SOLVE_DETERMINANT_EPSILON : Double = 0.0000000001

///|
fn is_finite(value : Double) -> Bool {
  !value.is_nan() && !value.is_inf()
}

///|
/// Solves `[a b; b c] * x = rhs` when the symmetric matrix is well-conditioned.
pub fn solve_symmetric_2x2(
  a : Double,
  b : Double,
  c : Double,
  rhs : Vec2,
) -> Result[Vec2, SolveError] {
  if !is_finite(a) ||
    !is_finite(b) ||
    !is_finite(c) ||
    !is_finite(rhs.x) ||
    !is_finite(rhs.y) {
    Err(NonFiniteInput)
  } else {
    let determinant = a * c - b * b
    if !is_finite(determinant) {
      Err(NonFiniteResult)
    } else if determinant.abs() <= SOLVE_DETERMINANT_EPSILON {
      Err(Singular)
    } else {
      let x = (c * rhs.x - b * rhs.y) / determinant
      let y = (a * rhs.y - b * rhs.x) / determinant
      if !is_finite(x) || !is_finite(y) {
        Err(NonFiniteResult)
      } else {
        Ok({ x, y })
      }
    }
  }
}
