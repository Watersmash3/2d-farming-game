extends Resource
class_name CropSpriteSheet

## Describes a horizontal strip sprite sheet where each column is one growth stage.
## Assign the PNG to `sheet` and set frame_width to the pixel width of one frame.
## Leave frame_height at 0 to auto-use the full sheet height (recommended).

@export var sheet: Texture2D
@export var frame_width: int = 16
## Height of one frame in pixels. Leave at 0 to automatically use the full sheet height.
@export var frame_height: int = 0

## Resolved height: full sheet height when frame_height is 0.
func _resolved_height() -> int:
	if sheet == null:
		return 0
	return frame_height if frame_height > 0 else sheet.get_height()

## Returns an AtlasTexture for the given stage index (0 = seed, last = ripe).
func get_frame(stage: int) -> AtlasTexture:
	if sheet == null:
		return null
	var h := _resolved_height()
	if h == 0 or frame_width == 0:
		return null
	var a := AtlasTexture.new()
	a.atlas = sheet
	a.region = Rect2(stage * frame_width, 0, frame_width, h)
	return a

## Total number of frames available in this sheet.
func frame_count() -> int:
	if sheet == null or frame_width <= 0:
		return 0
	return int(sheet.get_width()) / frame_width
