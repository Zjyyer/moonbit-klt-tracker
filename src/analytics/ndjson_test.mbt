///|
test "NDJSON export starts with a schema header and has byte-stable output" {
  let analysis : SequenceAnalysis = {
    tracks: [
      {
        id: 2,
        observation_count: 2,
        active_count: 1,
        lost_count: 1,
        displacement: 5.0,
        mean_velocity: 2.5,
        rank: 1,
        anomaly: ExcessiveVelocity,
      },
      {
        id: 1,
        observation_count: 1,
        active_count: 1,
        lost_count: 0,
        displacement: 1.0,
        mean_velocity: 1.0,
        rank: 2,
        anomaly: Normal,
      },
    ],
    quality: {
      observation_count: 3,
      active_count: 2,
      lost_count: 1,
      rejected_count: 0,
      out_of_bounds_count: 0,
    },
    events: [Lost(id=2, frame=3), Activated(id=1, frame=1)],
  }
  let expected =
    #|{"type":"trajectory_analytics","schema_version":"1.0"}
    #|{"type":"track_summary","id":1,"observation_count":1,"active_count":1,"lost_count":0,"displacement":1,"mean_velocity":1,"rank":2,"anomaly":"normal"}
    #|{"type":"track_summary","id":2,"observation_count":2,"active_count":1,"lost_count":1,"displacement":5,"mean_velocity":2.5,"rank":1,"anomaly":"excessive_velocity"}
    #|{"type":"event","event":"activated","id":1,"frame":1}
    #|{"type":"event","event":"lost","id":2,"frame":3}
    #|
  assert_eq(export_ndjson(analysis), expected)
  assert_eq(export_ndjson(analysis), export_ndjson(analysis))
}

///|
test "NDJSON export escapes JSON strings without altering Unicode" {
  assert_eq(
    escape_json_string(
      "quote: \" slash: \\ newline:\n tab:\t\u{0008}\u{000C} 中",
    ),
    "quote: \\\" slash: \\\\ newline:\\n tab:\\t\\b\\f 中",
  )
}

///|
test "NDJSON export orders equal-frame events by track ID then event type" {
  let analysis : SequenceAnalysis = {
    tracks: [],
    quality: {
      observation_count: 0,
      active_count: 0,
      lost_count: 0,
      rejected_count: 0,
      out_of_bounds_count: 0,
    },
    events: [Lost(id=7, frame=4), Lost(id=3, frame=4), Activated(id=7, frame=4)],
  }
  let expected =
    #|{"type":"trajectory_analytics","schema_version":"1.0"}
    #|{"type":"event","event":"lost","id":3,"frame":4}
    #|{"type":"event","event":"activated","id":7,"frame":4}
    #|{"type":"event","event":"lost","id":7,"frame":4}
    #|
  assert_eq(export_ndjson(analysis), expected)
}

///|
test "NDJSON export preserves the input track and event array orders" {
  let tracks : Array[TrackSummary] = [
    {
      id: 9,
      observation_count: 1,
      active_count: 1,
      lost_count: 0,
      displacement: 9.0,
      mean_velocity: 9.0,
      rank: 1,
      anomaly: Normal,
    },
    {
      id: 2,
      observation_count: 1,
      active_count: 1,
      lost_count: 0,
      displacement: 2.0,
      mean_velocity: 2.0,
      rank: 2,
      anomaly: Normal,
    },
  ]
  let events : Array[LifecycleEvent] = [
    Lost(id=9, frame=2),
    Activated(id=2, frame=1),
  ]
  let analysis : SequenceAnalysis = {
    tracks,
    quality: {
      observation_count: 2,
      active_count: 1,
      lost_count: 1,
      rejected_count: 0,
      out_of_bounds_count: 0,
    },
    events,
  }
  ignore(export_ndjson(analysis))
  assert_eq(tracks.map(fn(track) { track.id }), [9, 2])
  assert_eq(events, [Lost(id=9, frame=2), Activated(id=2, frame=1)])
}

///|
test "panic NDJSON export rejects constructed non-finite metrics" {
  let analysis : SequenceAnalysis = {
    tracks: [
      {
        id: 1,
        observation_count: 1,
        active_count: 1,
        lost_count: 0,
        displacement: 0.0 / 0.0,
        mean_velocity: 1.0,
        rank: 1,
        anomaly: Normal,
      },
    ],
    quality: {
      observation_count: 1,
      active_count: 1,
      lost_count: 0,
      rejected_count: 0,
      out_of_bounds_count: 0,
    },
    events: [],
  }
  ignore(export_ndjson(analysis))
}
