///|
/// A connected bright region descriptor for lightweight image diagnostics.
pub(all) struct BrightRegion {
  minimum_x : Int
  minimum_y : Int
  maximum_x : Int
  maximum_y : Int
  area : Int
  mean_intensity : Double
} derive(Debug)

///|
pub fn bright_regions(
  frame : GrayFrame,
  threshold : Double,
) -> Array[BrightRegion] {
  let regions : Array[BrightRegion] = []
  if threshold.is_nan() || threshold.is_inf() {
    return regions
  }
  let visited : Array[Bool] = []
  for _ in frame.pixels {
    visited.push(false)
  }
  for y in 0..<frame.height {
    for x in 0..<frame.width {
      let index = y * frame.width + x
      if visited[index] || frame.pixels[index].to_double() < threshold {
        continue
      }
      let queue : Array[Int] = [index]
      visited[index] = true
      let mut cursor = 0
      let mut min_x = x
      let mut min_y = y
      let mut max_x = x
      let mut max_y = y
      let mut intensity = 0.0
      while cursor < queue.length() {
        let current = queue[cursor]
        cursor += 1
        let current_x = current % frame.width
        let current_y = current / frame.width
        min_x = min_x.min(current_x)
        min_y = min_y.min(current_y)
        max_x = max_x.max(current_x)
        max_y = max_y.max(current_y)
        intensity += frame.pixels[current].to_double()
        add_neighbor(queue, visited, frame, current_x - 1, current_y, threshold)
        add_neighbor(queue, visited, frame, current_x + 1, current_y, threshold)
        add_neighbor(queue, visited, frame, current_x, current_y - 1, threshold)
        add_neighbor(queue, visited, frame, current_x, current_y + 1, threshold)
      }
      regions.push({
        minimum_x: min_x,
        minimum_y: min_y,
        maximum_x: max_x,
        maximum_y: max_y,
        area: queue.length(),
        mean_intensity: intensity / queue.length().to_double(),
      })
    }
  }
  regions
}

///|
fn add_neighbor(
  queue : Array[Int],
  visited : Array[Bool],
  frame : GrayFrame,
  x : Int,
  y : Int,
  threshold : Double,
) -> Unit {
  if x < 0 || y < 0 || x >= frame.width || y >= frame.height {
    return
  }
  let index = y * frame.width + x
  if !visited[index] && frame.pixels[index].to_double() >= threshold {
    visited[index] = true
    queue.push(index)
  }
}

///|
pub fn region_density(
  regions : Array[BrightRegion],
  width : Int,
  height : Int,
) -> Double {
  if width <= 0 || height <= 0 {
    0.0
  } else {
    let mut area = 0
    for region in regions {
      area += region.area
    }
    area.to_double() / (width * height).to_double()
  }
}

///|
pub fn region_area_sum(regions : Array[BrightRegion]) -> Int {
  let mut total = 0
  for region in regions {
    total += region.area
  }
  total
}

///|
pub fn largest_region(regions : Array[BrightRegion]) -> BrightRegion? {
  if regions.length() == 0 {
    return None
  }
  let mut best = regions[0]
  for region in regions[1:] {
    if region.area > best.area {
      best = region
    }
  }
  Some(best)
}

///|
pub fn regions_intersect(left : BrightRegion, right : BrightRegion) -> Bool {
  left.minimum_x <= right.maximum_x &&
  right.minimum_x <= left.maximum_x &&
  left.minimum_y <= right.maximum_y &&
  right.minimum_y <= left.maximum_y
}

///|
pub fn region_width(region : BrightRegion) -> Int {
  region.maximum_x - region.minimum_x + 1
}

///|
pub fn region_height(region : BrightRegion) -> Int {
  region.maximum_y - region.minimum_y + 1
}
