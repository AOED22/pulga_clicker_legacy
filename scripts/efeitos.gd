extends Node

# Evita hit stops sobrepostos
var parado := false


# Congela o jogo por um instante pra dar peso ao impacto
func hit_stop(duracao := 0.05, escala := 0.05) -> void:
	if parado:
		return
	parado = true
	Engine.time_scale = escala
	await get_tree().create_timer(duracao, true, false, true).timeout
	Engine.time_scale = 1.0
	parado = false


# Treme a camera (trauma de 0 a 1)
func tremer(trauma: float) -> void:
	var camera: CameraJogador = get_tree().get_first_node_in_group("camera")
	if camera:
		camera.adicionar_trauma(trauma)


# Cria uma cena de efeito na posicao indicada
func criar(cena: PackedScene, posicao: Vector2, rotacao := 0.0) -> Node2D:
	if cena == null:
		return null
	var instancia: Node2D = cena.instantiate()
	instancia.position = posicao
	instancia.rotation = rotacao
	get_tree().current_scene.add_child(instancia)
	return instancia
