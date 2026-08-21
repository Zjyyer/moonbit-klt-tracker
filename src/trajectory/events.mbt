///|
pub(all) enum LifecycleEvent {
  Activated(id~ : Int, frame~ : Int)
  Lost(id~ : Int, frame~ : Int)
  Recovered(id~ : Int, frame~ : Int)
  Terminated(id~ : Int, frame~ : Int)
} derive(Debug, Eq)

///|
pub fn lifecycle_events(
  trajectories : Array[Trajectory],
) -> Array[LifecycleEvent] {
  let events : Array[LifecycleEvent] = []
  for trajectory in trajectories {
    if trajectory.points.length() == 0 {
      continue
    }
    let first = trajectory.points[0]
    let mut previous = first.state
    if first.state == Accepted {
      events.push(Activated(id=trajectory.id, frame=first.frame))
    }
    for point in trajectory.points[1:] {
      if previous == Accepted && point.state != Accepted {
        events.push(Lost(id=trajectory.id, frame=point.frame))
      } else if previous != Accepted && point.state == Accepted {
        events.push(Recovered(id=trajectory.id, frame=point.frame))
      }
      previous = point.state
    }
    if previous != Accepted {
      events.push(
        Terminated(
          id=trajectory.id,
          frame=trajectory.points[trajectory.points.length() - 1].frame,
        ),
      )
    }
  }
  events.sort_by(event_order)
  events
}

///|
fn event_order(left : LifecycleEvent, right : LifecycleEvent) -> Int {
  let left_frame = event_frame(left)
  let right_frame = event_frame(right)
  if left_frame != right_frame {
    left_frame.compare(right_frame)
  } else {
    event_id(left).compare(event_id(right))
  }
}

///|
fn event_frame(event : LifecycleEvent) -> Int {
  match event {
    Activated(frame~, ..) => frame
    Lost(frame~, ..) => frame
    Recovered(frame~, ..) => frame
    Terminated(frame~, ..) => frame
  }
}

///|
fn event_id(event : LifecycleEvent) -> Int {
  match event {
    Activated(id~, ..) => id
    Lost(id~, ..) => id
    Recovered(id~, ..) => id
    Terminated(id~, ..) => id
  }
}
