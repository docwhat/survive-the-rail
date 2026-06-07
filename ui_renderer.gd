extends CanvasLayer
## Displays game state: speed, health, resources, phase indicator.

var label_speed: Label = null
var label_health: Label = null
var label_resources: Label = null
var label_phase: Label = null
var health_bar: ProgressBar = null


func _ready() -> void:
	# Find UI elements by name (set in scene)
	label_speed = $SpeedLabel as Label
	label_health = $HealthLabel as Label
	label_resources = $ResourcesLabel as Label
	label_phase = $PhaseLabel as Label
	health_bar = $HealthBar as ProgressBar


func update(train: Train, track: Track) -> void:
	# Speed display
	var speed_kmh: float = train.speed * 3.6 # world units to rough km/h
	if label_speed != null:
		label_speed.text = "Speed: %d" % int(speed_kmh)

	# Health display
	if label_health != null:
		var hp_pct: float = train.health / train.max_health * 100.0
		label_health.text = "HP: %d/%d" % [int(train.health), int(train.max_health)]

	if health_bar != null:
		health_bar.max_value = train.max_health
		health_bar.value = train.health

	# Resources display
	if track != null and label_resources != null:
		label_resources.text = "Resources: %.0f" % track.get_resources()

	# Phase indicator
	if label_phase != null:
		label_phase.text = "Phase: PLAYING"
