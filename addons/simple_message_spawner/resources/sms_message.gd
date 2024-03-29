extends PanelContainer
class_name SMSMessage

signal moving_finished
signal finished_displaying(message: SMSMessage)
signal displaying_paused(message: SMSMessage)
signal delete_message
signal resume_displaying(message: SMSMessage)

## How long the message should display after moving into place and before it
## starts moving off-screen
@export var display_time: float

## Whether the messages intercepts mouse clicks or not
@export var handle_mouse_clicks: bool

@export_group("Start Config")

## Starting colours of a message
@export var start_colour_config: SMSMessageColourConfig

## Starting stylebox texture of a message. If you're just using the panel colours and text, leave 
## this as null.
@export var start_texture: StyleBox

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




## Texture used to highlight the panel when hovered over
#@export var panel_container_highlight_style_box_texture: StyleBox

## Colour of the message panel container when created
#@export var start_panel_container_modulation: Color = Color.TRANSPARENT

## Colour of the message text when created
#@export var start_text_colour: Color = Color.TRANSPARENT

## Colour of image when created
#@export var start_image_modulation: Color = Color.TRANSPARENT

## Highlight colour of text when hovering over a message with mouse.
## Only works if handle_mouse_clicks is true
#@export var text_highlight_colour: Color

## Highlight colour of the panel container when hovering over a message with mouse.
## Only works if handle_mouse_clicks is true
#@export var panel_highlight_colour: Color

## Contains parameters for moving a message to a position on screen, where the user can
## read it. The actual position is set in the sms_message_spawner
#@export var display_message_config: SMSMessageMoveConfig

## Contains parameters for when a message has finished displaying and moves off-screen
## (if desired)
#@export var exit_message_config: SMSMessageMoveConfig

@onready var message_rich_label: RichTextLabel = $MessageMarginContainer/HBoxContainer/RichTextMessageLabel
@onready var image_texture_rect: TextureRect = $MessageMarginContainer/HBoxContainer/ImageMarginContainer/MessageImage
@onready var message_margin_container: MarginContainer = $MessageMarginContainer
@onready var message_sound: AudioStreamPlayer = $MessageSound

var start_position_config: SMSMessagePositionConfig
var is_moving: bool = false


var is_displaying: bool = false
var mouse_inside: bool = false
var handling_mouse_click: bool = false
var pause_displaying: bool = false
var text: String
var is_set_to_delete: bool = false
var panel_container_using_texture: bool = false
var has_theme: bool = false
var has_override_theme: bool = false
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
	set_initial_modulations_and_textures()
	check_themes()
		
	display_timer = Timer.new()
	add_child(display_timer)
	display_timer.autostart = false
	
	display_timer.one_shot = false
	display_timer.wait_time = display_time
	display_timer.stop()
	display_timer.timeout.connect(on_display_message_finished)	
	
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


func set_initial_modulations_and_textures():
	#image_texture_rect.self_modulate = start_image_modulation
	#self_modulate.a = 1
	self.visible = false
	#self["theme_override_styles/panel"] = panel_container_style_box_texture
	message_rich_label.modulate.a = 0


func check_themes():
	if theme != null:
		print("Has theme")
		has_theme = true;
	
	var theme_override_style = self["theme_override_styles/panel"]
	
	if theme_override_style != null:
		print("Has override theme")
		has_override_theme = true
	
	original_style_box_override = theme_override_style
	
	if theme_override_style is StyleBoxTexture:
		print("Do this to StyleBoxTexture")
		theme_override_type = ThemeOverrideType.STYLEBOX_TEXTURE
	elif theme_override_style is StyleBoxFlat:
		print("Do this StyleBoxFlat")
		theme_override_type = ThemeOverrideType.STYLEBOX_FLAT
	elif theme_override_style is StyleBoxEmpty:
		print("Do this StyleBoxEmpty")
		theme_override_type = ThemeOverrideType.STYLEBOX_EMPTY
	elif theme_override_style is StyleBoxLine:
		print("Do this StyleBoxLine")
		theme_override_type = ThemeOverrideType.STYLEBOX_LINE


func get_text():
	return message_rich_label.text
	

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
	name = "PC_" + new_text
	
	await get_tree().process_frame
	size.y = message_margin_container.size.y


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
	print("SMS_Message: Message: ", text, " finished displaying.")
	finished_displaying.emit()


# Gets the config specified by sms_message_config_type. For the start config and 
# highlight config, we have to create a new object 
func get_message_config_from_enum(sms_message_config_type: SMSMessageConfigType) -> SMSMessageConfig:
	var sms_message_config := SMSMessageConfig.new()
	
	match(sms_message_config_type):
		SMSMessageConfigType.START:
			sms_message_config.to_colour_config = start_colour_config
			sms_message_config.to_texture = start_texture
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


