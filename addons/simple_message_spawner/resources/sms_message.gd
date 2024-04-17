extends PanelContainer
class_name SMSMessage

signal moving_finished
signal finished_displaying(message: SMSMessage)
signal displaying_paused(message: SMSMessage)
signal delete_message
signal resume_displaying(message: SMSMessage)

static var message_number_id: int = 1;

## How long the message should display after moving into place and before it
## starts moving off-screen
@export var display_time: float

## Whether the messages intercepts mouse clicks or not
@export var handle_mouse_clicks: bool


@export_group("Start Config")

## Starting colours of a message
@export var start_colour_config: SMSMessageColourConfig

## Starting stylebox texture for the panel container of a message. If you're just using the 
## panel colours and text, leave this as null.
@export var start_panel_container_texture: StyleBox

## Starting image config for an image in the message. This image will use the
## MessageImage node. Leave blank to ignore the image.
@export var start_panel_image_config: SMSMessageImageConfig


@export_group("Display Config")

## Config of the message when it is displaying (i.e. not moving into position or off-screen)
@export var display_config: SMSMessageConfig


@export_group("Highlight Config")

## Highlight colour configuration of a message
@export var highlight_colour_config: SMSMessageColourConfig

## Highlight stylebox texture for a message. If you're just using the panel colours and text, 
## leave this as null.
@export var highlight_texture: StyleBox


@export_group("Reorder Config")

## Config for messages when they move out of the way of other messages
@export var reorder_config: SMSMessageConfig

@export_group("Exit Config")

## Config for messages when they are moving off-screen after displaying
@export var exit_config: SMSMessageConfig


@onready var message_rich_label: RichTextLabel = $MessageMarginContainer/HBoxContainer/RichTextMessageLabel
@onready var image_texture_rect: TextureRect = $MessageMarginContainer/HBoxContainer/ImageMarginContainer/MessageImage
@onready var message_margin_container: MarginContainer = $MessageMarginContainer
@onready var message_sound: AudioStreamPlayer = $MessageSound

var start_position_config: SMSMessagePositionConfig
var is_moving: bool = false
var has_theme: bool = false
var has_override_theme: bool = false
var panel_container_using_texture_at_start: bool = false


var is_displaying: bool = false
var mouse_inside: bool = false
var handling_mouse_click: bool = false
var pause_displaying: bool = false
var text: String
var is_set_to_delete: bool = false
var theme_override_type: ThemeOverrideType = ThemeOverrideType.NO_OVERRIDE
var original_style_box_override: StyleBox

var display_timer: Timer
var test_orig_colour: Color
var current_move_tween: Tween
var current_colour_tween: Tween


enum SMSMessageConfigType {
	START,
	DISPLAY,
	HIGHLIGHT,
	REORDER,
	EXIT,
}


enum ThemeOverrideType {
	NO_OVERRIDE,
	STYLEBOX_EMPTY,
	STYLEBOX_TEXTURE,
	STYLEBOX_FLAT,
	STYLEBOX_LINE,
}

func _ready():
	check_themes()
	set_initial_modulations_and_textures()
	setup_display_timer()
	set_message_name()
	
	
	if handle_mouse_clicks == true:
		mouse_filter = MOUSE_FILTER_STOP
	else:
		mouse_filter = MOUSE_FILTER_IGNORE

	
func _input(event):
	if (event is InputEventMouseButton == true && handling_mouse_click == false 
			&& event.button_index == MOUSE_BUTTON_LEFT && event.pressed == true 
			&& mouse_inside == true):
			await get_tree().process_frame
			handle_mouse_click()


