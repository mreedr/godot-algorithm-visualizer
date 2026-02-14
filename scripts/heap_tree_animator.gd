extends Node2D

const DEFAULT_NODE_COLOR := Color("#38bdf8")
const HIGHLIGHT_NODE_COLOR := Color("#f59e0b")
const SORTED_NODE_COLOR := Color("#34d399")
const EDGE_COLOR := Color("#94a3b8")
const BG_COLOR := Color("#0b1220")
const TREE_NODE_SCENE: PackedScene = preload("res://TreeNode.tscn")

@export var iteration_duration: float = 0.45
@export var top_padding: float = 110.0
@export var level_spacing: float = 105.0
@export var node_radius: float = 27.0

var node_views: Array[HeapNodeView] = []
var iteration_counter: int = 0
var sorted_from_index: int = -1
var hud_label: Label
var background: ColorRect


func _ready() -> void:
	_setup_hud()
	set_process(true)

	if DisplayServer.get_name() == "headless":
		hud_label.text = "Headless startup OK (heap tree scene)."
		return

	var input: Array = [14, 9, 11, 4, 3, 8, 2, 1, 6, 5, 7, 10, 13, 12]
	await doAlgoIteration(input, PackedInt32Array(), "Start: raw array as complete binary tree", -1)
	await _run_heap_sort_demo(input.duplicate())
	hud_label.text += "\nDone. Replace _run_heap_sort_demo with your own input/data."


func _process(_delta: float) -> void:
	queue_redraw()


# Main per-step animation hook for heap visualizations.
func doAlgoIteration(
	values: Array,
	highlights: PackedInt32Array = PackedInt32Array(),
	note: String = "",
	sorted_from: int = -1
) -> void:
	if values.is_empty():
		return

	iteration_counter += 1
	sorted_from_index = sorted_from
	_ensure_node_count(values.size())

	var positions: Array[Vector2] = _compute_tree_positions(values.size())
	var highlighted: Dictionary = {}
	for index in highlights:
		highlighted[int(index)] = true

	var tween: Tween = create_tween().set_parallel(true)
	for i in range(values.size()):
		var node: HeapNodeView = node_views[i]
		node.set_value(int(values[i]))
		node.radius = node_radius

		var target_color: Color = DEFAULT_NODE_COLOR
		if sorted_from_index >= 0 and i >= sorted_from_index:
			target_color = SORTED_NODE_COLOR
		if highlighted.has(i):
			target_color = HIGHLIGHT_NODE_COLOR

		tween.tween_property(node, "position", positions[i], iteration_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(node, "fill_color", target_color, iteration_duration * 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	_update_hud(note, values)
	await tween.finished


func _run_heap_sort_demo(data: Array) -> void:
	var n: int = data.size()

	for i in range((n / 2) - 1, -1, -1):
		await _sift_down(data, i, n, "Build max heap", -1)

	await doAlgoIteration(data, PackedInt32Array(), "Heap built. Start extraction.", -1)

	for end in range(n - 1, 0, -1):
		_swap(data, 0, end)
		await doAlgoIteration(
			data,
			PackedInt32Array([0, end]),
			"Move current max to sorted tail (index %d)." % end,
			end
		)
		await _sift_down(data, 0, end, "Restore heap", end)

	await doAlgoIteration(data, PackedInt32Array(), "Heap sort complete.", 0)


func _sift_down(data: Array, root_index: int, heap_size: int, phase: String, sorted_from: int) -> void:
	var current: int = root_index
	while true:
		var left: int = current * 2 + 1
		if left >= heap_size:
			break

		var right: int = left + 1
		var largest: int = current

		if int(data[left]) > int(data[largest]):
			largest = left
		if right < heap_size and int(data[right]) > int(data[largest]):
			largest = right

		var compare_highlights: PackedInt32Array
		if right < heap_size:
			compare_highlights = PackedInt32Array([current, left, right])
		else:
			compare_highlights = PackedInt32Array([current, left])

		await doAlgoIteration(
			data,
			compare_highlights,
			"%s: compare parent %d with children." % [phase, current],
			sorted_from
		)

		if largest == current:
			break

		_swap(data, current, largest)
		await doAlgoIteration(
			data,
			PackedInt32Array([current, largest]),
			"%s: swap %d and %d." % [phase, current, largest],
			sorted_from
		)
		current = largest


func swapHeapNodes(values: Array, i: int, j: int) -> void:
	_swap(values, i, j)


func _swap(values: Array, i: int, j: int) -> void:
	var temp_value: int = int(values[i])
	values[i] = int(values[j])
	values[j] = temp_value

	if i < node_views.size() and j < node_views.size():
		var temp_node: HeapNodeView = node_views[i]
		node_views[i] = node_views[j]
		node_views[j] = temp_node


func _ensure_node_count(target_count: int) -> void:
	while node_views.size() < target_count:
		var node_instance: Node = TREE_NODE_SCENE.instantiate()
		var node: HeapNodeView = node_instance as HeapNodeView
		if node == null:
			push_error("TreeNode.tscn must use HeapNodeView script.")
			node_instance.queue_free()
			return
		node.radius = node_radius
		node.fill_color = DEFAULT_NODE_COLOR
		add_child(node)
		node_views.append(node)

	while node_views.size() > target_count:
		var node_to_remove: HeapNodeView = node_views.pop_back()
		node_to_remove.queue_free()


func _compute_tree_positions(node_count: int) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	positions.resize(node_count)
	var viewport_size: Vector2 = get_viewport_rect().size

	for i in range(node_count):
		var one_based: int = i + 1
		var depth: int = 0
		var level_start_count: int = 1
		while level_start_count * 2 <= one_based:
			level_start_count *= 2
			depth += 1

		var level_start_index: int = level_start_count - 1
		var index_on_level: int = i - level_start_index
		var nodes_on_level: int = level_start_count
		var horizontal_gap: float = viewport_size.x / float(nodes_on_level + 1)

		var x: float = horizontal_gap * float(index_on_level + 1)
		var y: float = top_padding + float(depth) * level_spacing
		positions[i] = Vector2(x, y)

	return positions


func _draw() -> void:
	for i in range(node_views.size()):
		var left: int = i * 2 + 1
		var right: int = left + 1

		if left < node_views.size():
			draw_line(node_views[i].position, node_views[left].position, EDGE_COLOR, 2.0, true)
		if right < node_views.size():
			draw_line(node_views[i].position, node_views[right].position, EDGE_COLOR, 2.0, true)


func _setup_hud() -> void:
	background = ColorRect.new()
	background.color = BG_COLOR
	background.position = Vector2.ZERO
	background.size = get_viewport_rect().size
	background.z_index = -5
	add_child(background)

	var layer: CanvasLayer = CanvasLayer.new()
	add_child(layer)

	hud_label = Label.new()
	hud_label.position = Vector2(18, 14)
	hud_label.size = Vector2(1200, 90)
	hud_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud_label.add_theme_color_override("font_color", Color("#f8fafc"))
	layer.add_child(hud_label)


func _update_hud(note: String, values: Array) -> void:
	var serialized: PackedStringArray = PackedStringArray()
	for value in values:
		serialized.append(str(value))
	var values_text: String = ", ".join(serialized)
	hud_label.text = "Heap Sort Tree | Iteration %d\n%s\n[%s]" % [iteration_counter, note, values_text]
