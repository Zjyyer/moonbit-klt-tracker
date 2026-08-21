///|
/// Frame-indexed lifecycle counters for a tracking session.
pub(all) struct TimelinePoint {
  frame : Int
  active : Int
  lost : Int
  accepted : Int
  rejected : Int
  quality : Double
} derive(Debug)

///|
pub fn build_timeline(reports : Array[FrameReport]) -> Array[TimelinePoint] {
  let timeline : Array[TimelinePoint] = []
  for report in reports {
    let mut active = 0
    let mut lost = 0
    let mut accepted = 0
    let mut rejected = 0
    let mut quality = 0.0
    for item in report.observations {
      match item.state {
        Active => active += 1
        Lost => lost += 1
      }
      match item.observation.status {
        @klt.Tracked => accepted += 1
        @klt.Rejected => rejected += 1
        @klt.OutOfBounds => rejected += 1
      }
      quality += item.observation.minimum_eigenvalue
    }
    let count = report.observations.length()
    timeline.push({
      frame: report.frame_index,
      active,
      lost,
      accepted,
      rejected,
      quality: if count == 0 {
        0.0
      } else {
        quality / count.to_double()
      },
    })
  }
  timeline.sort_by(fn(left, right) { left.frame.compare(right.frame) })
  timeline
}

///|
pub fn peak_active(timeline : Array[TimelinePoint]) -> Int {
  let mut result = 0
  for point in timeline {
    result = result.max(point.active)
  }
  result
}

///|
pub fn total_decisions(timeline : Array[TimelinePoint]) -> Int {
  let mut result = 0
  for point in timeline {
    result += point.accepted + point.rejected
  }
  result
}

///|
pub fn timeline_quality(timeline : Array[TimelinePoint]) -> Double {
  if timeline.length() == 0 {
    0.0
  } else {
    let mut total = 0.0
    for point in timeline {
      total += point.quality
    }
    total / timeline.length().to_double()
  }
}
