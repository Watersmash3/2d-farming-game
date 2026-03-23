extends PanelContainer

@onready var icon: TextureRect = $Icon
@onready var count: Label = $Count

func set_slot(tex: Texture2D, amount: int) -> void:
	# Keep the slot box itself visible at all times
	visible = true

	if tex == null or amount <= 0:
		icon.visible = false
		count.visible = false
		icon.texture = null
		count.text = ""
		return

	icon.visible = true
	count.visible = true
	icon.texture = tex
	count.text = "x%d" % amount
