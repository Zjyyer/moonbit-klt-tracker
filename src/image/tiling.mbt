///|
/// A rectangular image tile descriptor.
pub(all) struct Tile {
  index : Int
  left : Int
  top : Int
  width : Int
  height : Int
} derive(Debug, Eq)

///|
pub fn tiles(
  width : Int,
  height : Int,
  tile_width : Int,
  tile_height : Int,
) -> Array[Tile] {
  let result : Array[Tile] = []
  if width <= 0 || height <= 0 || tile_width <= 0 || tile_height <= 0 {
    return result
  }
  let mut index = 0
  for top in 0..<height {
    if top % tile_height != 0 {
      continue
    }
    for left in 0..<width {
      if left % tile_width != 0 {
        continue
      }
      result.push({
        index,
        left,
        top,
        width: tile_width.min(width - left),
        height: tile_height.min(height - top),
      })
      index += 1
    }
  }
  result
}

///|
pub fn tile_for_point(tile_list : Array[Tile], x : Int, y : Int) -> Tile? {
  for tile in tile_list {
    if x >= tile.left &&
      y >= tile.top &&
      x < tile.left + tile.width &&
      y < tile.top + tile.height {
      return Some(tile)
    }
  }
  None
}

///|
pub fn tile_mean(frame : GrayFrame, tile : Tile) -> Double {
  let mut sum = 0.0
  for y in tile.top..<(tile.top + tile.height) {
    for x in tile.left..<(tile.left + tile.width) {
      sum += frame.pixels[y * frame.width + x].to_double()
    }
  }
  sum / (tile.width * tile.height).to_double()
}

///|
pub fn tile_contrast(frame : GrayFrame, tile : Tile) -> Double {
  let mean = tile_mean(frame, tile)
  let mut sum = 0.0
  for y in tile.top..<(tile.top + tile.height) {
    for x in tile.left..<(tile.left + tile.width) {
      let delta = frame.pixels[y * frame.width + x].to_double() - mean
      sum += delta * delta
    }
  }
  (sum / (tile.width * tile.height).to_double()).sqrt()
}

///|
pub fn tile_quality(
  frame : GrayFrame,
  tile : Tile,
  minimum_contrast : Double,
) -> Bool {
  tile_contrast(frame, tile) >= minimum_contrast
}

///|
pub fn tile_count(
  width : Int,
  height : Int,
  tile_width : Int,
  tile_height : Int,
) -> Int {
  tiles(width, height, tile_width, tile_height).length()
}

///|
pub fn tile_area(tile : Tile) -> Int {
  tile.width * tile.height
}

///|
pub fn tile_center(tile : Tile) -> @math.Vec2 {
  {
    x: tile.left.to_double() + tile.width.to_double() / 2.0,
    y: tile.top.to_double() + tile.height.to_double() / 2.0,
  }
}

///|
pub fn tiles_cover_area(
  tile_list : Array[Tile],
  width : Int,
  height : Int,
) -> Int {
  let mut area = 0
  for tile in tile_list {
    area += tile_area(tile)
  }
  if area > width * height {
    width * height
  } else {
    area
  }
}

///|
pub fn tile_neighbors(tile_list : Array[Tile], tile : Tile) -> Array[Tile] {
  let result : Array[Tile] = []
  for candidate in tile_list {
    if candidate.index != tile.index &&
      (
        candidate.left == tile.left + tile.width ||
        candidate.left + candidate.width == tile.left ||
        candidate.top == tile.top + tile.height ||
        candidate.top + candidate.height == tile.top
      ) {
      result.push(candidate)
    }
  }
  result
}
