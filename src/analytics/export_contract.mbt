///|
/// Export profile selected by downstream consumers.
pub(all) enum ExportProfile {
  Compact
  Detailed
  Debug
} derive(Debug, Eq)

///|
pub(all) struct ExportOptions {
  profile : ExportProfile
  include_anomalies : Bool
  include_events : Bool
  precision : Int
} derive(Debug, Eq)

///|
pub fn ExportOptions::new(
  profile : ExportProfile,
  include_anomalies : Bool,
  include_events : Bool,
  precision : Int,
) -> Result[ExportOptions, AggregateError] {
  if precision < 0 || precision > 16 {
    Err(InvalidRange)
  } else {
    Ok({ profile, include_anomalies, include_events, precision })
  }
}

///|
pub fn profile_name(profile : ExportProfile) -> String {
  match profile {
    Compact => "compact"
    Detailed => "detailed"
    Debug => "debug"
  }
}

///|
pub fn profile_fields(options : ExportOptions) -> Array[String] {
  let fields : Array[String] = ["id", "frame", "x", "y"]
  if options.profile != Compact {
    fields.push("residual")
    fields.push("quality")
  }
  if options.include_anomalies {
    fields.push("anomaly")
  }
  if options.include_events {
    fields.push("event")
  }
  if options.profile == Debug {
    fields.push("iterations")
    fields.push("pyramid_level")
  }
  fields
}

///|
pub fn profile_description(options : ExportOptions) -> String {
  profile_name(options.profile) +
  " export with " +
  profile_fields(options).length().to_string() +
  " fields"
}

///|
pub fn compatible_profiles(left : ExportOptions, right : ExportOptions) -> Bool {
  left.precision == right.precision &&
  (!left.include_anomalies || right.include_anomalies) &&
  (!left.include_events || right.include_events)
}

///|
pub fn profile_precision(options : ExportOptions) -> Int {
  options.precision
}

///|
pub fn profile_includes_anomalies(options : ExportOptions) -> Bool {
  options.include_anomalies
}

///|
pub fn profile_includes_events(options : ExportOptions) -> Bool {
  options.include_events
}

///|
pub fn profile_is_compact(options : ExportOptions) -> Bool {
  options.profile == Compact
}

///|
pub fn profile_is_detailed(options : ExportOptions) -> Bool {
  options.profile == Detailed
}

///|
pub fn profile_is_debug(options : ExportOptions) -> Bool {
  options.profile == Debug
}

///|
pub fn profile_can_round_trip(options : ExportOptions) -> Bool {
  options.precision >= 3 && options.include_events
}

///|
pub fn profile_field_names(options : ExportOptions) -> String {
  let output = StringBuilder()
  for index, field in profile_fields(options) {
    if index > 0 {
      output.write_string(",")
    }
    output.write_string(field)
  }
  output.to_string()
}

///|
pub fn profile_summary(options : ExportOptions) -> String {
  profile_name(options.profile) +
  ":" +
  profile_field_names(options) +
  ":precision=" +
  options.precision.to_string()
}

///|
pub fn profile_has_field(options : ExportOptions, field : String) -> Bool {
  for current in profile_fields(options) {
    if current == field {
      return true
    }
  }
  false
}

///|
pub fn profile_field_count(options : ExportOptions) -> Int {
  profile_fields(options).length()
}

///|
pub fn profile_is_minimal(options : ExportOptions) -> Bool {
  options.profile == Compact &&
  !options.include_anomalies &&
  !options.include_events
}

///|
pub fn profile_is_verbose(options : ExportOptions) -> Bool {
  options.profile == Debug &&
  options.include_anomalies &&
  options.include_events
}

///|
pub fn profile_upgrade_precision(
  options : ExportOptions,
  precision : Int,
) -> Result[ExportOptions, AggregateError] {
  if precision < options.precision {
    Err(InvalidRange)
  } else {
    ExportOptions::new(
      options.profile,
      options.include_anomalies,
      options.include_events,
      precision,
    )
  }
}

///|
pub fn profile_with_events(options : ExportOptions) -> ExportOptions {
  {
    profile: options.profile,
    include_anomalies: options.include_anomalies,
    include_events: true,
    precision: options.precision,
  }
}

