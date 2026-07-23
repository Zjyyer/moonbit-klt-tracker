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
    Ok("tracked=1\nlost=2\nrejected=1\n"),
  )
}
