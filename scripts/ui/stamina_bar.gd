extends TextureProgressBar

var player

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	if player == null:
		set_process(false)
		return
	max_value = player.max_stamina

func _process(_delta: float) -> void:
	if player == null:
		return
	value = player.stamina
	var fill_style = get_theme_stylebox("fill").duplicate()
	var ratio = player.stamina / player.max_stamina
	fill_style.bg_color = Color(1.0 - ratio, ratio, 0.0) 
	add_theme_stylebox_override("fill", fill_style)
