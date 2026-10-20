extends Area2D

@export var intervalo_spawn := 0.2
@export var entre_ondas := 1.2
@export var fx_spawn: PackedScene

var iniciada := false
var indice := 0
var vivos := 0
var jogador: Jogador

@onready var ondas: Node2D = $Ondas
@onready var portoes: Node2D = $Portoes


func _ready() -> void:
	jogador = get_tree().get_first_node_in_group("jogador")
	body_entered.connect(_ao_entrar)


func _ao_entrar(corpo: Node2D) -> void:
	if iniciada or not (corpo is Jogador):
		return
	iniciada = true
	for portao: Portao in portoes.get_children():
		portao.fechar()
	jogador.poder = jogador.poder_max
	await get_tree().create_timer(0.6).timeout
	_proxima_onda()


func _proxima_onda() -> void:
	if indice >= ondas.get_child_count():
		_vencer()
		return
	var onda := ondas.get_child(indice)
	indice += 1
	vivos = onda.get_child_count()
	for filho in onda.get_children():
		var ponto := filho as SpawnInimigo
		var inimigo: Inimigo = ponto.cena.instantiate()
		inimigo.position = ponto.global_position
		get_tree().current_scene.add_child(inimigo)
		inimigo.morreu.connect(_ao_inimigo_morrer)
		Efeitos.criar(fx_spawn, inimigo.position)
		await get_tree().create_timer(intervalo_spawn).timeout


func _ao_inimigo_morrer() -> void:
	vivos -= 1
	if vivos > 0:
		return
	await get_tree().create_timer(entre_ondas).timeout
	_proxima_onda()


func _vencer() -> void:
	for portao: Portao in portoes.get_children():
		portao.abrir()
	Efeitos.tremer(0.5)
	Efeitos.hit_stop(0.15, 0.2)
