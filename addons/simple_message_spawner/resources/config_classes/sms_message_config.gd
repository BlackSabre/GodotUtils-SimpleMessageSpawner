extends Resource
class_name SMSMessageConfig

## Configuration for how the message moves, where it moves, and how quickly it moves there
@export var move_config: SMSMessageMoveConfig

## Whether the colour config should be used or not. If you don't want the message to change 
## colours when moving, deselect this.
@export var is_changing_colours: bool = false

## Target colours of the message and the text
@export var target_colour_config: SMSMessageColourConfig

## Target texture confguration of the message's panel container
@export var target_panel_container_texture_config: SMSMessageTextureConfig

## Target texture confguration of message's image
@export var target_image_texture_config: SMSMessageTextureConfig
