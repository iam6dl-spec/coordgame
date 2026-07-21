extends CharacterBody2D


enum MoveState {
	IDLE,
	MOVING,
	BLOCKED
}

@export var move_duration: float = 0.12
@export var hold_initial_delay: float = 0.3
@export var hold_step_interval: float = 0.15

var current_state: MoveState = MoveState.IDLE
var facing_direction: Vector2i = Vector2i.DOWN
var grid_position: Vector2i

var held_direction: Vector2i = Vector2i.ZERO
var step_cooldown: float = 0.0

var buffered_direction: Vector2i = Vector2i.ZERO

var sprite: Sprite2D

@onready var tween: Tween
@onready var movement_system: MovementSystem = get_tree().get_first_node_in_group("movement_system")


func _ready():
	# TODO: Only for testing, will be adding actual texture later
	sprite = Sprite2D.new()
	sprite.name = "Sprite"
	add_child(sprite)
	sprite.centered = true
	_generate_placeholder_texture(Color(0x4a / 255.0, 0x90 / 255.0, 0xd9 / 255.0, 0.8))

	if movement_system:
		grid_position = movement_system.world_to_grid(position)
		movement_system.register_entity(self, true)
	_update_sprite_direction()


func _generate_placeholder_texture(c: Color):
	var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for x in range(16):
		for y in range(16):
			var inside = false
			if x >= 4 and x < 12 and y >= 2 and y < 14:
				inside = true
			var dx = x - 8
			var dy = y - 11
			if dy >= 0 and dy <= 3 and abs(dx) <= (3 - dy):
				inside = true
			if inside:
				img.set_pixel(x, y, c)
	sprite.texture = ImageTexture.create_from_image(img)


func _physics_process(delta):
	var just_dir = _get_just_pressed_direction()
	var held_dir = _get_held_direction()

	match current_state:
		MoveState.IDLE:
			_process_idle_input(just_dir, held_dir, delta)
		MoveState.MOVING:
			_process_moving_input(just_dir, held_dir)
		MoveState.BLOCKED:
			pass


func _process_idle_input(just_dir: Vector2i, held_dir: Vector2i, delta: float):
	if just_dir != Vector2i.ZERO:
		facing_direction = just_dir
		_update_sprite_direction()
		_try_move(just_dir)
		step_cooldown = hold_initial_delay
		held_direction = just_dir
	elif held_dir != Vector2i.ZERO:
		if held_dir != held_direction:
			facing_direction = held_dir
			_update_sprite_direction()
			_try_move(held_dir)
			step_cooldown = hold_initial_delay
			held_direction = held_dir
		else:
			step_cooldown -= delta
			if step_cooldown <= 0.0:
				_try_move(held_dir)
				step_cooldown = hold_step_interval
	else:
		held_direction = Vector2i.ZERO
		step_cooldown = 0.0


func _process_moving_input(just_dir: Vector2i, held_dir: Vector2i):
	if just_dir != Vector2i.ZERO:
		facing_direction = just_dir
		_update_sprite_direction()
		buffered_direction = just_dir
	elif held_dir != Vector2i.ZERO:
		if held_dir != held_direction:
			facing_direction = held_dir
			_update_sprite_direction()
			held_direction = held_dir
		buffered_direction = held_dir
	else:
		held_direction = Vector2i.ZERO


func _get_just_pressed_direction() -> Vector2i:
	var dir = Vector2i.ZERO
	if Input.is_action_just_pressed("ui_up"):      dir.y = -1
	elif Input.is_action_just_pressed("ui_down"):  dir.y = 1
	elif Input.is_action_just_pressed("ui_left"):  dir.x = -1
	elif Input.is_action_just_pressed("ui_right"): dir.x = 1
	return dir


func _get_held_direction() -> Vector2i:
	var dir = Vector2i.ZERO
	if Input.is_action_pressed("ui_up"):      dir.y = -1
	elif Input.is_action_pressed("ui_down"):  dir.y = 1
	elif Input.is_action_pressed("ui_left"):  dir.x = -1
	elif Input.is_action_pressed("ui_right"): dir.x = 1
	return dir


func _try_move(direction: Vector2i):
	if current_state != MoveState.IDLE or not movement_system:
		return

	var target_grid = grid_position + direction
	var success = movement_system.request_move(self, direction)
	if success:
		grid_position = target_grid
		_start_move_animation(direction)
	else:
		_update_sprite_direction()


func _start_move_animation(direction: Vector2i):
	current_state = MoveState.MOVING
	var target = movement_system.grid_to_world(grid_position)

	if tween and tween.is_running():
		tween.kill()

	tween = create_tween()
	tween.tween_property(self, "position", target, move_duration)
	tween.finished.connect(_on_move_finished)


func _on_move_finished():
	current_state = MoveState.IDLE
	position = movement_system.grid_to_world(grid_position)

	if buffered_direction != Vector2i.ZERO:
		facing_direction = buffered_direction
		buffered_direction = Vector2i.ZERO
		_update_sprite_direction()
		_try_move(facing_direction)
		return

	if held_direction != Vector2i.ZERO:
		facing_direction = held_direction
		_update_sprite_direction()
		_try_move(held_direction)


func _update_sprite_direction():
	if not sprite:
		return
	match facing_direction:
		Vector2i(0, -1):
			sprite.rotation = deg_to_rad(180)
		Vector2i(1, 0):
			sprite.rotation = deg_to_rad(90)
		Vector2i(0, 1):
			sprite.rotation = deg_to_rad(0)
		Vector2i(-1, 0):
			sprite.rotation = deg_to_rad(270)


func set_blocked(blocked: bool):
	if blocked:
		current_state = MoveState.BLOCKED
		buffered_direction = Vector2i.ZERO
		held_direction = Vector2i.ZERO
		step_cooldown = 0.0
	else:
		current_state = MoveState.IDLE
