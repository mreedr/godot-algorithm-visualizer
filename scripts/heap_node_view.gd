class_name HeapNodeView
extends Node2D

var radius: float = 24.0:
	set(value):
		radius = value
		if value_label != null:
			value_label.position = Vector2(-radius, -radius)
			value_label.size = Vector2(radius * 2.0, radius * 2.0)
		queue_redraw()

var fill_color: Color = Color("#38bdf8"):
	set(value):
		fill_color = value
		queue_redraw()

var border_color: Color = Color("#dbeafe")
var text_color: Color = Color("#0f172a")

var value_label: Label
var value_text: String = ""


func _ready() -> void:
	value_label = Label.new()
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.position = Vector2(-radius, -radius)
	value_label.size = Vector2(radius * 2.0, radius * 2.0)
	value_label.add_theme_color_override("font_color", text_color)
	add_child(value_label)
	_refresh_label()


func set_value(value: int) -> void:
	value_text = str(value)
	_refresh_label()


func _refresh_label() -> void:
	if value_label == null:
		return
	value_label.text = value_text


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, fill_color)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, border_color, 2.0, true)
