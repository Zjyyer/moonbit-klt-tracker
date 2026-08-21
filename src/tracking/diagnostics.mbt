///|
/// Per-track health information derived without mutating tracker state.
pub(all) struct TrackHealth {
  id : TrackId
  state : TrackState
  observation_count : Int
  accepted_count : Int
  rejected_count : Int
  loss_streak : Int
  mean_residual : Double
  mean_forward_backward_error : Double
  confidence : Double
} derive(Debug)

///|
pub(all) struct TrackingSummary {
  total_tracks : Int
  active_tracks : Int
  lost_tracks : Int
  total_observations : Int
  accepted_observations : Int
  rejected_observations : Int
  mean_confidence : Double
  mean_residual : Double
} derive(Debug)

///|
pub fn health(track : Track) -> TrackHealth {
  let mut accepted = 0
  let mut rejected = 0
  let mut residual = 0.0
  let mut round_trip = 0.0
  let mut confidence = track.seed.score
  for observation in track.observations {
    match observation.status {
      @klt.Tracked => accepted += 1
      @klt.Rejected => rejected += 1
      @klt.OutOfBounds => rejected += 1
    }
    residual += observation.residual
    round_trip += observation.forward_backward_error
    confidence += observation.minimum_eigenvalue
  }
  let count = track.observations.length()
  {
    id: track.id,
    state: track.state,
    observation_count: count,
    accepted_count: accepted,
    rejected_count: rejected,
    loss_streak: track.consecutive_losses,
    mean_residual: if count == 0 {
      0.0
    } else {
      residual / count.to_double()
    },
    mean_forward_backward_error: if count == 0 {
      0.0
    } else {
      round_trip / count.to_double()
    },
    confidence: if count == 0 {
      confidence
    } else {
      confidence / (count + 1).to_double()
    },
  }
}

///|
pub fn summarize_tracks(tracks : Array[Track]) -> TrackingSummary {
  let mut active = 0
  let mut lost = 0
  let mut observations = 0
  let mut accepted = 0
  let mut rejected = 0
  let mut confidence = 0.0
  let mut residual = 0.0
  for track in tracks {
    match track.state {
      Active => active += 1
      Lost => lost += 1
    }
    let item = health(track)
    observations += item.observation_count
    accepted += item.accepted_count
    rejected += item.rejected_count
    confidence += item.confidence
    residual += item.mean_residual * item.observation_count.to_double()
  }
  {
    total_tracks: tracks.length(),
    active_tracks: active,
    lost_tracks: lost,
    total_observations: observations,
    accepted_observations: accepted,
    rejected_observations: rejected,
    mean_confidence: if tracks.length() == 0 {
      0.0
    } else {
      confidence / tracks.length().to_double()
    },
    mean_residual: if observations == 0 {
      0.0
    } else {
      residual / observations.to_double()
    },
  }
}

///|
pub fn rank_tracks(tracks : Array[Track]) -> Array[TrackHealth] {
  let ranked : Array[TrackHealth] = []
  for track in tracks {
    ranked.push(health(track))
  }
  ranked.sort_by(fn(left, right) {
    if left.confidence != right.confidence {
      if left.confidence > right.confidence {
        -1
      } else {
        1
      }
    } else {
      left.id.compare(right.id)
    }
  })
  ranked
}

///|
pub fn frame_health(report : FrameReport) -> Double {
  if report.observations.length() == 0 {
    return 0.0
  }
  let mut accepted = 0
  for observation in report.observations {
    if observation.observation.status == @klt.Tracked {
      accepted += 1
    }
  }
  accepted.to_double() / report.observations.length().to_double()
}
