extends Node2D

@onready var countdown_label: Label = $CountdownLabel

func _ready() -> void:
	$ForestSFX.play()
	$FireSFX.play()

func _process(_delta: float) -> void:
	if $Timer.is_stopped():
		return
	# time_left — сколько секунд осталось до срабатывания
	var seconds_left: float = $Timer.time_left
	# Показываем целое число секунд, округляя вверх: 3.2 → 4
	countdown_label.text = str(ceili(seconds_left))


func _on_timer_timeout() -> void:
	get_tree().change_scene_to_file("res://win_screen.tscn")
