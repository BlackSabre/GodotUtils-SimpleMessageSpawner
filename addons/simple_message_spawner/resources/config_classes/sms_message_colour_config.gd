extends Resource
class_name SMSMessageColourConfig

## If true, panel_container_colour overrides the theme overrides
@export var use_panel_container_colour: bool = true 

## Colour that the panel container changes to. Overrides any existing themes / theme overrides
@export var panel_container_colour: Color = Color.BLACK

## If true, text_colour overrides the theme overrides
@export var use_text_colour: bool = true 

## Colour that the text changes to. Overrides any existing themes / theme overrides if 
## use_text_colour is true.
@export var text_colour: Color = Color.WHITE

## If true, text_outline_colour overrides the theme overrides 
@export var use_text_outline_colour: bool = false

## Colour that the text outline changes to if it is available. Overrides any existing themes / theme overrides
@export var text_outline_colour: Color = Color.ORANGE_RED

## If true, text_shadow_colour overrides the theme overrides 
@export var use_text_shadow_colour: bool = false

## Colour that the text shadow color changes to if it is available. Overrides any existing themes / theme overrides
@export var text_shadow_colour: Color = Color.DARK_RED

## Modulation of the image if there is one
@export var image_modulation: Color = Color.WHITE

## How long the colour texture takes to transition. This should always be as long or shorter
## than the move_duration. If this value is larger than the move_duration, it will use the
## move_duration instead
@export var colour_change_duration: float

## Tween transition type when changing colours of the message
@export var colour_tween_transition_type: Tween.TransitionType = Tween.TRANS_LINEAR

## Tween ease type when changing colours of the message
@export var colour_tween_ease_type: Tween.EaseType = Tween.EASE_IN_OUT
