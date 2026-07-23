///|
pub(all) struct TrackerConfig {
  klt_config : @klt.KltConfig
  pyramid_levels : Int
  max_consecutive_losses : Int
  redetection_interval : Int
  feature_config : @features.FeatureConfig
} derive(Debug)

///|
pub(all) enum TrackerError {
  InvalidPyramidLevels
  InvalidMaximumConsecutiveLosses
  InvalidRedetectionInterval
  InvalidSeed(index~ : Int)
  PyramidBuildFailed
  DetectionFailed
} derive(Debug, Eq)

///|
pub(all) struct Tracker {
  config : TrackerConfig
  mut previous_frame : @image.GrayFrame
  mut tracks : Array[Track]
  mut next_id : TrackId
  mut frame_index : Int
} derive(Debug)

///|
fn config_is_valid(config : TrackerConfig) -> Bool {
  config.pyramid_levels > 0 &&
  config.max_consecutive_losses > 0 &&
  config.redetection_interval >= 0
}

///|
fn make_track(id : TrackId, seed : @features.SeedPoint) -> Track {
  {
    id,
    seed,
    position: seed.position,
    state: Active,
    consecutive_losses: 0,
    observations: [],
  }
}

///|
pub fn Tracker::start(
  config : TrackerConfig,
  frame : @image.GrayFrame,
  seeds : Array[@features.SeedPoint],
) -> Result[Tracker, TrackerError] {
  if config.pyramid_levels <= 0 {
    return Err(InvalidPyramidLevels)
  }
  if config.max_consecutive_losses <= 0 {
    return Err(InvalidMaximumConsecutiveLosses)
  }
  if config.redetection_interval < 0 {
    return Err(InvalidRedetectionInterval)
  }
  for index, seed in seeds {
    let point = seed.position
    let max_x = (frame.width - 1).to_double()
    let max_y = (frame.height - 1).to_double()
    if point.x.is_nan() || point.x.is_inf() || point.y.is_nan() || point.y.is_inf() ||
      point.x < 0.0 || point.y < 0.0 || point.x > max_x || point.y > max_y {
      return Err(InvalidSeed(index~))
    }
  }
  let tracks : Array[Track] = []
  for index, seed in seeds {
    tracks.push(make_track(index, seed))
  }
  Ok({ config, previous_frame: frame, tracks, next_id: seeds.length(), frame_index: 0 })
}

///|
fn overlaps_active_track(tracks : Array[Track], point : @math.Vec2, radius : Double) -> Bool {
  for track in tracks {
    if track.state == Active {
      let dx = track.position.x - point.x
      let dy = track.position.y - point.y
      if dx * dx + dy * dy <= radius * radius {
        return true
      }
    }
  }
  false
}

///|
fn Tracker::append_redetections(self : Tracker, frame : @image.GrayFrame) -> Result[Unit, TrackerError] {
  let detected = match @features.detect_shi_tomasi(frame, self.config.feature_config) {
    Ok(seeds) => seeds
    Err(_) => return Err(DetectionFailed)
  }
  for seed in detected {
    if !overlaps_active_track(self.tracks, seed.position, self.config.feature_config.suppression_radius) {
      self.tracks.push(make_track(self.next_id, seed))
      self.next_id = self.next_id + 1
    }
  }
  Ok(())
}

///|
fn prune_expired(tracks : Array[Track], max_consecutive_losses : Int) -> Array[Track] {
  let retained : Array[Track] = []
  for track in tracks {
    if track.consecutive_losses < max_consecutive_losses {
      retained.push(track)
    }
  }
  retained
}

///|
pub fn observation_is_trackable(
  frame : @image.GrayFrame,
  observation : @klt.KltObservation,
) -> Bool {
  let target = observation.target
  observation.status == @klt.Tracked &&
  !target.x.is_nan() &&
  !target.x.is_inf() &&
  !target.y.is_nan() &&
  !target.y.is_inf() &&
  target.x >= 0.0 &&
  target.y >= 0.0 &&
  target.x <= (frame.width - 1).to_double() &&
  target.y <= (frame.height - 1).to_double()
}

///|
pub fn Tracker::step(self : Tracker, frame : @image.GrayFrame) -> Result[FrameReport, TrackerError] {
  if !config_is_valid(self.config) {
    return Err(InvalidPyramidLevels)
  }
  let previous = match @image.Pyramid::build(self.previous_frame, self.config.pyramid_levels) {
    Ok(pyramid) => pyramid
    Err(_) => return Err(PyramidBuildFailed)
  }
  let next = match @image.Pyramid::build(frame, self.config.pyramid_levels) {
    Ok(pyramid) => pyramid
    Err(_) => return Err(PyramidBuildFailed)
  }
  let reports : Array[TrackObservation] = []
  let updated : Array[Track] = []
  for track in self.tracks {
    let seed : @features.SeedPoint = { position: track.position, score: track.seed.score }
    let observation = @klt.track_pyramidal(previous, next, seed, self.config.klt_config)
    let mut state = track.state
    let mut losses = track.consecutive_losses
    let mut position = track.position
    if observation_is_trackable(frame, observation) {
      state = Active
      losses = 0
      position = observation.target
    } else {
      state = Lost
      losses = losses + 1
    }
    let history = track.observations
    history.push(observation)
    let current : Track = {
      id: track.id,
      seed: track.seed,
      position,
      state,
      consecutive_losses: losses,
      observations: history,
    }
    reports.push({ id: current.id, state: current.state, observation })
    updated.push(current)
  }
  self.frame_index = self.frame_index + 1
  self.previous_frame = frame
  self.tracks = prune_expired(updated, self.config.max_consecutive_losses)
  if self.config.redetection_interval > 0 &&
    self.frame_index % self.config.redetection_interval == 0 {
    match self.append_redetections(frame) {
      Ok(_) => ()
      Err(error) => return Err(error)
    }
  }
  Ok({ frame_index: self.frame_index, observations: reports })
}

///|
pub fn Tracker::tracks(self : Tracker) -> Array[Track] {
  self.tracks
}
