///|
test "single-level KLT rejects a finite update whose candidate displacement overflows" {
  assert_true(
    candidate_displacement(@math.Vec2::{ x: 1.0e308, y: 0.0 }, @math.Vec2::{
      x: -1.0e308,
      y: 0.0,
    })
    is None,
  )
}
