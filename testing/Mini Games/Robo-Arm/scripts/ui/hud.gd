extends CanvasLayer

@onready var time_label: Label = %TimeLabel
@onready var message_label: Label = %MessageLabel

func _ready() -> void:
	message_label.text = ''
	GameManager.level_completed.connect(_on_completed)
	GameManager.level_failed.connect(_on_failed)

func _process(_d: float) -> void:
	var t := GameManager.elapsed
	time_label.text = '%02d:%02d' % [floori(t / 60.0), int(t) % 60]

func _on_completed(stats: Dictionary) -> void:
	message_label.text = 'Victoire !  %.1f s  —  R pour rejouer' % stats['time']

func _on_failed(reason: String) -> void:
	message_label.text = reason + '  —  R pour rejouer'
