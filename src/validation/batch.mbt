///|
/// Batch-level validation report for reproducible sequence quality checks.
pub(all) struct BatchValidation {
  frame_count : Int
  observation_count : Int
  accepted_count : Int
  rejected_count : Int
  mean_texture : Double
  mean_residual : Double
  mean_round_trip : Double
  acceptance_rate : Double
  complete : Bool
} derive(Debug)

///|
pub fn batch_validation(
  textures : Array[Double],
  residuals : Array[Double],
  round_trips : Array[Double],
  frame_count : Int,
  policy : ThresholdPolicy,
) -> Result[BatchValidation, ThresholdError] {
  if frame_count < 1 {
    return Err(EmptyMeasurements)
  }
  if textures.length() != residuals.length() ||
    textures.length() != round_trips.length() {
    return Err(LengthMismatch)
  }
  let gate = evaluate_gate(textures, residuals, residuals, round_trips, policy)
  match gate {
    Err(error) => Err(error)
    Ok(result) => {
      let mut texture_sum = 0.0
      let mut residual_sum = 0.0
      let mut round_trip_sum = 0.0
      for index in 0..<textures.length() {
        if !finite(textures[index]) ||
          !finite(residuals[index]) ||
          !finite(round_trips[index]) {
          return Err(InvalidValue)
        }
        texture_sum += textures[index]
        residual_sum += residuals[index]
        round_trip_sum += round_trips[index]
      }
      let count = textures.length().to_double()
      Ok({
        frame_count,
        observation_count: textures.length(),
        accepted_count: result.passed,
        rejected_count: result.failed,
        mean_texture: texture_sum / count,
        mean_residual: residual_sum / count,
        mean_round_trip: round_trip_sum / count,
        acceptance_rate: result.acceptance_rate,
        complete: result.passed_gate,
      })
    }
  }
}

///|
pub fn batch_label(batch : BatchValidation) -> String {
  if batch.observation_count == 0 {
    "empty"
  } else if batch.complete && batch.acceptance_rate >= 0.95 {
    "stable"
  } else if batch.complete {
    "usable"
  } else if batch.acceptance_rate >= 0.5 {
    "degraded"
  } else {
    "invalid"
  }
}

///|
pub fn frame_coverage(batch : BatchValidation) -> Double {
  if batch.frame_count == 0 {
    0.0
  } else {
    batch.observation_count.to_double() / batch.frame_count.to_double()
  }
}

///|
pub fn merge_batches(
  left : BatchValidation,
  right : BatchValidation,
) -> BatchValidation {
  let observations = left.observation_count + right.observation_count
  let accepted = left.accepted_count + right.accepted_count
  {
    frame_count: left.frame_count + right.frame_count,
    observation_count: observations,
    accepted_count: accepted,
    rejected_count: observations - accepted,
    mean_texture: weighted_average(
      left.mean_texture,
      left.observation_count,
      right.mean_texture,
      right.observation_count,
    ),
    mean_residual: weighted_average(
      left.mean_residual,
      left.observation_count,
      right.mean_residual,
      right.observation_count,
    ),
    mean_round_trip: weighted_average(
      left.mean_round_trip,
      left.observation_count,
      right.mean_round_trip,
      right.observation_count,
    ),
    acceptance_rate: if observations == 0 {
      0.0
    } else {
      accepted.to_double() / observations.to_double()
    },
    complete: left.complete && right.complete,
  }
}

///|
fn weighted_average(
  left : Double,
  left_count : Int,
  right : Double,
  right_count : Int,
) -> Double {
  let total = left_count + right_count
  if total == 0 {
    0.0
  } else {
    (left * left_count.to_double() + right * right_count.to_double()) /
    total.to_double()
  }
}
