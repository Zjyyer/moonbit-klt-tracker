///|
/// Human-readable gate explanation assembled from typed analytics values.
pub(all) struct GateExplanation {
  title : String
  status : String
  headline : String
  details : Array[String]
} derive(Debug)

///|
pub fn explain_gate(result : @validation.GateResult) -> GateExplanation {
  let status = if result.passed_gate { "pass" } else { "fail" }
  let details : Array[String] = []
  details.push("total=" + result.total.to_string())
  details.push("passed=" + result.passed.to_string())
  details.push("failed=" + result.failed.to_string())
  details.push("acceptance_rate=" + result.acceptance_rate.to_string())
  if result.texture_failures > 0 {
    details.push("texture_failures=" + result.texture_failures.to_string())
  }
  if result.residual_failures > 0 {
    details.push("residual_failures=" + result.residual_failures.to_string())
  }
  if result.velocity_failures > 0 {
    details.push("velocity_failures=" + result.velocity_failures.to_string())
  }
  if result.round_trip_failures > 0 {
    details.push(
      "round_trip_failures=" + result.round_trip_failures.to_string(),
    )
  }
  {
    title: "tracking validation",
    status,
    headline: if result.passed_gate {
      "measurements satisfy configured thresholds"
    } else {
      "measurements need review"
    },
    details,
  }
}

///|
pub fn explanation_text(value : GateExplanation) -> String {
  let output = StringBuilder()
  output.write_string(value.title)
  output.write_string(" [")
  output.write_string(value.status)
  output.write_string("] ")
  output.write_string(value.headline)
  for detail in value.details {
    output.write_string("; ")
    output.write_string(detail)
  }
  output.to_string()
}

///|
pub fn explanation_is_success(value : GateExplanation) -> Bool {
  value.status == "pass"
}
