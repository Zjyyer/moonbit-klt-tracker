///|
pub type TrackId = Int

///|
pub(all) enum TrackState {
  Active
  Lost
} derive(Debug, Eq)

///|
pub(all) struct Track {
  id : TrackId
  seed : @features.SeedPoint
  position : @math.Vec2
  state : TrackState
  consecutive_losses : Int
  observations : Array[@klt.KltObservation]
} derive(Debug)

///|
pub(all) struct TrackObservation {
  id : TrackId
  state : TrackState
  observation : @klt.KltObservation
} derive(Debug)

///|
pub(all) struct FrameReport {
  frame_index : Int
  observations : Array[TrackObservation]
} derive(Debug)
