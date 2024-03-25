extends Resource
class_name SMSMessageMoveConfig

## How long the move takes
@export var move_duration: float

## How long the colour texture takes to transition. This should always be as long or shorter
## than the move_duration. If this value is larger than the move_duration, it will use the
## move_duration instead
@export var colour_change_duration: float

## Transition type when a message is moving
@export var move_tween_transition_type: Tween.TransitionType = Tween.TRANS_CUBIC

## Ease type when a message is moving
@export var move_tween_ease_type: Tween.EaseType = Tween.EASE_IN_OUT

## Tween transition type when changing colours of the message
@export var colour_tween_transition_type: Tween.TransitionType = Tween.TRANS_LINEAR

## Tween ease type when changing colours of the message
@export var colour_tween_ease_type: Tween.EaseType = Tween.EASE_IN_OUT

var position: Vector2

func get_position():
	return position

#var position_config: SMSMessagePositionConfig

