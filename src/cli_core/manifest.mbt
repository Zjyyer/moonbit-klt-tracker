///|
pub(all) struct ManifestFrame {
  index : Int
  width : Int
  height : Int
  pixels : Array[Byte]
} derive(Debug, Eq)

///|
pub(all) struct FrameManifest {
  frames : Array[ManifestFrame]
} derive(Debug, Eq)

///|
/// Returns the frame extent in the same coordinate system used by tracking.
pub fn ManifestFrame::extent(self : ManifestFrame) -> @math.Vec2 {
  { x: self.width.to_double(), y: self.height.to_double() }
}

///|
pub(all) enum ManifestError {
  InvalidJson
  InvalidShape
  InvalidPixel(index~ : Int)
  DuplicateFrameIndex(index~ : Int)
  DimensionMismatch(index~ : Int)
} derive(Debug, Eq)

///|
fn int_value(value : Json) -> Int? {
  match value {
    Number(number, ..) if number == number && number == number.floor() =>
      Some(number.to_int())
    _ => None
  }
}

///|
fn frame_from_json(value : Json) -> Result[ManifestFrame, ManifestError] {
  guard value is Object(object) else { return Err(InvalidShape) }
  guard object.get("index") is Some(index_value) else {
    return Err(InvalidShape)
  }
  guard object.get("width") is Some(width_value) else {
    return Err(InvalidShape)
  }
  guard object.get("height") is Some(height_value) else {
    return Err(InvalidShape)
  }
  guard object.get("pixels") is Some(pixels_value) else {
    return Err(InvalidShape)
  }
  guard int_value(index_value) is Some(index) else { return Err(InvalidShape) }
  guard int_value(width_value) is Some(width) else { return Err(InvalidShape) }
  guard int_value(height_value) is Some(height) else {
    return Err(InvalidShape)
  }
  guard pixels_value is Array(pixel_values) else { return Err(InvalidShape) }
  if width <= 0 ||
    height <= 0 ||
    width > 2147483647 / height ||
    pixel_values.length() != width * height {
    return Err(InvalidShape)
  }
  let pixels : Array[Byte] = []
  for pixel_value in pixel_values {
    guard int_value(pixel_value) is Some(pixel) && pixel >= 0 && pixel <= 255 else {
      return Err(InvalidPixel(index~))
    }
    pixels.push(pixel.to_byte())
  }
  Ok({ index, width, height, pixels })
}

///|
pub fn parse_manifest(text : String) -> Result[FrameManifest, ManifestError] {
  if !@json.valid(text) {
    return Err(InvalidJson)
  }
  let json = @json.parse(text) catch { _ => return Err(InvalidJson) }
  guard json is Object(root) else { return Err(InvalidShape) }
  guard root.get("frames") is Some(Array(values)) else {
    return Err(InvalidShape)
  }
  let frames : Array[ManifestFrame] = []
  let mut common_width : Int? = None
  let mut common_height : Int? = None
  for value in values {
    let frame = match frame_from_json(value) {
      Ok(frame) => frame
      Err(error) => return Err(error)
    }
    for earlier in frames {
      if earlier.index == frame.index {
        return Err(DuplicateFrameIndex(index=frame.index))
      }
    }
    match (common_width, common_height) {
      (None, None) => {
        common_width = Some(frame.width)
        common_height = Some(frame.height)
      }
      (Some(width), Some(height)) if width == frame.width &&
        height == frame.height => ()
      _ => return Err(DimensionMismatch(index=frame.index))
    }
    frames.push(frame)
  }
  Ok({ frames, })
}