func move(to_sms_message_config_type: SMSMessageConfigType,
		terminate_after: bool):	
	#if is_moving == true:
	#	await moving_finished
	
	#var from_config: SMSMessageConfig = get_message_config_from_enum(from_sms_message_config_type)
	var to_config: SMSMessageConfig = get_message_config_from_enum(to_sms_message_config_type)	
	
	#if from_config == null:
		#printerr("from_config is null.")
		#finish_move()
		#return
		
	if to_config == null:
		printerr("to_config is null.")
		finish_move()
		return
	
	var changing_colours: bool = to_config.is_changing_colours
	#var start_position: Vector2 = to_config.move_config.position_config.start_position
	var target_position: Vector2 = to_config.move_config.position
	
	self.visible = true
	is_moving = true
	
	# Tween position of message to target position and assign it to current_tween
	var move_tween: Tween = create_tween()
	move_tween.set_parallel(true).tween_property(
		self, 
		"position",
		to_config.move_config.position,
		to_config.move_config.move_duration
	).set_trans(
		to_config.move_config.colour_tween_transition_type
	).set_ease(
		to_config.move_config.colour_tween_ease_type
	)
	#current_move_tween = move_tween
	
	if changing_colours == true:
		var colour_tween_duration = to_config.move_config.colour_change_duration
		
		# Changing the colours of the message should not take longer than the move duration.
		# If it does, it might cause strange tweening where the desired colours aren't reached
		clampf(colour_tween_duration, 0, to_config.move_config.move_duration)
		
		# Create tween for changing the panel colour
		var panel_colour_tween: Tween = create_tween()
		panel_colour_tween.set_parallel(true
		).tween_property(
			self,
			"self_modulate",
			to_config.to_colour_config.panel_container_colour,
			colour_tween_duration
		).set_trans(
			to_config.move_config.colour_tween_transition_type
		).set_ease(
			to_config.move_config.colour_tween_ease_type
		)
		
		var text_colour_tween: Tween = create_tween()
		text_colour_tween.set_parallel(true
		).tween_property(
			self.message_rich_label,
			"theme_override_colors/default_color",
			to_config.to_colour_config.text_colour,
			colour_tween_duration
		).set_trans(
			to_config.move_config.colour_tween_transition_type
		).set_ease(
			to_config.move_config.colour_tween_ease_type
		)
		
		#Todo: text outline colour, text shadow colour, image modulation, texture?
		
		if terminate_after == false:
			move_tween.tween_callback(finish_move).set_delay(to_config.move_config.move_duration)
		else:
			move_tween.tween_callback(finish_move_and_delete).set_delay(to_config.move_config.move_duration)


# Moves this object to the target position in message_config in move_duration seconds
# using move_tween_transition_type and move_tween_ease_type if use_tween_transition_and_ease
# is true
#
# If change_colour is true, it will tween the panel container colour and font to 
# to_panel_container_colour and to_text_colour respectively using the change_duration
# and the change_tween_transition_type and change_tween_ease_type (if 
# use_tween_transition_and_ease is true in message_config
#
# To wait for the move, use await moving_finished if terminate_after is false
# To wait for the move and deletion, use await delete_message if terminate_after is true
#func move_old(start_position: Vector2, change_colour: bool = false, use_tween_transition_and_ease: bool = false,
		#message_config: SMSMessageConfig = display_config, terminate_after: bool = false,
		#use_start_colours: bool = false):
	#if message_config == null:
		#print_debug("Please set the message config object in sms_message.tscn")
		#finish_move()
		#return
		#
	#if is_moving == true:	
		#await moving_finished
	#
	#if use_start_colours:
		#self.position = start_position
		#self_modulate.a = 1
		#message_rich_label.modulate.a = 1
		#self_modulate = start_panel_container_modulation
		##message_rich_label.add_theme_color_override("font_color", start_text_colour)
		#message_rich_label.add_theme_color_override("default_color", start_text_colour)
		#
		#
	#is_moving = true
	#
	#var move_tween: Tween = create_tween()
	#var colour_tween: Tween
	#
	#move_tween.set_parallel(true)
	#if use_tween_transition_and_ease == true:
		#move_tween.tween_property(self, "position",
				#message_config.target_position, 
				#message_config.move_duration).set_trans(
				#message_config.move_tween_transition_type).set_ease(
				#message_config.move_tween_ease_type)
	#else: 
		#move_tween.tween_property(self, "position", 
				#message_config.target_position, message_config.move_duration)
	#
	#current_move_tween = move_tween
	#
	#if change_colour == true:
		#colour_tween = create_tween()
		#colour_tween.set_parallel(true)		
		#colour_tween.tween_property(self, "self_modulate", message_config.to_panel_container_colour, message_config.change_duration)		
		#colour_tween.tween_property(self.message_rich_label, "theme_override_colors/default_color", message_config.to_text_colour, message_config.change_duration)
		#current_colour_tween = colour_tween	
	#
	#if terminate_after == true:
		#move_tween.tween_callback(finish_move_and_delete).set_delay(message_config.move_duration)
	#else:
		#move_tween.tween_callback(finish_move).set_delay(message_config.move_duration)


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
	print("Moving finished. Deleting ", get_text())
	is_moving = false
	
	print("current_colour_tween: ", current_colour_tween)
	
	if current_colour_tween != null && current_colour_tween.is_running():
		print("waiting for colours: ", Time.get_datetime_string_from_system())
		await current_colour_tween.finished
		print("Finished waitiing for colours: ", Time.get_datetime_string_from_system())
	
	moving_finished.emit()
	delete_message.emit()
	handling_mouse_click = false
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
	
	#print("Mouse exited message: ", get_text())
	mouse_inside = false
	
	if has_override_theme == true:
		#print("Has override theme")
		self["theme_override_styles/panel"] = original_style_box_override
	
	if panel_container_using_texture == false:
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
