extends Node2D

const _Train = preload("res://train.gd")
const _Car = preload("res://car.gd")

## Main scene entry point.
## Manages game state transitions between phases:
## TrackLay -> Playing -> Upgrading -> GameOver

var train: _Train = null
var track: Track = null


func _ready() -> void:
	train = _Train.new()
	train.initialize(200.0, 100.0, 100.0, 100.0, 0.0, 0)
	track = Track.new()
	track.initialize(100.0, 100)
