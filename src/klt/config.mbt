///|
/// Per-observation outcome for the single-level solver.
pub(all) enum KltStatus {
  /// The local iteration produced a finite displacement.
  Tracked
  /// The source window lacks enough two-dimensional texture or configuration is invalid.
  Rejected
  /// The source or warped target window cannot be sampled completely.
  OutOfBounds
} derive(Debug, Eq)

///|
/// Deterministic controls for one Lucas-Kanade image level.
pub(all) struct KltConfig {
  /// Odd side length of the square sample window.
  window_size : Int
  /// Maximum number of local displacement updates.
  max_iterations : Int
  /// Iteration stops when the Euclidean update norm is at most this value.
  update_epsilon : Double
  /// Lower bound on the smaller eigenvalue of the gradient matrix.
  minimum_eigenvalue : Double
} derive(Debug)

///|
/// Diagnostics for one attempted feature observation at pyramid level zero.
///
/// `residual` is the RMS temporal residual from the most recent complete
/// window evaluation. `minimum_eigenvalue` is the smaller eigenvalue of the
/// fixed source-image gradient matrix. Bounds and conditioning failures retain
/// these diagnostics when they are available; unavailable values are zero.
pub(all) struct KltObservation {
  source : @math.Vec2
  target : @math.Vec2
  displacement : @math.Vec2
  residual : Double
  minimum_eigenvalue : Double
  iterations : Int
  pyramid_level : Int
  forward_backward_error : Double
  status : KltStatus
} derive(Debug)