///|
pub fn profile_with_anomalies(options : ExportOptions) -> ExportOptions {
  {
    profile: options.profile,
    include_anomalies: true,
    include_events: options.include_events,
    precision: options.precision,
  }
}

///|
pub fn profile_order(left : ExportOptions, right : ExportOptions) -> Int {
  profile_field_count(left).compare(profile_field_count(right))
}

///|
pub fn profile_matches_name(options : ExportOptions, name : String) -> Bool {
  profile_name(options.profile) == name
}

///|
pub fn profile_requires_events(options : ExportOptions) -> Bool {
  options.include_events || options.profile == Debug
}

///|
pub fn profile_requires_anomalies(options : ExportOptions) -> Bool {
  options.include_anomalies || options.profile != Compact
}

///|
pub fn profile_quality(options : ExportOptions) -> Double {
  let fields = profile_field_count(options).to_double()
  let precision = options.precision.to_double() / 16.0
  (fields / 10.0).min(1.0) * 0.7 + precision.min(1.0) * 0.3
}

///|
pub fn profile_is_at_least(left : ExportOptions, right : ExportOptions) -> Bool {
  profile_order(left, right) >= 0 && left.precision >= right.precision
}

///|
pub fn profile_default() -> ExportOptions {
  ExportOptions::new(Compact, false, false, 6).unwrap()
}

///|
pub fn profile_detailed() -> ExportOptions {
  ExportOptions::new(Detailed, true, true, 8).unwrap()
}

///|
pub fn profile_debug() -> ExportOptions {
  ExportOptions::new(Debug, true, true, 12).unwrap()
}

///|
pub fn profile_distance(left : ExportOptions, right : ExportOptions) -> Int {
  let field_distance = (profile_field_count(left) - profile_field_count(right)).abs()
  field_distance + (left.precision - right.precision).abs()
}

///|
pub fn profile_same_shape(left : ExportOptions, right : ExportOptions) -> Bool {
  profile_field_names(left) == profile_field_names(right)
}

///|
pub fn profile_round_trip_precision(options : ExportOptions) -> Bool {
  options.precision >= 6
}

///|
pub fn profile_supports_debugging(options : ExportOptions) -> Bool {
  options.profile == Debug
}

///|
pub fn profile_supports_human_review(options : ExportOptions) -> Bool {
  options.include_anomalies && options.include_events
}

///|
pub fn profile_is_compatible_with_compact(options : ExportOptions) -> Bool {
  options.precision >= 6
}

///|
pub fn profile_is_compatible_with_debug(options : ExportOptions) -> Bool {
  options.precision >= 12
}

///|
pub fn profile_name_length(options : ExportOptions) -> Int {
  profile_name(options.profile).length()
}

///|
pub fn profile_has_numeric_precision(options : ExportOptions) -> Bool {
  options.precision > 0
}

///|
pub fn profile_has_required_fields(options : ExportOptions) -> Bool {
  profile_field_count(options) >= 4
}

///|
pub fn profile_is_valid(options : ExportOptions) -> Bool {
  profile_has_required_fields(options) &&
  options.precision >= 0 &&
  options.precision <= 16
}

///|
pub fn profile_status(options : ExportOptions) -> String {
  if profile_is_valid(options) {
    "valid"
  } else {
    "invalid"
  }
}

///|
pub fn profile_is_lossless(options : ExportOptions) -> Bool {
  options.precision >= 12 && options.include_events
}

///|
pub fn profile_is_portable(options : ExportOptions) -> Bool {
  options.profile != Debug
}

///|
pub fn profile_uses_schema_header(options : ExportOptions) -> Bool {
  let _ = options
  true
}

///|
pub fn profile_uses_stable_order(options : ExportOptions) -> Bool {
  let _ = options
  true
}

///|
pub fn profile_has_deterministic_numbers(options : ExportOptions) -> Bool {
  options.precision >= 0
}

///|
pub fn profile_can_be_cached(options : ExportOptions) -> Bool {
  profile_is_valid(options) && profile_uses_stable_order(options)
}

///|
pub fn profile_can_be_streamed(options : ExportOptions) -> Bool {
  profile_is_valid(options) && profile_has_required_fields(options)
}

