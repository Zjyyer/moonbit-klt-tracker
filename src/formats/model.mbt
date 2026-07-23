///|
pub(all) struct TrajectoryDocument {
  tracks : Array[@tracking.Track]
  reports : Array[@tracking.FrameReport]
}

///|
pub fn TrajectoryDocument::new(
  tracks : Array[@tracking.Track],
  reports : Array[@tracking.FrameReport],
) -> TrajectoryDocument {
  { tracks, reports }
}

///|
priv struct TrajectoryRow {
  id : Int
  frame : Int
  state : String
  x : Double
  y : Double
}

///|
pub fn schema_version() -> String {
  "1.0"
}

///|
fn state_name(state : @tracking.TrackState) -> String {
  match state {
    @tracking.Active => "active"
    @tracking.Lost => "lost"
  }
}

///|
fn is_finite(value : Double) -> Bool {
  !value.is_nan() && !value.is_inf()
}

///|
fn validate_finite(value : Double) -> Unit {
  if !is_finite(value) {
    panic()
  }
}

///|
fn validate_document(document : TrajectoryDocument) -> Unit {
  for track in document.tracks {
    validate_finite(track.seed.position.x)
    validate_finite(track.seed.position.y)
    validate_finite(track.seed.score)
    validate_finite(track.position.x)
    validate_finite(track.position.y)
    for observation in track.observations {
      validate_observation(observation)
    }
  }
  for report in document.reports {
    for track_observation in report.observations {
      validate_observation(track_observation.observation)
    }
  }
}

///|
fn validate_observation(observation : @klt.KltObservation) -> Unit {
  validate_finite(observation.source.x)
  validate_finite(observation.source.y)
  validate_finite(observation.target.x)
  validate_finite(observation.target.y)
  validate_finite(observation.displacement.x)
  validate_finite(observation.displacement.y)
  validate_finite(observation.residual)
  validate_finite(observation.minimum_eigenvalue)
  validate_finite(observation.forward_backward_error)
}

///|
fn sorted_rows(document : TrajectoryDocument) -> Array[TrajectoryRow] {
  validate_document(document)
  let rows : Array[TrajectoryRow] = []
  for report in document.reports {
    for track_observation in report.observations {
      let observation = track_observation.observation
      rows.push({
        id: track_observation.id,
        frame: report.frame_index,
        state: state_name(track_observation.state),
        x: observation.target.x,
        y: observation.target.y,
      })
    }
  }
  rows.sort_by(fn(left, right) {
    if left.id < right.id {
      -1
    } else if left.id > right.id {
      1
    } else if left.frame < right.frame {
      -1
    } else if left.frame > right.frame {
      1
    } else {
      0
    }
  })
  rows
}

///|
fn format_number(value : Double) -> String {
  validate_finite(value)
  value.to_string()
}
