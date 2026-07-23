///|
test "library preserves executable argument normalization" {
  assert_eq(
    command_args(["klt-tracker", "inspect", "--manifest", "frames.json"]),
    ["inspect", "--manifest", "frames.json"],
  )
}