# Changing any properties for a theme will change them for all objects
# with that theme. So if there is a theme and we want to change properties, we 
# use theme overrides.
func check_themes():
	if theme != null:
		# If there is a theme, we need to set overrides for various properties so
		# as to not change the actual theme.
		print("Has theme")
		has_theme = true;
		var current_theme = theme["PanelContainer/styles/panel"]
		
		if theme["PanelContainer/styles/panel"] is StyleBoxTexture:
			# We only need to worry about stylebox textures. All other styleboxes
			# don't seem to have a property for a texture.
			print("It is a StyleBoxTexture")
			var original_panel_theme: StyleBoxTexture = theme["PanelContainer/styles/panel"]

	if start_panel_container_texture != null:
		# create texture override for the panel
		#self["theme_override_styles/panel"] = start_panel_container_texture
		pass
	
	var theme_override_style = self["theme_override_styles/panel"]
	
	if theme_override_style != null:
		#print("Has override theme")
		has_override_theme = true
	
	#original_style_box_override = theme_override_style
	
	if theme_override_style is StyleBoxTexture:
		#print("Do this to StyleBoxTexture")
		theme_override_type = ThemeOverrideType.STYLEBOX_TEXTURE
	elif theme_override_style is StyleBoxFlat:
		#print("Do this StyleBoxFlat")
		theme_override_type = ThemeOverrideType.STYLEBOX_FLAT
	elif theme_override_style is StyleBoxEmpty:
		#print("Do this StyleBoxEmpty")
		theme_override_type = ThemeOverrideType.STYLEBOX_EMPTY
	elif theme_override_style is StyleBoxLine:
		#print("Do this StyleBoxLine")
		theme_override_type = ThemeOverrideType.STYLEBOX_LINE


func set_initial_modulations_and_textures():
	#image_texture_rect.self_modulate = start_image_modulation
	#self_modulate.a = 1
	#self.visible = false
	self.modulate.a = 0
	
	# If there is no texture in start_panel_container_texture, we create a flat
	# texture so the colours can change 
	if start_panel_container_texture == null:
		var flat_colours_style_box_theme := StyleBoxFlat.new()
		flat_colours_style_box_theme.bg_color = Color.WHITE
		theme_override_type = ThemeOverrideType.STYLEBOX_FLAT
		self["theme_override_styles/panel"] = flat_colours_style_box_theme
	else:
		# duplicate the texture resource so that not all objects change when we edit
		# the override
		self.set("theme_override_styles/panel", start_panel_container_texture.duplicate())
	
	# Set start colours of the relevant nodes
	if start_colour_config.use_panel_container_colour == true:
		self_modulate = start_colour_config.panel_container_colour
	
	if start_colour_config.use_text_colour == true:
		message_rich_label.set("theme_override_colors/default_color", start_colour_config.text_colour)
	
	if start_colour_config.use_text_shadow_colour == true:
		print("Setting font shadow colour")
		message_rich_label.set("theme_override_colors/font_shadow_color", start_colour_config.text_shadow_colour)

	if start_colour_config.use_text_outline_colour == true:
		print("Setting font outline colour")
		message_rich_label.set("theme_override_colors/font_outline_color", start_colour_config.text_outline_colour)
	
	if (start_panel_image_config != null && start_panel_image_config.image_texture != null):
		image_texture_rect.visible = true
		image_texture_rect.texture = start_panel_image_config.image_texture
		image_texture_rect.self_modulate = start_panel_image_config.self_modulate_colour
	else:
		print("ASJDAS")
		image_texture_rect.visible = false


func setup_display_timer():
	display_timer = Timer.new()
	add_child(display_timer)
	display_timer.autostart = false
	
	display_timer.one_shot = false
	display_timer.wait_time = display_time
	display_timer.stop()
	display_timer.timeout.connect(on_display_message_finished)	


func set_message_name():
	name = "SMSMessage" + var_to_str(message_number_id)
	message_number_id += 1
	

func adjust_size():
	await get_tree().process_frame
	#print("AS: Message: ", name, " size.y: ", size.y)
	#print("AS: Message: ", name, " margin.size.y: ", message_margin_container.size.y)
	var panel_container_height: float = size.y
	var message_margin_container_height: float = message_margin_container.size.y
	
	size.y = message_margin_container_height
	await get_tree().process_frame


func get_text():
	return message_rich_label.text


func get_height() -> float:	
	#print("GH: Message: ", name, " size.y: ", size.y)
	#print("GH: Message: ", name, " margin.size.y: ", message_margin_container.size.y)
	return size.y

