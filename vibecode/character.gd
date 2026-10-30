extends Node2D

# --- Воздух---
@export var action_close_eyes: StringName = &"action_hold_breath"
@export var max_air_value: float = 100.0
@export var increase_air_per_second: float = 10.0  # растёт, пока глаза закрыты
@export var decrease_air_per_second: float = 5.0   # убывает, пока глаза открыты

# --- Огонь ---
@export_group("Campfire")
@export var action_add_fire: StringName = &"action_add_fire"
@export var max_fire_value: float = 100.0
@export var fire_decrease_per_second: float = 5.0   # медленное убывание
@export var fire_increase_on_press: float = 15.0    # +N за одно нажатие

@onready var air_bar: ProgressBar = $air
@onready var fire_bar: ProgressBar = $Fire


var current_air: float = 100.0
var current_fire: float = 100.0
var breath_holded: bool = false 

func _ready() -> void:
	air_bar.max_value = max_air_value
	air_bar.min_value = 0.0
	air_bar.value = current_air
	
	fire_bar.max_value = max_fire_value
	fire_bar.min_value = 0.0
	fire_bar.value = current_fire

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(action_close_eyes):
		breath_holded = true

	if event.is_action_released(action_close_eyes):
		breath_holded = false
	
	if event.is_action_pressed(action_add_fire):
		current_fire = min(current_fire + fire_increase_on_press, max_fire_value)

func _process(delta: float) -> void:
	if breath_holded:
		current_air = max(current_air - decrease_air_per_second * delta, 0.0)
	else:
		current_air = min(current_air + increase_air_per_second * delta, max_air_value) 
	air_bar.value = current_air
	# Огонь: плавно убывает независимо от FPS
	current_fire = max(current_fire - fire_decrease_per_second * delta, 0.0)
	fire_bar.value = current_fire
	
