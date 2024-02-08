extends CanvasLayer
class_name SMSMessageSpawner

signal new_message_added_for_processing

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
var message_action_array: Array[SMSMessageAction]

var is_processing_message_text_queue: bool = false
var is_processing_message_move_array: bool = false
var is_doing_message_initial_move: bool = false
var is_reordering_messages: bool = false
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


func add_message(message_string: String):
	message_text_queue.append(message_string)
	
	print("AM: New string: ", message_string, " received. Appending to message_move_array.")	
	add_to_message_action_array(func(): process_messages(), SMSMessageAction.ActionType.INITIAL_PROCESS_MESSAGES)
	
	process_message_move_array()


func process_message_move_array():
	if message_action_array.size() <= 0:
		print("No message moves to process")
		return
	
	if is_processing_message_move_array == true:
		return
	
	is_processing_message_move_array = true
	var message_action: SMSMessageAction = message_action_array.pop_front()
	
	print("PMMA: Processing new action")	
	await message_action.run_action()
	print("PMMA: Finished processing new action")
	
	is_processing_message_move_array = false
	process_message_move_array()


func process_messages():
	if is_processing_message_text_queue == true:
		return
		
	if messages_on_screen.size() >= max_messages_on_screen:
		return
	
	if message_text_queue.size() <= 0:
		return
	
	# Add message to message_text_queue
	is_processing_message_text_queue = true
	
	var message: SMSMessage = await add_and_configure_message_object()
	
	add_to_message_action_array(func(): await initial_reorder_on_screen_messages(message), SMSMessageAction.ActionType.INITIAL_REORDER_MOVE, message)
	await process_message_move_array()
	
	add_to_message_action_array(func(): await move_message_initial(message), SMSMessageAction.ActionType.INITIAL_MOVE, message)
	await process_message_move_array()
	
	add_to_message_action_array(func(): await display_message(message), SMSMessageAction.ActionType.DISPLAY, message)
	await process_message_move_array()
	print("PM: Finished processing more messages after appending display message: ", message.get_text())
	
	is_processing_message_text_queue = false
	
	#print("PM: Appending process all messages again after message: ", message.get_text())
	add_to_message_action_array(func(): process_messages(), SMSMessageAction.ActionType.PROCESS_MESSAGES)
	await process_message_move_array()


func add_and_configure_message_object() -> SMSMessage:
	print("AACMO: Getting and configuring new message")
	var message_text: String = message_text_queue.pop_front()
	var message: SMSMessage = message_scene.instantiate()
	add_child(message)
	
	message.finished_displaying.connect(on_message_finished_displaying.bind(message))	
	message.set_label_text(message_text)
	
	set_anchors(message, message_screen_position)
	
	# Need to wait until next frame so the message size & positions properties are updated
	await get_tree().process_frame
	
	set_none_position(message)
	message.z_index = 0
	
	await get_tree().process_frame
	print("AACMO: Finished getting and configuring new message. Message: ", message.get_text())
	return message


func move_message_initial(message: SMSMessage):
	print("MMI: Doing initial move for message: ", message.get_text())
	
	if is_doing_message_initial_move == true:
		print("ALREADY DOING MESSAGE INITIAL MOVE: ", message.get_text())
		return
	
	if messages_on_screen.size() >= max_messages_on_screen:
		add_to_message_action_array(func(): await initial_reorder_on_screen_messages(message), SMSMessageAction.ActionType.INITIAL_REORDER_MOVE, message)
		
		add_to_message_action_array(func(): await move_message_initial(message), SMSMessageAction.ActionType.INITIAL_MOVE, message)
		
		add_to_message_action_array(func(): await display_message(message), SMSMessageAction.ActionType.DISPLAY, message)
		
		return
	
	is_doing_message_initial_move = true
	message.z_index = -1
	var start_position: Vector2 = get_message_start_position(message)
	var target_position: Vector2 = get_message_target_position(message)
	
	message.set_display_config_target_position(target_position)
	message.move(start_position, true, true, message.display_message_config, false, true)
	
	await message.moving_finished
	
	messages_on_screen.append(message)
	
	is_doing_message_initial_move = false
	print("MMI: Finished doing initial move for message: ", message.get_text())


