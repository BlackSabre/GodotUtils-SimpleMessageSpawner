extends CanvasLayer
class_name SMSMessageSpawner

signal new_message_added_for_processing
signal all_messages_moved
signal new_slot_opened
signal can_move_messages
signal can_continue_processing
signal message_finished_displaying


signal finished_initial_move
signal finished_y_moves
signal finished_reordering_messages_on_screen
signal finished_moving_message_off_screen



## Part of screen where message displays
@export var message_screen_position: MessageScreenPosition = MessageScreenPosition.TOP

## Direction off-screen from where the message comes from
## i.e. message looking like it comes from the top
@export var message_source_direction: MessageMoveDirection = MessageMoveDirection.TOP

## Direction off-screen where the message disappears to
## i.e message moves off-screen to the right after displaying
@export var message_exit_direction: MessageMoveDirection = MessageMoveDirection.NONE

## Maximum number of messages that can show on the screen at once.
## If the messages are set to display for a long time, messages will be queued
## If the messages are set to display quickly, this number may not ever be reached
@export var max_messages_on_screen: int = 3

@onready var message_scene: PackedScene = preload("res://addons/simple_message_spawner/sms_message.tscn")

var message_text_queue: Array[String]
var messages_on_screen: Array[SMSMessage]
var message_move_array: Array[SMSMessageAction]
var processing_messages: bool = false
var messages_moving: bool = false
var processing_move_array: bool = false

var is_adding_new_message: bool = false
var is_moving_messages_y_value: bool = false
var reordering_messages: bool = false
var is_moving_message_off_screen: bool = false

# Part of screen where the popups display. Didn't bother with left and right 
# as it doesn't seem like normal behaviour for a message message of this 
# kind
enum MessageScreenPosition {
	TOP,
	BOTTOM,
}

# The direction messages move to/from the screen
enum MessageMoveDirection {
	NONE,
	TOP,
	BOTTOM,
	LEFT,
	RIGHT,
}

func _ready():
	new_message_added_for_processing.connect(process_messages)
	
	#add_message("1. This is a message")
	


# Main function to be called by outside classes to create a message on screen
# Adds the message to message_queue for processing
func add_message(message: String) -> void:
	message_text_queue.append(message)
	new_message_added_for_processing.emit()


# Gets string from message_text_queue, creates an sms_message_object and moves
# it into position.
func process_messages() -> void:	
	if processing_messages == true:
		return
		
	if message_text_queue.size() <= 0:
		return
	
	if messages_on_screen.size() >= max_messages_on_screen:
		return
	
	processing_messages = true
	var sms_message: SMSMessage = await add_and_configure_message_object()
	
	
	
	#await move_message_initial(sms_message)
	
	# Move all y-positions of existing messages
	if messages_on_screen.size() > 0:
		var move_all_messages_y_action := SMSMessageAction.new()
		move_all_messages_y_action.set_message(sms_message)
		move_all_messages_y_action.set_action(func(): await move_all_messages_y_position(sms_message))
		move_all_messages_y_action.set_action_type(SMSMessageAction.ActionType.Y_MOVE)
		message_move_array.append(move_all_messages_y_action)
		#await process_message_move_array()
	
	# Move new message into position
	var initial_move_action := SMSMessageAction.new()
	initial_move_action.set_message(sms_message)
	initial_move_action.set_action(func(): await move_message_initial(sms_message))
	initial_move_action.set_action_type(SMSMessageAction.ActionType.INITIAL_MOVE)
	message_move_array.append(initial_move_action)
	
	await process_message_move_array()
	#print("Now display")
	
	# Display
	display_message(sms_message)
	#var display_move_callable: Callable = func(): await display_message(sms_message)
	#message_move_array.append(display_move_callable)
	#display_message(sms_message)
	
	#print("Finished processing entire message")
	#is_currently_processing = false
	processing_messages = false
	await process_messages()


