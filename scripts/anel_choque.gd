class_name AnelChoque
extends Node2D

@export var duracao := 0.3

var raio := 80.0

@onready var sprite: Sprite2D = $Sprite


func _ready() -> void:
	# Cresce ate o raio final e some
	var escala_final := raio * 2.0 / sprite.texture.get_size().x
	scale = Vector2.ONE * 0.1
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "scale", Vector2.ONE * escala_final, duracao).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, duracao)
	tween.chain().tween_callback(queue_free)