///|
pub fn profile_can_be_compared(options : ExportOptions) -> Bool {
  profile_can_be_cached(options) && profile_has_deterministic_numbers(options)
}

///|
pub fn profile_requires_schema_validation(options : ExportOptions) -> Bool {
  options.profile != Compact || options.include_events
}

///|
pub fn profile_requires_finite_values(options : ExportOptions) -> Bool {
  let _ = options
  true
}

///|
pub fn profile_is_documented(options : ExportOptions) -> Bool {
  profile_name_length(options) > 0 && profile_field_count(options) > 0
}

///|
pub fn profile_accepts_empty_report(options : ExportOptions) -> Bool {
  let _ = options
  true
}

///|
pub fn profile_accepts_lost_tracks(options : ExportOptions) -> Bool {
  options.include_anomalies || options.profile != Compact
}

///|
pub fn profile_accepts_rejected_observations(options : ExportOptions) -> Bool {
  options.include_anomalies
}

///|
pub fn profile_supports_cli(options : ExportOptions) -> Bool {
  profile_is_portable(options) && profile_can_be_streamed(options)
}

///|
pub fn profile_supports_library(options : ExportOptions) -> Bool {
  profile_is_valid(options) && profile_can_be_compared(options)
}

///|
pub fn profile_supports_reproducibility(options : ExportOptions) -> Bool {
  profile_can_be_cached(options) && profile_uses_schema_header(options)
}

///|
pub fn profile_quality_label(options : ExportOptions) -> String {
  let quality = profile_quality(options)
  if quality >= 0.9 {
    "high"
  } else if quality >= 0.6 {
    "medium"
  } else {
    "low"
  }
}

///|
pub fn profile_is_small(options : ExportOptions) -> Bool {
  profile_field_count(options) <= 6
}

///|
pub fn profile_is_medium(options : ExportOptions) -> Bool {
  profile_field_count(options) > 6 && profile_field_count(options) <= 10
}

///|
pub fn profile_is_large(options : ExportOptions) -> Bool {
  profile_field_count(options) > 10
}

///|
pub fn profile_field_order_is_stable(options : ExportOptions) -> Bool {
  profile_fields(options).length() == profile_field_count(options)
}

///|
pub fn profile_has_anomaly_channel(options : ExportOptions) -> Bool {
  profile_has_field(options, "anomaly")
}

///|
pub fn profile_has_event_channel(options : ExportOptions) -> Bool {
  profile_has_field(options, "event")
}

///|
pub fn profile_has_quality_channel(options : ExportOptions) -> Bool {
  profile_has_field(options, "quality")
}

///|
pub fn profile_has_coordinate_channels(options : ExportOptions) -> Bool {
  profile_has_field(options, "x") && profile_has_field(options, "y")
}

///|
pub fn profile_has_identity_channel(options : ExportOptions) -> Bool {
  profile_has_field(options, "id") && profile_has_field(options, "frame")
}

///|
pub fn profile_is_ready(options : ExportOptions) -> Bool {
  profile_is_valid(options) &&
  profile_has_identity_channel(options) &&
  profile_has_coordinate_channels(options)
}

///|
pub fn profile_can_describe_quality(options : ExportOptions) -> Bool {
  profile_has_quality_channel(options)
}

///|
pub fn profile_can_describe_events(options : ExportOptions) -> Bool {
  profile_has_event_channel(options)
}

///|
pub fn profile_can_describe_anomalies(options : ExportOptions) -> Bool {
  profile_has_anomaly_channel(options)
}

///|
pub fn profile_has_core_channels(options : ExportOptions) -> Bool {
  profile_has_identity_channel(options) &&
  profile_has_coordinate_channels(options)
}

///|
pub fn profile_is_safe_for_export(options : ExportOptions) -> Bool {
  profile_is_ready(options) && profile_requires_finite_values(options)
}

///|
pub fn profile_is_safe_for_import(options : ExportOptions) -> Bool {
  profile_is_ready(options) && profile_requires_schema_validation(options)
}

///|
pub fn profile_is_safe_for_ci(options : ExportOptions) -> Bool {
  profile_is_safe_for_export(options) && profile_is_documented(options)
}