func handle_mouse_click():
	if handling_mouse_click == true:
		return
	
	handling_mouse_click = true
	print("Clicked on message. Currently doing nothing.")
	handling_mouse_click = false


# sets the text in message_rich_label
func set_label_text(new_text: String) -> void:
	self.text = new_text
	message_rich_label.text = new_text	
	await get_tree().process_frame


func set_config_target_position(config_type: SMSMessageConfigType, target_position: Vector2) -> void:
	var config: SMSMessageConfig = get_message_config_from_enum(config_type)
	config.move_config.position = target_position

# sets the target_position in display_message_config
func set_display_config_target_position(target_position: Vector2):
	#display_config.move_config.set_target_position(target_position)
	display_config.move_config.position = target_position


# sets the target_position in exit_message_config
func set_exit_config_target_position(target_position: Vector2):
	#exit_config.move_config.target_position = target_position
	exit_config.move_config.position = target_position


# Main method to show a message. Note that this does not handle moving the message
# off screen and deleting it. I tried to do this all here, but if the position changes,
# the position off screen has to be recalculated, which is done on the sms_message_spawner
func display_message(start_position: Vector2, change_colour: bool):
	if is_moving == true:
		await moving_finished
		
	self.position = start_position
	self_modulate.a = 1
	message_rich_label.modulate.a = 1
	
	if message_sound != null:
		message_sound.play()
	
	display_timer.start(display_time)


func on_display_message_finished():
	#print("SMS_Message: Message: ", text, " finished displaying.")
	finished_displaying.emit()


# Gets the config specified by sms_message_config_type. For the start config and 
# highlight config, we have to create a new object 
func get_message_config_from_enum(sms_message_config_type: SMSMessageConfigType) -> SMSMessageConfig:
	var sms_message_config := SMSMessageConfig.new()
	
	match(sms_message_config_type):
		SMSMessageConfigType.START:
			sms_message_config.to_colour_config = start_colour_config
			sms_message_config.to_texture = start_panel_container_texture
			sms_message_config.move_config.position_config = start_position_config
		SMSMessageConfigType.DISPLAY:
			return display_config
		SMSMessageConfigType.HIGHLIGHT:
			sms_message_config.to_colour_config = highlight_colour_config
			sms_message_config.to_texture = highlight_texture
		SMSMessageConfigType.REORDER:
			return reorder_config
		SMSMessageConfigType.EXIT:
			return exit_config
	
	return sms_message_config


