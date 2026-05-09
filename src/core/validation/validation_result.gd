extends RefCounted
class_name ValidationResult


var errors: Array[String] = []


func addError(message: String) -> void:
	errors.append(message)


func isValid() -> bool:
	return errors.is_empty()


func merge(prefix: String, result: ValidationResult) -> void:
	for error in result.errors:
		addError("%s: %s" % [prefix, error])
