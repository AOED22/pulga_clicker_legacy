class_name CameraJogador
extends Camera2D

@export var tremor_max := 16.0
@export var tremor_queda := 2.0
@export var olhar_fator := 0.12
@export var olhar_max := 70.0
@export var olhar_suavidade := 6.0

var tremida := 0.0
var olhar := Vector2.ZERO


func adicionar_tremida(valor: float) -> void:
	tremida = minf(tremida + valor, 1.0)


func definir_limites(limites: Rect2i) -> void:
	limit_left = limites.position.x
	limit_top = limites.position.y
	limit_right = limites.end.x
	limit_bottom = limites.end.y


func _process(delta: float) -> void:
	tremida = maxf(tremida - tremor_queda * delta, 0.0)
	var forca := tremida * tremida * tremor_max
	var tremor := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * forca

	var centro := get_viewport_rect().size / 2.0
	var alvo := (get_viewport().get_mouse_position() - centro) / zoom.x * olhar_fator
	olhar = olhar.lerp(alvo.limit_length(olhar_max), 1.0 - exp(-olhar_suavidade * delta))

	offset = olhar + tremor
