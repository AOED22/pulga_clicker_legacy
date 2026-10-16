class_name GotaAcida
extends Area2D

@export var velocidade := 250.0
@export var dano := 1
@export var duracao := 1.8
@export var raio_acerto := 14.0
@export var fx_splat: PackedScene

var direcao := Vector2.RIGHT
var tempo := 0.0
var estourada := false
var jogador: Jogador

@onready var visual: Node2D = $Visual


func _ready() -> void:
	add_to_group("projeteis")
	jogador = get_tree().get_first_node_in_group("jogador")
	rotation = direcao.angle()
	# bate em parede ou obstaculo e estoura
	body_entered.connect(_ao_bater)
	visual.scale = Vector2(0.4, 0.4)


func _physics_process(delta: float) -> void:
	tempo += delta
	global_position += direcao * velocidade * delta
	visual.scale = visual.scale.lerp(Vector2.ONE, 1.0 - exp(-20.0 * delta))
	if tempo >= duracao:
		_estourar()
		return
	# dash e pulo passam direto (pode_ser_atingido cuida disso)
	var perto := global_position.distance_to(jogador.global_position) <= raio_acerto
	if perto and jogador.pode_ser_atingido():
		jogador.receber_dano(dano, direcao)
		_estourar()


# chamada pela agulha do jogador
func cortar() -> void:
	_estourar()


func _ao_bater(_corpo: Node2D) -> void:
	_estourar()


func _estourar() -> void:
	if estourada:
		return
	estourada = true
	remove_from_group("projeteis")
	Efeitos.criar(fx_splat, global_position, direcao.angle() + PI)
	queue_free()
