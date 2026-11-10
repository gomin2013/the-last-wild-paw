class_name TouchControls
extends CanvasLayer
## On-screen buttons for phones and tablets (shown only on a touchscreen): move left / right on the
## left thumb, pounce and jump on the right, pause at the top. Each button presses the same input
## action as the keyboard, so Kai and the menus need nothing extra. Hidden while the game is paused
## (the pause menu's own buttons take taps then). Glyphs are drawn shapes: the web build has no
## font with arrow symbols.

const INK := Color("f4ede1")

## action, top-left corner, diameter (game px, 1280x720)
const BUTTONS := [
	["move_left", Vector2(40, 540), 150.0],
	["move_right", Vector2(210, 540), 150.0],
	["attack", Vector2(920, 560), 140.0],
	["jump", Vector2(1090, 470), 160.0],
	["pause", Vector2(604, 12), 72.0],
]


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	for b: Array in BUTTONS:
		add_child(_button(b[0], b[1], b[2]))


func _process(_delta: float) -> void:
	# Hide the whole layer: TOUCHSCREEN_ONLY hides a button's texture, not its glyph child.
	visible = DisplayServer.is_touchscreen_available() and not get_tree().paused


func _button(action: String, pos: Vector2, d: float) -> TouchScreenButton:
	var t := TouchScreenButton.new()
	t.action = action
	t.position = pos
	t.visibility_mode = TouchScreenButton.VISIBILITY_TOUCHSCREEN_ONLY
	t.passby_press = action.begins_with("move")  # slide the thumb between left and right
	t.texture_normal = _disc(d, 0.28)
	t.texture_pressed = _disc(d, 0.5)
	var shape := CircleShape2D.new()
	shape.radius = d / 2.0
	t.shape = shape
	t.add_child(_glyph(action, d))
	return t


## The button's symbol, centred in a `d`-wide disc: arrows, a three-line claw swipe, pause bars.
static func _glyph(action: String, d: float) -> Node2D:
	var c := Vector2(d, d) / 2.0
	var r := d * 0.2
	var tri := {
		"move_left": [Vector2(-r, 0), Vector2(r * 0.7, -r), Vector2(r * 0.7, r)],
		"move_right": [Vector2(r, 0), Vector2(-r * 0.7, -r), Vector2(-r * 0.7, r)],
		"jump": [Vector2(0, -r), Vector2(r, r * 0.7), Vector2(-r, r * 0.7)],
	}
	var root := Node2D.new()
	if action in tri:
		var poly := Polygon2D.new()
		poly.polygon = PackedVector2Array(tri[action])
		poly.position = c
		poly.color = INK
		root.add_child(poly)
	elif action == "attack":
		for i in 3:
			var line := Line2D.new()
			var x := (i - 1) * r * 0.6
			line.points = PackedVector2Array(
				[c + Vector2(x - r * 0.4, -r), c + Vector2(x + r * 0.4, r)]
			)
			line.width = d * 0.05
			line.default_color = INK
			line.begin_cap_mode = Line2D.LINE_CAP_ROUND
			line.end_cap_mode = Line2D.LINE_CAP_ROUND
			root.add_child(line)
	else:
		for x: float in [-r * 0.45, r * 0.45]:
			var bar := Polygon2D.new()
			var w := r * 0.3
			bar.polygon = PackedVector2Array(
				[Vector2(-w / 2, -r), Vector2(w / 2, -r), Vector2(w / 2, r), Vector2(-w / 2, r)]
			)
			bar.position = c + Vector2(x, 0)
			bar.color = INK
			root.add_child(bar)
	return root


## A soft-edged cream disc `d` px wide.
static func _disc(d: float, alpha: float) -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.93, 1.0])
	var c := Color(0.96, 0.93, 0.88, alpha)
	g.colors = PackedColorArray([c, c, Color(c, 0.0)])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = int(d)
	tex.height = int(d)
	return tex
