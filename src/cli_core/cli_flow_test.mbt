///|
fn observation(
  status : @klt.KltStatus,
  x : Double,
  y : Double,
) -> @klt.KltObservation {
  {
    source: @math.Vec2::{ x: 0.0, y: 0.0 },
    target: @math.Vec2::{ x, y },
    displacement: @math.Vec2::{ x, y },
    residual: 0.0,
    minimum_eigenvalue: 1.0,
    iterations: 1,
    pyramid_level: 0,
    forward_backward_error: 0.0,
    status,
  }
}

///|
fn report(
  frame : Int,
  state : @tracking.TrackState,
  status : @klt.KltStatus,
) -> @tracking.FrameReport {
  {
    frame_index: frame,
    observations: [{ id: 0, state, observation: observation(status, 2.0, 3.0) }],
  }
}

///|
test "manifest preserves the listed frame order" {
  // Frame order is part of the CLI manifest contract.
  let manifest = parse_manifest(
    "{\"frames\":[{\"index\":4,\"width\":2,\"height\":2,\"pixels\":[1,2,3,4]},{\"index\":1,\"width\":2,\"height\":2,\"pixels\":[5,6,7,8]}]}",
  ).unwrap()
  assert_eq(manifest.frames.length(), 2)
  assert_eq(manifest.frames[0].index, 4)
  assert_eq(manifest.frames[1].index, 1)
}

///|
test "manifest rejects duplicate frame indexes with a stable error" {
  let result = parse_manifest(
    "{\"frames\":[{\"index\":1,\"width\":1,\"height\":1,\"pixels\":[0]},{\"index\":1,\"width\":1,\"height\":1,\"pixels\":[0]}]}",
  )
  assert_eq(result, Err(DuplicateFrameIndex(index=1)))
}

///|
test "manifest rejects mismatched dimensions with a stable error" {
  let result = parse_manifest(
    "{\"frames\":[{\"index\":1,\"width\":2,\"height\":2,\"pixels\":[0,0,0,0]},{\"index\":2,\"width\":3,\"height\":2,\"pixels\":[0,0,0,0,0,0]}]}",
  )
  assert_eq(result, Err(DimensionMismatch(index=2)))
}

///|
test "track renders versioned JSON deterministically" {
  let document = @formats.TrajectoryDocument::new([], [
    report(1, @tracking.Active, @klt.Tracked),
  ])
  assert_eq(
    run_command("track", document),
    Ok(
      "{\"schema_version\":\"1.0\",\"tracks\":[{\"id\":0,\"frame\":1,\"state\":\"active\",\"x\":2,\"y\":3}]}",
    ),
  )
}

///|
test "inspect reports tracked lost and rejected counts in a fixed order" {
  let document = @formats.TrajectoryDocument::new([], [
    report(2, @tracking.Lost, @klt.OutOfBounds),
    report(1, @tracking.Active, @klt.Tracked),
    report(3, @tracking.Lost, @klt.Rejected),
  ])
  assert_eq(
    run_command("inspect", document),
    Ok("tracked=1\nlost=1\nrejected=1\n"),
  )
}

///|
test "CLI parses required manifest and requested output paths" {
  let request = parse_request([
    "track", "--manifest", "translation.json", "--json", "result.json", "--csv",
    "result.csv",
  ]).unwrap()
  assert_eq(request.command, "track")
  assert_eq(request.manifest_path, "translation.json")
  assert_eq(request.json_path, Some("result.json"))
  assert_eq(request.csv_path, Some("result.csv"))
}

///|
test "entrypoint drops the process executable from command arguments" {
  assert_eq(
    command_args(["klt-tracker", "inspect", "--manifest", "frames.json"]),
    ["inspect", "--manifest", "frames.json"],
  )
}

///|
test "CLI uses a distinct usage exit code for missing track outputs" {
  let result = run_cli(
    ["track", "--manifest", "translation.json"],
    "{\"frames\":[]}",
  )
  assert_eq(result.exit_code, 2)
}

