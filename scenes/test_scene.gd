extends Node2D

@onready var message_spawner: SMSMessageSpawner = $MessageSpawner

# Called when the node enters the scene tree for the first time.
func _ready():
	await get_tree().create_timer(.5).timeout
	message_spawner.add_message("1. This is a message")
	
	await get_tree().create_timer(.5).timeout
	message_spawner.add_message("2. This is another message that will be jumbled up")
	
	await get_tree().create_timer(.5).timeout
	message_spawner.add_message("3. This is another annoying message! This is an annoying message! This is an annoying message! This is an annoying message! This is an annoying message! This is an annoying message! This is an annoying message! This is an annoying message! This is an annoying message! This is an annoying message!")
	
	await get_tree().create_timer(.5).timeout
	message_spawner.add_message("4. This is another annoying message! This is an annoying message! This is an annoying message!")
	
	message_spawner.add_message("5. This is a message")
	message_spawner.add_message("6. This is a message")
	message_spawner.add_message("7. This is another annoying message! This is an annoying message! This is an annoying message! This is another annoying message! This is an annoying message! This is an annoying message!")
	message_spawner.add_message("8. This is a message")
	message_spawner.add_message("9. This is a message")
	message_spawner.add_message("10. This is a message")
	message_spawner.add_message("11. This is a message")
	message_spawner.add_message("12. This is a message")
	message_spawner.add_message("13. This is a message")
	
	await get_tree().create_timer(.5).timeout
	message_spawner.add_message("14. This is another annoying message! This is an annoying message! This is an annoying message!")
