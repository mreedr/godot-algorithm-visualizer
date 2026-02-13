extends Node2D

const BAR_COLOR := Color("#36c9a7")
const HIGHLIGHT_COLOR := Color("#ff9f43")

@export var iteration_duration := 0.35
@export var top_margin := 90.0
@export var side_margin := 40.0
@export var bottom_margin := 70.0
@export var bar_spacing := 8.0

var bars: Array[ColorRect] = []
var iteration_counter := 0
var max_value := 1
var hud_label: Label


func _ready() -> void:
	_setup_hud()
	if DisplayServer.get_name() == "headless":
		hud_label.text = "Headless startup OK."
		return

	var input := [8, 3, 6, 2, 7, 1, 5, 4]
	await doAlgoIteration(input, PackedInt32Array(), "Start")
	await _run_bubble_sort_demo(input.duplicate())
	hud_label.text += "\nDone. Replace _run_bubble_sort_demo with your own algorithm."


# Call this function from your algorithm after every state change.
func doAlgoIteration(values: Array, highlights: PackedInt32Array = PackedInt32Array(), note: String = "") -> void:
	if values.is_empty():
		return

	iteration_counter += 1
	max_value = max(1, _max_of(values))
	_ensure_bar_count(values.size())

	var viewport_size: Vector2 = get_viewport_rect().size
	var usable_width: float = viewport_size.x - side_margin * 2.0
	var usable_height: float = viewport_size.y - top_margin - bottom_margin
	var value_count: int = values.size()
	var gap_count: int = maxi(0, value_count - 1)
	var bar_width: float = maxf(10.0, (usable_width - float(gap_count) * bar_spacing) / float(value_count))
	var baseline_y: float = viewport_size.y - bottom_margin

	var highlighted := {}
	for i in highlights:
		highlighted[i] = true

	var tween := create_tween().set_parallel(true)
	for i in range(values.size()):
		var value := int(values[i])
		var bar := bars[i]
		var normalized := float(value) / float(max_value)
		var bar_height: float = maxf(6.0, normalized * usable_height)
		var x: float = side_margin + float(i) * (bar_width + bar_spacing)
		var y: float = baseline_y - bar_height
		var target_color := HIGHLIGHT_COLOR if highlighted.has(i) else BAR_COLOR

		tween.tween_property(bar, "position", Vector2(x, y), iteration_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(bar, "size", Vector2(bar_width, bar_height), iteration_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(bar, "color", target_color, iteration_duration * 0.5)

	_update_hud(note, values)
	await tween.finished


func _run_bubble_sort_demo(data: Array) -> void:
	var n := data.size()
	for i in range(n):
		var swapped := false
		for j in range(n - 1 - i):
			if data[j] > data[j + 1]:
				var temp: int = int(data[j])
				data[j] = data[j + 1]
				data[j + 1] = temp
				swapped = true
			await doAlgoIteration(data, PackedInt32Array([j, j + 1]), "Compare %d and %d" % [j, j + 1])
		if not swapped:
			break


func _ensure_bar_count(target_count: int) -> void:
	while bars.size() < target_count:
		var bar := ColorRect.new()
		bar.color = BAR_COLOR
		bar.position = Vector2(side_margin, get_viewport_rect().size.y - bottom_margin)
		bar.size = Vector2(10, 10)
		add_child(bar)
		bars.append(bar)

	while bars.size() > target_count:
		var bar_to_remove: ColorRect = bars.pop_back()
		bar_to_remove.queue_free()


func _setup_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	hud_label = Label.new()
	hud_label.position = Vector2(16, 16)
	hud_label.size = Vector2(900, 90)
	hud_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud_label.add_theme_color_override("font_color", Color("#f2f2f2"))
	layer.add_child(hud_label)

	var background := ColorRect.new()
	background.color = Color("#101219")
	background.position = Vector2.ZERO
	background.size = get_viewport_rect().size
	background.z_index = -1
	add_child(background)


func _update_hud(note: String, values: Array) -> void:
	var nums := PackedStringArray()
	for v in values:
		nums.append(str(v))
	var values_text := ", ".join(nums)
	hud_label.text = "Iteration %d\n%s\n[%s]" % [iteration_counter, note, values_text]


func _max_of(values: Array) -> int:
	var current_max := int(values[0])
	for v in values:
		var value := int(v)
		if value > current_max:
			current_max = value
	return current_max
