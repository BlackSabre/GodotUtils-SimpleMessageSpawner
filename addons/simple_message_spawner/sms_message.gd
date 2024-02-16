extends PanelContainer
class_name SMSMessage

signal moving_finished
signal finished_displaying(message: SMSMessage)
signal displaying_paused(message: SMSMessage)
signal delete_message
signal resume_displaying(message: SMSMessage)

## Colour of the message panel container when created
@export var start_panel_container_colour: Color

## Colour of the message text when created
@export var start_text_colour: Color

## Contains parameters for moving a message to a position on screen, where the user can
## read it. The actual position is set in the sms_message_spawner
@export var display_message_config: SMSMessageMoveConfig

## Contains parameters for when a message has finished displaying and moves off-screen
## (if desired)
@export var exit_message_config: SMSMessageMoveConfig

## How long the message should display after moving into place and before it
## starts moving again
@export var display_time: float

## Whether this object intercepts mouse clicks
@export var handle_mouse_clicks: bool

@onready var message_label: Label = $MessageMarginContainer/MessageLabel
@onready var message_sound: AudioStreamPlayer = $MessageSound

var is_moving: bool = false
var is_displaying: bool = false
var mouse_inside: bool = false
var handling_mouse_click: bool = false
var pause_displaying: bool = false
var text: String
var is_set_to_delete = false

var display_timer: Timer
var test_orig_colour: Color

enum move_configs {
	DISPLAY_CONFIG,
	EXIT_CONFIG,
}

func _ready():
	self_modulate.a = 0
	message_label.modulate.a = 0
	
	display_timer = Timer.new()
	add_child(display_timer)
	display_timer.autostart = false
	#display_timer.one_shot = true
	display_timer.one_shot = false
	display_timer.wait_time = display_time
	display_timer.stop()
	display_timer.timeout.connect(on_display_message_finished)
	
	if handle_mouse_clicks == true:
		mouse_filter = MOUSE_FILTER_STOP
	else:
		mouse_filter = MOUSE_FILTER_IGNORE
	
	

func _input(event):
	if handle_mouse_clicks == false:
		return
		
	if (event is InputEventMouseButton == true && handling_mouse_click == false 
			&& event.button_index == MOUSE_BUTTON_LEFT && event.pressed == true 
			&& mouse_inside == true):
			await get_tree().process_frame
			handle_mouse_click()


func get_text():
	return message_label.text
	

func handle_mouse_click():
	if handling_mouse_click == true:
		return
	
	handling_mouse_click = true
	await get_tree().create_timer(3).timeout
	handling_mouse_click = false


# sets the text in message_label
func set_label_text(new_text: String) -> void:
	self.text = new_text
	message_label.text = new_text
	name = "PC_" + new_text


# sets the target_position in display_message_config
func set_display_config_target_position(target_position: Vector2):
	display_message_config.target_position = target_position


# sets the target_position in exit_message_config
func set_exit_config_target_position(target_position: Vector2):
	exit_message_config.target_position = target_position


# Main method to show a message. Note that this does not handle moving the message
# off screen and deleting it. I tried to do this all here, but if the position changes,
# the position off screen has to be recalculated, which is done on the sms_message_spawner
func display_message(start_position: Vector2, change_colour: bool):
	if is_moving == true:
		await moving_finished
		
	self.position = start_position
	self_modulate.a = 1
	message_label.modulate.a = 1
	
	if message_sound != null:
		message_sound.play()
	
	display_timer.start(display_time)


func on_display_message_finished():
	print("SMS_Message: Message: ", text, " finished displaying.")
	finished_displaying.emit()


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
func move(start_position: Vector2, change_colour: bool = false, use_tween_transition_and_ease: bool = false,
		message_config: SMSMessageMoveConfig = display_message_config, terminate_after: bool = false,
		use_start_colours: bool = false):
	if message_config == null:
		print_debug("Please set the message config object in sms_message.tscn")
		finish_move()
		return
		
	if is_moving == true:
		await moving_finished
	
	if use_start_colours:
		self.position = start_position
		self_modulate.a = 1
		message_label.modulate.a = 1
		self_modulate = start_panel_container_colour
		message_label.add_theme_color_override("font_color", start_text_colour)	
		
	is_moving = true
	
	var move_tween: Tween = create_tween()
	var colour_tween: Tween
	
	move_tween.set_parallel(true)
	if use_tween_transition_and_ease == true:
		move_tween.tween_property(self, "position",
				message_config.target_position,message_config.move_duration).set_trans(
				message_config.move_tween_transition_type).set_ease(
				message_config.move_tween_ease_type)
	else: 
		move_tween.tween_property(self, "position", 
				message_config.target_position, message_config.move_duration)
	
	if change_colour == true:
		colour_tween = create_tween()
		colour_tween.set_parallel(true)		
		colour_tween.tween_property(self, "self_modulate", message_config.to_panel_container_colour, message_config.change_duration)
		colour_tween.tween_property(self.message_label, "theme_override_colors/font_color", message_config.to_text_colour, message_config.change_duration)
	
	if terminate_after == true:
		move_tween.tween_callback(finish_move_and_delete).set_delay(message_config.move_duration)
	else:
		move_tween.tween_callback(finish_move).set_delay(message_config.move_duration)


# moves this object to the target position using exit_message_config and deletes it 
# afterwards
func move_and_delete(target_position: Vector2, change_colour: bool):
	#print("In Message: Move and delete")
	if is_moving == true:
		await moving_finished
	
	
	exit_message_config.target_position = target_position
	#print("In Message: Move!!!!")
	move(position, true, true, exit_message_config, true, false)
	
	await delete_message


# At the moment, just starts timer for displaying before moving off_screen
# If you want to do something with this object while it's displaying, this would be
# a decent place to do it
func display():
	is_displaying = true
	
	await get_tree().create_timer(display_time).timeout
	
	#if is_moving == true:
		#await moving_finished
	
	if pause_displaying == false:
		#print("Emitting finished displaying")
		finished_displaying.emit()
		is_displaying = false


# Called after a move is finished
func finish_move():
	is_moving = false
	moving_finished.emit()


# Called after a move and when it's set to delete
func finish_move_and_delete():
	#print("Moving finished. Deleting")
	is_moving = false
	moving_finished.emit()
	delete_message.emit()
	handling_mouse_click = false
	#queue_free()


func _on_mouse_entered():
	if handle_mouse_clicks == false:
		return
	
	if check_mouse_cursor_in_viewport() == false:
		return
	
	test_orig_colour = modulate
	modulate = Color.CHARTREUSE
	display_timer.stop()
	mouse_inside = true
	pause_displaying = true


func _on_mouse_exited():
	if handle_mouse_clicks == false || is_moving == true:
		return
		
	mouse_inside = false
	modulate = test_orig_colour
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
