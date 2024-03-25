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
var messages_to_process: Array[SMSMessage]
var messages_on_screen: Array[SMSMessage]
var message_action_array: Array[SMSMessageAction]

var is_processing_message_text_queue: bool = false
var is_processing_message_move_array: bool = false
var is_doing_message_initial_move: bool = false
var is_reordering_messages: bool = false
var is_moving_message_off_screen: bool = false

var number_messages_processing: int = 0

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


# Adds a message to message_text_queue and queues the processing of this object. This should be all
# you need from this class to spawn messages unless you want different functionality
func add_message(message_string: String):	
	message_text_queue.append(message_string)
	
	if messages_on_screen.size() >= max_messages_on_screen:
		return
	
	add_to_message_action_array(func(): await process_messages(), SMSMessageAction.ActionType.INITIAL_PROCESS_MESSAGES)
	
	await process_message_action_array()


# Processes actions in the message_action_array object, and perform each one sequentially
func process_message_action_array():
	get_tree().process_frame
	
	if message_action_array.size() <= 0:
		print("No message moves to process")
		return
	
	if is_processing_message_move_array == true:
		return
	
	is_processing_message_move_array = true
	
	var message_action: SMSMessageAction = message_action_array.pop_front()
	
	if is_instance_valid(message_action) == false:
		return
	
	if ((message_action.get_action_type() == SMSMessageAction.ActionType.INITIAL_PROCESS_MESSAGES ||
			message_action.get_action_type() == SMSMessageAction.ActionType.PROCESS_MESSAGES) &&
			messages_on_screen.size() >= max_messages_on_screen):
		is_processing_message_move_array = false
		process_message_action_array()
		return
	
	await message_action.run_action()
	
	is_processing_message_move_array = false
	process_message_action_array()


# Processes messages that are in the message_text_queue object, and queues actions for their 
# display
func process_messages():	
	if is_processing_message_text_queue == true:
		return
	
	if number_messages_processing >= max_messages_on_screen:
		return
	
	if messages_on_screen.size() >= max_messages_on_screen:
		return
	
	if message_text_queue.size() <= 0:
		return
	
	# Add message to message_text_queue
	is_processing_message_text_queue = true
	number_messages_processing += 1
	
	var message: SMSMessage = await add_and_configure_message_object()
	
	if message == null:
		is_processing_message_text_queue = false
		return
	
	add_to_message_action_array(func(): await reorder_on_screen_messages(message, true), SMSMessageAction.ActionType.INITIAL_REORDER_MOVE, message)
	
	add_to_message_action_array(func(): await move_message_initial(message), SMSMessageAction.ActionType.INITIAL_MOVE, message)
	
	add_to_message_action_array(func(): await display_message(message), SMSMessageAction.ActionType.DISPLAY, message)
	
	is_processing_message_text_queue = false
	
	add_to_message_action_array(func(): await process_messages(), SMSMessageAction.ActionType.PROCESS_MESSAGES)
	await process_message_action_array()


# Instantiates a new message using the first object in message_text_queue, adds it to the tree,
# sets the anhchors, and sets the initial position.
func add_and_configure_message_object() -> SMSMessage:
	await get_tree().process_frame
	
	if messages_on_screen.size() > max_messages_on_screen:
		return
	
	var message_text: String = message_text_queue.pop_front()
	var message: SMSMessage = message_scene.instantiate()
	add_child(message)
	
	message.finished_displaying.connect(on_message_finished_displaying.bind(message))	
	message.set_label_text(message_text)
	
	set_anchors(message, message_screen_position)
	
	if message_screen_position == MessageScreenPosition.TOP:
		message.position.y = -message.size.y
	elif message_screen_position == MessageScreenPosition.BOTTOM:
		message.position.y = get_viewport().size.y + message.size.y
	
	# Need to wait until next frame so the message size & positions properties are updated
	await get_tree().process_frame
	
	message.z_index = 0
	
	await get_tree().process_frame
	
	return message


# Moves the message from the off screen position set in message_source_direction to
# the position set in message_screen_position
func move_message_initial(message: SMSMessage):	
	if is_doing_message_initial_move == true:
		return
		
	is_doing_message_initial_move = true
	message.z_index = -1
	var start_position: Vector2 = get_message_start_position(message)
	var target_position: Vector2 = get_message_target_position(message)
	
	message.set_display_config_target_position(target_position)
	#message.move(start_position, true, true, message.display_message_config, false, true)
	message.move(SMSMessage.SMSMessageConfigType.DISPLAY, false)
	
	await message.moving_finished
	
	messages_on_screen.append(message)
	
	is_doing_message_initial_move = false


# Changes Z-index of message so it appears in front of any possible messages and starts a 
# "display" timer for when it should start moving off screen
func display_message(message: SMSMessage):
	message.z_index = 0
	message.display_message(message.position, true)


# Moves the message off screen based on what is set in message_exit_direction
func move_message_off_screen(message: SMSMessage):
	if is_instance_valid(message) == false:
		return
	
	is_moving_message_off_screen = true
	
	var message_size_y: float = message.size.y	
	
	message.set_exit_config_target_position(get_message_exit_position(message))	
	message.move_and_delete(get_message_exit_position(message), true)
	
	await message.delete_message
	
	var message_index: int = messages_on_screen.find(message)
	if message_index >= 0:
		messages_on_screen.remove_at(message_index)
	
	is_moving_message_off_screen = false
	delete_message(message)


# Reorders messages on the screen according to the message_screen_position
func reorder_on_screen_messages(message: SMSMessage, ignore_first_message: bool = false):
	if is_instance_valid(message) == false:
		return
	
	if messages_on_screen.size() <= 0:
		return
	
	if is_reordering_messages == true:
		return
	
	is_reordering_messages = true
	
	if message_screen_position == MessageScreenPosition.TOP:
		await reorder_messages_at_top_of_screen(message, ignore_first_message)
	else:
		await reorder_messages_at_bottom_of_screen(message, ignore_first_message)
	
	is_reordering_messages = false


