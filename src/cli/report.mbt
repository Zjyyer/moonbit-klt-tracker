///|
pub fn render_report(document : @formats.TrajectoryDocument) -> String {
  let mut tracked = 0
  let mut lost = 0
  let mut rejected = 0
  for frame_report in document.reports {
    for item in frame_report.observations {
      if item.observation.status == @klt.Rejected {
        rejected = rejected + 1
      } else if item.state == @tracking.Lost {
        lost = lost + 1
      } else if item.observation.status == @klt.Tracked {
        tracked = tracked + 1
      }
    }
  }
  "tracked=" +
  tracked.to_string() +
  "\nlost=" +
  lost.to_string() +
  "\nrejected=" +
  rejected.to_string() +
  "\n"
}
