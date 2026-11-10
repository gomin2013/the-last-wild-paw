class_name UiKit
extends RefCounted
## Shared menu look (series palette: graphite, cream, coral) and the small widgets every menu uses.

const GRAPHITE := Color("1f2433")
const PANEL := Color("272d3e")
const CREAM := Color("f4ede1")
const CORAL := Color("f2643d")
const MUTED := Color("c9c2b5")

static var _theme: Theme


static func theme() -> Theme:
	if _theme:
		return _theme
	var t := Theme.new()
	t.default_font_size = 24
	t.set_stylebox("panel", "PanelContainer", _box(Color(GRAPHITE, 0.94), 36, 14))
	t.set_stylebox("normal", "Button", _box(PANEL, 12, 999))
	t.set_stylebox("hover", "Button", _box(CORAL, 12, 999))
	t.set_stylebox("pressed", "Button", _box(CORAL.darkened(0.15), 12, 999))
	var focus := _box(Color(0, 0, 0, 0), 12, 999)
	focus.set_border_width_all(3)
	focus.border_color = CORAL
	t.set_stylebox("focus", "Button", focus)
	for c in ["font_color", "font_focus_color"]:
		t.set_color(c, "Button", CREAM)
	for c in ["font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		t.set_color(c, "Button", GRAPHITE)
	t.set_color("font_color", "Label", CREAM)
	t.set_color("font_color", "CheckButton", CREAM)
	_theme = t
	return t


## Dimmed full-screen overlay with a centred panel; returns the box that pages fill.
static func overlay(parent: Node, dim := 0.55) -> VBoxContainer:
	var root := Control.new()
	root.name = "Overlay"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = theme()
	var shade := ColorRect.new()
	shade.color = Color(GRAPHITE, dim)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.custom_minimum_size.x = 520
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	parent.add_child(root)
	return box


## Clears the box and starts a new page with a title and optional body text.
static func page(box: VBoxContainer, title: String, body := "") -> void:
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()
	var t := Label.new()
	t.text = title
	t.add_theme_font_size_override("font_size", 42)
	box.add_child(t)
	if body:
		var b := Label.new()
		b.text = body
		b.add_theme_color_override("font_color", MUTED)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(b)


static func button(box: VBoxContainer, text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size.y = 52
	b.pressed.connect(action)
	box.add_child(b)
	return b


## Focus the first button so keyboard and gamepad work without a mouse.
static func focus_first(box: VBoxContainer) -> void:
	for c in box.get_children():
		if c is Button:
			(c as Button).call_deferred("grab_focus")
			return


## With `touch`, a first line names the on-screen buttons.
static func controls_text(touch := DisplayServer.is_touchscreen_available()) -> String:
	return (
		(
			"Touch:  left / right buttons run   ·   big right button jumps   ·   claw pounces\n\n"
			if touch
			else ""
		)
		+ "Run:  ← →  or  A D   ·   D-pad / left stick\n"
		+ "Jump:  Z  or  Space   ·   A / Cross  (hold to jump higher)\n"
		+ "Pounce:  X  or  J   ·   X / Square\n"
		+ "Pause:  Esc   ·   Start\n\n"
		+ "Find food to heal, pounce twice to chase a jackal off, and reach the den."
	)


## Volume sliders and the fullscreen toggle, saved by GameState.
static func settings(box: VBoxContainer, game_state: Node) -> void:
	for key: String in ["master", "music", "sfx"]:
		var row := HBoxContainer.new()
		var name := Label.new()
		name.text = {"master": "Master", "music": "Music", "sfx": "Sound effects"}[key]
		name.custom_minimum_size.x = 200
		row.add_child(name)
		var s := HSlider.new()
		s.min_value = 0.0
		s.max_value = 1.0
		s.step = 0.05
		s.value = game_state.settings[key]
		s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		s.value_changed.connect(func(v: float) -> void: game_state.set_setting(key, v))
		row.add_child(s)
		box.add_child(row)
	var full := CheckButton.new()
	full.text = "Fullscreen"
	full.button_pressed = game_state.settings["fullscreen"]
	full.toggled.connect(func(on: bool) -> void: game_state.set_setting("fullscreen", on))
	box.add_child(full)


static func _box(color: Color, pad: float, radius: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(pad)
	s.content_margin_left = pad * 1.6
	s.content_margin_right = pad * 1.6
	return s
