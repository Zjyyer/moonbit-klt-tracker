///|
test "trajectory schema contract is stable and searchable" {
  let contract = trajectory_contract()
  assert_true(contract_is_compatible(contract, "1.0"))
  assert_eq(required_field_index(contract, "tracks"), Some(1))
  assert_true(contract_text(contract).contains("trajectory-document@1.0"))
}
