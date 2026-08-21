///|
/// Closed interval operations used for frame and pixel domains.
pub(all) struct Interval {
  minimum : Double
  maximum : Double
} derive(Debug)

///|
pub fn Interval::new(
  minimum : Double,
  maximum : Double,
) -> Result[Interval, MatrixError] {
  if !finite(minimum) || !finite(maximum) || minimum > maximum {
    Err(NonFiniteInput)
  } else {
    Ok({ minimum, maximum })
  }
}

///|
pub fn Interval::contains(self : Interval, value : Double) -> Bool {
  value >= self.minimum && value <= self.maximum
}

///|
pub fn Interval::length(self : Interval) -> Double {
  self.maximum - self.minimum
}

///|
pub fn Interval::clamp(self : Interval, value : Double) -> Double {
  value.max(self.minimum).min(self.maximum)
}

///|
pub fn Interval::expand(self : Interval, amount : Double) -> Interval {
  { minimum: self.minimum - amount, maximum: self.maximum + amount }
}

///|
pub fn Interval::intersect(self : Interval, other : Interval) -> Interval? {
  let minimum = self.minimum.max(other.minimum)
  let maximum = self.maximum.min(other.maximum)
  if minimum > maximum {
    None
  } else {
    Some({ minimum, maximum })
  }
}

///|
pub fn Interval::union(self : Interval, other : Interval) -> Interval {
  {
    minimum: self.minimum.min(other.minimum),
    maximum: self.maximum.max(other.maximum),
  }
}

///|
pub fn Interval::lerp(self : Interval, ratio : Double) -> Double {
  self.minimum + self.length() * ratio
}

///|
pub fn Interval::normalize(self : Interval, value : Double) -> Double {
  if self.length() == 0.0 {
    0.0
  } else {
    (value - self.minimum) / self.length()
  }
}

///|
pub fn Interval::split(self : Interval, parts : Int) -> Array[Interval] {
  let result : Array[Interval] = []
  if parts < 1 {
    return result
  }
  let width = self.length() / parts.to_double()
  for index in 0..<parts {
    result.push({
      minimum: self.minimum + width * index.to_double(),
      maximum: self.minimum + width * (index + 1).to_double(),
    })
  }
  result
}

///|
pub fn interval_sum(intervals : Array[Interval]) -> Double {
  let mut total = 0.0
  for interval in intervals {
    total += interval.length()
  }
  total
}

///|
pub fn merge_intervals(intervals : Array[Interval]) -> Array[Interval] {
  if intervals.length() == 0 {
    return []
  }
  let ordered = intervals.copy()
  ordered.sort_by(fn(left, right) { left.minimum.compare(right.minimum) })
  let result : Array[Interval] = [ordered[0]]
  for interval in ordered[1:] {
    let last = result[result.length() - 1]
    if interval.minimum <= last.maximum {
      result[result.length() - 1] = last.union(interval)
    } else {
      result.push(interval)
    }
  }
  result
}

///|
pub fn interval_contains_all(
  interval : Interval,
  values : Array[Double],
) -> Bool {
  for value in values {
    if !interval.contains(value) {
      return false
    }
  }
  true
}

///|
pub fn interval_midpoint(interval : Interval) -> Double {
  interval.lerp(0.5)
}

///|
pub fn interval_distance(left : Interval, right : Interval) -> Double {
  if left.intersect(right) is Some(_) {
    0.0
  } else if left.maximum < right.minimum {
    right.minimum - left.maximum
  } else {
    left.minimum - right.maximum
  }
}
