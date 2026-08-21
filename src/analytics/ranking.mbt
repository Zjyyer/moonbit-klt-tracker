///|
/// Ranking direction for deterministic report sorting.
pub(all) enum RankingDirection {
  Ascending
  Descending
} derive(Debug, Eq)

///|
pub(all) enum RankingField {
  Displacement
  PathLength
  MeanSpeed
  PeakSpeed
  Quality
  ObservationCount
} derive(Debug, Eq)

///|
pub fn rank_rows(
  rows : Array[TrajectoryReportRow],
  field : RankingField,
  direction : RankingDirection,
) -> Array[TrajectoryReportRow] {
  let result = rows.copy()
  result.sort_by(fn(left, right) {
    let comparison = compare_rows(left, right, field)
    let oriented = match direction {
      Ascending => comparison
      Descending => -comparison
    }
    if oriented != 0 {
      oriented
    } else {
      left.id.compare(right.id)
    }
  })
  result
}

///|
fn compare_rows(
  left : TrajectoryReportRow,
  right : TrajectoryReportRow,
  field : RankingField,
) -> Int {
  match field {
    Displacement => left.displacement.compare(right.displacement)
    PathLength => left.path_length.compare(right.path_length)
    MeanSpeed => left.mean_speed.compare(right.mean_speed)
    PeakSpeed => left.peak_speed.compare(right.peak_speed)
    Quality => left.quality_score.compare(right.quality_score)
    ObservationCount => left.observation_count.compare(right.observation_count)
  }
}

///|
pub fn top_rows(
  rows : Array[TrajectoryReportRow],
  field : RankingField,
  count : Int,
) -> Array[TrajectoryReportRow] {
  if count <= 0 {
    return []
  }
  let ranked = rank_rows(rows, field, Descending)
  let limit = count.min(ranked.length())
  let result : Array[TrajectoryReportRow] = []
  for index in 0..<limit {
    result.push(ranked[index])
  }
  result
}

///|
pub fn normalize_report_scores(
  rows : Array[TrajectoryReportRow],
) -> Array[Double] {
  if rows.length() == 0 {
    return []
  }
  let mut maximum = rows[0].quality_score
  let mut minimum = rows[0].quality_score
  for row in rows {
    minimum = minimum.min(row.quality_score)
    maximum = maximum.max(row.quality_score)
  }
  let values : Array[Double] = []
  if maximum == minimum {
    for _ in rows {
      values.push(1.0)
    }
  } else {
    for row in rows {
      values.push((row.quality_score - minimum) / (maximum - minimum))
    }
  }
  values
}

///|
pub fn rank_percentile(rows : Array[TrajectoryReportRow], id : Int) -> Double? {
  if rows.length() == 0 {
    return None
  }
  let ranked = rank_rows(rows, Quality, Descending)
  for index, row in ranked {
    if row.id == id {
      return Some((index + 1).to_double() / ranked.length().to_double())
    }
  }
  None
}

///|
pub fn stable_unique_ids(rows : Array[TrajectoryReportRow]) -> Array[Int] {
  let ids : Array[Int] = []
  for row in rows {
    let mut exists = false
    for id in ids {
      if id == row.id {
        exists = true
        break
      }
    }
    if !exists {
      ids.push(row.id)
    }
  }
  ids.sort_by(fn(left, right) { left.compare(right) })
  ids
}
