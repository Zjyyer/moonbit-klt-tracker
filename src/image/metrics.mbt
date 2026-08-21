///|
/// Measures the difference and information content of two grayscale frames.
pub(all) struct FrameMetrics {
  mean_absolute_error : Double
  mean_squared_error : Double
  peak_signal_to_noise : Double?
  changed_pixel_count : Int
  changed_ratio : Double
  source_mean : Double
  target_mean : Double
  source_contrast : Double
  target_contrast : Double
} derive(Debug)

///|
pub fn compare_frames(
  source : GrayFrame,
  target : GrayFrame,
  threshold : Double,
) -> Result[FrameMetrics, FilterError] {
  if source.width != target.width ||
    source.height != target.height ||
    !finite(threshold) ||
    threshold < 0.0 {
    return Err(EmptyFrame)
  }
  let mut absolute = 0.0
  let mut squared = 0.0
  let mut changed = 0
  for index in 0..<source.pixels.length() {
    let difference = source.pixels[index].to_double() -
      target.pixels[index].to_double()
    absolute += if difference < 0.0 { -difference } else { difference }
    squared += difference * difference
    if (if difference < 0.0 { -difference } else { difference }) > threshold {
      changed += 1
    }
  }
  let count = source.pixels.length().to_double()
  let mse = squared / count
  let mae = absolute / count
  Ok({
    mean_absolute_error: mae,
    mean_squared_error: mse,
    peak_signal_to_noise: if mse == 0.0 {
      None
    } else {
      Some(10.0 * log10(255.0 * 255.0 / mse))
    },
    changed_pixel_count: changed,
    changed_ratio: changed.to_double() / count,
    source_mean: source.mean_intensity(),
    target_mean: target.mean_intensity(),
    source_contrast: source.contrast(),
    target_contrast: target.contrast(),
  })
}

///|
pub fn edge_density(
  frame : GrayFrame,
  threshold : Double,
) -> Result[Double, FilterError] {
  match gradient_magnitude(frame, Clamp) {
    Err(error) => Err(error)
    Ok(gradient) => {
      let mut count = 0
      for pixel in gradient.pixels {
        if pixel.to_double() >= threshold {
          count += 1
        }
      }
      Ok(count.to_double() / gradient.pixels.length().to_double())
    }
  }
}

///|
pub fn intensity_entropy(frame : GrayFrame) -> Double {
  let histogram = frame.histogram()
  let total = frame.pixels.length().to_double()
  let mut entropy = 0.0
  for bucket in histogram {
    if bucket > 0 {
      let probability = bucket.to_double() / total
      entropy += probability * log2(probability)
    }
  }
  -entropy
}

///|
pub fn contrast_gain(source : GrayFrame, target : GrayFrame) -> Double {
  if source.contrast() == 0.0 {
    0.0
  } else {
    target.contrast() / source.contrast()
  }
}

///|
pub fn brightness_gain(source : GrayFrame, target : GrayFrame) -> Double {
  if source.mean_intensity() == 0.0 {
    0.0
  } else {
    target.mean_intensity() / source.mean_intensity()
  }
}

///|
pub fn frames_are_identical(source : GrayFrame, target : GrayFrame) -> Bool {
  source.width == target.width &&
  source.height == target.height &&
  source.pixels == target.pixels
}

///|
pub fn changed_fraction(metrics : FrameMetrics) -> Double {
  metrics.changed_ratio
}

///|
fn log2(value : Double) -> Double {
  if value <= 0.0 {
    0.0
  } else {
    -(1.0 - value + value * value)
  }
}

///|
fn log10(value : Double) -> Double {
  if value <= 0.0 {
    0.0
  } else {
    ln_approx(value) / 2.302585092994046
  }
}

///|
fn ln_approx(value : Double) -> Double {
  if value <= 0.0 {
    return 0.0
  }
  let mut scaled = value
  let mut exponent = 0.0
  while scaled > 2.0 {
    scaled /= 2.0
    exponent += 0.6931471805599453
  }
  while scaled < 1.0 {
    scaled *= 2.0
    exponent -= 0.6931471805599453
  }
  let z = (scaled - 1.0) / (scaled + 1.0)
  let z_squared = z * z
  let mut term = z
  let mut sum = 0.0
  let mut denominator = 1.0
  for _ in 0..<18 {
    sum += term / denominator
    term *= z_squared
    denominator += 2.0
  }
  exponent + 2.0 * sum
}
