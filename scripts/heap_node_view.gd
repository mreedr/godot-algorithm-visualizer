class_name HeapNodeView
extends Node2D

const SQUARE_SIZE: float = 5.0
const SQUARE_GAP: float = 2.0
const WALL_SEGMENTS: int = 56
const WALL_THICKNESS: float = 6.0
const BOX_BOUNCE: float = 0.2
const BOX_FRICTION: float = 0.15
const BOX_DAMPING: float = 2.4
const BOX_SPEED: float = 18.0

var radius: float = 24.0:
	set(value):
		radius = value
		_rebuild_walls()
		_scatter_boxes()
		_layout_value_label()
		queue_redraw()

var fill_color: Color = Color("#38bdf8"):
	set(value):
		fill_color = value
		queue_redraw()

var border_color: Color = Color("#dbeafe")
var square_color: Color = Color("#f8fafc"):
	set(value):
		square_color = value
		_update_box_visuals()
var square_count: int = 0

var wall_root: StaticBody2D
var wall_segments: Array[CollisionShape2D] = []
var boxes: Array[RigidBody2D] = []
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var box_material: PhysicsMaterial
var value_label: Label
var value_number: int = 0


func _ready() -> void:
	rng.randomize()
	box_material = PhysicsMaterial.new()
	box_material.bounce = BOX_BOUNCE
	box_material.friction = BOX_FRICTION
	set_physics_process(true)
	_setup_value_label()
	_ensure_wall_root()
	_rebuild_walls()
	_sync_box_count()


func set_value(value: int) -> void:
	value_number = value
	_refresh_value_label()
	var clamped_count: int = maxi(0, value)
	if clamped_count == square_count:
		return
	square_count = clamped_count
	_sync_box_count()


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


func _ensure_wall_root() -> void:
	if wall_root != null:
		return
	wall_root = StaticBody2D.new()
	wall_root.collision_layer = 1
	wall_root.collision_mask = 1
	add_child(wall_root)


func _rebuild_walls() -> void:
	if wall_root == null:
		return

	for segment in wall_segments:
		segment.queue_free()
	wall_segments.clear()

	var segment_length: float = maxf(10.0, (TAU * radius) / float(WALL_SEGMENTS) + WALL_THICKNESS)
	for i in range(WALL_SEGMENTS):
		var angle: float = (TAU * float(i)) / float(WALL_SEGMENTS)
		var tangent_angle: float = angle + PI * 0.5
		var direction: Vector2 = Vector2(cos(angle), sin(angle))

		var shape: RectangleShape2D = RectangleShape2D.new()
		shape.size = Vector2(segment_length, WALL_THICKNESS)

		var collider: CollisionShape2D = CollisionShape2D.new()
		collider.shape = shape
		collider.position = direction * (radius - WALL_THICKNESS)
		collider.rotation = tangent_angle

		wall_root.add_child(collider)
		wall_segments.append(collider)


func _sync_box_count() -> void:
	_ensure_wall_root()

	var diameter: float = radius * 2.0
	var cells_per_axis: int = maxi(1, int(floor((diameter + SQUARE_GAP) / (SQUARE_SIZE + SQUARE_GAP))))
	var max_capacity: int = cells_per_axis * cells_per_axis
	var target_count: int = mini(square_count, max_capacity)

	while boxes.size() < target_count:
		var box: RigidBody2D = _create_box()
		add_child(box)
		boxes.append(box)
		_place_box_randomly(box)

	while boxes.size() > target_count:
		var box_to_remove: RigidBody2D = boxes.pop_back()
		box_to_remove.queue_free()

	_update_box_visuals()
	_scatter_boxes()


func _create_box() -> RigidBody2D:
	var box: RigidBody2D = RigidBody2D.new()
	box.gravity_scale = 0.0
	box.linear_damp = BOX_DAMPING
	box.angular_damp = BOX_DAMPING
	box.continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	box.collision_layer = 1
	box.collision_mask = 1
	box.physics_material_override = box_material
	box.z_index = 3
	box.lock_rotation = true

	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(SQUARE_SIZE, SQUARE_SIZE)
	collision.shape = shape
	box.add_child(collision)

	var visual: Polygon2D = Polygon2D.new()
	visual.name = "Visual"
	visual.polygon = PackedVector2Array([
		Vector2(-SQUARE_SIZE * 0.5, -SQUARE_SIZE * 0.5),
		Vector2(SQUARE_SIZE * 0.5, -SQUARE_SIZE * 0.5),
		Vector2(SQUARE_SIZE * 0.5, SQUARE_SIZE * 0.5),
		Vector2(-SQUARE_SIZE * 0.5, SQUARE_SIZE * 0.5)
	])
	visual.color = square_color
	box.add_child(visual)

	return box


func _update_box_visuals() -> void:
	for box in boxes:
		var visual: Polygon2D = box.get_node_or_null("Visual")
		if visual != null:
			visual.color = square_color


func _scatter_boxes() -> void:
	for box in boxes:
		_place_box_randomly(box)


func _place_box_randomly(box: RigidBody2D) -> void:
	var max_distance: float = maxf(2.0, radius - WALL_THICKNESS - SQUARE_SIZE)
	var candidate: Vector2 = Vector2.ZERO
	var found: bool = false

	for _attempt in range(24):
		var x: float = rng.randf_range(-max_distance, max_distance)
		var y: float = rng.randf_range(-max_distance, max_distance)
		var sample: Vector2 = Vector2(x, y)
		if sample.length() <= max_distance:
			candidate = sample
			found = true
			break

	if not found:
		candidate = Vector2.ZERO

	box.position = candidate
	box.rotation = rng.randf_range(0.0, TAU)
	box.linear_velocity = Vector2(rng.randf_range(-BOX_SPEED, BOX_SPEED), rng.randf_range(-BOX_SPEED, BOX_SPEED))
	box.angular_velocity = rng.randf_range(-3.5, 3.5)
	box.sleeping = false


func _physics_process(_delta: float) -> void:
	var max_distance: float = maxf(2.0, radius - WALL_THICKNESS - SQUARE_SIZE * 0.5)
	for box in boxes:
		var local_pos: Vector2 = box.position
		var length: float = local_pos.length()
		if length <= max_distance:
			continue

		var normal: Vector2 = local_pos / length
		box.position = normal * max_distance
		var inward_component: float = box.linear_velocity.dot(normal)
		if inward_component > 0.0:
			box.linear_velocity -= normal * inward_component * 1.6
