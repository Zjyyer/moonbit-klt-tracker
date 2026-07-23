///|
/// The matrix could not be safely inverted.
pub(all) enum SolveError {
  Singular
} derive(Debug, Eq)

///|
/// Determinants at or below this magnitude are treated as singular.
const SOLVE_DETERMINANT_EPSILON : Double = 0.0000000001

///|
/// Solves `[a b; b c] * x = rhs` when the symmetric matrix is well-conditioned.
pub fn solve_symmetric_2x2(
  a : Double,
  b : Double,
  c : Double,
  rhs : Vec2,
) -> Result[Vec2, SolveError] {
  let determinant = a * c - b * b
  if determinant.abs() <= SOLVE_DETERMINANT_EPSILON {
    Err(Singular)
  } else {
    Ok({
      x: (c * rhs.x - b * rhs.y) / determinant,
      y: (a * rhs.y - b * rhs.x) / determinant,
    })
  }
}
