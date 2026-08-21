///|
test "export profiles expose deterministic field contracts" {
  let compact = ExportOptions::new(Compact, false, false, 6).unwrap()
  let detailed = upgrade_profile(compact)
  assert_eq(profile_name(detailed.profile), "detailed")
  assert_true(
    profile_fields(detailed).length() > profile_fields(compact).length(),
  )
  assert_true(compatible_profiles(compact, detailed))
  assert_true(profile_description(detailed).contains("fields"))
}
