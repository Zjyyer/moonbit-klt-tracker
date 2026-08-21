///|
/// Session-level summaries for multi-frame tracker runs.
pub(all) struct SessionSummary {
  first_frame : Int?
  last_frame : Int?
  frame_count : Int
  observation_count : Int
  active_peak : Int
  mean_frame_quality : Double
  dropped_frame_count : Int
} derive(Debug)

///|
pub fn session_summary(reports : Array[FrameReport]) -> SessionSummary {
  if reports.length() == 0 {
    return {
      first_frame: None,
      last_frame: None,
      frame_count: 0,
      observation_count: 0,
      active_peak: 0,
      mean_frame_quality: 0.0,
      dropped_frame_count: 0,
    }
  }
  let timeline = build_timeline(reports)
  let mut observations = 0
  let mut peak = 0
  let mut gaps = 0
  let mut quality = 0.0
  for point in timeline {
    observations += point.accepted + point.rejected
    peak = peak.max(point.active)
    quality += point.quality
  }
  for index in 1..<timeline.length() {
    if timeline[index].frame - timeline[index - 1].frame > 1 {
      gaps += 1
    }
  }
  {
    first_frame: Some(timeline[0].frame),
    last_frame: Some(timeline[timeline.length() - 1].frame),
    frame_count: timeline.length(),
    observation_count: observations,
    active_peak: peak,
    mean_frame_quality: quality / timeline.length().to_double(),
    dropped_frame_count: gaps,
  }
}

///|
pub fn session_label(summary : SessionSummary) -> String {
  if summary.frame_count == 0 {
    "empty"
  } else if summary.dropped_frame_count == 0 && summary.mean_frame_quality > 0.0 {
    "continuous"
  } else if summary.dropped_frame_count < summary.frame_count / 2 {
    "recoverable"
  } else {
    "fragmented"
  }
}

///|
pub fn session_coverage(summary : SessionSummary) -> Double {
  match (summary.first_frame, summary.last_frame) {
    (Some(first), Some(last)) =>
      if last == first {
        1.0
      } else {
        summary.frame_count.to_double() / (last - first + 1).to_double()
      }
    (_, _) => 0.0
  }
}

///|
pub fn session_density(summary : SessionSummary) -> Double {
  if summary.frame_count == 0 {
    0.0
  } else {
    summary.observation_count.to_double() / summary.frame_count.to_double()
  }
}

///|
pub fn session_is_complete(summary : SessionSummary) -> Bool {
  summary.frame_count > 0 &&
  summary.dropped_frame_count == 0 &&
  summary.mean_frame_quality > 0.0
}

///|
pub fn session_observations_per_frame(summary : SessionSummary) -> Double {
  session_density(summary)
}

///|
pub fn session_has_frames(summary : SessionSummary) -> Bool {
  summary.frame_count > 0
}

///|
pub fn session_has_observations(summary : SessionSummary) -> Bool {
  summary.observation_count > 0
}

///|
pub fn session_drop_rate(summary : SessionSummary) -> Double {
  if summary.frame_count == 0 {
    0.0
  } else {
    summary.dropped_frame_count.to_double() / summary.frame_count.to_double()
  }
}
