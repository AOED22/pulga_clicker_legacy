class_name Portao
extends StaticBody2D

@export var fx_poeira: PackedScene

var tween: Tween

@onready var colisao: CollisionShape2D = $Colisao
@onready var visual: Node2D = $Visual


func _ready() -> void:
	colisao.disabled = true
	visual.visible = false


func fechar() -> void:
	colisao.set_deferred("disabled", false)
	visual.visible = true
	visual.scale.y = 0.05
	_animar(1.0)
	Efeitos.criar(fx_poeira, global_position)
	Efeitos.tremer(0.4)


func abrir() -> void:
	colisao.set_deferred("disabled", true)
	_animar(0.05)
	tween.tween_callback(visual.hide)
	Efeitos.criar(fx_poeira, global_position)


func _animar(escala_y: float) -> void:
	if tween and tween.is_valid():
		tween.kill()
	tween = create_tween()
	tween.tween_property(visual, "scale:y", escala_y, 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
