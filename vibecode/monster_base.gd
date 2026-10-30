# res://monsters/monster_base.gd
class_name MonsterBase
extends Node2D

@export_group("Attack")
@export var time_to_attack: float = 3.0
@export var damage: int = 1

@export_group("Lifetime")
@export var lifetime_min: float = 5.0
@export var lifetime_max: float = 10.0

@export var player_path: NodePath

var player: Node2D
var attack_time_left: float
var lifetime_left: float
var is_active: bool = true

func _ready() -> void:
	if player_path and not player_path.is_empty():
		player = get_node_or_null(player_path)
	else:
		player = get_tree().get_first_node_in_group("player")

	if not player:
		push_error("Monster: игрок не найден. Добавь игрока в группу 'player'")
		is_active = false
		return

	attack_time_left = time_to_attack
	lifetime_left = randf_range(lifetime_min, lifetime_max)

	print("[", monster_name(), "] появился. Условие: ", counter_name(),
		" | атака через ", time_to_attack,
		"с | исчезнет через ", snapped(lifetime_left, 0.1), "с")

func _process(delta: float) -> void:
	if not is_active or not player:
		return

	var condition_met: bool = _is_condition_met()
	visible = not condition_met

	# Время жизни идёт всегда — защита от «вечного» монстра
	lifetime_left -= delta
	if lifetime_left <= 0.0:
		print("[", monster_name(), "] исчез по таймеру жизни")
		_die()
		return

	# Таймер атаки стоит, пока условие выполнено
	if condition_met:
		return

	attack_time_left -= delta
	if attack_time_left <= 0.0:
		player.take_damage(damage)
		print("[", monster_name(), "] атаковал на ", damage, " и исчез")
		_die()

# --- Переопределяется в наследниках ---

func _is_condition_met() -> bool:
	return false

func monster_name() -> String:
	return "Monster"

func counter_name() -> String:
	return "?"

# --- Общий килл ---

func _die() -> void:
	is_active = false
	queue_free()
