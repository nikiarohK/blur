# res://monsters/spawner.gd
extends Node2D

const MONSTER_SCENES: Array[PackedScene] = [
	preload("res://monster_eyes.tscn"),
	preload("res://monster_ears.tscn"),
	preload("res://monster_breath.tscn"),
]

@export var spawn_interval: float = 4.0
@export var spawn_area: Rect2 = Rect2(-400, -300, 800, 600)

@export_range(1, 10) var max_alive: int = 1

var timer: float

func _process(delta: float) -> void:
	if _alive_count() >= max_alive:
		return

	timer -= delta
	if timer <= 0.0:
		timer = spawn_interval
		_spawn()

func _alive_count() -> int:
	var n := 0
	for child in get_children():
		if child is MonsterBase and child.is_active:
			n += 1
	return n

func _spawn() -> void:
	var scene: PackedScene = MONSTER_SCENES.pick_random()
	var m := scene.instantiate() as MonsterBase
	m.global_position = spawn_area.position + Vector2(
		randf() * spawn_area.size.x,
		randf() * spawn_area.size.y
	)
	add_child(m)
