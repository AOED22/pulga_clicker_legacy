extends Node

var parado := false


func hit_stop(duracao := 0.05, escala := 0.05) -> void:
	if parado:
		return
	parado = true
	Engine.time_scale = escala
	await get_tree().create_timer(duracao, true, false, true).timeout
	Engine.time_scale = 1.0
	parado = false


func tremer(tremida: float) -> void:
	var camera: CameraJogador = get_tree().get_first_node_in_group("camera")
	if camera:
		camera.adicionar_tremida(tremida)


func criar(cena: PackedScene, posicao: Vector2, rotacao := 0.0) -> Node2D:
	if cena == null:
		return null
	var instancia: Node2D = cena.instantiate()
	instancia.position = posicao
	instancia.rotation = rotacao
	get_tree().current_scene.add_child(instancia)
	return instancia


func criar_anel(cena: PackedScene, posicao: Vector2, raio: float, cor := Color.WHITE) -> void:
	if cena == null:
		return
	var anel: AnelChoque = cena.instantiate()
	anel.raio = raio
	anel.modulate = cor
	anel.position = posicao
	get_tree().current_scene.add_child(anel)
