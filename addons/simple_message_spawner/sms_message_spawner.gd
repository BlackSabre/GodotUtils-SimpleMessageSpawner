extends CanvasLayer
class_name SMSMessageSpawner

signal new_message_added_for_processing
signal all_messages_moved
signal new_slot_opened

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
var is_currently_processing: bool = false

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


# Main function to be called by outside classes to create a message on screen
# Adds the message to message_queue for processing
func add_message(message: String) -> void:
	message_text_queue.append(message)
	new_message_added_for_processing.emit()


# Gets string from message_text_queue, creates an sms_message_object and moves
# it into position.
func process_messages() -> void:	
	if is_currently_processing == true:
		#print("is currently processing already")
		return
	
	if message_text_queue.size() == 0:
		#print("Queue size empty")
		return
	
	if max_messages_on_screen > 0 && messages_on_screen.size() >= max_messages_on_screen:
		#print("Too many messages on screen")
		return
	
	is_currently_processing = true
	var message_text: String = message_text_queue.pop_front()
	var sms_message: SMSMessage = message_scene.instantiate()
	add_child(sms_message)
	
	sms_message.finished_displaying.connect(on_message_finished_displaying.bind(sms_message))
	sms_message.displaying_paused.connect(on_message_paused_displaying.bind(sms_message))
	sms_message.set_label_text(message_text)
	
	set_anchors(sms_message, message_screen_position)
		
	# Need to wait until next frame so tje message size & positions properties are updated
	await get_tree().process_frame
	
	set_none_position(sms_message)
	sms_message.z_index = -messages_on_screen.size()
	
	if messages_on_screen.size() > 0:
		move_all_messages_y_position(sms_message)
		await all_messages_moved
		
	var start_position: Vector2 = get_message_start_position(sms_message)
	var target_position: Vector2 = get_message_target_position(sms_message)	
	sms_message.set_display_config_target_position(target_position)
	sms_message.display_message(start_position, true)
	
	await sms_message.moving_finished
	
	messages_on_screen.append(sms_message)
	
	is_currently_processing = false
	
	process_messages()


# Moves all messages on screen by the y-size of current_message
func move_all_messages_y_position(current_message: SMSMessage):	
	var move_amount: float = current_message.size.y
	
	if message_screen_position == MessageScreenPosition.BOTTOM:
		move_amount = -move_amount
	
	for message in messages_on_screen:
		if message.is_moving:
			await message.moving_finished
			process_messages()
		
		message.z_index = 0 # ensures the messages don't get covered by incoming messages
		var target_position :=  Vector2(message.position.x, message.position.y + move_amount)
		
		message.set_display_config_target_position(target_position)
		message.move()
	
	await messages_on_screen[messages_on_screen.size() - 1].moving_finished
	all_messages_moved.emit()


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
	print("Dealing with message: ", finished_message.get_text())
	# Need to move message off screen and recalculate the target position
	# in case it has moved
	var target_position: Vector2 = get_message_exit_position(finished_message)
	
	# ensure the message displays behind other messages on screen
	finished_message.z_index = -max_messages_on_screen
	finished_message.move_and_delete(target_position, true)
	
	await finished_message.delete_message
	
	var count: int = 0
	
	# if there are any messages after this message that were paused, we need to move them
	# down or up by the size of this notification
	var message_index: int = messages_on_screen.find(finished_message)
	
	if message_index > 0:
		for message in messages_on_screen:
			if count == message_index:
				break
			var new_position := Vector2(message.position.x, message.position.y - finished_message.size.y)
			message.set_display_config_target_position(new_position)
			message.move()
			count += 1
	
	
	
	count = 0
	for message in messages_on_screen:
		if message == finished_message:
			messages_on_screen
			print("count: ", count, " Message: ", messages_on_screen[count].get_text())
			messages_on_screen.remove_at(count)
			break
		count += 1	
	
	process_messages()


func on_message_paused_displaying(paused_message: SMSMessage):
	print("Message has paused displaying")
	pass

# Sets the position of the message if it is not set to move from anywhere off-screen
func set_none_position(message: SMSMessage):
	if (message_source_direction == MessageMoveDirection.NONE &&
			message_screen_position == MessageScreenPosition.BOTTOM):
		var viewport_size: Vector2 = get_viewport().get_visible_rect().size
		message.position.y = viewport_size.y - message.size.y
