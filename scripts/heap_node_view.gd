class_name HeapNodeView
extends Node2D

const SQUARE_SIZE: float = 5.0
const SQUARE_GAP: float = 2.0

var radius: float = 24.0:
	set(value):
		radius = value
		queue_redraw()

var fill_color: Color = Color("#38bdf8"):
	set(value):
		fill_color = value
		queue_redraw()

var border_color: Color = Color("#dbeafe")
var square_color: Color = Color("#0f172a")
var square_count: int = 0


func set_value(value: int) -> void:
	square_count = maxi(0, value)
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, fill_color)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, border_color, 2.0, true)
	_draw_square_amount()


func _draw_square_amount() -> void:
	if square_count <= 0:
		return

	var diameter: float = radius * 2.0
	var cells_per_axis: int = maxi(1, int(floor((diameter + SQUARE_GAP) / (SQUARE_SIZE + SQUARE_GAP))))
	var total_capacity: int = cells_per_axis * cells_per_axis
	var squares_to_draw: int = mini(square_count, total_capacity)
	var columns: int = cells_per_axis
	var rows: int = int(ceil(float(squares_to_draw) / float(columns)))
	var total_width: float = float(columns) * SQUARE_SIZE + float(columns - 1) * SQUARE_GAP
	var total_height: float = float(rows) * SQUARE_SIZE + float(rows - 1) * SQUARE_GAP
	var start_x: float = -total_width * 0.5
	var start_y: float = -total_height * 0.5

	for i in range(squares_to_draw):
		var row: int = i / columns
		var col: int = i % columns
		var x: float = start_x + float(col) * (SQUARE_SIZE + SQUARE_GAP)
		var y: float = start_y + float(row) * (SQUARE_SIZE + SQUARE_GAP)
		draw_rect(Rect2(Vector2(x, y), Vector2(SQUARE_SIZE, SQUARE_SIZE)), square_color)
