///|
/// Limits used to classify unusually fast or high-residual tracks.
pub(all) struct AnalysisConfig {
  maximum_velocity : Double
  maximum_residual : Double
} derive(Debug)

///|
pub(all) enum AnalysisError {
  InvalidMaximumVelocity
  InvalidMaximumResidual
  NonFiniteDisplacement
} derive(Debug, Eq)

///|
pub fn AnalysisConfig::new(
  maximum_velocity : Double,
  maximum_residual : Double,
) -> Result[AnalysisConfig, AnalysisError] {
  if maximum_velocity.is_nan() ||
    maximum_velocity.is_inf() ||
    maximum_velocity < 0.0 {
    Err(InvalidMaximumVelocity)
  } else if maximum_residual.is_nan() ||
    maximum_residual.is_inf() ||
    maximum_residual < 0.0 {
    Err(InvalidMaximumResidual)
  } else {
    Ok({ maximum_velocity, maximum_residual })
  }
}

///|
pub(all) enum TrackAnomaly {
  Normal
  ExcessiveResidual
  ExcessiveVelocity
} derive(Debug, Eq)

///|
pub(all) struct TrackSummary {
  id : Int
  observation_count : Int
  active_count : Int
  lost_count : Int
  displacement : Double
  mean_velocity : Double
  rank : Int
  anomaly : TrackAnomaly
} derive(Debug)

///|
pub(all) struct QualitySummary {
  observation_count : Int
  active_count : Int
  lost_count : Int
  rejected_count : Int
  out_of_bounds_count : Int
} derive(Debug, Eq)

///|
pub(all) struct SequenceAnalysis {
  tracks : Array[TrackSummary]
  quality : QualitySummary
  events : Array[LifecycleEvent]
} derive(Debug)

///|
priv struct ObservationRow {
  id : Int
  frame : Int
  state : @tracking.TrackState
  displacement_x : Double
  displacement_y : Double
  residual : Double
  status : @klt.KltStatus
}

///|
fn sorted_rows(document : @formats.TrajectoryDocument) -> Array[ObservationRow] {
  let rows : Array[ObservationRow] = []
  for report in document.reports {
    for track_observation in report.observations {
      let observation = track_observation.observation
      rows.push({
        id: track_observation.id,
        frame: report.frame_index,
        state: track_observation.state,
        displacement_x: observation.displacement.x,
        displacement_y: observation.displacement.y,
        residual: observation.residual,
        status: observation.status,
      })
    }
  }
  rows.sort_by(fn(left, right) {
    if left.frame < right.frame {
      -1
    } else if left.frame > right.frame {
      1
    } else if left.id < right.id {
      -1
    } else if left.id > right.id {
      1
    } else if left.state == @tracking.Active && right.state == @tracking.Lost {
      -1
    } else if left.state == @tracking.Lost && right.state == @tracking.Active {
      1
    } else {
      0
    }
  })
  rows
}

///|
fn row_displacement(row : ObservationRow) -> Result[Double, AnalysisError] {
  let x = if row.displacement_x < 0.0 {
    -row.displacement_x
  } else {
    row.displacement_x
  }
  let y = if row.displacement_y < 0.0 {
    -row.displacement_y
  } else {
    row.displacement_y
  }
  let scale = if x > y { x } else { y }
  let magnitude = if scale == 0.0 {
    0.0
  } else {
    scale * (x / scale * (x / scale) + y / scale * (y / scale)).sqrt()
  }
  if magnitude.is_nan() || magnitude.is_inf() {
    Err(NonFiniteDisplacement)
  } else {
    Ok(magnitude)
  }
}

///|
fn track_ids(
  document : @formats.TrajectoryDocument,
  rows : Array[ObservationRow],
) -> Array[Int] {
  let ids : Array[Int] = []
  for track in document.tracks {
    ids.push(track.id)
  }
  for row in rows {
    ids.push(row.id)
  }
  ids.sort()
  let unique : Array[Int] = []
  for id in ids {
    if unique.length() == 0 || unique[unique.length() - 1] != id {
      unique.push(id)
    }
  }
  unique
}

///|
fn summarize_track(
  id : Int,
  rows : Array[ObservationRow],
  config : AnalysisConfig,
) -> Result[TrackSummary, AnalysisError] {
  let mut observation_count = 0
  let mut active_count = 0
  let mut lost_count = 0
  let mut displacement = 0.0
  let mut excessive_residual = false
  for row in rows {
    if row.id == id {
      observation_count = observation_count + 1
      let step = match row_displacement(row) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      let next_displacement = displacement + step
      if next_displacement.is_nan() || next_displacement.is_inf() {
        return Err(NonFiniteDisplacement)
      }
      displacement = next_displacement
      if row.state == @tracking.Active {
        active_count = active_count + 1
      } else {
        lost_count = lost_count + 1
      }
      if row.residual > config.maximum_residual {
        excessive_residual = true
      }
    }
  }
  let mean_velocity = if observation_count == 0 {
    0.0
  } else {
    displacement / observation_count.to_double()
  }
  let anomaly = if excessive_residual {
    ExcessiveResidual
  } else if mean_velocity > config.maximum_velocity {
    ExcessiveVelocity
  } else {
    Normal
  }
  Ok({
    id,
    observation_count,
    active_count,
    lost_count,
    displacement,
    mean_velocity,
    rank: 0,
    anomaly,
  })
}

///|
fn quality_summary(rows : Array[ObservationRow]) -> QualitySummary {
  let mut observation_count = 0
  let mut active_count = 0
  let mut lost_count = 0
  let mut rejected_count = 0
  let mut out_of_bounds_count = 0
  for row in rows {
    observation_count = observation_count + 1
    if row.state == @tracking.Active {
      active_count = active_count + 1
    } else {
      lost_count = lost_count + 1
    }
    match row.status {
      @klt.Rejected => rejected_count = rejected_count + 1
      @klt.OutOfBounds => out_of_bounds_count = out_of_bounds_count + 1
      @klt.Tracked => ()
    }
  }
  {
    observation_count,
    active_count,
    lost_count,
    rejected_count,
    out_of_bounds_count,
  }
}

///|
fn rank_tracks(tracks : Array[TrackSummary]) -> Array[TrackSummary] {
  let ranked = tracks
  ranked.sort_by(fn(left, right) {
    if left.displacement > right.displacement {
      -1
    } else if left.displacement < right.displacement {
      1
    } else if left.id < right.id {
      -1
    } else if left.id > right.id {
      1
    } else {
      0
    }
  })
  for index in 0..<ranked.length() {
    let track = ranked[index]
    ranked[index] = { ..track, rank: index + 1 }
  }
  ranked.sort_by(fn(left, right) {
    if left.id < right.id {
      -1
    } else if left.id > right.id {
      1
    } else {
      0
    }
  })
  ranked
}

///|
/// Analyzes a trajectory document without changing its tracker-derived data.
pub fn analyze(
  document : @formats.TrajectoryDocument,
  config : AnalysisConfig,
) -> Result[SequenceAnalysis, AnalysisError] {
  match AnalysisConfig::new(config.maximum_velocity, config.maximum_residual) {
    Err(error) => Err(error)
    Ok(valid_config) => {
      let rows = sorted_rows(document)
      let tracks : Array[TrackSummary] = []
      for id in track_ids(document, rows) {
        match summarize_track(id, rows, valid_config) {
          Err(error) => return Err(error)
          Ok(track) => tracks.push(track)
        }
      }
      Ok({
        tracks: rank_tracks(tracks),
        quality: quality_summary(rows),
        events: lifecycle_events(rows),
      })
    }
  }
}
