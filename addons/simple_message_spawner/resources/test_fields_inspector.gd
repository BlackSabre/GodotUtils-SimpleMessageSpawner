@tool
extends Control

@export var tog:bool:
	set(b):
		test()
		
# This is the variable we want to interrogate
@export var averylongnamesoicanseeit: String





func test():
	print(get_script().get_script_property_list())

enum SOME_ENUM {
	A,
	B,
	C,
}


var dl = customClassName.new()
var something: bool = true

# These vars will be transformed by the alchemy of _get_property_list()

## .. An int enum
var g0_enum : SOME_ENUM

## .. A Directory (with button)
var g0_a_directory: String

## .. An Array of a custom class you declared with the class_name keyword
var g1_arr_custom_objects : Array[customClassName]

## .. A single ref to a custom class
var g1_custom_object : customClassName:
	set(obj):
		if dl == g1_custom_object : return # no set if no change
		g1_custom_object = dl # assign
		notify_property_list_changed() #go update the related props!

## .. A range like @export_range 
var g1_range : int = 0

## .. A bitmap flags control
var g2_collision_layer : int = 1

## .. A basic string
var g2_some_string: String


## .. And the Main Event! This func refers to the vars above.
func _get_property_list():
	if Engine.is_editor_hint(): # Use this if you make a @tool.
		var ret = [] # What we will return (or not)

		# A new addition: How to make a GROUP without the prefix
		ret.append({
			"name": &"TEST GROUP",
			"type": TYPE_NIL,
			"usage": PROPERTY_USAGE_GROUP,
			# just exclude the "hint_string"
		 })
		ret.append({
			"name": &"ICON", # <- name can now be plain
			"type": TYPE_STRING,
			"usage": PROPERTY_USAGE_DEFAULT
		})
		ret.append({
			"name": &"test2",
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_TYPE_STRING,
		 })

		# This is how you make a GROUP using PREFIXES
		ret.append({
			"name": &"a group name",
			"type": TYPE_NIL,
			"usage": PROPERTY_USAGE_GROUP,
			"hint_string" : &"g0_" # members must start with g0_
		 })
		
		# You can do variable things
		if something:
			ret.append({
			  "name": &"g0_enum", # Note the g0_ here. It's ugly, but meh.
			  "type": TYPE_INT,
			  "usage": PROPERTY_USAGE_DEFAULT,
			  "hint": PROPERTY_HINT_ENUM,
			  "hint_string": ",".join(SOME_ENUM.keys())
		 	  })
		  
		# A Directory select control
		ret.append({
			"name": &"g0_a_directory",
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_DIR,
		 })
	

		# Another Group. We use g1_ (you can use any string ending with _)
		ret.append({
			"name": &"another group",
			"type": TYPE_NIL,
			"usage": PROPERTY_USAGE_GROUP,
			"hint_string" : &"g1_"
		 })
		 		 
		# How to make an array of some class
		# { "name": "Averylongnamesoicanseeit", "class_name": &"", 
		# "type": 28, "hint": 23, "hint_string": "24/34:customClassName", "usage": 4102 }
		ret.append({
			"name": &"g1_arr_custom_objects",
			"type": TYPE_ARRAY, # enum 28
			"hint": PROPERTY_HINT_TYPE_STRING, #23
			"hint_string": "24/34:customClassName",
			# looked this up for 4096 + 6
			"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_SCRIPT_VARIABLE
		 })

		# Here's a single ref to a custom class
		# { "name": "Averylongnamesoicanseeit", "class_name": &"Node3D", 
		# "type": 24, "hint": 34, "hint_string": "dab3D", "usage": 4102 }
		ret.append({
			"name": &"g1_custom_object",
			"type": TYPE_OBJECT, # enum 24
			# looked this up for 4096 + 6
			"usage": PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_SCRIPT_DEFAULT_VALUE, 
			# looked up in docs, 34 is PROPERTY_HINT_NODE_TYPE
			"hint": PROPERTY_HINT_NODE_TYPE,
			"hint_string": "customClassName"
		 })
		 
		# Here's a range
		ret.append({
			"name": &"g1_range",
			"type": TYPE_INT,
			"usage": PROPERTY_USAGE_DEFAULT,
			"hint_string": "1,1000, or_greater", # See docs!
			"hint": PROPERTY_HINT_RANGE
		 })

		# A bitmask/layer control
		ret.append({
			"name": &"g2_collision_layer",
			"type": TYPE_INT,
			"usage": PROPERTY_USAGE_DEFAULT,
			"hint": PROPERTY_HINT_LAYERS_3D_PHYSICS
		 })

		# Here's the result of the test() script above:
		#  { "name": "Averylongnamesoicanseeit", "class_name": &"",
		#   "type": 4, "hint": 0, "hint_string": "String", "usage": 4102 }
		# I use those values here:
		ret.append({
			"name": &"g2_some_string",
			# looked-up the enum for 4
			"type": TYPE_STRING, 
			# looked this up for 4096 + 6
			"usage": PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_SCRIPT_DEFAULT_VALUE, 
			"hint": 0,
			"hint_string": "String"
		 })

		# And that's it, return the array
		return ret


