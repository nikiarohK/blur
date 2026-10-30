extends Control
@export var max_value: float = 100.0
@export var decrease_per_second: float = 5.0   # сколько убавляется за 1 секунду
@export var increase_amount: float = 20.0      # сколько прибавляется за нажатие
@export var action_name: StringName = &"add_energy"

@onready var progress_bar: ProgressBar = $ProgressBar

var current_value: float = 100.0

func _ready() -> void:
	progress_bar.max_value = max_value
	progress_bar.min_value = 0.0
	progress_bar.value = current_value

func _process(delta: float) -> void:
	# плавное убывание, не зависящее от FPS
	current_value = max(current_value - decrease_per_second * delta, 0.0)
	progress_bar.value = current_value

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(action_name):
		current_value = min(current_value + increase_amount, max_value)
		progress_bar.value = current_value
