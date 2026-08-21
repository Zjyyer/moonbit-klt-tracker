///|
/// Feature-score normalization and spatial density utilities.
pub(all) struct ScoreSummary {
  count : Int
  minimum : Double
  maximum : Double
  mean : Double
  median : Double
  density : Double
} derive(Debug)

///|
pub(all) enum ScoreError {
  Empty
  NonFinite
  InvalidRadius
} derive(Debug, Eq)

///|
pub fn score_summary(
  seeds : Array[SeedPoint],
  width : Int,
  height : Int,
) -> Result[ScoreSummary, ScoreError] {
  if seeds.length() == 0 {
    return Err(Empty)
  }
  let mut minimum = seeds[0].score
  let mut maximum = seeds[0].score
  let mut mean = 0.0
  for seed in seeds {
    if !finite(seed.score) ||
      !finite(seed.position.x) ||
      !finite(seed.position.y) {
      return Err(NonFinite)
    }
    minimum = minimum.min(seed.score)
    maximum = maximum.max(seed.score)
    mean += seed.score
  }
  let ordered : Array[Double] = []
  for seed in seeds {
    ordered.push(seed.score)
  }
  ordered.sort_by(fn(left, right) { left.compare(right) })
  let middle = ordered.length() / 2
  let median = if ordered.length() % 2 == 1 {
    ordered[middle]
  } else {
    (ordered[middle - 1] + ordered[middle]) / 2.0
  }
  Ok({
    count: seeds.length(),
    minimum,
    maximum,
    mean: mean / seeds.length().to_double(),
    median,
    density: if width <= 0 || height <= 0 {
      0.0
    } else {
      seeds.length().to_double() / (width * height).to_double()
    },
  })
}

///|
pub fn score_percentile(
  seeds : Array[SeedPoint],
  score : Double,
) -> Result[Double, ScoreError] {
  if seeds.length() == 0 {
    return Err(Empty)
  }
  if !finite(score) {
    return Err(NonFinite)
  }
  let mut count = 0
  for seed in seeds {
    if !finite(seed.score) {
      return Err(NonFinite)
    }
    if seed.score <= score {
      count += 1
    }
  }
  Ok(count.to_double() / seeds.length().to_double())
}

///|
pub fn suppress_by_radius(
  seeds : Array[SeedPoint],
  radius : Double,
) -> Result[Array[SeedPoint], ScoreError] {
  if radius < 0.0 || !finite(radius) {
    return Err(InvalidRadius)
  }
  let ordered = seeds.copy()
  ordered.sort_by(fn(left, right) {
    if left.score != right.score {
      right.score.compare(left.score)
    } else {
      left.position.x.compare(right.position.x)
    }
  })
  let result : Array[SeedPoint] = []
  for seed in ordered {
    let mut keep = true
    for selected in result {
      if distance(seed.position, selected.position) < radius {
        keep = false
        break
      }
    }
    if keep {
      result.push(seed)
    }
  }
  Ok(result)
}

///|
pub fn grid_occupancy(
  seeds : Array[SeedPoint],
  cell_size : Double,
) -> Result[Int, ScoreError] {
  if cell_size <= 0.0 || !finite(cell_size) {
    return Err(InvalidRadius)
  }
  let occupied : Array[Int] = []
  for seed in seeds {
    if !finite(seed.position.x) || !finite(seed.position.y) {
      return Err(NonFinite)
    }
    let x_cell = (seed.position.x / cell_size).floor().to_int()
    let y_cell = (seed.position.y / cell_size).floor().to_int()
    let key = x_cell * 1000003 + y_cell
    let mut known = false
    for item in occupied {
      if item == key {
        known = true
        break
      }
    }
    if !known {
      occupied.push(key)
    }
  }
  Ok(occupied.length())
}
