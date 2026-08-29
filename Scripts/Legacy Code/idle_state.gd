extends NodeState

@export var player: Player
@export var animated_sprite_2d: AnimatedSprite2D

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _on_process(_delta : float) -> void:
	pass


func _on_physics_process(_delta : float) -> void:
	#Determines Direction
	
	#Walking/Running Animations
	if player.player_direction == Vector2.LEFT:
		animated_sprite_2d.flip_h = true
		animated_sprite_2d.play("Idle")
	elif player.player_direction == Vector2.RIGHT:
		animated_sprite_2d.flip_h = false
		animated_sprite_2d.play("Idle")


func _on_next_transitions() -> void:
	GameInputEvents.movement_input()
	
	if GameInputEvents.is_movement_input():
		transition.emit("Run")
	#if GameInputEvents.is_attack_input():
		#transition.emit("Attack")
	if GameInputEvents.is_jump_input():
		transition.emit("Jump")


func _on_enter() -> void:
	pass


func _on_exit() -> void:
	animated_sprite_2d.stop()
