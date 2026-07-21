extends Node
class_name MovementSystem

@export var grid_size: int = 16

var entities: Dictionary = {}       # entity -> {"is_player": bool}
var occupied_positions: Dictionary = {}  # Vector2i -> entity

func _ready():
	add_to_group("movement_system")

func register_entity(entity: Node, is_player: bool = false):
	entities[entity] = {"is_player": is_player}
	var grid_pos = world_to_grid(entity.position)
	occupied_positions[grid_pos] = entity

func unregister_entity(entity: Node):
	var grid_pos = world_to_grid(entity.position)
	occupied_positions.erase(grid_pos)
	entities.erase(entity)

func request_move(entity: Node, direction: Vector2i) -> bool:
	if not entities.has(entity):
		return false
	
	var current_grid = world_to_grid(entity.position)
	var target_grid = current_grid + direction
	var target_world = grid_to_world(target_grid)
	
	# collision detection
	if is_tile_occupied(target_grid, entity):
		return false
	
	# edge detection
	if not is_within_bounds(target_world):
		return false
	
	# update occupied grid table
	occupied_positions.erase(current_grid)
	occupied_positions[target_grid] = entity
	
	# logic update here
	# notify if removed successfully
	if entities[entity]["is_player"]:
		EventBus.player_moved.emit(target_grid)
	else:
		EventBus.enemy_moved.emit(entity, target_grid)
	
	return true

func is_tile_occupied(grid_pos: Vector2i, exclude: Node) -> bool:
	return occupied_positions.has(grid_pos) and occupied_positions[grid_pos] != exclude

func is_within_bounds(world_pos: Vector2) -> bool:
	# TODO: should be implemented with a real map
	return true

func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(round(world_pos.x / grid_size), round(world_pos.y / grid_size))

func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.x * grid_size, grid_pos.y * grid_size)
