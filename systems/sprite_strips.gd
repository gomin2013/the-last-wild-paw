class_name SpriteStrips
## Builds an AnimatedSprite2D from the strips in a sprite folder (one PNG per animation plus
## sprites.json, written by .claude/tools/sprites/export_sprites.py). Each animation keeps its own
## offset so the feet sit on the node's origin whatever the frame size.


## Adds every animation in `dir` to `sprite` (names get `prefix`); returns name -> offset.
static func add(sprite: AnimatedSprite2D, dir: String, prefix := "") -> Dictionary:
	if sprite.sprite_frames == null:
		sprite.sprite_frames = SpriteFrames.new()
	var frames := sprite.sprite_frames
	var meta: Dictionary = (load(dir + "/sprites.json") as JSON).data
	sprite.scale = Vector2.ONE * float(meta.scale)
	var offsets := {}
	for anim: String in meta.anims:
		var a: Dictionary = meta.anims[anim]
		var tex: Texture2D = load("%s/%s.png" % [dir, anim])
		var anim_name := prefix + anim
		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, a.fps)
		frames.set_animation_loop(anim_name, a.loop)
		for i in int(a.frames):
			var region := AtlasTexture.new()
			region.atlas = tex
			region.region = Rect2(i * a.w, 0, a.w, a.h)
			frames.add_frame(anim_name, region)
		offsets[anim_name] = Vector2(a.w / 2.0 - a.pivot[0], -a.h / 2.0)
	return offsets


## Plays `anim_name` (restarting only when it changes) with its offset.
static func play(sprite: AnimatedSprite2D, offsets: Dictionary, anim_name: String) -> void:
	if sprite.animation != anim_name:
		sprite.play(anim_name)
	sprite.offset = offsets[anim_name]
