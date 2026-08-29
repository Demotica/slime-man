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
const FLOAT_GRAVITY := 200.0
const FLOAT_VELOCITY := 100.0
const LEDGE_JUMP_VELOCITY := -250.0

var can_double_jump := false
var facing_direction := 1.0

@onready var animated_sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var coyote_timer: Timer = %CoyoteTimer
@onready var float_cooldown: Timer = %FloatCooldown
@onready var collision_shape_2d: CollisionShape2D = %CollisionShape2D
@onready var ledge_climb_ray_cast: RayCast2D = %LedgeClimbRayCast
@onready var ledge_space_ray_cast: RayCast2D = %LedgeSpaceRayCast


#Instantiating States
var active_state := STATE.FALL

func _ready() -> void:
	switch_state(active_state)
	#Prevents ray cast from detecting play collision in its own check
	ledge_climb_ray_cast.add_exception(self)

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
			
		STATE.FLOAT:
			if float_cooldown.time_left > 0:
				active_state = prev_state
				return
			animated_sprite.play("Float")
			velocity.y = 0
		
		STATE.LEDGE_CLIMB:
			animated_sprite.play("Ledge Climb")
			velocity = Vector2.ZERO
			global_position.y = ledge_climb_ray_cast.get_collision_point().y
			can_double_jump = true
		
		STATE.LEDGE_JUMP:
			animated_sprite.play("Double Jump")
			velocity.y = LEDGE_JUMP_VELOCITY

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
				else:
					switch_state(STATE.FLOAT)
			elif is_input_toward_facing() and is_ledge() and is_space():
				switch_state(STATE.LEDGE_CLIMB)
				
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
		
		STATE.JUMP, STATE.DOUBLE_JUMP, STATE.LEDGE_JUMP:
			velocity.y = move_toward(velocity.y, 0, JUMP_DECELERATION * delta)
			handle_movement()
			
			if Input.is_action_just_pressed("jump") or velocity.y >= 0:
				velocity.y = 0
				switch_state(STATE.FALL)
		STATE.FLOAT:
			velocity.y = move_toward(velocity.y, FLOAT_VELOCITY, FLOAT_GRAVITY * delta)
			handle_movement()
			
			if is_on_floor():
				switch_state(STATE.FLOOR)
			elif Input.is_action_just_released("jump"):
				float_cooldown.start()
				switch_state(STATE.FALL)
			elif is_input_toward_facing() and is_ledge() and is_space():
				switch_state(STATE.LEDGE_CLIMB)
		
		STATE.LEDGE_CLIMB:
			if not animated_sprite.is_playing():
				animated_sprite.play("Idle")
				var offset := ledge_climb_offset()
				offset.x *= facing_direction
				position += offset
				switch_state(STATE.FLOOR)
			elif Input.is_action_just_pressed("jump"):
				#determines how many frames have passed with a value inbetween 0 and 1
				var progress := inverse_lerp(0, animated_sprite.sprite_frames.get_frame_count("Ledge Climb"), animated_sprite.frame)
				var offset := ledge_climb_offset()
				offset.x *= facing_direction * progress
				position += offset
				switch_state(STATE.LEDGE_JUMP)


func handle_movement() -> void:
	var input_direction := signf(Input.get_axis("move_left", "move_right"))
	
	if input_direction:
		animated_sprite.flip_h = input_direction < 0
		facing_direction = input_direction
		
		ledge_climb_ray_cast.position.x = input_direction * absf(ledge_climb_ray_cast.position.x) #Flips Ray cast to the facing direction
		
		ledge_climb_ray_cast.target_position.x = input_direction * absf(ledge_climb_ray_cast.target_position.x) #Flips target position Ray cast to the facing direction
		
		ledge_climb_ray_cast.force_raycast_update() #Forces update to avoid outdated raycast information
		
		 
	velocity.x = input_direction * WALK_VELOCITY

#Function helps prevent grabbing a ledge when not facing toward a grabable ledge
func is_input_toward_facing() -> bool:
	return signf(Input.get_axis("move_left", "move_right")) == facing_direction
	
func is_ledge() -> bool:
	return is_on_wall_only() and ledge_climb_ray_cast.is_colliding() and ledge_climb_ray_cast.get_collision_normal().is_equal_approx(Vector2.UP)
	
#this function checks if there is enough space for our character to go when grabbing ledge
func is_space() -> bool:
	ledge_space_ray_cast.global_position = ledge_climb_ray_cast.get_collision_point()
	ledge_space_ray_cast.force_raycast_update()
	return not ledge_space_ray_cast.is_colliding()
	
#Makes sure the player snaps perfectly to the ledge
func ledge_climb_offset() -> Vector2:
	var shape := collision_shape_2d.shape
	if shape is CapsuleShape2D:
		return Vector2(shape.radius * 2.0, -shape.height * 0.5)
	if shape is RectangleShape2D:
		return Vector2(shape.size.x, -shape.size.y * 0.5)
	return Vector2.ZERO
