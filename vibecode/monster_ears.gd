# res://monsters/monster_ears.gd
class_name MonsterEars
extends MonsterBase

func _is_condition_met() -> bool:
	return player.ears_closed

func monster_name() -> String:
	return "Шептун"

func counter_name() -> String:
	return "закрыть уши"
