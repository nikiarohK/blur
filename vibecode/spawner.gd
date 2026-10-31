# res://monsters/spawner.gd
extends Node2D

const MONSTER_SCENES: Array[PackedScene] = [
	preload("res://monster_eyes.tscn"),
	preload("res://monster_ears.tscn"),
	preload("res://monster_breath.tscn"),
]

@export var spawn_interval_min: float = 3.0
@export var spawn_interval_max: float = 7.0
@export var spawn_area: Rect2 = Rect2(-400, -300, 800, 600)
@export var first_spawn_delay: float = 10.0

@export_range(1, 10) var max_alive: int = 1

var timer: float
var _last_scene: PackedScene = null   # ← запоминаем последнего монстра

func _ready() -> void:
	timer = first_spawn_delay


func _process(delta: float) -> void:
	if _alive_count() >= max_alive:
		return

	timer -= delta
	if timer <= 0.0:
		timer = randf_range(spawn_interval_min, spawn_interval_max)
		_spawn()

func _alive_count() -> int:
	var n := 0
	for child in get_children():
		if child is MonsterBase and child.is_active:
			n += 1
	return n

func _spawn() -> void:
	# Формируем пул кандидатов: все, кроме последнего заспавненного
	var candidates := MONSTER_SCENES
	if _last_scene != null and MONSTER_SCENES.size() > 1:
		candidates = MONSTER_SCENES.filter(
			func(s: PackedScene) -> bool: return s != _last_scene
		)

	var scene: PackedScene = candidates.pick_random()
	_last_scene = scene                                  # ← обновляем «последний»

	var m := scene.instantiate() as MonsterBase
	m.global_position = spawn_area.position + Vector2(
		randf() * spawn_area.size.x,
		randf() * spawn_area.size.y
	)
	add_child(m)