func move_message_initial(sms_message: SMSMessage):
	is_adding_new_message = true
	var start_position: Vector2 = get_message_start_position(sms_message)
	var target_position: Vector2 = get_message_target_position(sms_message)
	
	sms_message.set_display_config_target_position(target_position)
	messages_on_screen.append(sms_message)
	sms_message.move(start_position, true, true, sms_message.display_message_config, false, true)
	
	await sms_message.moving_finished
	
	finished_initial_move.emit()
	is_adding_new_message = false

#
#func move_ys(sms_message: SMSMessage):
	##if is_adding_new_message == true:
		##await finished_initial_move
	##
	##if is_moving_messages_y_value == true:
		##await finished_y_moves
##
	##if reordering_messages == true:
		##await finished_reordering_messages_on_screen
	##
	##if is_moving_message_off_screen == true:
		##await finished_moving_message_off_screen
	#
	#is_moving_messages_y_value = true
	##print("Moving ys")
	#move_all_messages_y_position(sms_message)
	#await finished_y_moves
	##print("All ys moved")
	#is_moving_messages_y_value = false
	#can_move_messages.emit()


# Moves all messages on screen by the y-size of current_message
func move_all_messages_y_position(current_message: SMSMessage):
	var move_amount: float = current_message.size.y
	
	if message_screen_position == MessageScreenPosition.BOTTOM:
		move_amount = -move_amount
	
	for message in messages_on_screen:
		if !message:
			continue
		
		#if message.is_moving:
			#await message.moving_finished
		
		if message == current_message:
			continue
		
		message.z_index = 0 # ensures the messages don't get covered by incoming messages
		var target_position := Vector2(message.position.x, message.position.y + move_amount)
		
		message.set_display_config_target_position(target_position)
		message.move(message.position)
	
	if messages_on_screen[messages_on_screen.size() - 1] != null:
		await messages_on_screen[messages_on_screen.size() - 1].moving_finished
	
	finished_y_moves.emit()


func process_move_array_and_messages():
	await process_message_move_array()
	await process_messages()


func display_message(sms_message: SMSMessage):
	sms_message.display()


func move_message_off_screen(sms_message: SMSMessage):
	if sms_message == null: 
		return
	
	is_moving_message_off_screen = true
	
	var message_size_y: float = sms_message.size.y	
	
	sms_message.set_exit_config_target_position(get_message_exit_position(sms_message))	
	sms_message.move_and_delete(get_message_exit_position(sms_message), true)
	
	await sms_message.delete_message
	
	is_moving_message_off_screen = false
	
	
	#finished_moving_message_off_screen.emit()
	#await process_move_array_and_messages()


func add_and_configure_message_object() -> SMSMessage:
	if message_text_queue.size() <= 0:
		return
		
	var message_text: String = message_text_queue.pop_front()
	var sms_message: SMSMessage = message_scene.instantiate()
	add_child(sms_message)
	
	sms_message.finished_displaying.connect(on_message_finished_displaying.bind(sms_message))
	#sms_message.resume_displaying.connect(on_message_display_resume.bind(sms_message))
	sms_message.set_label_text(message_text)
	
	set_anchors(sms_message, message_screen_position)
	
	# Need to wait until next frame so the message size & positions properties are updated
	await get_tree().process_frame
	
	set_none_position(sms_message)
	sms_message.z_index = -messages_on_screen.size()
	
	return sms_message


func on_message_display_resume(message: SMSMessage):
	display_message(message)


func process_message_move_array() -> void:
	if processing_move_array == true:
		return
	
	if message_move_array.size() <= 0:
		print("No moves to process")
		can_continue_processing.emit()
		return
	
	processing_move_array = true
	var message_action: SMSMessageAction = message_move_array.pop_front()
	
	#print("Processing next action. Message: ", message_action.message.get_text(), " Move type: ", message_action.get_action_type_string())
	await message_action.run_action()
	#print("Finished Action")
	processing_move_array = false
	await process_message_move_array()
	#print("Finished message move. Calling again")
	
	

