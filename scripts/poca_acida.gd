class_name PocaAcida
extends Node2D

@export var raio := 40.0
@export var duracao := 5.0
@export var dano := 1
@export var intervalo_dano := 0.8
@export var atraso := 0.35

var tempo := 0.0
var recarga := 0.0
var jogador: Jogador

@onready var sprite: Sprite2D = $Sprite
@onready var bolhas: CPUParticles2D = $Bolhas


func _ready() -> void:
	add_to_group("pocas")
	jogador = get_tree().get_first_node_in_group("jogador")
	var escala_final := raio * 2.0 / sprite.texture.get_size().x
	sprite.scale = Vector2.ZERO
	sprite.modulate.a = 0.45
	var tween := create_tween()
	tween.tween_property(sprite, "scale", Vector2.ONE * escala_final, 0.3).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	bolhas.emission_sphere_radius = raio * 0.7


func _physics_process(delta: float) -> void:
	tempo += delta
	recarga = maxf(recarga - delta, 0.0)

	if tempo >= duracao:
		queue_free()
		return

	
	if tempo < atraso:
		sprite.modulate.a = 0.45
	else:
		sprite.modulate.a = clampf(duracao - tempo, 0.0, 1.0) * (0.85 + 0.15 * sin(tempo * 6.0))
	bolhas.emitting = tempo >= atraso and tempo < duracao - 1.0

	if tempo < atraso or recarga > 0.0:
		return
	if not is_instance_valid(jogador) or jogador.morto:
		return

	var ate := jogador.global_position - global_position
	if ate.length() <= raio and jogador.pode_ser_atingido():
		var direcao := ate.normalized() if ate.length() > 1.0 else Vector2.DOWN
		jogador.receber_dano(dano, direcao)
		recarga = intervalo_dano
