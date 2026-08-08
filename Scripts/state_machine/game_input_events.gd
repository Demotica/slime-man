class_name GameInputEvents

static var direction: Vector2



static func movement_input() -> Vector2:
	if Input.is_action_pressed("jump"):
		direction = Vector2.UP
	
	if Input.is_action_pressed("move_left"):
		direction = Vector2.LEFT
	elif Input.is_action_pressed("move_right"):
		direction = Vector2.RIGHT
	else:
		direction = Vector2.ZERO
	
	
	return direction

static func is_movement_input() -> bool:
	if direction == Vector2.ZERO:
		return false
	else:
		return true
		
	
static func is_attack_input() -> bool:
	if Input.is_action_pressed("Primary-Attack"):
		return true
	else:
		return false

static func is_jump_input() -> bool:
	if Input.is_action_pressed("jump"):
		return true
	else:
		return false
