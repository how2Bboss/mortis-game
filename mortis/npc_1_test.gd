extends Node3D

func _on_ready() -> void:
	
	$Shuffling/AnimationPlayer.play("mixamo_com", -1, 0.6)