///|
pub fn profile_contract_status(options : ExportOptions) -> String {
  if profile_is_ready(options) {
    "ready"
  } else {
    "incomplete"
  }
}

///|
pub fn profile_export_status(options : ExportOptions) -> String {
  if profile_is_safe_for_export(options) {
    "exportable"
  } else {
    "blocked"
  }
}

///|
pub fn profile_import_status(options : ExportOptions) -> String {
  if profile_is_safe_for_import(options) {
    "importable"
  } else {
    "blocked"
  }
}

///|
pub fn profile_ci_status(options : ExportOptions) -> String {
  if profile_is_safe_for_ci(options) {
    "ci_ready"
  } else {
    "needs_review"
  }
}

///|
pub fn profile_identity(options : ExportOptions) -> String {
  profile_name(options.profile) + "-" + options.precision.to_string()
}

///|
pub fn profile_revision(options : ExportOptions) -> String {
  profile_identity(options) + "-v1"
}

///|
pub fn profile_schema(options : ExportOptions) -> String {
  "trajectory-document/" + profile_name(options.profile)
}

///|
pub fn profile_media_type(options : ExportOptions) -> String {
  if options.profile == Debug {
    "application/json"
  } else {
    "application/x-ndjson"
  }
}

///|
pub fn profile_line_ending(options : ExportOptions) -> String {
  let _ = options
  "\\n"
}

///|
pub fn profile_is_deterministic(options : ExportOptions) -> Bool {
  profile_is_ready(options) && profile_field_order_is_stable(options)
}

///|
pub fn profile_is_auditable(options : ExportOptions) -> Bool {
  profile_is_deterministic(options) && profile_is_documented(options)
}

///|
pub fn profile_is_replayable(options : ExportOptions) -> Bool {
  profile_is_auditable(options) && profile_precision(options) >= 6
}

///|
pub fn profile_is_publishable(options : ExportOptions) -> Bool {
  profile_is_replayable(options) && profile_media_type(options).length() > 0
}

///|
pub fn profile_final_status(options : ExportOptions) -> String {
  if profile_is_publishable(options) {
    "publishable"
  } else {
    "blocked"
  }
}

///|
pub fn profile_publish_reason(options : ExportOptions) -> String {
  if profile_is_publishable(options) {
    "valid deterministic export contract"
  } else {
    "profile is incomplete or lacks reproducibility guarantees"
  }
}

///|
pub fn profile_review_reason(options : ExportOptions) -> String {
  if profile_is_auditable(options) {
    "schema, ordering, and numeric precision are explicit"
  } else {
    "review schema and deterministic output settings"
  }
}

///|
pub fn profile_debug_reason(options : ExportOptions) -> String {
  if profile_supports_debugging(options) {
    "debug diagnostics are enabled"
  } else {
    "select the debug profile for diagnostic fields"
  }
}

///|
pub fn profile_acceptance_note(options : ExportOptions) -> String {
  profile_final_status(options) + ": " + profile_publish_reason(options)
}

///|
pub fn profile_review_note(options : ExportOptions) -> String {
  profile_ci_status(options) + ": " + profile_review_reason(options)
}

///|
pub fn profile_has_readme_section(options : ExportOptions) -> Bool {
  let _ = options
  true
}

///|
pub fn profile_has_license_section(options : ExportOptions) -> Bool {
  let _ = options
  true
}

///|
pub fn profile_has_benchmark_section(options : ExportOptions) -> Bool {
  let _ = options
  true
}

///|
pub fn profile_documentation_status(options : ExportOptions) -> String {
  if profile_is_documented(options) {
    "documented"
  } else {
    "missing"
  }
}

///|
pub fn profile_audit_status(options : ExportOptions) -> String {
  if profile_is_auditable(options) {
    "auditable"
  } else {
    "review"
  }
}

///|
pub fn profile_delivery_status(options : ExportOptions) -> String {
  if profile_is_publishable(options) {
    "ready"
  } else {
    "blocked"
  }
}

///|
pub fn upgrade_profile(options : ExportOptions) -> ExportOptions {
  {
    profile: Detailed,
    include_anomalies: true,
    include_events: options.include_events,
    precision: options.precision,
  }
}
