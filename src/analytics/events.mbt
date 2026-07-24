///|
pub(all) enum LifecycleEvent {
  Activated(id~ : Int, frame~ : Int)
  Lost(id~ : Int, frame~ : Int)
} derive(Debug, Eq)

///|
fn lifecycle_events(rows : Array[ObservationRow]) -> Array[LifecycleEvent] {
  let events : Array[LifecycleEvent] = []
  let seen_ids : Array[Int] = []
  let previous_states : Array[@tracking.TrackState] = []
  for row in rows {
    let mut index = 0
    while index < seen_ids.length() && seen_ids[index] != row.id {
      index = index + 1
    }
    if index == seen_ids.length() {
      seen_ids.push(row.id)
      previous_states.push(row.state)
      if row.state == @tracking.Active {
        events.push(Activated(id=row.id, frame=row.frame))
      } else {
        events.push(Lost(id=row.id, frame=row.frame))
      }
    } else if previous_states[index] != row.state {
      previous_states[index] = row.state
      if row.state == @tracking.Active {
        events.push(Activated(id=row.id, frame=row.frame))
      } else {
        events.push(Lost(id=row.id, frame=row.frame))
      }
    }
  }
  events
}
