class_name ObjetoCenario
extends StaticBody2D

signal quebrou

enum Reacao { CHACOALHAR, BALANCAR, GIRAR }

@export_group("Resistencia")
@export var vida := 1
@export var quebra_no_dash := false

@export_group("Reacao")
@export var reacao := Reacao.CHACOALHAR
@export var reagir_ao_passar := false
@export var deslize := 0.0

@export_group("Cenas")
@export var fx_hit: PackedScene
@export var fx_quebra: PackedScene
@export var tremor_quebra := 0.1

var quebrado := false
var tween_visual: Tween
var tween_posicao: Tween

@onready var visual: Node2D = $Visual
@onready var contato: Area2D = get_node_or_null("Contato")


func _ready() -> void:
	add_to_group("objetos")
	if contato:
		contato.body_entered.connect(_ao_contato)


func atingido(direcao: Vector2) -> void:
	if quebrado:
		return
	if vida == 1:
		_quebrar(direcao)
		return
	if vida > 1:
		vida -= 1
	Efeitos.criar(fx_hit, global_position, direcao.angle())
	_reagir(direcao)


func _ao_contato(corpo: Node2D) -> void:
	if quebrado or not (corpo is Jogador):
		return
	var direcao := (global_position - corpo.global_position).normalized()
	if quebra_no_dash and corpo.em_dash():
		_quebrar(direcao)
	elif reagir_ao_passar and not (tween_visual and tween_visual.is_running()):
		_reagir(direcao)


func _reagir(direcao: Vector2) -> void:
	if tween_visual and tween_visual.is_valid():
		tween_visual.kill()
	visual.scale = Vector2.ONE
	visual.rotation = 0.0
	var lado := 1.0 if direcao.x >= 0.0 else -1.0
	tween_visual = create_tween()
	match reacao:
		Reacao.CHACOALHAR:
			visual.scale = Vector2(1.3, 0.7)
			tween_visual.tween_property(visual, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		Reacao.BALANCAR:
			visual.rotation = 0.5 * lado
			tween_visual.tween_property(visual, "rotation", 0.0, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		Reacao.GIRAR:
			tween_visual.tween_property(visual, "rotation", TAU * lado, 0.45).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	if deslize > 0.0:
		if tween_posicao and tween_posicao.is_valid():
			tween_posicao.kill()
		tween_posicao = create_tween()
		tween_posicao.tween_property(self, "position", position + direcao * deslize, 0.3).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)


func _quebrar(direcao: Vector2) -> void:
	quebrado = true
	remove_from_group("objetos")
	Efeitos.criar(fx_quebra, global_position, direcao.angle())
	if tremor_quebra > 0.0:
		Efeitos.tremer(tremor_quebra)
	for filho in get_children():
		if filho is CollisionShape2D:
			filho.set_deferred("disabled", true)
	quebrou.emit()
	queue_free()
