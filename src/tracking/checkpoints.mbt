///|
/// A compact checkpoint of tracker state for deterministic replay.
pub(all) struct TrackingCheckpoint {
  frame : Int
  active_ids : Array[TrackId]
  lost_ids : Array[TrackId]
  observation_count : Int
  quality : Double
} derive(Debug)

///|
pub fn checkpoint(frame : Int, tracks : Array[Track]) -> TrackingCheckpoint {
  let active : Array[TrackId] = []
  let lost : Array[TrackId] = []
  let mut observations = 0
  let mut quality = 0.0
  for track in tracks {
    match track.state {
      Active => active.push(track.id)
      Lost => lost.push(track.id)
    }
    observations += track.observations.length()
    quality += health(track).confidence
  }
  active.sort_by(fn(left, right) { left.compare(right) })
  lost.sort_by(fn(left, right) { left.compare(right) })
  {
    frame,
    active_ids: active,
    lost_ids: lost,
    observation_count: observations,
    quality: if tracks.length() == 0 {
      0.0
    } else {
      quality / tracks.length().to_double()
    },
  }
}

///|
pub fn checkpoint_is_monotonic(
  previous : TrackingCheckpoint,
  current : TrackingCheckpoint,
) -> Bool {
  current.frame >= previous.frame &&
  current.observation_count >= 0 &&
  current.quality >= 0.0
}

///|
pub fn checkpoint_active_count(value : TrackingCheckpoint) -> Int {
  value.active_ids.length()
}

///|
pub fn checkpoint_lost_count(value : TrackingCheckpoint) -> Int {
  value.lost_ids.length()
}

///|
pub fn checkpoint_summary(value : TrackingCheckpoint) -> String {
  "frame=" +
  value.frame.to_string() +
  ",active=" +
  value.active_ids.length().to_string() +
  ",lost=" +
  value.lost_ids.length().to_string() +
  ",observations=" +
  value.observation_count.to_string()
}

///|
pub fn checkpoint_contains_active(
  value : TrackingCheckpoint,
  id : TrackId,
) -> Bool {
  for current in value.active_ids {
    if current == id {
      return true
    }
  }
  false
}

///|
pub fn checkpoint_contains_lost(
  value : TrackingCheckpoint,
  id : TrackId,
) -> Bool {
  for current in value.lost_ids {
    if current == id {
      return true
    }
  }
  false
}

///|
pub fn checkpoint_total_tracks(value : TrackingCheckpoint) -> Int {
  value.active_ids.length() + value.lost_ids.length()
}
