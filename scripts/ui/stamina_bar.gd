extends TextureProgressBar

@onready var player = $"/root/Town/Player"

func _ready() -> void:
	max_value = player.max_stamina

func _process(_delta: float) -> void:
	value = player.stamina
	var fill_style = get_theme_stylebox("fill").duplicate()
	var ratio = player.stamina / player.max_stamina
	fill_style.bg_color = Color(1.0 - ratio, ratio, 0.0) 
	add_theme_stylebox_override("fill", fill_style)
