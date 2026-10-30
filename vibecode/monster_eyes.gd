# res://monsters/monster_eyes.gd
class_name MonsterEyes
extends MonsterBase

func _is_condition_met() -> bool:
	return player.eyes_closed

func monster_name() -> String:
	return "Глазастик"

func counter_name() -> String:
	return "закрыть глаза"