# Sets the anchors of message based on the value set in message_screen_position. 
# it'll be either top wide or bottom wide
func set_anchors(message: SMSMessage, message_screen_position: MessageScreenPosition) -> void:
	if message_screen_position == MessageScreenPosition.TOP:
		# Anchors for top wide
		message.anchor_left = 0
		message.anchor_top = 0
		message.anchor_bottom = 0
		message.anchor_right = 1
	elif message_screen_position == MessageScreenPosition.BOTTOM:
		# Anchors for bottom wide
		message.anchor_left = 0
		message.anchor_top = 1
		message.anchor_bottom = 1
		message.anchor_right = 1


# The start position for a message is always off-screen. We just need to calculate
# the offset based on where its set to come from in the message_source_direction
# variable using the size of the message since the anchors are set
func get_message_start_position(message: SMSMessage) -> Vector2:	
	var viewport_size = get_viewport().get_visible_rect().size
	var start_position_x: float
	var start_position_y: float
	var start_position: Vector2
	
	if message_source_direction == MessageMoveDirection.NONE:
		return Vector2(message.position)
	
	# There's a way to do tbe below in fewer lines, but I find this more readable and 
	# I doubt it takes much more time to process if there is any difference at all
	if message_screen_position == MessageScreenPosition.TOP:
		if message_source_direction == MessageMoveDirection.TOP:
			start_position_x = message.position.x
			start_position_y = message.position.y - message.size.y
		elif message_source_direction == MessageMoveDirection.BOTTOM:
			start_position_x = message.position.x
			start_position_y = viewport_size.y + message.size.y
		elif message_source_direction == MessageMoveDirection.LEFT:
			start_position_x = message.position.x - message.size.x
			start_position_y = message.position.y
		elif message_source_direction == MessageMoveDirection.RIGHT:
			start_position_x = message.position.x + message.size.x
			start_position_y = message.position.y
	elif message_screen_position == MessageScreenPosition.BOTTOM:
		if message_source_direction == MessageMoveDirection.TOP:
			start_position_x = message.position.x
			start_position_y = 0 - message.size.y
		elif message_source_direction == MessageMoveDirection.BOTTOM:
			start_position_x = message.position.x
			start_position_y = message.position.y + message.size.y
		elif message_source_direction == MessageMoveDirection.LEFT:
			start_position_x = message.position.x - message.size.x
			start_position_y = message.position.y - message.size.y
		elif message_source_direction == MessageMoveDirection.RIGHT:
			start_position_x = message.position.x + message.size.x
			start_position_y = message.position.y - message.size.y
	
	start_position = Vector2(start_position_x, start_position_y)
	return start_position


# The position where a message goes off-screen. We just calculate the offset based
# on where it currently is and check the message_exit_direction for the desired
# place to go
func get_message_exit_position(message: SMSMessage) -> Vector2:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var exit_position_x: float
	var exit_position_y: float
	var exit_position: Vector2	
	
	if message_exit_direction == MessageMoveDirection.NONE:
		return Vector2(message.position)

	# There's a way to do tbe below in fewer lines, but I find this more readable and 
	# I doubt it takes much more time to process if there is any difference at all
	if message_screen_position == MessageScreenPosition.TOP:
		if message_exit_direction == MessageMoveDirection.TOP:
			exit_position_x = message.position.x
			exit_position_y = 0 - message.size.y
		elif message_exit_direction == MessageMoveDirection.BOTTOM:
			exit_position_x = message.position.x
			exit_position_y = viewport_size.y + message.size.y
		elif message_exit_direction == MessageMoveDirection.LEFT:
			exit_position_x = message.position.x - message.size.x
			exit_position_y = message.position.y
		elif message_exit_direction == MessageMoveDirection.RIGHT:
			exit_position_x = message.position.x + message.size.x
			exit_position_y = message.position.y
	elif message_screen_position == MessageScreenPosition.BOTTOM:
		if message_exit_direction == MessageMoveDirection.TOP:
			exit_position_x = message.position.x
			exit_position_y = 0 - message.size.y
		elif message_exit_direction == MessageMoveDirection.BOTTOM:
			exit_position_x = message.position.x
			exit_position_y = viewport_size.y + message.size.y
		elif message_exit_direction == MessageMoveDirection.LEFT:
			exit_position_x = message.position.x - message.size.x
			exit_position_y = message.position.y
		elif message_exit_direction == MessageMoveDirection.RIGHT:
			exit_position_x = message.position.x + message.size.x
			exit_position_y = message.position.y

	exit_position = Vector2(exit_position_x, exit_position_y)
	return exit_position


