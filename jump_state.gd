extends NodeState

@export var player: Player
@export var animated_sprite_2d: AnimatedSprite2D

const JUMP_VELOCITY = -375.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")


func _on_process(_delta : float) -> void:
	pass


func _on_physics_process(delta : float) -> void:
	#gravity
	if not player.is_on_floor():
		player.velocity.y += gravity * delta
		



func _on_next_transitions() -> void:
	if !GameInputEvents.is_movement_input() and player.is_on_floor():
		transition.emit("Idle")
	if GameInputEvents.is_movement_input() and player.is_on_floor():
		transition.emit("Run")


func _on_enter() -> void:
		#jump
	if player.is_on_floor():
		player.velocity.y = JUMP_VELOCITY
		player.velocity.x *= 1.25
	


func _on_exit() -> void:
	animated_sprite_2d.stop()
