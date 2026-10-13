extends Node2D

@export var cena_acaro: PackedScene
@export var fx_spawn: PackedScene
@export var limites := Rect2i(0, 0, 1600, 1000)
@export var entre_ondas := 3.0
@export var acaros_base := 3
@export var variacao_spawn := 30.0

var onda := 0
var espera := 0.0

@onready var jogador: Jogador = $Jogador
@onready var spawns: Node2D = $Spawns


func _ready() -> void:
	jogador.definir_limites(limites)
	_gerar_onda()


func _process(delta: float) -> void:
	# Quando nao sobra inimigo, espera um pouco e chama a proxima onda
	if get_tree().get_nodes_in_group("inimigos").is_empty():
		espera += delta
		if espera >= entre_ondas:
			_gerar_onda()


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("reiniciar"):
		get_tree().reload_current_scene()


# Cria os acaros nos pontos de spawn (cada onda traz mais um)
func _gerar_onda() -> void:
	onda += 1
	espera = 0.0
	var pontos := spawns.get_children()
	for i in acaros_base + onda:
		var ponto: Marker2D = pontos[i % pontos.size()]
		var variacao := Vector2(randf_range(-variacao_spawn, variacao_spawn), randf_range(-variacao_spawn, variacao_spawn))
		var acaro: Acaro = cena_acaro.instantiate()
		acaro.position = ponto.position + variacao
		add_child(acaro)
		Efeitos.criar(fx_spawn, acaro.position)
