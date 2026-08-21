///|
test "gate explanation renders a typed validation result" {
  let policy = @validation.ThresholdPolicy::new(0.0, 1.0, 1.0, 1.0, 0.5).unwrap()
  let result = @validation.evaluate_gate([1.0], [0.1], [0.1], [0.1], policy).unwrap()
  let explanation = explain_gate(result)
  assert_true(explanation_is_success(explanation))
  assert_true(explanation_text(explanation).contains("tracking validation"))
}
