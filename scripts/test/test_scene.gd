extends Node2D


## Test scene controller for PlayerControl + MovementSystem manual testing.
##
## Draws a visible 16px grid, creates obstacle entities ("walls"), and shows a
## debug HUD with player state, grid position, facing direction, etc.
##
## Use arrow keys to move the blue player block.  Hold a key for auto-step.

const GRID_SIZE := 16
const GRID_COLS := 25
const GRID_ROWS := 20
const GRID_LINE_COLOR := Color(0.3, 0.3, 0.3, 0.2)
const AXIS_LINE_COLOR := Color(0.5, 0.5, 0.5, 0.5)

var movement_system: MovementSystem
var player: CharacterBody2D

var state_label: Label
var grid_label: Label
var facing_label: Label
var held_label: Label
var buffer_label: Label
var move_label: Label


func _ready():
	queue_redraw()

	movement_system = $MovementSystem
	player = $Player

	_setup_debug_hud()
	_setup_obstacles()

	EventBus.player_moved.connect(_on_player_moved)


func _draw():
	var ox = -GRID_COLS * GRID_SIZE / 2
	var oy = -GRID_ROWS * GRID_SIZE / 2

	for col in range(GRID_COLS + 1):
		var x = ox + col * GRID_SIZE
		var c = AXIS_LINE_COLOR if col == GRID_COLS / 2 else GRID_LINE_COLOR
		draw_line(Vector2(x, oy), Vector2(x, oy + GRID_ROWS * GRID_SIZE), c)

	for row in range(GRID_ROWS + 1):
		var y = oy + row * GRID_SIZE
		var c = AXIS_LINE_COLOR if row == GRID_ROWS / 2 else GRID_LINE_COLOR
		draw_line(Vector2(ox, y), Vector2(ox + GRID_COLS * GRID_SIZE, y), c)


func _setup_debug_hud():
	var panel = CanvasLayer.new()
	panel.name = "DebugPanel"
	panel.layer = 100
	add_child(panel)

	var margin = 10
	var y = margin

	state_label    = _add_label(panel, "State: --", margin, y);   y += 20
	grid_label     = _add_label(panel, "Grid: --", margin, y);    y += 20
	facing_label   = _add_label(panel, "Facing: --", margin, y);  y += 20
	held_label     = _add_label(panel, "Held: --", margin, y);    y += 20
	buffer_label   = _add_label(panel, "Buffered: --", margin, y); y += 20
	move_label     = _add_label(panel, "Last move: --", margin, y); y += 20

	_add_label(panel, "[Arrow keys \u2014 press to step, hold to auto-run]", margin, y)\
		.modulate = Color(0.5, 0.5, 0.5)


static func _add_label(panel: CanvasLayer, text: String, x: int, y: int) -> Label:
	var l = Label.new()
	l.text = text
	l.position = Vector2(x, y)
	l.add_theme_font_size_override("font_size", 14)
	l.add_theme_color_override("font_color", Color.WHITE)
	l.add_theme_color_override("font_shadow_color", Color.BLACK)
	l.add_theme_constant_override("shadow_outline_size", 2)
	panel.add_child(l)
	return l


func _setup_obstacles():
	var positions: Array[Vector2i] = [
		# L-shaped wall (top-right area)
		Vector2i(6, 3), Vector2i(6, 4), Vector2i(6, 5),
		Vector2i(3, 6), Vector2i(4, 6), Vector2i(5, 6),
		# Small block (top-left corner)
		Vector2i(-3, -2), Vector2i(-4, -2), Vector2i(-3, -3),
		# Single isolated pillar
		Vector2i(-6, 3),
		# Block near origin
		Vector2i(2, -1),
	]

	for pos in positions:
		var block = Node2D.new()
		block.name = "Blocker_%d_%d" % [pos.x, pos.y]

		var s = Sprite2D.new()
		s.name = "Sprite"
		var img = Image.create(14, 14, false, Image.FORMAT_RGBA8)
		img.fill(Color(0.8, 0.2, 0.15, 0.9))
		s.texture = ImageTexture.create_from_image(img)
		s.centered = true
		block.add_child(s)

		block.position = movement_system.grid_to_world(pos)
		add_child(block)
		movement_system.register_entity(block, false)


func _process(_delta):
	if not (player and player.get_script()):
		return
	var p = player
	var state_map: Dictionary = {0: "IDLE", 1: "MOVING", 2: "BLOCKED"}

	state_label.text  = "State: %s"    % state_map.get(p.current_state, "?")
	grid_label.text   = "Grid: (%d, %d)" % [p.grid_position.x, p.grid_position.y]
	facing_label.text = "Facing: (%d, %d)" % [p.facing_direction.x, p.facing_direction.y]
	held_label.text   = "Held: (%d, %d)"   % [p.held_direction.x, p.held_direction.y]
	buffer_label.text = "Buffered: (%d, %d)" % [p.buffered_direction.x, p.buffered_direction.y]


func _on_player_moved(target_grid: Vector2i):
	if not move_label:
		return
	move_label.text = "Last move: OK \u2192 (%d, %d)" % [target_grid.x, target_grid.y]
	move_label.modulate = Color(0.3, 1.0, 0.3)
	var t = create_tween()
	t.tween_property(move_label, "modulate", Color.WHITE, 1.2)
