extends Node
class_name SMSMessageAction

var message: SMSMessage
var action: Callable
var action_type: ActionType

enum ActionType {
	INITIAL_MOVE,
	Y_MOVE,
	DISPLAY,
	REORDER_MOVE,
	FINISHING_MOVE,
}

func set_message(new_message: SMSMessage):
	message = new_message


func set_action(new_action: Callable):
	action = new_action


func set_action_type(new_action_type: ActionType):
	action_type = new_action_type


func run_action():
	if message == null:
		print_debug("Please set the message before attempting to run the action.")
	
	if action == null:
		print_debug("Please set the action before attempting to run the action")
	
	action.call()

func get_action_type_string() -> String:
	return ActionType.keys()[action_type]
