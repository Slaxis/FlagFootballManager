# Assertion collector handed to every test function. A test fails by
# recording messages, never by crashing, so one broken test does not take
# the rest of the suite down with it.
extends RefCounted
class_name TestHelper

var _failures: Array[String] = []
# GDScript has no exceptions: a runtime error aborts the test function and
# returns to the runner, which then sees no failures and prints "ok". Counting
# assertions is how a test that died on its first line gets caught.
var _checks: int = 0

func has_failures() -> bool:
	return not _failures.is_empty()

func failures() -> Array[String]:
	return _failures

func checks() -> int:
	return _checks

func fail(message: String) -> void:
	_checks += 1
	_failures.append(message)

func check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)

func equal(actual: Variant, expected: Variant, what: String = "") -> void:
	_checks += 1
	if actual != expected:
		_failures.append("%s: esperado %s, veio %s" % [what if what != "" else "valor", str(expected), str(actual)])

func not_null(value: Variant, what: String = "") -> void:
	_checks += 1
	if value == null:
		_failures.append("%s é null" % [what if what != "" else "valor"])
