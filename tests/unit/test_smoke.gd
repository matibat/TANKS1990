extends GutTest

## Simple smoke test to verify GUT is working

func test_basic_assertion():
	assert_true(true, "Basic assertion should pass")

func test_numbers():
	assert_eq(1 + 1, 2, "Math should work")

func test_strings():
	assert_eq("hello", "hello", "String comparison should work")
