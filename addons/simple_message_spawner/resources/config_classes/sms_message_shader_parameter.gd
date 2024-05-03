@tool
extends Resource
class_name SMSMessageShaderParameter

## This must match the name of the parameter in the shader. No error 
## or warning will show if it doesn't exist as there isn't a way to 
## differentiate null shader shader parameters in the shader script
## and values that don't exist (that I know of, at least)
@export var parameter_name: String

## Used to return the correct parameter based on the type selected here.
## Note that textures have a default texture value to help check
## whether a shader parameter exists in a shader or not.
@export var parameter_type: SMSMessagerShaderParameterType:
	set(value):
		parameter_type = value
		match value:
			SMSMessagerShaderParameterType.TEXTURE:
				if parameter_texture == null:
					parameter_texture = default_texture
		
		notify_property_list_changed()

## If true, it will tween the parameter from it's current / default value
## to the parameter set in "parameter_float", "parameter_colour", or
## "parameter_int". Texture's can't be tweened as far as I know.
var tween_this_parameter: bool = false

const TWEEN_THIS_PARAMETER_PROPERTY_DICTIONARY: Dictionary = {
		"name": "tween_this_parameter",
		"type": 1,
		"hint": 0,
		"hint_string": "bool",
		"usage": 4102
	}

var parameter_float: float
var parameter_colour: Color
var parameter_int: int
var parameter_texture: Texture
var default_texture: Texture = preload("res://addons/simple_message_spawner/resources/images/default_texture_16x16.png")

enum SMSMessagerShaderParameterType {
	FLOAT,
	COLOUR,
	INT,
	TEXTURE,
}


# Uncomment below to get properties when show_properties is selected in
# the inspector
#@export var show_properties: bool:
	#set(value):
		#show_all_properties()
#
#func show_all_properties() -> void:
	#print("Properties:")
	#print(get_property_list(), "\n")




## Overrides get_property_list() so that the appropriate parameter 
## (parameter_float, parameter_colour, parameter_int, or parameter_texture)
## appears in the inspector based on what is selected in parameter_type.
## The variable 'tween_this_parameter' shouldn't show for textures as you
## cannot really tween them without a shader
func _get_property_list() -> Array[Dictionary]:
	var properties_array: Array[Dictionary]
	
	match(parameter_type):
		SMSMessagerShaderParameterType.FLOAT:
			properties_array.append({
				"name": "parameter_float",
				"type": TYPE_FLOAT, 
				"hint": PROPERTY_HINT_NONE,
				"hint_string": "",
				"useage": 4102
			})
			
			properties_array.append(TWEEN_THIS_PARAMETER_PROPERTY_DICTIONARY)
			
		SMSMessagerShaderParameterType.COLOUR:
			properties_array.append({
				"name": "parameter_colour",
				"type": TYPE_COLOR, 
				"hint": PROPERTY_HINT_NONE,
				"hint_string": "",
				"useage": 4102
			})
			
			properties_array.append(TWEEN_THIS_PARAMETER_PROPERTY_DICTIONARY)
			
		SMSMessagerShaderParameterType.INT:
			properties_array.append({
				"name": "parameter_int",
				"type": TYPE_INT, 
				"hint": PROPERTY_HINT_NONE,
				"hint_string": "",
				"useage": 4102
			})
			
			properties_array.append(TWEEN_THIS_PARAMETER_PROPERTY_DICTIONARY)
			
		SMSMessagerShaderParameterType.TEXTURE:
			properties_array.append({
				"name": "parameter_texture",
				"class_name": &"Texture",
				"type": TYPE_OBJECT, 
				"hint": PROPERTY_HINT_RESOURCE_TYPE,
				"hint_string": "Texture",
				"useage": 4102
			})
	
	return properties_array

# Returns a parameter value based on what is selected in parameter_type
func get_parameter_value() -> Variant:
	match parameter_type:
		SMSMessagerShaderParameterType.FLOAT:
			return parameter_float
			
		SMSMessagerShaderParameterType.COLOUR:
			return parameter_colour
			
		SMSMessagerShaderParameterType.INT:
			return parameter_int
			
		SMSMessagerShaderParameterType.TEXTURE:
			return parameter_texture
	
	return null
