class_name Checkpoint
extends Area2D

# numero da zona da fase (a primeira zona nao precisa de checkpoint)
@export var indice := 1
@export var cena_anel: PackedScene


func _ready() -> void:
	body_entered.connect(_ao_entrar)


func _ao_entrar(corpo: Node2D) -> void:
	if not (corpo is Jogador) or TapeteVelho.checkpoint >= indice:
		return
	TapeteVelho.checkpoint = indice
	# anelzinho avisando que o progresso foi salvo
	var anel: AnelChoque = cena_anel.instantiate()
	anel.raio = 60.0
	anel.position = global_position
	get_tree().current_scene.add_child(anel)
