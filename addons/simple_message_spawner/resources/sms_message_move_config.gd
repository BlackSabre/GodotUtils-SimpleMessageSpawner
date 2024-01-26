extends Resource
class_name SMSMessageMoveConfig

@export var to_panel_container_colour: Color

@export var to_text_colour: Color

@export var change_duration: float

@export var move_duration: float

@export var move_tween_transition_type: Tween.TransitionType = Tween.TRANS_CUBIC

@export var move_tween_ease_type: Tween.EaseType

@export var change_tween_transition_type: Tween.TransitionType = Tween.TRANS_LINEAR

@export var change_tween_ease_type: Tween.EaseType

var target_position: Vector2
