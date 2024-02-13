extends Node
class_name SMSMessageAction

var message: SMSMessage
var action: Callable
var action_type: ActionType

enum ActionType {
	INITIAL_MOVE,
	Y_MOVE,
	DISPLAY,
	INITIAL_REORDER_MOVE,
	REORDER_MOVE,
	FINISHING_MOVE,
	INITIAL_PROCESS_MESSAGES,
	MESSAGE_DELETE,
	PROCESS_MESSAGES,
}

func get_action_type() -> ActionType:
	return action_type


func set_message(new_message: SMSMessage):
	message = new_message


func set_action(new_action: Callable):
	action = new_action


func set_action_type(new_action_type: ActionType):
	action_type = new_action_type


func run_action():
	if message == null:
		#print_debug("Please set the message before attempting to run the action.")
		#return
		pass
	
	if action == null:
		print_debug("Please set the action before attempting to run the action")
		return
	
	var message_text: String = "NoMessage"
	
	if message != null:
		message_text = message.get_text()
	
	#print("SMSMSA: Performing action: ", get_action_type_string(), " for message: ", message_text, " Time: ", Time.get_time_dict_from_system())
	await action.call()
	#print("SMSMSA: Finished action: ", get_action_type_string(), " for message: ", message_text, " Time: ", Time.get_time_dict_from_system())

func get_action_type_string() -> String:
	return ActionType.keys()[action_type]