func move(target_sms_message_config_type: SMSMessageConfigType,
		terminate_after: bool):	
	var target_config: SMSMessageConfig = get_message_config_from_enum(target_sms_message_config_type)	
		
	if target_config == null:
		printerr("target_config is null.")
		finish_move()
		return
	
	var target_position: Vector2 = target_config.move_config.position
	
	self.modulate.a = 1
	is_moving = true
	
	# Tween position of message to target position and assign it to current_tween
	var move_tween: Tween = start_move_tween(target_config)
	
	var target_colour_config: SMSMessageColourConfig = target_config.target_colour_config
	var target_panel_container_texture_config: SMSMessageTextureConfig = target_config.target_panel_container_texture_config
	
	# Create tween for changing colours of the various nodes and properties
	var panel_colour_tween: Tween
	var text_colour_tween: Tween
	var text_outline_colour_tween: Tween
	var text_shadow_colour_tween: Tween
	var colour_change_duration: float = 0
	
	if target_colour_config != null:
		# Changing the colours of the message should not take longer than the move duration.
		# If it does, the desired colours probably won't be reached.
		colour_change_duration = clampf(
			target_config.target_colour_config.colour_change_duration, 
			0, 
			target_config.move_config.move_duration)
		
		if target_colour_config.use_panel_container_colour == true:
			#print("Using panel container colour")
			
			panel_colour_tween = create_tween()
			panel_colour_tween.set_parallel(true)
			var obj: StyleBoxTexture = self["theme_override_styles/panel"]
			#print("name: ", name)
			#print("obj: ", obj)
			#print("modulate_color: ", obj["modulate_color"])
			#print("target_colour: ", target_colour_config.panel_container_colour)
			#print("colour_change_duration: ", colour_change_duration)
			#print(" ")
			#panel_colour_tween.tween_property(obj, "modulate_color", target_colour_config.panel_container_colour, colour_change_duration)
			panel_colour_tween.tween_property(self, "self_modulate", target_colour_config.panel_container_colour, colour_change_duration)
			panel_colour_tween = start_colour_change_tween(self, 
				"self_modulate", 
				target_colour_config.panel_container_colour, 
				colour_change_duration, 
				target_config)
		
		if target_colour_config.use_text_colour == true:
			text_colour_tween = start_colour_change_tween(message_rich_label,
				"theme_override_colors/default_color",
				target_colour_config.text_colour, 
				colour_change_duration,
				target_config)
		
		if target_colour_config.use_text_outline_colour == true:
			text_outline_colour_tween = start_colour_change_tween(message_rich_label,
				"theme_override_colors/font_outline_color",
				target_colour_config.text_outline_colour, 
				colour_change_duration,
				target_config)
		
		if target_colour_config.use_text_shadow_colour == true:
			text_shadow_colour_tween = start_colour_change_tween(message_rich_label,
				"theme_override_colors/font_shadow_color",
				target_colour_config.text_shadow_colour, 
				colour_change_duration,
				target_config)
	
	#Shader stuff
	if (target_panel_container_texture_config != null &&
		target_panel_container_texture_config.use_shader == true):		
		# The duration of the shaders should not be longer than the move duration
		# If it does, it could cause issues if there are additional shaders for the same
		# texture
		print("Doing shader stuff")
		var shader_duration = clampf(target_panel_container_texture_config.change_time, 
								0,
								display_config.move_config.move_duration)
		var panel_container_shader_material: ShaderMaterial = target_panel_container_texture_config.texture_shader_material
		
		if panel_container_shader_material != null:
			
			# duplicate the material so not all messages are changed at the same time
			panel_container_shader_material = panel_container_shader_material.duplicate()
			material = panel_container_shader_material
			var panel_container_shader_tween = start_panel_container_shader(
				panel_container_shader_material,
				target_panel_container_texture_config,
				shader_duration)
	
	if terminate_after == false:
		move_tween.tween_callback(finish_move).set_delay(target_config.move_config.move_duration)
	else:
		move_tween.tween_callback(finish_move_and_delete).set_delay(target_config.move_config.move_duration)


func start_panel_container_shader(shader_material: ShaderMaterial, 
		texture_config: SMSMessageTextureConfig, 
		shader_duration: float) -> Tween:
	var target_colour: Color = texture_config.target_texture_modulation
	var target_stylebox_texture: StyleBoxTexture = texture_config.target_texture
	
	shader_material.set_shader_parameter("target_texture", target_stylebox_texture.texture)
	var panel_container_texture_tween: Tween = create_tween()
	
	panel_container_texture_tween.tween_method(set_fade_shader_value.bind(shader_material), 0.0, 1.0, shader_duration)
	panel_container_texture_tween.tween_callback(finish_panel_container_shader.bind(texture_config))
	return panel_container_texture_tween
	self_modulate = Color.PURPLE


func finish_panel_container_shader(texture_config: SMSMessageTextureConfig):
	# Set the material to null since the next move might not use a shader, but
	# could want to use colour on the texture.
	self["theme_override_styles/panel"] = texture_config.target_texture
	material = null


func set_fade_shader_value(value: float, shader_material: ShaderMaterial):
	#print("Value: ", value)
	shader_material.set_shader_parameter("weight", value)
	pass


func start_move_tween(target_config: SMSMessageConfig) -> Tween:
	var move_tween: Tween = create_tween()
	
	move_tween.set_parallel(true).tween_property(
		self, 
		"position",
		target_config.move_config.position,
		target_config.move_config.move_duration
	).set_trans(
		target_config.move_config.move_tween_transition_type
	).set_ease(
		target_config.move_config.move_tween_ease_type
	)
	
	return move_tween


