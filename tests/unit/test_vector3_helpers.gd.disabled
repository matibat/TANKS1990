extends GutTest
## BDD-style tests for Vector3 helper utilities
## 
## Feature: Vector3 Quantization and Comparison
## As a developer, I want deterministic 3D vector operations
## So that gameplay remains reproducible across sessions

const Vector3Helpers = preload("res://src/utils/vector3_helpers.gd")


# Scenario: Quantize Vector3 for determinism
class TestQuantizeVec3:
	extends GutTest
	
	func test_given_precise_vector_when_quantized_then_rounds_to_precision():
		# Given
		var vec = Vector3(10.123456, 20.987654, 30.555555)
		
		# When
		var result = Vector3Helpers.quantize_vec3(vec, 0.01)
		
		# Then
		assert_almost_eq(result.x, 10.12, 0.0001, "X should round to 0.01")
		assert_almost_eq(result.y, 20.99, 0.0001, "Y should round to 0.01")
		assert_almost_eq(result.z, 30.56, 0.0001, "Z should round to 0.01")
	
	func test_given_vector_when_quantized_with_default_then_uses_0_001():
		# Given
		var vec = Vector3(1.2345, 2.3456, 3.4567)
		
		# When
		var result = Vector3Helpers.quantize_vec3(vec)
		
		# Then
		assert_almost_eq(result.x, 1.235, 0.0001, "X should round to 0.001")
		assert_almost_eq(result.y, 2.346, 0.0001, "Y should round to 0.001")
		assert_almost_eq(result.z, 3.457, 0.0001, "Z should round to 0.001")
	
	func test_given_zero_vector_when_quantized_then_stays_zero():
		# Given
		var vec = Vector3.ZERO
		
		# When
		var result = Vector3Helpers.quantize_vec3(vec, 0.01)
		
		# Then
		assert_eq(result, Vector3.ZERO, "Should remain zero")
	
	func test_given_negative_vector_when_quantized_then_rounds_correctly():
		# Given
		var vec = Vector3(-10.126, -20.984, -30.551)
		
		# When
		var result = Vector3Helpers.quantize_vec3(vec, 0.01)
		
		# Then
		assert_almost_eq(result.x, -10.13, 0.0001, "X should round to -10.13")
		assert_almost_eq(result.y, -20.98, 0.0001, "Y should round to -20.98")
		assert_almost_eq(result.z, -30.55, 0.0001, "Z should round to -30.55")
	
	func test_given_exact_multiple_when_quantized_then_unchanged():
		# Given
		var vec = Vector3(10.0, 20.5, 30.25)
		
		# When
		var result = Vector3Helpers.quantize_vec3(vec, 0.25)
		
		# Then
		assert_almost_eq(result.x, 10.0, 0.0001, "X should stay 10.0")
		assert_almost_eq(result.y, 20.5, 0.0001, "Y should stay 20.5")
		assert_almost_eq(result.z, 30.25, 0.0001, "Z should stay 30.25")


# Scenario: Approximate Vector3 equality
class TestVec3ApproxEqual:
	extends GutTest
	
	func test_given_identical_vectors_when_compared_then_returns_true():
		# Given
		var a = Vector3(10.0, 20.0, 30.0)
		var b = Vector3(10.0, 20.0, 30.0)
		
		# When
		var result = Vector3Helpers.vec3_approx_equal(a, b)
		
		# Then
		assert_true(result, "Identical vectors should be equal")
	
	func test_given_vectors_within_epsilon_when_compared_then_returns_true():
		# Given
		var a = Vector3(10.0, 20.0, 30.0)
		var b = Vector3(10.0005, 19.9995, 30.0003)
		
		# When
		var result = Vector3Helpers.vec3_approx_equal(a, b, 0.001)
		
		# Then
		assert_true(result, "Vectors within epsilon should be equal")
	
	func test_given_vectors_outside_epsilon_when_compared_then_returns_false():
		# Given
		var a = Vector3(10.0, 20.0, 30.0)
		var b = Vector3(10.01, 20.0, 30.0)
		
		# When
		var result = Vector3Helpers.vec3_approx_equal(a, b, 0.001)
		
		# Then
		assert_false(result, "Vectors outside epsilon should not be equal")
	
	func test_given_negative_vectors_when_compared_then_handles_correctly():
		# Given
		var a = Vector3(-5.0, -10.0, -15.0)
		var b = Vector3(-5.0005, -9.9995, -15.0003)
		
		# When
		var result = Vector3Helpers.vec3_approx_equal(a, b, 0.001)
		
		# Then
		assert_true(result, "Negative vectors within epsilon should be equal")
	
	func test_given_zero_vectors_when_compared_then_returns_true():
		# Given
		var a = Vector3.ZERO
		var b = Vector3.ZERO
		
		# When
		var result = Vector3Helpers.vec3_approx_equal(a, b)
		
		# Then
		assert_true(result, "Zero vectors should be equal")
	
	func test_given_vectors_with_default_epsilon_when_compared_then_uses_0_001():
		# Given
		var a = Vector3(1.0, 2.0, 3.0)
		var b = Vector3(1.0005, 2.0, 3.0)
		
		# When
		var result = Vector3Helpers.vec3_approx_equal(a, b)
		
		# Then
		assert_true(result, "Should use default epsilon 0.001")
	
	func test_given_one_component_outside_epsilon_when_compared_then_returns_false():
		# Given
		var a = Vector3(10.0, 20.0, 30.0)
		var b = Vector3(10.0, 20.0, 30.01)  # Z outside epsilon
		
		# When
		var result = Vector3Helpers.vec3_approx_equal(a, b, 0.001)
		
		# Then
		assert_false(result, "Should fail if any component outside epsilon")


# Scenario: Determinism with quantization
class TestDeterminism:
	extends GutTest
	
	func test_given_floating_point_drift_when_quantized_then_normalizes():
		# Simulate floating point accumulation errors
		# Given
		var vec1 = Vector3(0.1, 0.2, 0.3)
		var accumulated = Vector3.ZERO
		for i in range(10):
			accumulated += vec1
		
		var expected = Vector3(1.0, 2.0, 3.0)
		
		# When (without quantization, might have drift)
		var quantized = Vector3Helpers.quantize_vec3(accumulated, 0.001)
		
		# Then
		assert_true(
			Vector3Helpers.vec3_approx_equal(quantized, expected, 0.01),
			"Quantization should normalize accumulated errors"
		)
	
	func test_given_same_operations_when_quantized_then_reproducible():
		# Given
		var vec1 = Vector3(1.234, 2.345, 3.456)
		var vec2 = Vector3(4.567, 5.678, 6.789)
		
		# When (operations in different order)
		var result1 = Vector3Helpers.quantize_vec3(vec1 + vec2, 0.01)
		var result2 = Vector3Helpers.quantize_vec3(vec2 + vec1, 0.01)
		
		# Then
		assert_true(
			Vector3Helpers.vec3_approx_equal(result1, result2, 0.0001),
			"Quantized operations should be commutative"
		)
