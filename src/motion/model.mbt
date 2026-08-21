///|
/// A correspondence between a source point and its measured target point.
pub(all) struct Correspondence {
  source : @math.Vec2
  target : @math.Vec2
} derive(Debug)

///|
/// Creates a point correspondence.
pub fn Correspondence::new(
  source : @math.Vec2,
  target : @math.Vec2,
) -> Correspondence {
  { source, target }
}

///|
/// Errors shared by geometric fitting and transformation.
pub(all) enum MotionError {
  InsufficientSamples
  NonFiniteInput
  NonFiniteResult
  DegenerateGeometry
  SingularSystem
  AtInfinity
  InvalidConfiguration
} derive(Debug, Eq)

///|
/// Controls deterministic robust fitting.
pub(all) struct FitConfig {
  minimum_inliers : Int
  threshold : Double
  iterations : Int
} derive(Debug)

///|
/// Default fitting controls for pixel-space trajectories.
pub fn FitConfig::default() -> FitConfig {
  { minimum_inliers: 3, threshold: 1.0, iterations: 32 }
}

///|
/// Returns a validated fitting configuration.
pub fn FitConfig::new(
  minimum_inliers : Int,
  threshold : Double,
  iterations : Int,
) -> Result[FitConfig, MotionError] {
  if minimum_inliers < 1 ||
    threshold <= 0.0 ||
    !finite(threshold) ||
    iterations < 1 {
    Err(InvalidConfiguration)
  } else {
    Ok({ minimum_inliers, threshold, iterations })
  }
}

///|
/// A constant displacement model.
pub(all) struct Translation {
  displacement : @math.Vec2
} derive(Debug)

///|
/// Creates a translation model.
pub fn Translation::new(displacement : @math.Vec2) -> Translation {
  { displacement, }
}

///|
/// Applies the displacement to a point.
pub fn Translation::transform(
  self : Translation,
  point : @math.Vec2,
) -> @math.Vec2 {
  point.add(self.displacement)
}

///|
/// Returns Euclidean residual for one correspondence.
pub fn Translation::residual(
  self : Translation,
  source : @math.Vec2,
  target : @math.Vec2,
) -> Double {
  distance(self.transform(source), target)
}

///|
/// A six-parameter affine point transform.
pub(all) struct Affine {
  xx : Double
  xy : Double
  tx : Double
  yx : Double
  yy : Double
  ty : Double
} derive(Debug)

///|
/// Creates an affine model using row-major linear terms and translation.
pub fn Affine::new(
  xx : Double,
  xy : Double,
  tx : Double,
  yx : Double,
  yy : Double,
  ty : Double,
) -> Affine {
  { xx, xy, tx, yx, yy, ty }
}

///|
/// Applies an affine transform.
pub fn Affine::transform(self : Affine, point : @math.Vec2) -> @math.Vec2 {
  {
    x: self.xx * point.x + self.xy * point.y + self.tx,
    y: self.yx * point.x + self.yy * point.y + self.ty,
  }
}

///|
/// Returns Euclidean residual for an affine correspondence.
pub fn Affine::residual(
  self : Affine,
  source : @math.Vec2,
  target : @math.Vec2,
) -> Double {
  distance(self.transform(source), target)
}

///|
/// A homogeneous three-by-three projective transform.
pub(all) struct Projective {
  values : Array[Double]
} derive(Debug)

///|
/// Creates a projective model. Exactly nine finite coefficients are required.
pub fn Projective::new(values : Array[Double]) -> Projective {
  { values: values.copy() }
}

///|
/// Applies a projective transform, rejecting a point whose homogeneous scale is zero.
pub fn Projective::transform(
  self : Projective,
  point : @math.Vec2,
) -> Result[@math.Vec2, MotionError] {
  if self.values.length() != 9 {
    return Err(DegenerateGeometry)
  }
  let denominator = self.values[6] * point.x +
    self.values[7] * point.y +
    self.values[8]
  if !finite(denominator) || abs(denominator) <= 0.000000000001 {
    return Err(AtInfinity)
  }
  let x = (self.values[0] * point.x + self.values[1] * point.y + self.values[2]) /
    denominator
  let y = (self.values[3] * point.x + self.values[4] * point.y + self.values[5]) /
    denominator
  if finite(x) && finite(y) {
    Ok({ x, y })
  } else {
    Err(NonFiniteResult)
  }
}