func start_colour_change_tween(control_node: Control, property: String, 
		target_colour: Color, duration: float, target_config: SMSMessageConfig) -> Tween:	
	var colour_change_tween: Tween = create_tween()
	
	#print("control_node: ", control_node.name)
	#print("property: ", property)
	#print("target_colour: ", target_colour)
	if (control_node[property] == null):
		#print("Adding property '", property, "' to control node ", control_node.name)
		control_node.set(property, Color.WHITE)
	
	colour_change_tween.set_parallel(true
		).tween_property(
			control_node,
			property,
			target_colour,
			duration
		).set_trans(
			target_config.target_colour_config.colour_tween_transition_type
		).set_ease(
			target_config.target_colour_config.colour_tween_ease_type
		)
	
	return colour_change_tween


func start_shader_tween(texture_config: SMSMessageTextureConfig, ) -> Tween:
	return create_tween()
	pass

# moves this object to the target position using exit_message_config and deletes it 
# afterwards
func move_and_delete(target_position: Vector2, change_colour: bool):
	if is_moving == true:
		await moving_finished	
	
	exit_config.move_config.position = target_position
	move(SMSMessageConfigType.EXIT, true)
	
	await delete_message


# At the moment, just starts timer for displaying before moving off_screen
# If you want to do something with this object while it's displaying, this would be
# a decent place to do it
func display():
	is_displaying = true
	
	await get_tree().create_timer(display_time).timeout
	
	if pause_displaying == false:
		finished_displaying.emit()
		is_displaying = false


# Called after a move is finished
func finish_move():
	is_moving = false
	moving_finished.emit()


# Called after a move and when it's set to delete
func finish_move_and_delete():
	#print("Moving finished. Deleting ", get_text())
	is_moving = false
	
	print("current_colour_tween: ", current_colour_tween)
	
	if current_colour_tween != null && current_colour_tween.is_running():
		print("waiting for colours: ", Time.get_datetime_string_from_system())
		await current_colour_tween.finished
		print("Finished waitiing for colours: ", Time.get_datetime_string_from_system())
	
	moving_finished.emit()
	delete_message.emit()
	handling_mouse_click = false
	#message_number_id -= 1
	#queue_free()


func _on_mouse_entered():
	if handle_mouse_clicks == false:
		return
	
	var panel_container_highlight_style_box_texture = null # was class variable
	
	if has_override_theme == true:
		#print("Has override theme")
		#self["theme_override_styles/panel"] = panel_container_highlight_style_box_texture
		pass
	elif has_theme == true && panel_container_highlight_style_box_texture != null:
		#print("Changing theme")
		#self["theme_override_styles/panel"] = panel_container_highlight_style_box_texture
		pass
	
	#message_rich_label["theme_override_colors/default_color"] = text_highlight_colour
	
	#panel_container_using_texture
	#test_orig_colour = modulate
	#modulate = Color.CHARTREUSE
	display_timer.stop()
	mouse_inside = true
	pause_displaying = true


func _on_mouse_exited():
	if handle_mouse_clicks == false:
		return
	
	if is_instance_valid(self) == false:
		return
	
	#print("Mouse exited message: ", get_text())
	mouse_inside = false
	
	if has_override_theme == true:
		#print("Has override theme")
		self["theme_override_styles/panel"] = original_style_box_override
	
	if panel_container_using_texture_at_start == false:
		#self.self_modulate = display_message_config.to_panel_container_colour
		pass
	
	#message_rich_label["theme_override_colors/default_color"] = display_message_config.to_text_colour
	
	display_timer.start(display_time)


func check_mouse_cursor_in_viewport():
	var mouse_coordinates: Vector2 = get_viewport().get_mouse_position()
	var viewport_rect: Rect2 = get_viewport_rect()
	#print("Mouse coordinates: ", mouse_coordinates)
	#print("viewport rect: ", viewport_rect)
	
	if mouse_coordinates.x < 0 || mouse_coordinates.x > viewport_rect.size.x:
		#print("X is out of bounds")
		return false
	elif mouse_coordinates.y < 0 || mouse_coordinates.y > viewport_rect.size.y:
		return false
		#print("Y is out of bounds")
	
	return true


func hide() -> void:
	visible = false


func show() -> void:
	visible = true


func stop_timer() -> void:
	if display_timer == null:
		display_timer.stop()
