class_name PocaAcida
extends Node2D

# poca que o acido da Rainha deixa no chao: obriga o jogador a sair de cima.
# usa a arte em pixel art (duas versoes: pequena e grande) e machuca de tempos em tempos.

@export var raio := 40.0
@export var duracao := 5.0
@export var dano := 1
@export var intervalo_dano := 0.8
@export var atraso := 0.35

var tempo := 0.0
var recarga := 0.0
var jogador: Jogador

@onready var sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	add_to_group("pocas")
	jogador = get_tree().get_first_node_in_group("jogador")
	# duas artes: 80px (raio ~40) e 128px (raio ~64); a escala so ajusta a diferenca
	var grande := raio > 48.0
	sprite.play(&"grande" if grande else &"pequena")
	var tamanho := 122.0 if grande else 74.0
	var escala_final := raio * 2.0 / tamanho
	sprite.scale = Vector2.ZERO
	sprite.modulate.a = 0.45
	var tween := create_tween()
	tween.tween_property(sprite, "scale", Vector2.ONE * escala_final, 0.3).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)


func _physics_process(delta: float) -> void:
	tempo += delta
	recarga = maxf(recarga - delta, 0.0)

	if tempo >= duracao:
		queue_free()
		return

	# comeca fraquinha (ainda nao machuca) e some devagar no final
	if tempo < atraso:
		sprite.modulate.a = 0.45
	else:
		sprite.modulate.a = clampf(duracao - tempo, 0.0, 1.0)

	if tempo < atraso or recarga > 0.0:
		return
	if not is_instance_valid(jogador) or jogador.morto:
		return

	var ate := jogador.global_position - global_position
	if ate.length() <= raio and jogador.pode_ser_atingido():
		var direcao := ate.normalized() if ate.length() > 1.0 else Vector2.DOWN
		jogador.receber_dano(dano, direcao)
		recarga = intervalo_dano
