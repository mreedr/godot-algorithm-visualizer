class_name HeapNodeView
extends Node2D

var radius: float = 24.0:
	set(value):
		radius = value
		_layout_value_label()
		_update_collision_shape()
		queue_redraw()

var fill_color: Color = Color("#38bdf8"):
	set(value):
		fill_color = value
		queue_redraw()

var border_color: Color = Color("#dbeafe")
var value_label: Label
var value_number: int = 0

var collision_body: StaticBody2D
var collision_shape: CollisionShape2D


func _ready() -> void:
	_setup_value_label()
	_setup_collision_body()
	_update_collision_shape()


func set_value(value: int) -> void:
	value_number = value
	_refresh_value_label()


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, fill_color)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, border_color, 2.0, true)


func _setup_value_label() -> void:
	if value_label != null:
		return
	value_label = Label.new()
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.add_theme_color_override("font_color", Color("#020617"))
	value_label.add_theme_color_override("font_shadow_color", Color(1, 1, 1, 0.4))
	value_label.add_theme_constant_override("shadow_outline_size", 1)
	value_label.z_index = 6
	add_child(value_label)
	_layout_value_label()
	_refresh_value_label()


func _layout_value_label() -> void:
	if value_label == null:
		return
	value_label.position = Vector2(-radius, -radius)
	value_label.size = Vector2(radius * 2.0, radius * 2.0)


func _refresh_value_label() -> void:
	if value_label == null:
		return
	value_label.text = str(value_number)


func _setup_collision_body() -> void:
	if collision_body != null:
		return
	collision_body = StaticBody2D.new()
	collision_body.collision_layer = 1
	collision_body.collision_mask = 1
	add_child(collision_body)

	collision_shape = CollisionShape2D.new()
	collision_body.add_child(collision_shape)


func _update_collision_shape() -> void:
	if collision_shape == null:
		return
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = maxf(2.0, radius)
	collision_shape.shape = shape
