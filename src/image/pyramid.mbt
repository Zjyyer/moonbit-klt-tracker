///|
/// A requested Gaussian-pyramid depth is invalid.
pub(all) enum PyramidError {
  InvalidLevelCount
  InsufficientDimensions(level~ : Int, width~ : Int, height~ : Int)
} derive(Debug, Eq)

///|
/// Successively blurred and half-resolution grayscale frames.
pub(all) struct Pyramid {
  levels : Array[GrayFrame]
} derive(Debug)

///|
/// Builds `levels` Gaussian-pyramid layers, starting with `frame`.
pub fn Pyramid::build(
  frame : GrayFrame,
  levels : Int,
) -> Result[Pyramid, PyramidError] {
  if levels <= 0 {
    Err(InvalidLevelCount)
  } else {
    let frames = [frame]
    for level in 1..<levels {
      let source = frames[level - 1]
      if source.width < 4 || source.height < 4 {
        return Err(
          InsufficientDimensions(
            level~,
            width=source.width,
            height=source.height,
          ),
        )
      }
      frames.push(downsample(source))
    }
    Ok({ levels: frames })
  }
}

///|
/// Returns the requested built layer.
pub fn Pyramid::level(self : Pyramid, index : Int) -> GrayFrame {
  self.levels[index]
}

///|
fn gaussian_weight(index : Int) -> Int {
  match index {
    0 => 1
    1 => 4
    2 => 6
    3 => 4
    _ => 1
  }
}

///|
fn reflected_index(index : Int, length : Int) -> Int {
  let mut result = index
  while result < 0 || result >= length {
    if result < 0 {
      result = -result
    } else {
      result = 2 * length - 2 - result
    }
  }
  result
}

///|
fn GrayFrame::pixel_at_reflected(self : GrayFrame, x : Int, y : Int) -> Byte {
  let reflected_x = reflected_index(x, self.width)
  let reflected_y = reflected_index(y, self.height)
  self.pixels[reflected_y * self.width + reflected_x]
}

///|
fn downsample(frame : GrayFrame) -> GrayFrame {
  let width = frame.width / 2
  let height = frame.height / 2
  let pixels = []
  for y in 0..<height {
    for x in 0..<width {
      let center_x = x * 2
      let center_y = y * 2
      let mut weighted_sum = 0
      for kernel_y in 0..<5 {
        for kernel_x in 0..<5 {
          let weight = gaussian_weight(kernel_y) * gaussian_weight(kernel_x)
          let pixel = frame.pixel_at_reflected(
            center_x + kernel_x - 2,
            center_y + kernel_y - 2,
          )
          weighted_sum += weight * pixel.to_int()
        }
      }
      pixels.push((weighted_sum / 256).to_byte())
    }
  }
  match GrayFrame::new(width, height, pixels) {
    Ok(reduced) => reduced
    Err(_) => abort("downsampled dimensions must be valid")
  }
}
