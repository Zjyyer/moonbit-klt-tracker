///|
pub(all) enum CommandError {
  Usage
  Manifest
  Configuration
  Input
} derive(Debug, Eq)

///|
/// Renders the requested deterministic command result.  File access is kept at
/// the embedding boundary so the core command flow works on every MoonBit target.
pub fn run_command(
  command : String,
  document : @formats.TrajectoryDocument,
) -> Result[String, CommandError] {
  match command {
    "detect" => Ok("detected=" + document.tracks.length().to_string() + "\n")
    "track" => Ok(@formats.export_json(document))
    "inspect" => Ok(render_report(document))
    _ => Err(Usage)
  }
}

///|
pub fn run_command_as_csv(
  command : String,
  document : @formats.TrajectoryDocument,
) -> Result[String, CommandError] {
  match command {
    "track" => Ok(@formats.export_csv(document))
    "detect" | "inspect" => run_command(command, document)
    _ => Err(Usage)
  }
}
