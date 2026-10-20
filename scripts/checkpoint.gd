class_name Checkpoint
extends Area2D

@export var indice := 1
@export var cena_anel: PackedScene
@export var fx_ativar: PackedScene

@export_group("Luz")
@export var luz_apagada := 0.25
@export var luz_acesa := 0.8

static var atual := -1

@onready var luz: PointLight2D = $Luz
@onready var brasa: CPUParticles2D = $Brasa


func _ready() -> void:
	body_entered.connect(_ao_entrar)
	if atual >= indice:
		luz.energy = luz_acesa
		brasa.emitting = true
	else:
		luz.energy = luz_apagada


func _ao_entrar(corpo: Node2D) -> void:
	if not (corpo is Jogador) or atual >= indice:
		return
	atual = indice
	create_tween().tween_property(luz, "energy", luz_acesa, 0.6)
	brasa.emitting = true
	Efeitos.criar(fx_ativar, global_position)
	Efeitos.tremer(0.15)
	Efeitos.criar_anel(cena_anel, global_position, 60.0)
