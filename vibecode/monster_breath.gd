# res://monsters/monster_breath.gd
class_name MonsterBreath
extends MonsterBase

func _is_condition_met() -> bool:
	return player.breath_holded

func monster_name() -> String:
	return "Душитель"

func counter_name() -> String:
	return "задержать дыхание"