func display_message(message: SMSMessage):
	print("DM: Displaying message: ", message.get_text())
	message.z_index = 0
	message.modulate = Color.RED
	message.display_message(message.position, true)


func move_message_off_screen(message: SMSMessage):
	print("MMOS: Moving message off screen: ", message.get_text())	
		
	is_moving_message_off_screen = true
	
	var message_size_y: float = message.size.y	
	
	message.set_exit_config_target_position(get_message_exit_position(message))	
	message.move_and_delete(get_message_exit_position(message), true)
	
	await message.delete_message
	
	var message_index: int = messages_on_screen.find(message)
	if message_index >= 0:
		messages_on_screen.remove_at(message_index)
	
	is_moving_message_off_screen = false
	print("MMOS: Finished moving message off screen: ", message.get_text())


func reorder_on_screen_messages(message: SMSMessage):
	print("ROSM: Reordering all messages for message: ", message.get_text())
	
	if messages_on_screen.size() <= 0:
		return
	
	if is_reordering_messages == true:
		print("ALREADY REORDERING MESSAGES: ", message.get_text())
		return
	
	is_reordering_messages = true
	var move_amount_y: float = message.size.y
	
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
	
	for current_message in messages_on_screen:
		if current_message.is_moving:
			await current_message.moving_finished
	
	#await messages_on_screen[0].moving_finished
	print("ROSM: Finished reordering all messages for message: ", message.get_text())
	
	is_reordering_messages = false


func initial_reorder_on_screen_messages(message: SMSMessage):
	print("IROSM: Reordering all messages for message: ", message.get_text())
	
	if messages_on_screen.size() <= 0:
		return
	
	if is_reordering_messages == true:
		print("ALREADY INITIALLY REORDERING MESSAGES: ", message.get_text())
		return
	
	is_reordering_messages = true
	var move_amount_y: float = message.size.y
	
	if message_screen_position == MessageScreenPosition.TOP:
		move_amount_y = -move_amount_y
		
	var current_message_index = messages_on_screen.size() - 1
	var y_position: float = message.size.y
	
	while current_message_index >= 0:
		var current_message = messages_on_screen[current_message_index]
		var target_position := Vector2(current_message.position.x, y_position)
		current_message.set_display_config_target_position(target_position)
		current_message.move(current_message.position)
		y_position += current_message.size.y
		current_message_index -= 1
	
	for current_message in messages_on_screen:
		if current_message.is_moving:
			await current_message.moving_finished
	
	print("IROSM: Finished reordering all messages for message: ", message.get_text())
	
	is_reordering_messages = false


func delete_message(message: SMSMessage):
	#message.queue_free()
	pass


func on_message_finished_displaying(message: SMSMessage):
	print("OMFD: Message: ", message.get_text(), " has finished displaying.")
	
	add_to_message_action_array(func(): await move_message_off_screen(message), SMSMessageAction.ActionType.FINISHING_MOVE, message)
	await process_message_move_array()
	
	print("OMFD: Message: ", message.get_text(), " has finished moving. Reordering...")
	
	add_to_message_action_array(func(): await reorder_on_screen_messages(message), SMSMessageAction.ActionType.REORDER_MOVE, message)
	await process_message_move_array()
	
	print("OMFD: Message: ", message.get_text(), " has finished moving and reordering. Deleting...")
	
	add_to_message_action_array(func(): await delete_message(message), SMSMessageAction.ActionType.MESSAGE_DELETE, message)	
	await process_message_move_array()
	
	add_to_message_action_array(func(): process_messages(), SMSMessageAction.ActionType.PROCESS_MESSAGES)
	await process_message_move_array()


func add_to_message_action_array(action: Callable, action_type: SMSMessageAction.ActionType, 
		message: SMSMessage = null):
	var message_move := SMSMessageAction.new()
	message_move.set_action_type(action_type)
	message_move.set_action(action)
	
	if message != null:
		message_move.message = message
	
	message_action_array.append(message_move)


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


# Sets the position of the message if it is not set to move from anywhere off-screen
func set_none_position(message: SMSMessage):
	if (message_source_direction == MessageMoveDirection.NONE &&
			message_screen_position == MessageScreenPosition.BOTTOM):
		var viewport_size: Vector2 = get_viewport().get_visible_rect().size
		message.position.y = viewport_size.y - message.size.y
