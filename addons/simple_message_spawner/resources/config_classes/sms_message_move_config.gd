extends Resource
class_name SMSMessageMoveConfig

## How long the move takes
@export var move_duration: float

## Transition type when a message is moving
@export var move_tween_transition_type: Tween.TransitionType = Tween.TRANS_CUBIC

## Ease type when a message is moving
@export var move_tween_ease_type: Tween.EaseType = Tween.EASE_IN_OUT

var position: Vector2

func get_position():
	return position

#var position_config: SMSMessagePositionConfig

