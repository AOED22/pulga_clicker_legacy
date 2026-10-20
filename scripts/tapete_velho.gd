extends Node2D

@export var limites := Rect2i(0, 0, 5200, 600)
@export_multiline var texto_abertura := ""
@export_multiline var texto_final := ""
@export var nome_fase := ""

@onready var jogador: Jogador = $Jogador
@onready var zonas: Node2D = $Zonas
@onready var fade: ColorRect = $Transicao/Fade
@onready var titulo: Label = $Transicao/Titulo
@onready var aviso_fase: Control = $Transicao/AvisoFase
@onready var rotulo_fase: Label = $Transicao/AvisoFase/Nome


func _ready() -> void:
	add_to_group("fase")
	jogador.definir_limites(limites)
	rotulo_fase.text = nome_fase
	aviso_fase.modulate.a = 0.0
	fade.color.a = 1.0
	titulo.modulate.a = 0.0
	if Checkpoint.atual >= 1:
		_voltar_ao_checkpoint()
	else:
		_abertura()


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("reiniciar"):
		if Input.is_key_pressed(KEY_SHIFT):
			Checkpoint.atual = -1
		get_tree().reload_current_scene()


func _abertura() -> void:
	titulo.text = texto_abertura
	jogador.set_physics_process(false)
	var tween := create_tween()
	tween.tween_property(titulo, "modulate:a", 1.0, 1.2)
	tween.tween_interval(1.8)
	tween.tween_property(titulo, "modulate:a", 0.0, 0.8)
	tween.tween_callback(jogador.set_physics_process.bind(true))
	tween.tween_property(fade, "color:a", 0.0, 1.5)
	tween.tween_callback(_mostrar_nome_fase)


func _voltar_ao_checkpoint() -> void:
	for i in Checkpoint.atual:
		zonas.get_child(i).queue_free()
	var ponto: Checkpoint = zonas.get_child(Checkpoint.atual).get_node("Checkpoint")
	jogador.global_position = ponto.global_position
	jogador.camera.reset_smoothing()
	create_tween().tween_property(fade, "color:a", 0.0, 0.6)


func _mostrar_nome_fase() -> void:
	var tween := create_tween()
	tween.tween_property(aviso_fase, "modulate:a", 1.0, 0.8)
	tween.tween_interval(2.4)
	tween.tween_property(aviso_fase, "modulate:a", 0.0, 1.2)


func terminar(cena: String) -> void:
	Checkpoint.atual = -1
	jogador.set_physics_process(false)
	titulo.text = texto_final
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 1.2)
	tween.tween_property(titulo, "modulate:a", 1.0, 1.0)
	tween.tween_interval(2.0)
	tween.tween_callback(get_tree().change_scene_to_file.bind(cena))
