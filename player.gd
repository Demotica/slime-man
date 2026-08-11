extends CharacterBody2D

enum STATE{
	FALL,
	FLOOR,
	JUMP,
	DOUBLE_JUMP,
	FLOAT,
	LEDGE_CLIMB,
	LEDGE_JUMP,
}

var player_direction: Vector2
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

const FALL_VELOCITY := 500.0
const WALK_VELOCITY := 200.0
const JUMP_VELOCITY := -300.0
const JUMP_DECELERATION := 1500.0
const DOUBLE_JUMP_VELOCITY := -250.0

var can_double_jump := false

@onready var animated_sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var coyote_timer: Timer = %CoyoteTimer


#Instantiating States
var active_state := STATE.FALL

func _ready() -> void:
	switch_state(active_state)

func _physics_process(delta: float) -> void:
	process_state(delta)	
	move_and_slide()

func switch_state(to_state: STATE) -> void:
	var prev_state := active_state
	active_state = to_state
	
	#State specific things that need to only run once upon entering the next state
	match active_state:
		STATE.FALL:
			if prev_state != STATE.DOUBLE_JUMP:
				animated_sprite.play("Fall")
			if prev_state == STATE.FLOOR:
				coyote_timer.start()
		STATE.FLOOR:
			can_double_jump = true
		
		STATE.JUMP:
			animated_sprite.play("Jump")
			velocity.y = JUMP_VELOCITY
			coyote_timer.stop()
		
		STATE.DOUBLE_JUMP:
			animated_sprite.play("Double Jump")
			velocity.y = DOUBLE_JUMP_VELOCITY
			can_double_jump = false

func process_state(delta: float) -> void:
	#match is similar to switch statements in other languages
	match active_state:
		STATE.FALL:
			velocity.y = move_toward(velocity.y, FALL_VELOCITY, gravity * delta)
			handle_movement()
			
			if is_on_floor():
				switch_state(STATE.FLOOR)
			elif Input.is_action_just_pressed("jump"):
				if coyote_timer.time_left > 0:
					switch_state(STATE.JUMP)
				elif can_double_jump:
					switch_state(STATE.DOUBLE_JUMP)
				
		STATE.FLOOR:
			if Input.get_axis("move_left", "move_right"):
				animated_sprite.play("Run")
			else:
				animated_sprite.play("Idle")
			handle_movement()
			
			if not is_on_floor():
				switch_state(STATE.FALL)
			elif Input.is_action_just_pressed("jump"):
				switch_state(STATE.JUMP)
		
		STATE.JUMP, STATE.DOUBLE_JUMP:
			velocity.y = move_toward(velocity.y, 0, JUMP_DECELERATION * delta)
			handle_movement()
			
			if Input.is_action_just_pressed("jump") or velocity.y >= 0:
				velocity.y = 0
				switch_state(STATE.FALL)


func handle_movement() -> void:
	var input_direction := signf(Input.get_axis("move_left", "move_right"))
	
	if input_direction:
		animated_sprite.flip_h = input_direction < 0
	
	velocity.x = input_direction * WALK_VELOCITY
