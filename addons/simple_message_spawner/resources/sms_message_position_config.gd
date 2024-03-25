extends Resource
class_name SMSMessagePositionConfig

var start_position: Vector2: set = set_start_position

var target_position: Vector2: set = set_target_position


func set_start_position(new_position) -> void:
	start_position = new_position


func set_target_position(new_position) -> void:
	target_position = new_position
