///|
fn observation(target_x : Double, target_y : Double) -> @klt.KltObservation {
  {
    source: @math.Vec2::{ x: 0.0, y: 0.0 },
    target: @math.Vec2::{ x: target_x, y: target_y },
    displacement: @math.Vec2::{ x: target_x, y: target_y },
    residual: 0.25,
    minimum_eigenvalue: 2.0,
    iterations: 3,
    pyramid_level: 0,
    forward_backward_error: 0.125,
    status: @klt.Tracked,
  }
}

///|
fn track(id : Int) -> @tracking.Track {
  {
    id,
    seed: { position: @math.Vec2::{ x: 0.0, y: 0.0 }, score: 1.0 },
    position: @math.Vec2::{ x: 0.0, y: 0.0 },
    state: @tracking.Active,
    consecutive_losses: 0,
    observations: [],
  }
}

///|
fn report(frame_index : Int, id : Int, x : Double, y : Double) -> @tracking.FrameReport {
  {
    frame_index,
    observations: [{ id, state: @tracking.Active, observation: observation(x, y) }],
  }
}

///|
test "JSON export is versioned and orders rows by track ID then frame" {
  let document = TrajectoryDocument::new(
    [track(2), track(1)],
    [report(4, 2, 20.0, 21.0), report(3, 1, 10.0, 11.0)],
  )
  assert_eq(
    export_json(document),
    "{\"schema_version\":\"1.0\",\"tracks\":[{\"id\":1,\"frame\":3,\"state\":\"active\",\"x\":10,\"y\":11},{\"id\":2,\"frame\":4,\"state\":\"active\",\"x\":20,\"y\":21}]}",
  )
}

///|
test "CSV export uses a stable header and is byte-identical across renderings" {
  let document = TrajectoryDocument::new(
    [track(2), track(1)],
    [report(4, 2, 20.0, 21.0), report(3, 1, 10.0, 11.0)],
  )
  let expected = "schema_version,track_id,frame,state,x,y\n1.0,1,3,active,10,11\n1.0,2,4,active,20,21\n"
  assert_eq(export_csv(document), expected)
  assert_eq(export_csv(document), export_csv(document))
}

///|
test "JSON export orders extreme track IDs and frames without integer overflow" {
  let smallest = -2147483648
  let largest = 2147483647
  let document = TrajectoryDocument::new([track(largest), track(smallest)], [
    report(largest, largest, 30.0, 31.0),
    report(smallest, largest, 20.0, 21.0),
    report(largest, smallest, 10.0, 11.0),
  ])
  assert_eq(
    export_json(document),
    "{\"schema_version\":\"1.0\",\"tracks\":[{\"id\":-2147483648,\"frame\":2147483647,\"state\":\"active\",\"x\":10,\"y\":11},{\"id\":2147483647,\"frame\":-2147483648,\"state\":\"active\",\"x\":20,\"y\":21},{\"id\":2147483647,\"frame\":2147483647,\"state\":\"active\",\"x\":30,\"y\":31}]}",
  )
}
