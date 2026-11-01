extends Node2D

# --- Воздух ---
@export_group("Air")
@export var action_hold_breath: StringName = &"action_hold_breath"
@export var max_air_value: float = 100.0
@export var increase_air_per_second: float = 10.0
@export var decrease_air_per_second: float = 5.0
# урон и его частота при нулевом воздухе
@export var air_damage: int = 1
@export var air_damage_interval: float = 1.0   # раз в секунду
var air_damage_timer: float = 0.0

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
@export_range(0.0, 1.0) var blood_alpha_at_full_hp: float = 0.05
@export_range(0.0, 1.0) var blood_alpha_at_zero_hp: float = 1.0
@export var blood_fade_duration: float = 0.25


@onready var air_bar: TextureProgressBar = $air
@onready var fire_visual: AnimatedSprite2D = $FireVisual
@onready var hand_sprite: Sprite2D = $Sprite2D
@onready var blood_sprite: Sprite2D = $blood_sprite

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

var _blood_tween: Tween


func _ready() -> void:
	add_to_group("player")

	current_hp = max_hp
	update_sprite_opacity(false)

	# ДОБАВЛЕНО: синхронизируем ресурсы с их максимумами из инспектора
	current_air = max_air_value
	current_fire = max_fire_value

	air_bar.max_value = max_air_value
	air_bar.min_value = 0.0
	air_bar.value = current_air

	_update_fire_visual()

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
		_update_fire_visual()
		fire_cooldown_timer = fire_cooldown
		print("Огонь +", fire_increase_on_press, " → ", current_fire, " (кулдаун ", fire_cooldown, "с)")


func _process(delta: float) -> void:
	if fire_cooldown_timer > 0.0:
		fire_cooldown_timer = max(fire_cooldown_timer - delta, 0.0)

	# --- Воздух ---
	if breath_holded:
		current_air = max(current_air - decrease_air_per_second * delta, 0.0)
	else:
		current_air = min(current_air + increase_air_per_second * delta, max_air_value)
	air_bar.value = current_air

	# Урон, пока воздуха нет
	if current_air <= 0.0 and not is_dead:
		air_damage_timer += delta
		if air_damage_timer >= air_damage_interval:
			air_damage_timer -= air_damage_interval
			take_damage(air_damage)
	else:
		air_damage_timer = 0.0

	# --- Огонь ---
	current_fire = max(current_fire - fire_decrease_per_second * delta, 0.0)
	_update_fire_visual()
	if current_fire <= 0.0 and not is_dead:
		_die()

	# --- Глаза / уши ---
	if eyes_closed != _prev_eyes_closed or ears_closed != _prev_ears_closed:
		_prev_eyes_closed = eyes_closed
		_prev_ears_closed = ears_closed
		_print_status()
	hand_sprite.visible = eyes_closed


# --- Здоровье ---

func take_damage(amount: int) -> void:
	if amount <= 0 or is_dead:
		return
	current_hp = max(current_hp - amount, 0)
	print("[HP] получено ", amount, " урона → ", current_hp, "/", max_hp)
	update_sprite_opacity(true)
	if current_hp <= 0:
		_die()


func heal(amount: int) -> void:
	if amount <= 0 or is_dead:
		return
	current_hp = min(current_hp + amount, max_hp)
	print("[HP] вылечено ", amount, " → ", current_hp, "/", max_hp)
	update_sprite_opacity(true)


func _die() -> void:
	if is_dead:
		return
	is_dead = true
	print("[HP] персонаж УМЕР")
	get_tree().change_scene_to_file("res://death_screen.tscn")


# --- Огонь: визуал ---

# 5 равномерных стадий огня: 100% → fire_5 (максимум), 0% → fire_1 (минимум).
func _update_fire_visual() -> void:
	if not is_instance_valid(fire_visual) or fire_visual.sprite_frames == null:
		return

	var anim: StringName

	if current_fire <= 0.0:
		# Спец-случай: огонь погас полностью
		anim = &"fire_1"
	else:
		var ratio: float = clampf(current_fire / max_fire_value, 0.0, 1.0)
		# 4 равные полосы в (0, 1]: делим на 4, получаем индексы 0..3
		var stage: int = clampi(int(floor(ratio * 4.0)), 0, 3)
		anim = StringName("fire_%d" % (stage + 2))

	if not fire_visual.sprite_frames.has_animation(anim):
		return

	if fire_visual.animation != anim:
		fire_visual.play(anim)
	elif not fire_visual.is_playing():
		fire_visual.play(anim)


# --- Прочее ---

func _print_status() -> void:
	var eyes_str: String = "Глаза: ЗАКРЫТЫ" if eyes_closed else "Глаза: открыты"
	var ears_str: String = "Уши: ЗАКРЫТЫ" if ears_closed else "Уши: открыты"
	print(eyes_str, " | ", ears_str)


func update_sprite_opacity(animated: bool = false) -> void:
	var hp_ratio: float = float(current_hp) / float(max_hp)
	var damage_ratio: float = 1.0 - hp_ratio
	var target_alpha: float = lerp(blood_alpha_at_full_hp, blood_alpha_at_zero_hp, damage_ratio)

	if not animated:
		if _blood_tween and _blood_tween.is_valid():
			_blood_tween.kill()
		blood_sprite.modulate.a = target_alpha
		return

	if _blood_tween and _blood_tween.is_valid():
		_blood_tween.kill()
	_blood_tween = create_tween()
	_blood_tween.tween_property(blood_sprite, "modulate:a", target_alpha, blood_fade_duration)
