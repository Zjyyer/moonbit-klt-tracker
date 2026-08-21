///|
/// Grid-level image quality sampling.
pub(all) struct GridCell {
  index : Int
  tile : Tile
  mean : Double
  contrast : Double
  edge_density : Double
  usable : Bool
} derive(Debug)

///|
pub fn analyze_grid(
  frame : GrayFrame,
  tile_width : Int,
  tile_height : Int,
  minimum_contrast : Double,
) -> Array[GridCell] {
  let cells : Array[GridCell] = []
  let tile_list = tiles(frame.width, frame.height, tile_width, tile_height)
  for tile in tile_list {
    let mean = tile_mean(frame, tile)
    let contrast = tile_contrast(frame, tile)
    let edges = match edge_density(frame, minimum_contrast) {
      Ok(value) => value
      Err(_) => 0.0
    }
    cells.push({
      index: tile.index,
      tile,
      mean,
      contrast,
      edge_density: edges,
      usable: contrast >= minimum_contrast && edges > 0.0,
    })
  }
  cells
}

///|
pub fn usable_cells(cells : Array[GridCell]) -> Array[GridCell] {
  let result : Array[GridCell] = []
  for cell in cells {
    if cell.usable {
      result.push(cell)
    }
  }
  result
}

///|
pub fn grid_quality(cells : Array[GridCell]) -> Double {
  if cells.length() == 0 {
    return 0.0
  }
  let mut quality = 0.0
  for cell in cells {
    quality += if cell.usable { 1.0 } else { 0.0 }
  }
  quality / cells.length().to_double()
}

///|
pub fn grid_mean(cells : Array[GridCell]) -> Double {
  if cells.length() == 0 {
    return 0.0
  }
  let mut total = 0.0
  for cell in cells {
    total += cell.mean
  }
  total / cells.length().to_double()
}

///|
pub fn grid_contrast_range(cells : Array[GridCell]) -> Double {
  if cells.length() == 0 {
    return 0.0
  }
  let mut minimum = cells[0].contrast
  let mut maximum = cells[0].contrast
  for cell in cells {
    minimum = minimum.min(cell.contrast)
    maximum = maximum.max(cell.contrast)
  }
  maximum - minimum
}

///|
pub fn best_cell(cells : Array[GridCell]) -> GridCell? {
  if cells.length() == 0 {
    return None
  }
  let mut best = cells[0]
  for cell in cells[1:] {
    if cell.contrast > best.contrast ||
      (cell.contrast == best.contrast && cell.index < best.index) {
      best = cell
    }
  }
  Some(best)
}

///|
pub fn cells_to_points(cells : Array[GridCell]) -> Array[@math.Vec2] {
  let points : Array[@math.Vec2] = []
  for cell in cells {
    points.push({
      x: cell.tile.left.to_double() + cell.tile.width.to_double() / 2.0,
      y: cell.tile.top.to_double() + cell.tile.height.to_double() / 2.0,
    })
  }
  points
}
