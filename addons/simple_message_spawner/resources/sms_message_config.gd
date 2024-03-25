extends Resource
class_name SMSMessageConfig

## Configuration for how the message moves, where it moves, and how quickly it moves there
@export var move_config: SMSMessageMoveConfig

## Whether the colour config should be used or not. If you don't want the message to change 
## colours when moving, deselect this.
@export var is_changing_colours: bool = false

## Target colours of the message and the text
@export var to_colour_config: SMSMessageColourConfig

## Target texture of the message. If you're just using the panel colours and text, leave this 
## as null.
@export var to_texture: StyleBox = null
