///|
/// A named threshold policy for repeatable quality gates.
pub(all) struct ThresholdPolicy {
  minimum_texture : Double
  maximum_residual : Double
  maximum_velocity : Double
  maximum_round_trip : Double
  minimum_acceptance_rate : Double
} derive(Debug)

///|
pub(all) enum ThresholdError {
  InvalidValue
  EmptyMeasurements
  LengthMismatch
  FailedGate
} derive(Debug, Eq)

///|
pub fn ThresholdPolicy::new(
  minimum_texture : Double,
  maximum_residual : Double,
  maximum_velocity : Double,
  maximum_round_trip : Double,
  minimum_acceptance_rate : Double,
) -> Result[ThresholdPolicy, ThresholdError] {
  if !finite(minimum_texture) ||
    !finite(maximum_residual) ||
    !finite(maximum_velocity) ||
    !finite(maximum_round_trip) ||
    !finite(minimum_acceptance_rate) ||
    minimum_texture < 0.0 ||
    maximum_residual < 0.0 ||
    maximum_velocity < 0.0 ||
    maximum_round_trip < 0.0 ||
    minimum_acceptance_rate < 0.0 ||
    minimum_acceptance_rate > 1.0 {
    Err(InvalidValue)
  } else {
    Ok({
      minimum_texture,
      maximum_residual,
      maximum_velocity,
      maximum_round_trip,
      minimum_acceptance_rate,
    })
  }
}

///|
pub(all) struct GateResult {
  total : Int
  passed : Int
  failed : Int
  texture_failures : Int
  residual_failures : Int
  velocity_failures : Int
  round_trip_failures : Int
  acceptance_rate : Double
  passed_gate : Bool
} derive(Debug)

///|
pub fn evaluate_gate(
  textures : Array[Double],
  residuals : Array[Double],
  velocities : Array[Double],
  round_trips : Array[Double],
  policy : ThresholdPolicy,
) -> Result[GateResult, ThresholdError] {
  if textures.length() == 0 {
    return Err(EmptyMeasurements)
  }
  if textures.length() != residuals.length() ||
    textures.length() != velocities.length() ||
    textures.length() != round_trips.length() {
    return Err(LengthMismatch)
  }
  let mut texture_failures = 0
  let mut residual_failures = 0
  let mut velocity_failures = 0
  let mut round_trip_failures = 0
  let mut passed = 0
  for index in 0..<textures.length() {
    let texture = textures[index]
    let residual = residuals[index]
    let velocity = velocities[index]
    let round_trip = round_trips[index]
    if !finite(texture) ||
      !finite(residual) ||
      !finite(velocity) ||
      !finite(round_trip) {
      return Err(InvalidValue)
    }
    let texture_ok = texture >= policy.minimum_texture
    let residual_ok = residual <= policy.maximum_residual
    let velocity_ok = velocity <= policy.maximum_velocity
    let round_trip_ok = round_trip <= policy.maximum_round_trip
    if !texture_ok {
      texture_failures += 1
    }
    if !residual_ok {
      residual_failures += 1
    }
    if !velocity_ok {
      velocity_failures += 1
    }
    if !round_trip_ok {
      round_trip_failures += 1
    }
    if texture_ok && residual_ok && velocity_ok && round_trip_ok {
      passed += 1
    }
  }
  let total = textures.length()
  let acceptance_rate = passed.to_double() / total.to_double()
  Ok({
    total,
    passed,
    failed: total - passed,
    texture_failures,
    residual_failures,
    velocity_failures,
    round_trip_failures,
    acceptance_rate,
    passed_gate: acceptance_rate >= policy.minimum_acceptance_rate,
  })
}

///|
pub fn require_gate(result : GateResult) -> Result[Unit, ThresholdError] {
  if result.passed_gate {
    Ok(())
  } else {
    Err(FailedGate)
  }
}

///|
pub fn quality_label(result : GateResult) -> String {
  if result.passed_gate && result.acceptance_rate >= 0.95 {
    "excellent"
  } else if result.passed_gate {
    "accepted"
  } else if result.acceptance_rate >= 0.5 {
    "review"
  } else {
    "rejected"
  }
}

///|
pub fn failure_rate(result : GateResult) -> Double {
  if result.total == 0 {
    0.0
  } else {
    result.failed.to_double() / result.total.to_double()
  }
}

///|
pub fn dominant_failure(result : GateResult) -> String {
  let maximum = result.texture_failures
    .max(result.residual_failures)
    .max(result.velocity_failures.max(result.round_trip_failures))
  if maximum == result.texture_failures && maximum > 0 {
    "texture"
  } else if maximum == result.residual_failures && maximum > 0 {
    "residual"
  } else if maximum == result.velocity_failures && maximum > 0 {
    "velocity"
  } else if maximum > 0 {
    "round_trip"
  } else {
    "none"
  }
}

///|
pub fn merge_gate_results(left : GateResult, right : GateResult) -> GateResult {
  let total = left.total + right.total
  let passed = left.passed + right.passed
  {
    total,
    passed,
    failed: total - passed,
    texture_failures: left.texture_failures + right.texture_failures,
    residual_failures: left.residual_failures + right.residual_failures,
    velocity_failures: left.velocity_failures + right.velocity_failures,
    round_trip_failures: left.round_trip_failures + right.round_trip_failures,
    acceptance_rate: if total == 0 {
      0.0
    } else {
      passed.to_double() / total.to_double()
    },
    passed_gate: left.passed_gate && right.passed_gate,
  }
}