# The target position should be pretty much the same as when we instantiate it because
# of the anchors. However, when the messages have anchors at the bottom of the 
# screen, they need to be moved up by their size first unless the
# message_source_direction value is NONE
func get_message_target_position(message: SMSMessage) -> Vector2:	
	var viewport_size = get_viewport().get_visible_rect().size
	var target_position_x: float
	var target_position_y: float
	var target_position: Vector2
	
	if message_source_direction == MessageMoveDirection.NONE:
		return Vector2(message.position)
	elif message_screen_position == MessageScreenPosition.TOP:
		target_position_x = message.position.x
		target_position_y = message.position.y
	elif message_screen_position == MessageScreenPosition.BOTTOM:
		target_position_x = message.position.x
		target_position_y = message.position.y - message.size.y
	
	target_position = Vector2(target_position_x, target_position_y)
	return target_position


# When the message is finished displaying, this gets called to move it off-screen
# and delete it when it's done
func on_message_finished_displaying(finished_message: SMSMessage):
	#print("Message needs to go.")
	#if finished_message.pause_displaying == true:
		#print("Message paused. Returning")
		#return
	
	# append move off-screen movement
	var move_off_screen_action := SMSMessageAction.new()
	move_off_screen_action.set_message(finished_message)
	move_off_screen_action.set_action(func(): await move_message_off_screen(finished_message))
	move_off_screen_action.set_action_type(SMSMessageAction.ActionType.FINISHING_MOVE)
	message_move_array.append(move_off_screen_action)
	
	await process_message_move_array()
	#print("Check if need to reorder")
	# reorder if needed
	if messages_on_screen.size() > 0:
		#print("Reordering")
		var message_index: int = messages_on_screen.find(finished_message)
		if message_index >= 0:
			messages_on_screen.remove_at(message_index)		
	
		if message_index > 0:
			#print("we need to move")
			var reorder_message_action := SMSMessageAction.new()
			reorder_message_action.set_message(finished_message)
			reorder_message_action.set_action(func(): await reorder_messages(finished_message.size.y, message_index))
			reorder_message_action.set_action_type(SMSMessageAction.ActionType.REORDER_MOVE)
			message_move_array.append(reorder_message_action)
		
	var final_process_action := SMSMessageAction.new()
	final_process_action.set_message(finished_message)
	final_process_action.set_action_type(SMSMessageAction.ActionType.REORDER_MOVE)
	final_process_action.set_action(func(): await process_move_array_and_messages())
	message_move_array.append(final_process_action)
	#finished_message.queue_free()


func reorder_messages(move_amount_y: float, message_index: int):
	#print("in reorder messages")
	
	reordering_messages = true
	
	if message_screen_position == MessageScreenPosition.TOP:
		move_amount_y = -move_amount_y
		
	var current_message_index = messages_on_screen.size() - 1
	var y_position: float = 0
	
	while current_message_index >= 0:
		var current_message = messages_on_screen[current_message_index]
		var target_position := Vector2(current_message.position.x, y_position)
		current_message.set_display_config_target_position(target_position)
		current_message.move(current_message.position)
		y_position += current_message.size.y
		current_message_index -= 1
		#print("awaiting message: ", current_message.get_text())
		#await current_message.moving_finished
	
	await messages_on_screen[0].moving_finished
	
	reordering_messages = false
	finished_reordering_messages_on_screen.emit()


# Sets the position of the message if it is not set to move from anywhere off-screen
func set_none_position(message: SMSMessage):
	if (message_source_direction == MessageMoveDirection.NONE &&
			message_screen_position == MessageScreenPosition.BOTTOM):
		var viewport_size: Vector2 = get_viewport().get_visible_rect().size
		message.position.y = viewport_size.y - message.size.y
