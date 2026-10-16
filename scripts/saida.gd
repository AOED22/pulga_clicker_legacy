extends Area2D

# para onde vai quando a fase termina
@export_file("*.tscn") var proxima_cena := "res://cenas/main.tscn"

var usada := false


func _ready() -> void:
	body_entered.connect(_ao_entrar)


func _ao_entrar(corpo: Node2D) -> void:
	if usada or not (corpo is Jogador):
		return
	usada = true
	get_tree().call_group("fase", "terminar", proxima_cena)
