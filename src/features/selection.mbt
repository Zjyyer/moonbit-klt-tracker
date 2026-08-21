///|
/// Deterministic seed selection policy used before tracking starts.
pub(all) struct SelectionConfig {
  maximum_features : Int
  minimum_distance : Double
  minimum_score : Double
} derive(Debug)

///|
pub(all) enum SelectionError {
  InvalidMaximum
  InvalidDistance
  InvalidScore
  NonFiniteScore
} derive(Debug, Eq)

///|
pub fn SelectionConfig::new(
  maximum_features : Int,
  minimum_distance : Double,
  minimum_score : Double,
) -> Result[SelectionConfig, SelectionError] {
  if maximum_features < 1 {
    return Err(InvalidMaximum)
  }
  if minimum_distance < 0.0 || !finite(minimum_distance) {
    return Err(InvalidDistance)
  }
  if !finite(minimum_score) {
    return Err(InvalidScore)
  }
  Ok({ maximum_features, minimum_distance, minimum_score })
}

///|
/// Sorts by descending score, then coordinates, and applies greedy spacing.
pub fn select_seeds(
  seeds : Array[SeedPoint],
  config : SelectionConfig,
) -> Result[Array[SeedPoint], SelectionError] {
  let candidates : Array[SeedPoint] = []
  for seed in seeds {
    if !finite(seed.position.x) ||
      !finite(seed.position.y) ||
      !finite(seed.score) {
      return Err(NonFiniteScore)
    }
    if seed.score >= config.minimum_score {
      candidates.push(seed)
    }
  }
  candidates.sort_by(seed_order)
  let selected : Array[SeedPoint] = []
  for candidate in candidates {
    if selected.length() >= config.maximum_features {
      break
    }
    let mut separated = true
    for existing in selected {
      if distance(candidate.position, existing.position) <
        config.minimum_distance {
        separated = false
        break
      }
    }
    if separated {
      selected.push(candidate)
    }
  }
  Ok(selected)
}

///|
fn seed_order(left : SeedPoint, right : SeedPoint) -> Int {
  if left.score != right.score {
    if left.score > right.score {
      -1
    } else {
      1
    }
  } else if left.position.y != right.position.y {
    left.position.y.compare(right.position.y)
  } else {
    left.position.x.compare(right.position.x)
  }
}

///|
fn distance(left : @math.Vec2, right : @math.Vec2) -> Double {
  let dx = left.x - right.x
  let dy = left.y - right.y
  (dx * dx + dy * dy).sqrt()
}

///|
fn finite(value : Double) -> Bool {
  !value.is_nan() && !value.is_inf()
}
