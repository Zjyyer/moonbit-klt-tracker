///|
/// Reason categories for an observation rejected by the validation stage.
pub(all) enum RejectionReason {
  NonFinite
  LowTexture
  HighResidual
  ForwardBackwardMismatch
  OutOfBounds
  DuplicateFrame
} derive(Debug, Eq)

///|
pub(all) struct ValidationConfig {
  minimum_texture : Double
  maximum_residual : Double
  maximum_round_trip : Double
} derive(Debug)

///|
pub fn ValidationConfig::new(
  minimum_texture : Double,
  maximum_residual : Double,
  maximum_round_trip : Double,
) -> Result[ValidationConfig, RejectionReason] {
  if !finite(minimum_texture) ||
    !finite(maximum_residual) ||
    !finite(maximum_round_trip) ||
    minimum_texture < 0.0 ||
    maximum_residual < 0.0 ||
    maximum_round_trip < 0.0 {
    Err(NonFinite)
  } else {
    Ok({ minimum_texture, maximum_residual, maximum_round_trip })
  }
}

///|
pub fn classify(
  texture : Double,
  residual : Double,
  round_trip : Double,
  out_of_bounds : Bool,
  config : ValidationConfig,
) -> Result[RejectionReason?, RejectionReason] {
  if !finite(texture) || !finite(residual) || !finite(round_trip) {
    return Err(NonFinite)
  }
  if out_of_bounds {
    Ok(Some(OutOfBounds))
  } else if texture < config.minimum_texture {
    Ok(Some(LowTexture))
  } else if residual > config.maximum_residual {
    Ok(Some(HighResidual))
  } else if round_trip > config.maximum_round_trip {
    Ok(Some(ForwardBackwardMismatch))
  } else {
    Ok(None)
  }
}

///|
pub(all) struct ValidationSummary {
  total : Int
  accepted : Int
  rejected : Int
  non_finite : Int
  low_texture : Int
  high_residual : Int
  round_trip_mismatch : Int
  out_of_bounds : Int
  acceptance_rate : Double
} derive(Debug)

///|
pub fn summarize_validations(
  textures : Array[Double],
  residuals : Array[Double],
  round_trips : Array[Double],
  bounds : Array[Bool],
  config : ValidationConfig,
) -> Result[ValidationSummary, RejectionReason] {
  if textures.length() != residuals.length() ||
    textures.length() != round_trips.length() ||
    textures.length() != bounds.length() {
    return Err(DuplicateFrame)
  }
  let mut accepted = 0
  let mut non_finite = 0
  let mut low_texture = 0
  let mut high_residual = 0
  let mut round_trip_mismatch = 0
  let mut out_of_bounds = 0
  for index in 0..<textures.length() {
    match
      classify(
        textures[index],
        residuals[index],
        round_trips[index],
        bounds[index],
        config,
      ) {
      Ok(None) => accepted += 1
      Ok(Some(reason)) =>
        match reason {
          NonFinite => non_finite += 1
          LowTexture => low_texture += 1
          HighResidual => high_residual += 1
          ForwardBackwardMismatch => round_trip_mismatch += 1
          OutOfBounds => out_of_bounds += 1
          DuplicateFrame => ()
        }
      Err(NonFinite) => non_finite += 1
      Err(_) => non_finite += 1
    }
  }
  let total = textures.length()
  Ok({
    total,
    accepted,
    rejected: total - accepted,
    non_finite,
    low_texture,
    high_residual,
    round_trip_mismatch,
    out_of_bounds,
    acceptance_rate: if total == 0 {
      0.0
    } else {
      accepted.to_double() / total.to_double()
    },
  })
}

///|
pub fn confidence_score(summary : ValidationSummary) -> Double {
  if summary.total == 0 {
    return 0.0
  }
  let finite_rate = (summary.total - summary.non_finite).to_double() /
    summary.total.to_double()
  let texture_rate = (summary.total - summary.low_texture).to_double() /
    summary.total.to_double()
  let geometry_rate = (summary.total -
    summary.high_residual -
    summary.round_trip_mismatch -
    summary.out_of_bounds).to_double() /
    summary.total.to_double()
  (finite_rate + texture_rate + geometry_rate) / 3.0
}

///|
pub fn finite(value : Double) -> Bool {
  !value.is_nan() && !value.is_inf()
}
