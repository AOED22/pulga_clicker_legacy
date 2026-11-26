class_name CameraJogador
extends Camera2D

@export var tremor_max := 16.0
@export var tremor_queda := 2.0
@export var olhar_fator := 0.12
@export var olhar_max := 70.0
@export var olhar_suavidade := 6.0

var tremida := 0.0
var olhar := Vector2.ZERO

# foco: faz a camera olhar para outro no (ex: a Rainha na transicao). 0 = normal, 1 = centrada no alvo
var foco: Node2D = null
var foco_forca := 0.0


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

	var alvo_olhar := olhar
	if foco_forca > 0.0 and is_instance_valid(foco):
		alvo_olhar = olhar.lerp(foco.global_position - global_position, foco_forca)

	# o Godot nao aplica os limites ao offset: sem isso o foco/olhar mostra o cinza fora do mapa.
	# "base" e onde o Godot ja deixa a camera; o offset so pode ir ate onde a tela ainda cabe nos limites.
	var base := _limitar_centro(global_position)
	var desejado := _limitar_centro(global_position + alvo_olhar)
	offset = (desejado - base) + tremor


# centro da camera ajustado para a tela inteira ficar dentro dos limites do mapa
func _limitar_centro(centro: Vector2) -> Vector2:
	var meia := get_viewport_rect().size / zoom * 0.5
	return Vector2(
		_limitar_eixo(centro.x, limit_left + meia.x, limit_right - meia.x),
		_limitar_eixo(centro.y, limit_top + meia.y, limit_bottom - meia.y)
	)


func _limitar_eixo(valor: float, minimo: float, maximo: float) -> float:
	if minimo > maximo:
		return (minimo + maximo) * 0.5
	return clampf(valor, minimo, maximo)
