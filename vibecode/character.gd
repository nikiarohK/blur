extends Node2D

# --- Воздух---
@export_group("Air")
@export var action_hold_breath: StringName = &"action_hold_breath"
@export var max_air_value: float = 100.0
@export var increase_air_per_second: float = 10.0
@export var decrease_air_per_second: float = 5.0

# --- Огонь ---
@export_group("Campfire")
@export var action_add_fire: StringName = &"action_add_fire"
@export var max_fire_value: float = 100.0
@export var fire_decrease_per_second: float = 5.0
@export var fire_increase_on_press: float = 15.0
@export var fire_cooldown: float = 1.0

# --- Глаза / Уши ---
@export_group("Eyes & Ears")
@export var action_close_eyes: StringName = &"action_close_eyes"
@export var action_close_ears: StringName = &"action_close_ears"

# --- Здоровье ---
@export_group("Health")
@export var max_hp: int = 3


@onready var air_bar: ProgressBar = $air
@onready var fire_bar: ProgressBar = $Fire
@onready var hand_sprite: Sprite2D = $Sprite2D


var bus_idx = AudioServer.get_bus_index("Sfx")
var current_air: float = 100.0
var current_fire: float = 100.0
var breath_holded: bool = false
var eyes_closed: bool = false
var ears_closed: bool = false

var current_hp: int = 3
var is_dead: bool = false

var fire_cooldown_timer: float = 0.0

var _prev_eyes_closed: bool = false
var _prev_ears_closed: bool = false

func _ready() -> void:
	add_to_group("player")  # чтобы монстры находили игрока

	air_bar.max_value = max_air_value
	air_bar.min_value = 0.0
	air_bar.value = current_air

	fire_bar.max_value = max_fire_value
	fire_bar.min_value = 0.0
	fire_bar.value = current_fire

	current_hp = max_hp
	print("[HP] старт — ", current_hp, "/", max_hp)
	_print_status()
	_prev_eyes_closed = eyes_closed
	_prev_ears_closed = ears_closed
	hand_sprite.visible = false

func _unhandled_input(event: InputEvent) -> void:
	# --- 1) Отпускания всегда ---
	if event.is_action_released(action_hold_breath):
		breath_holded = false
	if event.is_action_released(action_close_eyes):
		eyes_closed = false
	if event.is_action_released(action_close_ears):
		ears_closed = false
		AudioServer.set_bus_volume_db(bus_idx, 0.0)

	if is_dead:
		return

	# --- 2) Кулдаун огня блокирует всё ---
	if fire_cooldown_timer > 0.0:
		return

	# --- 3) air / eyes / ears — можно жать в любом сочетании ---
	if event.is_action_pressed(action_hold_breath):
		breath_holded = true
	if event.is_action_pressed(action_close_eyes):
		eyes_closed = true
	if event.is_action_pressed(action_close_ears):
		ears_closed = true
		AudioServer.set_bus_volume_db(bus_idx, -50.0)

	# --- 4) fire — только если ни одно из трёх не удерживается ---
	if event.is_action_pressed(action_add_fire):
		if breath_holded or eyes_closed or ears_closed:
			return
		current_fire = min(current_fire + fire_increase_on_press, max_fire_value)
		fire_cooldown_timer = fire_cooldown
		print("Огонь +", fire_increase_on_press, " → ", current_fire, " (кулдаун ", fire_cooldown, "с)")

func _process(delta: float) -> void:
	if fire_cooldown_timer > 0.0:
		fire_cooldown_timer = max(fire_cooldown_timer - delta, 0.0)

	if breath_holded:
		current_air = max(current_air - decrease_air_per_second * delta, 0.0)
	else:
		current_air = min(current_air + increase_air_per_second * delta, max_air_value)
	air_bar.value = current_air

	current_fire = max(current_fire - fire_decrease_per_second * delta, 0.0)
	fire_bar.value = current_fire
	if fire_bar.value == 0.0:
		_die()

	if eyes_closed != _prev_eyes_closed or ears_closed != _prev_ears_closed:
		_prev_eyes_closed = eyes_closed
		_prev_ears_closed = ears_closed
		_print_status()
	if eyes_closed:
		hand_sprite.visible = true
	else:
		hand_sprite.visible = false

# --- Здоровье ---

func take_damage(amount: int) -> void:
	if amount <= 0 or is_dead:
		return
	current_hp = max(current_hp - amount, 0)
	print("[HP] получено ", amount, " урона → ", current_hp, "/", max_hp)
	if current_hp <= 0:
		_die()

func heal(amount: int) -> void:
	if amount <= 0 or is_dead:
		return
	current_hp = min(current_hp + amount, max_hp)
	print("[HP] вылечено ", amount, " → ", current_hp, "/", max_hp)

func _die() -> void:
	is_dead = true
	print("[HP] персонаж УМЕР")
	get_tree().change_scene_to_file("res://death_screen.tscn")

# --- Прочее ---

func _print_status() -> void:
	var eyes_str: String = "Глаза: ЗАКРЫТЫ" if eyes_closed else "Глаза: открыты"
	var ears_str: String = "Уши: ЗАКРЫТЫ" if ears_closed else "Уши: открыты"
	print(eyes_str, " | ", ears_str)
