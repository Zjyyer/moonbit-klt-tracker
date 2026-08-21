///|
/// Policy for recovering lost tracks from newly detected seeds.
pub(all) struct RecoveryConfig {
  maximum_loss_streak : Int
  search_radius : Double
  minimum_seed_score : Double
  maximum_recovery_distance : Double
} derive(Debug)

///|
pub(all) enum RecoveryError {
  InvalidConfiguration
  NoCandidate
  NonFiniteCandidate
} derive(Debug, Eq)

///|
pub fn RecoveryConfig::new(
  maximum_loss_streak : Int,
  search_radius : Double,
  minimum_seed_score : Double,
  maximum_recovery_distance : Double,
) -> Result[RecoveryConfig, RecoveryError] {
  if maximum_loss_streak < 1 ||
    search_radius <= 0.0 ||
    minimum_seed_score < 0.0 ||
    maximum_recovery_distance <= 0.0 ||
    !finite(search_radius) ||
    !finite(minimum_seed_score) ||
    !finite(maximum_recovery_distance) {
    Err(InvalidConfiguration)
  } else {
    Ok({
      maximum_loss_streak,
      search_radius,
      minimum_seed_score,
      maximum_recovery_distance,
    })
  }
}

///|
pub fn recovery_candidate(
  track : Track,
  candidates : Array[@features.SeedPoint],
  config : RecoveryConfig,
) -> Result[@features.SeedPoint, RecoveryError] {
  if track.state != Lost ||
    track.consecutive_losses > config.maximum_loss_streak {
    return Err(NoCandidate)
  }
  let mut best : @features.SeedPoint? = None
  let mut best_distance = config.maximum_recovery_distance
  for candidate in candidates {
    if !finite(candidate.position.x) ||
      !finite(candidate.position.y) ||
      !finite(candidate.score) {
      return Err(NonFiniteCandidate)
    }
    let distance = distance(track.position, candidate.position)
    if candidate.score >= config.minimum_seed_score &&
      distance <= config.search_radius &&
      distance < best_distance {
      best = Some(candidate)
      best_distance = distance
    }
  }
  match best {
    Some(candidate) => Ok(candidate)
    None => Err(NoCandidate)
  }
}

///|
pub fn recovery_score(
  track : Track,
  candidate : @features.SeedPoint,
  config : RecoveryConfig,
) -> Double {
  let distance_value = distance(track.position, candidate.position)
  let distance_score = 1.0 - (distance_value / config.search_radius).min(1.0)
  let loss_score = 1.0 -
    track.consecutive_losses.to_double() /
    config.maximum_loss_streak.to_double()
  (distance_score + candidate.score + loss_score) / 3.0
}

///|
fn distance(left : @math.Vec2, right : @math.Vec2) -> Double {
  let dx = left.x - right.x
  let dy = left.y - right.y
  (dx * dx + dy * dy).sqrt()
}

///|
fn finite(value : Double) -> Bool {
  !value.is_nan() && !value.is_inf()
}
