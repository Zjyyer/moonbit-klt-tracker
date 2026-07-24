///|
/// Escapes a string fragment according to JSON string rules.
pub fn escape_json_string(value : String) -> String {
  let output = StringBuilder()
  for character in value {
    match character {
      '"' => output.write_string("\\\"")
      '\\' => output.write_string("\\\\")
      '\u{0008}' => output.write_string("\\b")
      '\u{000C}' => output.write_string("\\f")
      '\n' => output.write_string("\\n")
      '\r' => output.write_string("\\r")
      '\t' => output.write_string("\\t")
      _ if character.is_control() => {
        let hexadecimal = character.to_int().to_string(radix=16)
        output.write_string("\\u")
        for _ in hexadecimal.length()..<4 {
          output.write_string("0")
        }
        output.write_string(hexadecimal)
      }
      _ => output.write_char(character)
    }
  }
  output.to_string()
}

///|
fn finite_number(value : Double) -> String {
  if value.is_nan() || value.is_inf() {
    panic()
  }
  value.to_string()
}

///|
fn anomaly_name(anomaly : TrackAnomaly) -> String {
  match anomaly {
    Normal => "normal"
    ExcessiveResidual => "excessive_residual"
    ExcessiveVelocity => "excessive_velocity"
  }
}

///|
fn event_name(event : LifecycleEvent) -> String {
  match event {
    Activated(..) => "activated"
    Lost(..) => "lost"
  }
}

///|
fn event_order(event : LifecycleEvent) -> Int {
  match event {
    Activated(..) => 0
    Lost(..) => 1
  }
}

///|
fn sorted_tracks(tracks : Array[TrackSummary]) -> Array[TrackSummary] {
  let ordered = tracks.copy()
  ordered.sort_by(fn(left, right) {
    if left.id < right.id {
      -1
    } else if left.id > right.id {
      1
    } else {
      0
    }
  })
  ordered
}

///|
fn event_id(event : LifecycleEvent) -> Int {
  match event {
    Activated(id~, ..) => id
    Lost(id~, ..) => id
  }
}

///|
fn event_frame(event : LifecycleEvent) -> Int {
  match event {
    Activated(frame~, ..) => frame
    Lost(frame~, ..) => frame
  }
}

///|
fn sorted_events(events : Array[LifecycleEvent]) -> Array[LifecycleEvent] {
  let ordered = events.copy()
  ordered.sort_by(fn(left, right) {
    let left_frame = event_frame(left)
    let right_frame = event_frame(right)
    let left_id = event_id(left)
    let right_id = event_id(right)
    if left_frame < right_frame {
      -1
    } else if left_frame > right_frame {
      1
    } else if left_id < right_id {
      -1
    } else if left_id > right_id {
      1
    } else if event_order(left) < event_order(right) {
      -1
    } else if event_order(left) > event_order(right) {
      1
    } else {
      0
    }
  })
  ordered
}

///|
fn write_track(output : StringBuilder, track : TrackSummary) -> Unit {
  output.write_string("{\"type\":\"track_summary\",\"id\":")
  output.write_object(track.id)
  output.write_string(",\"observation_count\":")
  output.write_object(track.observation_count)
  output.write_string(",\"active_count\":")
  output.write_object(track.active_count)
  output.write_string(",\"lost_count\":")
  output.write_object(track.lost_count)
  output.write_string(",\"displacement\":")
  output.write_string(finite_number(track.displacement))
  output.write_string(",\"mean_velocity\":")
  output.write_string(finite_number(track.mean_velocity))
  output.write_string(",\"rank\":")
  output.write_object(track.rank)
  output.write_string(",\"anomaly\":\"")
  output.write_string(escape_json_string(anomaly_name(track.anomaly)))
  output.write_string("\"}\n")
}

///|
fn write_event(output : StringBuilder, event : LifecycleEvent) -> Unit {
  output.write_string("{\"type\":\"event\",\"event\":\"")
  output.write_string(escape_json_string(event_name(event)))
  output.write_string("\",\"id\":")
  output.write_object(event_id(event))
  output.write_string(",\"frame\":")
  output.write_object(event_frame(event))
  output.write_string("}\n")
}

///|
/// Renders a stable NDJSON analytics report: schema header, tracks, then events.
///
/// Numeric fields are finite because `analyze` rejects non-finite derived values.
pub fn export_ndjson(analysis : SequenceAnalysis) -> String {
  let output = StringBuilder()
  output.write_string(
    "{\"type\":\"trajectory_analytics\",\"schema_version\":\"",
  )
  output.write_string(escape_json_string(@formats.schema_version()))
  output.write_string("\"}\n")
  for track in sorted_tracks(analysis.tracks) {
    write_track(output, track)
  }
  for event in sorted_events(analysis.events) {
    write_event(output, event)
  }
  output.to_string()
}
