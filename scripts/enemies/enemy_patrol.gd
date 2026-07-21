# scripts/enemies/enemy_patrol.gd
extends CharacterBody2D

enum MoveState { IDLE, MOVING }

@export var waypoints: Array[Vector2i]         # grid waypoints
@export var move_interval: float = 1.0
@export var move_duration: float = 0.2

var current_state: MoveState = MoveState.IDLE
var path_index: int = 0
var move_timer: float = 0.0
var facing_direction: Vector2i = Vector2i.DOWN
var grid_position: Vector2i
var sprite: Sprite2D

@onready var movement_system: MovementSystem = get_tree().get_first_node_in_group("movement_system")


func _ready():
	sprite = Sprite2D.new()
	sprite.name = "Sprite"
	add_child(sprite)
	sprite.centered = true
	_generate_placeholder_texture(Color(0xd9 / 255.0, 0x4a / 255.0, 0x4a / 255.0, 0.8))

	if movement_system:
		grid_position = movement_system.world_to_grid(position)
		movement_system.register_entity(self, false)
	_update_sprite_direction()


# TODO: only for testing, will be adding actual texture later
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
	match current_state:
		MoveState.IDLE:
			move_timer += delta
			if move_timer >= move_interval:
				move_timer = 0.0
				_move_to_next()
		MoveState.MOVING:
			pass

func _move_to_next():
	if waypoints.is_empty() or not movement_system:
		return
	
	var target_grid = waypoints[path_index]
	var dir = target_grid - grid_position
	
	# walk step by step
	if dir.length() > 1:
		dir = Vector2i(sign(dir.x), sign(dir.y))
	
	facing_direction = dir
	_update_sprite_direction()

	var success = movement_system.request_move(self, dir)
	if success:
		grid_position += dir
		_start_move_animation(dir)
		if grid_position == target_grid:
			path_index = wrap(path_index + 1, 0, waypoints.size())

func _start_move_animation(direction: Vector2i):
	current_state = MoveState.MOVING
	var target = movement_system.grid_to_world(grid_position)
	var t = create_tween()
	t.tween_property(self, "position", target, move_duration)
	t.finished.connect(func():
		position = movement_system.grid_to_world(grid_position)
		current_state = MoveState.IDLE)


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
