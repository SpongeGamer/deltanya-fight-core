extends Node2D
## Copies the currently visible sprite into small textured fragments. Their
## motion is calculated in screen space, so scaled sprites drift at the same speed.

const DURATION := 1.55
const PIECE_SIZE_ON_SCREEN := 4.0

var _texture: Texture2D
var _pieces: Array[Dictionary] = []
var _elapsed := 0.0
var _flip_h := false
var _flip_v := false
var _tint := Color.WHITE

func setup(source: CanvasItem) -> bool:
	if not (source is Sprite2D or source is AnimatedSprite2D):
		return false
	var frame_region := Rect2()
	var local_rect := Rect2()
	if source is Sprite2D:
		var s := source as Sprite2D
		_texture = s.texture
		if _texture == null:
			return false
		var bounds := s.region_rect if s.region_enabled else Rect2(Vector2.ZERO, _texture.get_size())
		var frame_size := bounds.size / Vector2(s.hframes, s.vframes)
		frame_region = Rect2(bounds.position + Vector2(s.frame % s.hframes, s.frame / s.hframes) * frame_size, frame_size)
		local_rect = s.get_rect()
		_flip_h = s.flip_h
		_flip_v = s.flip_v
	else:
		var s := source as AnimatedSprite2D
		if s.sprite_frames == null or not s.sprite_frames.has_animation(s.animation):
			return false
		_texture = s.sprite_frames.get_frame_texture(s.animation, s.frame)
		if _texture == null:
			return false
		frame_region = Rect2(Vector2.ZERO, _texture.get_size())
		var origin := s.offset
		if s.centered:
			origin -= frame_region.size * 0.5
		local_rect = Rect2(origin, frame_region.size)
		_flip_h = s.flip_h
		_flip_v = s.flip_v

	# Unwrap atlas frames so both drawing and alpha checks use the atlas coordinates.
	while _texture is AtlasTexture:
		var atlas := _texture as AtlasTexture
		frame_region.position += atlas.region.position
		_texture = atlas.atlas
		if _texture == null:
			return false

	transform = get_parent().global_transform.affine_inverse() * source.global_transform
	_tint = source.modulate
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var world_scale: Vector2 = source.get_global_transform().get_scale().abs()
	var step_x := maxi(1, roundi(PIECE_SIZE_ON_SCREEN / maxf(world_scale.x, 0.01)))
	var step_y := maxi(1, roundi(PIECE_SIZE_ON_SCREEN / maxf(world_scale.y, 0.01)))
	var image := _texture.get_image()
	var width := roundi(frame_region.size.x)
	var height := roundi(frame_region.size.y)
	if width <= 0 or height <= 0:
		return false
	for y in range(0, height, step_y):
		for x in range(0, width, step_x):
			var w := mini(step_x, width - x)
			var h := mini(step_y, height - y)
			var source_x := width - x - w if _flip_h else x
			var source_y := height - y - h if _flip_v else y
			var crop := Rect2(frame_region.position + Vector2(source_x, source_y), Vector2(w, h))
			if image != null and not _has_visible_pixel(image, crop):
				continue
			var center := local_rect.position + Vector2(x + w * 0.5, y + h * 0.5)
			var world_velocity := Vector2(randf_range(18.0, 42.0), randf_range(-12.0, 8.0))
			_pieces.append({
				"crop": crop, "center": center,
				"velocity": source.global_transform.basis_xform_inv(world_velocity),
				"delay": randf_range(0.08, 0.20) + 0.25 * float(x) / float(width),
				"lifetime": randf_range(0.75, 1.1),
			})
	return not _pieces.is_empty()

func _has_visible_pixel(image: Image, rect: Rect2) -> bool:
	var x0 := maxi(0, floori(rect.position.x))
	var y0 := maxi(0, floori(rect.position.y))
	var x1 := mini(image.get_width(), ceili(rect.end.x))
	var y1 := mini(image.get_height(), ceili(rect.end.y))
	for y in range(y0, y1):
		for x in range(x0, x1):
			if image.get_pixel(x, y).a > 0.01:
				return true
	return false

func _process(delta: float) -> void:
	_elapsed += delta
	queue_redraw()

func _draw() -> void:
	if _texture == null:
		return
	for piece in _pieces:
		var age := maxf(0.0, _elapsed - float(piece["delay"]))
		var progress := clampf(age / float(piece["lifetime"]), 0.0, 1.0)
		if progress >= 1.0:
			continue
		var crop: Rect2 = piece["crop"]
		var drift: Vector2 = piece["velocity"] * age
		var color := _tint
		color.a *= 1.0 - progress * progress
		draw_set_transform(piece["center"] + drift, 0.0, Vector2(-1.0 if _flip_h else 1.0, -1.0 if _flip_v else 1.0))
		draw_texture_rect_region(_texture, Rect2(-crop.size * 0.5, crop.size), crop, color)
	draw_set_transform(Vector2.ZERO)
