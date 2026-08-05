class_name Player
extends CharacterBody2D

var player_direction: Vector2

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta):
	velocity += get_gravity() * delta
	
	move_and_slide()
