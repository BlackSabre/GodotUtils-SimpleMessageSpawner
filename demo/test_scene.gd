extends Node2D

@onready var message_spawner: SMSMessageSpawner = $MessageSpawner

var test: bool = true

var arr: Array[Callable]

# Called when the node enters the scene tree for the first time.
func _ready():
	if test == true:
		test_messages()
		
	
	#for i in 10:
		#arr.append(func(): await test_mess(i))
#
	#for item in arr:
		#await item.call()

func test_messages():
	#await get_tree().create_timer(.5).timeout
	#message_spawner.add_message("1. This is a message")
	#
	##await get_tree().create_timer(.5).timeout
	#message_spawner.add_message("2. This is another message that will be jumbled up")
	#
	##await get_tree().create_timer(.5).timeout
	#message_spawner.add_message("3. This is another annoying message! This is an annoying message! This is an annoying message! This is an annoying message! This is an annoying message! This is an annoying message! This is an annoying message! This is an annoying message! This is an annoying message! This is an annoying message!")
	#
	##await get_tree().create_timer(.5).timeout
	#message_spawner.add_message("4. This is another annoying message! This is an annoying message! This is an annoying message!")
	#
	#message_spawner.add_message("5. This is a message")
	#message_spawner.add_message("6. This is a message")
	#message_spawner.add_message("7. This is another annoying message! This is an annoying message! This is an annoying message! This is another annoying message! This is an annoying message! This is an annoying message!")
	#message_spawner.add_message("8. This is a message")
	#message_spawner.add_message("9. This is a message")
	#message_spawner.add_message("10. This is a message")
	#message_spawner.add_message("11. This is a message")
	#message_spawner.add_message("12. This is a message")
	#message_spawner.add_message("13. This is a message")
	#
	##await get_tree().create_timer(.5).timeout
	#message_spawner.add_message("14. This is another annoying message! This is an annoying message! This is an annoying message!")\
	
	
	
	message_spawner.add_message("1.")
	message_spawner.add_message("2.")
	message_spawner.add_message("3.")
	message_spawner.add_message("4.")
	message_spawner.add_message("5.")
	message_spawner.add_message("6.")
	message_spawner.add_message("7.")
	message_spawner.add_message("8.")
	message_spawner.add_message("9.")
	#message_spawner.add_message("10.")
	#message_spawner.add_message("11.")
	#message_spawner.add_message("12.")
	#message_spawner.add_message("13.")
	#message_spawner.add_message("14.")
	#message_spawner.add_message("15.")
	#message_spawner.add_message("16.")
	#message_spawner.add_message("17.")
	#message_spawner.add_message("18.")
	#message_spawner.add_message("19.")
	#message_spawner.add_message("20.")


func test_mess(num: int):
	await get_tree().create_timer(1).timeout
	#print("Test ", num, " finished")