///|
test "CLI gives manifest and configuration failures distinct exit codes" {
  let invalid = run_cli(["inspect", "--manifest", "invalid.json"], "{")
  let empty = run_cli(
    ["inspect", "--manifest", "empty.json"],
    "{\"frames\":[]}",
  )
  assert_eq(invalid.exit_code, 3)
  assert_eq(empty.exit_code, 4)
}

///|
test "CLI track runs the real detector and engine for a manifest" {
  let manifest = "{\"frames\":[{\"index\":0,\"width\":3,\"height\":3,\"pixels\":[0,32,64,32,96,128,64,128,255]},{\"index\":1,\"width\":3,\"height\":3,\"pixels\":[0,0,32,32,64,96,64,128,255]}]}"
  let result = run_cli(
    [
      "track", "--manifest", "translation.json", "--json", "translation-output.json",
    ],
    manifest,
  )
  assert_eq(result.exit_code, 0)
  assert_eq(
    result.json,
    Some(
      "{\"schema_version\":\"1.0\",\"tracks\":[{\"id\":0,\"frame\":1,\"state\":\"lost\",\"x\":1.1422484407611613,\"y\":1.3425589614995106}]}",
    ),
  )
  assert_eq(result.stdout, "tracked=0\nlost=1\nrejected=0\n")
}

///|
test "detect and inspect execute the manifest pipeline without output files" {
  let manifest = "{\"frames\":[{\"index\":0,\"width\":3,\"height\":3,\"pixels\":[0,32,64,32,96,128,64,128,255]},{\"index\":1,\"width\":3,\"height\":3,\"pixels\":[0,0,32,32,64,96,64,128,255]}]}"
  let detected = run_cli(["detect", "--manifest", "translation.json"], manifest)
  let inspected = run_cli(
    ["inspect", "--manifest", "translation.json"],
    manifest,
  )
  assert_eq(detected.exit_code, 0)
  assert_eq(detected.stdout, "detected=1\n")
  assert_eq(inspected.exit_code, 0)
  assert_eq(inspected.stdout, "tracked=0\nlost=1\nrejected=0\n")
}

///|
test "CLI occlusion fixture emits a byte-stable golden JSON result" {
  let manifest = "{\"frames\":[{\"index\":0,\"width\":3,\"height\":3,\"pixels\":[0,32,64,32,96,128,64,128,255]},{\"index\":1,\"width\":3,\"height\":3,\"pixels\":[0,0,0,0,0,0,0,0,0]}]}"
  let result = run_cli(
    ["track", "--manifest", "occlusion.json", "--json", "occlusion-output.json"],
    manifest,
  )
  assert_eq(result.exit_code, 0)
  assert_eq(
    result.json,
    Some(
      "{\"schema_version\":\"1.0\",\"tracks\":[{\"id\":0,\"frame\":1,\"state\":\"lost\",\"x\":2.2103916351742954,\"y\":2.2103916351742954}]}",
    ),
  )
}

///|
test "native CLI flow reads a manifest and writes only requested result paths" {
  let output = "tests/fixtures/translation/cli-golden-output.json"
  @fs.remove_file(output) catch {
    _ => ()
  }
  let exit_code = run_cli_from_files([
    "track", "--manifest", "tests/fixtures/translation/manifest.json", "--json",
    output,
  ])
  assert_eq(exit_code, 0)
  assert_eq(
    @fs.read_file_to_string(output),
    @fs.read_file_to_string("tests/fixtures/translation/expected.json"),
  )
  @fs.remove_file(output)
}

///|
test "native CLI flow matches the checked-in occlusion golden output" {
  let output = "tests/fixtures/occlusion/cli-golden-output.json"
  @fs.remove_file(output) catch {
    _ => ()
  }
  let exit_code = run_cli_from_files([
    "track", "--manifest", "tests/fixtures/occlusion/manifest.json", "--json", output,
  ])
  assert_eq(exit_code, 0)
  assert_eq(
    @fs.read_file_to_string(output),
    @fs.read_file_to_string("tests/fixtures/occlusion/expected.json"),
  )
  @fs.remove_file(output)
}
