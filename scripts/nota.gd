extends Node2D

# recado riscado no tapete: aparece devagar quando o jogador chega perto
@export_multiline var texto := ""
@export var raio := 280.0

var jogador: Jogador

@onready var rotulo: Label = $Texto


func _ready() -> void:
	jogador = get_tree().get_first_node_in_group("jogador")
	rotulo.text = texto
	modulate.a = 0.0


func _process(delta: float) -> void:
	var distancia := global_position.distance_to(jogador.global_position)
	var alvo := clampf((raio - distancia) / 100.0, 0.0, 1.0)
	modulate.a = lerpf(modulate.a, alvo, 1.0 - exp(-4.0 * delta))
