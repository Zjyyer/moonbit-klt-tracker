///|
pub(all) enum CommandError {
  Usage
  Manifest
  Configuration
  Input
} derive(Debug, Eq)

///|
pub(all) struct CliRequest {
  command : String
  manifest_path : String
  json_path : String?
  csv_path : String?
} derive(Debug)

///|
pub(all) struct CliResult {
  exit_code : Int
  stdout : String
  json : String?
  csv : String?
} derive(Debug)

///|
const USAGE_EXIT = 2

///|
const MANIFEST_EXIT = 3

///|
const CONFIGURATION_EXIT = 4

///|
const INPUT_EXIT = 5

///|
fn cli_result(
  exit_code : Int,
  stdout : String,
  json : String?,
  csv : String?,
) -> CliResult {
  { exit_code, stdout, json, csv }
}

///|
pub fn parse_request(args : Array[String]) -> Result[CliRequest, CommandError] {
  if args.length() == 0 {
    return Err(Usage)
  }
  let command = args[0]
  if command != "detect" && command != "track" && command != "inspect" {
    return Err(Usage)
  }
  let mut manifest_path : String? = None
  let mut json_path : String? = None
  let mut csv_path : String? = None
  let mut index = 1
  while index < args.length() {
    if index + 1 >= args.length() {
      return Err(Usage)
    }
    let flag = args[index]
    let value = args[index + 1]
    match flag {
      "--manifest" if manifest_path is None => manifest_path = Some(value)
      "--json" if json_path is None => json_path = Some(value)
      "--csv" if csv_path is None => csv_path = Some(value)
      _ => return Err(Usage)
    }
    index = index + 2
  }
  guard manifest_path is Some(manifest_path) else { return Err(Usage) }
  if command == "track" && json_path is None && csv_path is None {
    return Err(Usage)
  }
  if command != "track" && (json_path is Some(_) || csv_path is Some(_)) {
    return Err(Usage)
  }
  Ok({ command, manifest_path, json_path, csv_path })
}

///|
fn default_tracker_config() -> @tracking.TrackerConfig {
  {
    klt_config: {
      window_size: 3,
      max_iterations: 12,
      update_epsilon: 0.0001,
      minimum_eigenvalue: 1.0,
    },
    pyramid_levels: 1,
    max_consecutive_losses: 2,
    redetection_interval: 0,
    feature_config: {
      window_size: 3,
      minimum_score: 1.0,
      max_features: 20,
      suppression_radius: 3.0,
    },
  }
}

///|
fn manifest_frames(manifest : FrameManifest) -> Result[Array[@image.GrayFrame], CommandError] {
  let frames : Array[@image.GrayFrame] = []
  for source in manifest.frames {
    match @image.GrayFrame::new(source.width, source.height, source.pixels) {
      Ok(frame) => frames.push(frame)
      Err(_) => return Err(Input)
    }
  }
  if frames.length() == 0 {
    Err(Configuration)
  } else {
    Ok(frames)
  }
}

///|
fn document_for(manifest : FrameManifest) -> Result[@formats.TrajectoryDocument, CommandError] {
  let frames = match manifest_frames(manifest) {
    Ok(frames) => frames
    Err(error) => return Err(error)
  }
  let seeds = match @features.detect_shi_tomasi(frames[0], default_tracker_config().feature_config) {
    Ok(seeds) => seeds
    Err(_) => return Err(Configuration)
  }
  let tracker = match @tracking.Tracker::start(default_tracker_config(), frames[0], seeds) {
    Ok(tracker) => tracker
    Err(_) => return Err(Configuration)
  }
  let reports : Array[@tracking.FrameReport] = []
  for index in 1..<frames.length() {
    match tracker.step(frames[index]) {
      Ok(report) => reports.push(report)
      Err(_) => return Err(Configuration)
    }
  }
  Ok(@formats.TrajectoryDocument::new(tracker.tracks(), reports))
}

///|
/// Executes a fully parsed command with the manifest text supplied by the host.
/// Hosts own filesystem access: `manifest_path`, `json_path`, and `csv_path`
/// identify the only permitted input/output paths.
pub fn run_cli(args : Array[String], manifest_text : String) -> CliResult {
  let request = match parse_request(args) {
    Ok(request) => request
    Err(_) => return cli_result(USAGE_EXIT, "usage error\n", None, None)
  }
  let manifest = match parse_manifest(manifest_text) {
    Ok(manifest) => manifest
    Err(_) => return cli_result(MANIFEST_EXIT, "manifest error\n", None, None)
  }
  let document = match document_for(manifest) {
    Ok(document) => document
    Err(Configuration) => return cli_result(CONFIGURATION_EXIT, "configuration error\n", None, None)
    Err(_) => return cli_result(INPUT_EXIT, "input error\n", None, None)
  }
  match request.command {
    "detect" => cli_result(
      0,
      "detected=" + document.tracks.length().to_string() + "\n",
      None,
      None,
    )
    "track" => {
      let json = match request.json_path {
        Some(_) => Some(@formats.export_json(document))
        None => None
      }
      let csv = match request.csv_path {
        Some(_) => Some(@formats.export_csv(document))
        None => None
      }
      cli_result(0, render_report(document), json, csv)
    }
    "inspect" => cli_result(0, render_report(document), None, None)
    _ => cli_result(USAGE_EXIT, "usage error\n", None, None)
  }
}

///|
/// Native file boundary for the command line program. It reads exactly the
/// requested manifest and writes JSON/CSV only to the requested output paths.
pub fn run_cli_from_files(args : Array[String]) -> Int {
  let request = match parse_request(args) {
    Ok(request) => request
    Err(_) => {
      println("usage error")
      return USAGE_EXIT
    }
  }
  let manifest_text = @fs.read_file_to_string(request.manifest_path) catch {
    _ => {
      println("input error")
      return INPUT_EXIT
    }
  }
  let result = run_cli(args, manifest_text)
  if result.exit_code != 0 {
    println(result.stdout)
    return result.exit_code
  }
  match (request.json_path, result.json) {
    (Some(path), Some(json)) => @fs.write_string_to_file(path, json + "\n") catch {
      _ => {
        println("input error")
        return INPUT_EXIT
      }
    }
    _ => ()
  }
  match (request.csv_path, result.csv) {
    (Some(path), Some(csv)) => @fs.write_string_to_file(path, csv) catch {
      _ => {
        println("input error")
        return INPUT_EXIT
      }
    }
    _ => ()
  }
  println(result.stdout)
  0
}

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
