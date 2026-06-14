extends Node
## Autoload sound manager (Kenney CC0 sfx). Call Sfx.play("click"/"dice"/"cash"/"confirm").

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []

func _ready() -> void:
	_streams = {
		"click": _ld("res://assets/audio/sfx/kenney_interface/Audio/click_001.ogg"),
		"dice": _ld("res://assets/audio/sfx/kenney_casino/Audio/chips-collide-1.ogg"),
		"cash": _ld("res://assets/audio/sfx/kenney_casino/Audio/chip-lay-1.ogg"),
		"confirm": _ld("res://assets/audio/sfx/kenney_interface/Audio/confirmation_001.ogg"),
	}
	for i in 6:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)

func _ld(path: String) -> AudioStream:
	return load(path) if ResourceLoader.exists(path) else null

func play(sound: String) -> void:
	var s: AudioStream = _streams.get(sound)
	if s == null:
		return
	for p in _players:
		if not p.playing:
			p.stream = s
			p.play()
			return
	_players[0].stream = s
	_players[0].play()