# Reorders messages at the top of the screen so that they stack
func reorder_messages_at_top_of_screen(message: SMSMessage, ignore_first_message: bool = false):
	var move_amount_y: float = -message.size.y	
	
	var current_message_index = messages_on_screen.size() - 1
	var y_position: float = 0

	if ignore_first_message == true:
		# leaves space for message to move in 
		y_position = message.size.y
	
	while current_message_index >= 0:
		var current_message = messages_on_screen[current_message_index]
		var target_position := Vector2(current_message.position.x, y_position)
		current_message.set_display_config_target_position(target_position)
		#current_message.move(current_message.position)
		current_message.move(SMSMessage.SMSMessageConfigType.DISPLAY, false)
		y_position += current_message.size.y
		current_message_index -= 1
	
	for current_message in messages_on_screen:
		if current_message.is_moving:
			await current_message.moving_finished


# Reorders messages at the bottom of the screen so that they stack
func reorder_messages_at_bottom_of_screen(message: SMSMessage, ignore_first_message: bool = false):
	var move_amount_y: float = message.size.y
	var viewport_size_y: float = get_viewport().get_visible_rect().size.y	
	var current_message_index = messages_on_screen.size() - 1
	var y_position: float = viewport_size_y - move_amount_y
	
	if ignore_first_message == true:
		# leaves space for message to move in 
		y_position -= move_amount_y
	
	while current_message_index >= 0:
		var current_message = messages_on_screen[current_message_index]
		var target_position := Vector2(current_message.position.x, y_position)
		current_message.set_display_config_target_position(target_position)
		#current_message.move(current_message.position)
		current_message.move(SMSMessage.SMSMessageConfigType.DISPLAY, false)
		y_position -= current_message.size.y
		current_message_index -= 1
	
	for current_message in messages_on_screen:
		if current_message.is_moving:
			await current_message.moving_finished


# Removes any further actions in message_action_array and deletes the message
func delete_message(message: SMSMessage):
	if is_instance_valid(message) == false:
		return
	
	var action_index: int = 0
	
	message.is_set_to_delete = true
	for action in message_action_array:
		if message == action.get_message():
			message_action_array.remove_at(action_index)
		
		action_index += 1 
	
	number_messages_processing -= 1
	message.queue_free()


# When a message is finished displaying, this adds several actions to message_action_array
func on_message_finished_displaying(message: SMSMessage):
	add_to_message_action_array(func(): await move_message_off_screen(message), SMSMessageAction.ActionType.FINISHING_MOVE, message)
	
	add_to_message_action_array(func(): await reorder_on_screen_messages(message, false), SMSMessageAction.ActionType.REORDER_MOVE, message)
	
	add_to_message_action_array(func(): await process_messages(), SMSMessageAction.ActionType.PROCESS_MESSAGES)
	
	process_message_action_array()


# Adds an action to be executed to message_action_array. Actions are processed one after another
# since handling them as they come becomes too complex
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
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var start_position_x: float
	var start_position_y: float
	var start_position: Vector2
	
	if message_source_direction == MessageMoveDirection.NONE:		
		pass
	
	# There's a way to do tbe below in fewer lines, but I find this more readable and 
	# I doubt it takes much more time to process
	if message_screen_position == MessageScreenPosition.TOP:
		if message_source_direction == MessageMoveDirection.NONE:
			return Vector2(message.position.x, 0)
		elif message_source_direction == MessageMoveDirection.TOP:
			start_position_x = message.position.x
			start_position_y = message.position.y - message.size.y
		elif message_source_direction == MessageMoveDirection.BOTTOM:
			start_position_x = message.position.x
			start_position_y = viewport_size.y + message.size.y
		elif message_source_direction == MessageMoveDirection.LEFT:
			start_position_x = message.position.x - message.size.x
			start_position_y = 0
		elif message_source_direction == MessageMoveDirection.RIGHT:
			start_position_x = message.position.x + message.size.x
			start_position_y = 0
	elif message_screen_position == MessageScreenPosition.BOTTOM:
		if message_source_direction == MessageMoveDirection.NONE:
			start_position_x = message.position.x
			start_position_y = viewport_size.y - message.size.y
		elif message_source_direction == MessageMoveDirection.TOP:
			start_position_x = message.position.x
			start_position_y = -message.size.y
		elif message_source_direction == MessageMoveDirection.BOTTOM:
			start_position_x = message.position.x
			start_position_y = message.position.y + message.size.y
		elif message_source_direction == MessageMoveDirection.LEFT:
			start_position_x = message.position.x - message.size.x
			start_position_y = viewport_size.y - message.size.y
		elif message_source_direction == MessageMoveDirection.RIGHT:
			start_position_x = message.position.x + message.size.x
			start_position_y = viewport_size.y - message.size.y
	
	start_position = Vector2(start_position_x, start_position_y)
	return start_position


# Returns the target position of the message when it is instantiated, which is currently
# only the top or bottom of the screen.
func get_message_target_position(message: SMSMessage) -> Vector2:	
	var viewport_size = get_viewport().get_visible_rect().size
	var target_position_x: float
	var target_position_y: float
	var target_position: Vector2	
	
	if message_screen_position == MessageScreenPosition.TOP:
		target_position_x = message.position.x
		target_position_y = 0
	elif message_screen_position == MessageScreenPosition.BOTTOM:
		target_position_x = message.position.x
		target_position_y = viewport_size.y - message.size.y
	
	target_position = Vector2(target_position_x, target_position_y)
	
	return target_position


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