///|
/// Returns the Euclidean residual of a projective correspondence.
pub fn Projective::residual(
  self : Projective,
  source : @math.Vec2,
  target : @math.Vec2,
) -> Result[Double, MotionError] {
  match self.transform(source) {
    Ok(value) => Ok(distance(value, target))
    Err(error) => Err(error)
  }
}

///|
/// A model that can be used by generic trajectory consumers.
pub(all) enum MotionModel {
  TranslationModel(Translation)
  AffineModel(Affine)
  ProjectiveModel(Projective)
} derive(Debug)

///|
/// Applies any supported model.
pub fn MotionModel::transform(
  self : MotionModel,
  point : @math.Vec2,
) -> Result[@math.Vec2, MotionError] {
  match self {
    TranslationModel(value) => Ok(value.transform(point))
    AffineModel(value) => Ok(value.transform(point))
    ProjectiveModel(value) => value.transform(point)
  }
}

///|
/// Counts and summarizes residuals for a model.
pub(all) struct ResidualSummary {
  count : Int
  inlier_count : Int
  rejected_count : Int
  mean : Double
  maximum : Double
  rms : Double
} derive(Debug)

///|
/// A model plus its deterministic consensus score.
pub(all) struct ConsensusTranslation {
  model : Translation
  inlier_count : Int
  residual : ResidualSummary
} derive(Debug)

///|
/// Returns true for ordinary finite floating point values.
pub fn finite(value : Double) -> Bool {
  !value.is_nan() && !value.is_inf()
}

///|
/// Absolute value helper kept local for predictable cross-target behavior.
pub fn abs(value : Double) -> Double {
  if value < 0.0 {
    -value
  } else {
    value
  }
}

///|
/// Euclidean distance between two points.
pub fn distance(left : @math.Vec2, right : @math.Vec2) -> Double {
  let dx = left.x - right.x
  let dy = left.y - right.y
  let squared = dx * dx + dy * dy
  if !finite(squared) {
    0.0 / 0.0
  } else {
    squared.sqrt()
  }
}

///|
/// Returns the signed cross product of two vectors.
pub fn cross(left : @math.Vec2, right : @math.Vec2) -> Double {
  left.x * right.y - left.y * right.x
}

///|
/// Returns the dot product of two vectors.
pub fn dot(left : @math.Vec2, right : @math.Vec2) -> Double {
  left.x * right.x + left.y * right.y
}

///|
/// Returns the axis-aligned bounding box of finite points.
pub(all) struct Bounds {
  minimum : @math.Vec2
  maximum : @math.Vec2
} derive(Debug)

///|
/// Computes finite bounds, rejecting an empty or invalid set.
pub fn bounds(points : Array[@math.Vec2]) -> Result[Bounds, MotionError] {
  if points.length() == 0 {
    return Err(InsufficientSamples)
  }
  let first = points[0]
  if !finite(first.x) || !finite(first.y) {
    return Err(NonFiniteInput)
  }
  let mut min_x = first.x
  let mut min_y = first.y
  let mut max_x = first.x
  let mut max_y = first.y
  for point in points[1:] {
    if !finite(point.x) || !finite(point.y) {
      return Err(NonFiniteInput)
    }
    if point.x < min_x {
      min_x = point.x
    }
    if point.y < min_y {
      min_y = point.y
    }
    if point.x > max_x {
      max_x = point.x
    }
    if point.y > max_y {
      max_y = point.y
    }
  }
  Ok({ minimum: { x: min_x, y: min_y }, maximum: { x: max_x, y: max_y } })
}
