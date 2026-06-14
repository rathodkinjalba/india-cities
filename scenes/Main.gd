extends Control
## M0 smoke scene: confirms the cloud-built APK runs on the device.
## Replaced by the real menu/board in later milestones.

func _ready() -> void:
	var v := Engine.get_version_info()
	var label := $Center/Label as Label
	label.text = "India Cities\nMonopoly-style\n\nBuild OK\nGodot %s" % v.string
	print("India Cities booted on Godot ", v.string)
