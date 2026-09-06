# Assertion collector handed to every test function. A test fails by
# recording messages, never by crashing, so one broken test does not take
# the rest of the suite down with it.
extends RefCounted
class_name TestHelper

var _failures: Array[String] = []

func has_failures() -> bool:
	return not _failures.is_empty()

func failures() -> Array[String]:
	return _failures

func fail(message: String) -> void:
	_failures.append(message)

func check(condition: bool, message: String) -> void:
	if not condition:
		fail(message)

func equal(actual: Variant, expected: Variant, what: String = "") -> void:
	if actual != expected:
		fail("%s: esperado %s, veio %s" % [what if what != "" else "valor", str(expected), str(actual)])

func not_null(value: Variant, what: String = "") -> void:
	if value == null:
		fail("%s é null" % [what if what != "" else "valor"])
