class_name Vector3Helpers
extends RefCounted
## Utility functions for deterministic Vector3 operations in 3D gameplay
##
## Provides quantization and approximate equality for reproducible physics
## and collision detection across different runs and network sessions.


## Quantize Vector3 to specified precision for determinism
## Rounds each component to the nearest multiple of precision
##
## @param v: Vector3 to quantize
## @param precision: Rounding precision (default: 0.001 = 1mm)
## @return: Quantized Vector3 with consistent floating-point values
static func quantize_vec3(v: Vector3, precision: float = 0.001) -> Vector3:
	return Vector3(
		snappedf(v.x, precision),
		snappedf(v.y, precision),
		snappedf(v.z, precision)
	)


## Check if two Vector3 values are approximately equal within epsilon
## Useful for deterministic comparisons with floating-point arithmetic
##
## @param a: First Vector3
## @param b: Second Vector3
## @param epsilon: Maximum allowed difference per component (default: 0.001)
## @return: true if all components are within epsilon, false otherwise
static func vec3_approx_equal(a: Vector3, b: Vector3, epsilon: float = 0.001) -> bool:
	return (
		absf(a.x - b.x) <= epsilon and
		absf(a.y - b.y) <= epsilon and
		absf(a.z - b.z) <= epsilon
	)
